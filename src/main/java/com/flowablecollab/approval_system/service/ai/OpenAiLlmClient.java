package com.flowablecollab.approval_system.service.ai;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
@ConditionalOnProperty(name = "ai.llm.provider", havingValue = "openai")
public class OpenAiLlmClient implements LlmClient {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private final String baseUrl;
    private final String apiKey;
    private final String model;
    private final double temperature;

    @Autowired
    public OpenAiLlmClient(
            RestTemplateBuilder restTemplateBuilder,
            ObjectMapper objectMapper,
            @Value("${ai.llm.openai.base-url:https://api.openai.com/v1}") String baseUrl,
            @Value("${ai.llm.openai.api-key:}") String apiKey,
            @Value("${ai.llm.openai.model:gpt-5.4-mini}") String model,
            @Value("${ai.llm.openai.temperature:0.2}") double temperature,
            @Value("${ai.llm.openai.connect-timeout-seconds:10}") long connectTimeoutSeconds,
            @Value("${ai.llm.openai.read-timeout-seconds:30}") long readTimeoutSeconds) {
        this(
                restTemplateBuilder
                        .setConnectTimeout(Duration.ofSeconds(connectTimeoutSeconds))
                        .setReadTimeout(Duration.ofSeconds(readTimeoutSeconds))
                        .build(),
                objectMapper,
                baseUrl,
                apiKey,
                model,
                temperature
        );
    }

    OpenAiLlmClient(
            RestTemplate restTemplate,
            ObjectMapper objectMapper,
            String baseUrl,
            String apiKey,
            String model,
            double temperature) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
        this.baseUrl = baseUrl;
        this.apiKey = apiKey;
        this.model = model;
        this.temperature = temperature;
    }

    @Override
    public Suggestion suggestApproval(SuggestionRequest request) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("OpenAI api-key is required when ai.llm.provider=openai");
        }
        String endpoint = normalizeBaseUrl(baseUrl) + "/chat/completions";

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("model", model);
        payload.put("temperature", temperature);
        payload.put("messages", List.of(
                Map.of("role", "system", "content", buildSystemPrompt()),
                Map.of("role", "user", "content", buildUserPrompt(request))
        ));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        ResponseEntity<String> response;
        try {
            response = restTemplate.postForEntity(endpoint, new HttpEntity<>(payload, headers), String.class);
        } catch (RestClientException ex) {
            throw new IllegalStateException("OpenAI request failed", ex);
        }

        return parseSuggestion(response.getBody());
    }

    private Suggestion parseSuggestion(String rawBody) {
        try {
            JsonNode root = objectMapper.readTree(rawBody);
            String content = root.path("choices").path(0).path("message").path("content").asText("");
            String jsonText = extractJsonObject(content);

            JsonNode suggestionNode = jsonText == null
                    ? objectMapper.createObjectNode()
                    : objectMapper.readTree(jsonText);

            Suggestion suggestion = new Suggestion();
            String decision = suggestionNode.path("decision").asText("REVIEW").toUpperCase();
            if (!"APPROVE".equals(decision) && !"REJECT".equals(decision) && !"REVIEW".equals(decision)) {
                decision = "REVIEW";
            }
            suggestion.setDecision(decision);
            suggestion.setSummary(suggestionNode.path("summary").asText("No summary from model."));
            suggestion.setRiskFlags(readStringArray(suggestionNode.path("riskFlags")));
            suggestion.setFollowUpChecks(readStringArray(suggestionNode.path("followUpChecks")));
            suggestion.setModel(root.path("model").asText(model));
            return suggestion;
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to parse OpenAI response", ex);
        }
    }

    private List<String> readStringArray(JsonNode node) {
        if (node == null || !node.isArray()) {
            return List.of();
        }
        List<String> values = new ArrayList<>();
        for (JsonNode item : node) {
            if (item.isTextual() && !item.asText().isBlank()) {
                values.add(item.asText());
            }
        }
        return values;
    }

    private String extractJsonObject(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        int start = text.indexOf('{');
        int end = text.lastIndexOf('}');
        if (start < 0 || end <= start) {
            return null;
        }
        return text.substring(start, end + 1);
    }

    private String buildSystemPrompt() {
        return "You are an approval assistant. Return strict JSON only with keys: decision, summary, riskFlags, followUpChecks. "
                + "decision must be APPROVE, REJECT, or REVIEW. riskFlags and followUpChecks must be string arrays.";
    }

    private String buildUserPrompt(SuggestionRequest request) {
        String variablesJson;
        try {
            variablesJson = objectMapper.writeValueAsString(request.getVariables() == null ? Map.of() : request.getVariables());
        } catch (JsonProcessingException ex) {
            variablesJson = "{}";
        }
        return "Task context:\n"
                + "- taskId: " + safe(request.getTaskId()) + "\n"
                + "- taskName: " + safe(request.getTaskName()) + "\n"
                + "- processInstanceId: " + safe(request.getProcessInstanceId()) + "\n"
                + "- businessKey: " + safe(request.getBusinessKey()) + "\n"
                + "- title: " + safe(request.getTitle()) + "\n"
                + "- variables: " + variablesJson + "\n"
                + "Please output strict JSON only.";
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }

    private String normalizeBaseUrl(String value) {
        if (value == null || value.isBlank()) {
            return "https://api.openai.com/v1";
        }
        if (value.endsWith("/")) {
            return value.substring(0, value.length() - 1);
        }
        return value;
    }
}
