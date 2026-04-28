package com.flowablecollab.approval_system.service.ai;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.service.settings.AiProviderSettingsService;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
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
    private final String fallbackModel;
    private final double temperature;
    private final AiProviderSettingsService aiProviderSettingsService;

    @Autowired
    public OpenAiLlmClient(
            RestTemplateBuilder restTemplateBuilder,
            ObjectMapper objectMapper,
            @Value("${ai.llm.openai.base-url:https://api.openai.com/v1}") String baseUrl,
            @Value("${ai.llm.openai.api-key:}") String apiKey,
            @Value("${ai.llm.openai.model:gpt-5.4-mini}") String fallbackModel,
            @Value("${ai.llm.openai.temperature:0.2}") double temperature,
            @Value("${ai.llm.openai.connect-timeout-seconds:10}") long connectTimeoutSeconds,
            @Value("${ai.llm.openai.read-timeout-seconds:30}") long readTimeoutSeconds,
            ObjectProvider<AiProviderSettingsService> aiProviderSettingsServiceProvider) {
        this(
                restTemplateBuilder
                        .setConnectTimeout(Duration.ofSeconds(connectTimeoutSeconds))
                        .setReadTimeout(Duration.ofSeconds(readTimeoutSeconds))
                        .build(),
                objectMapper,
                baseUrl,
                apiKey,
                fallbackModel,
                temperature,
                aiProviderSettingsServiceProvider.getIfAvailable()
        );
    }

    OpenAiLlmClient(
            RestTemplate restTemplate,
            ObjectMapper objectMapper,
            String baseUrl,
            String apiKey,
            String fallbackModel,
            double temperature) {
        this(restTemplate, objectMapper, baseUrl, apiKey, fallbackModel, temperature, null);
    }

    OpenAiLlmClient(
            RestTemplate restTemplate,
            ObjectMapper objectMapper,
            String baseUrl,
            String apiKey,
            String fallbackModel,
            double temperature,
            AiProviderSettingsService aiProviderSettingsService) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
        this.baseUrl = baseUrl;
        this.apiKey = apiKey;
        this.fallbackModel = fallbackModel;
        this.temperature = temperature;
        this.aiProviderSettingsService = aiProviderSettingsService;
    }

    @Override
    public Suggestion suggestApproval(SuggestionRequest request) {
        ChatResult chatResult = executeChat(List.of(
                Map.of("role", "system", "content", buildSuggestionSystemPrompt()),
                Map.of("role", "user", "content", buildSuggestionUserPrompt(request))
        ));

        JsonNode suggestionNode = parseJsonNode(chatResult.content());
        Suggestion suggestion = new Suggestion();
        suggestion.setDecision(suggestionNode.path("decision").asText(""));
        String recommendation = suggestionNode.path("recommendation").asText("");
        String summary = suggestionNode.path("summary").asText("");
        suggestion.setRecommendation(!recommendation.isBlank() ? recommendation : summary);
        suggestion.setSummary(!summary.isBlank() ? summary : recommendation);
        suggestion.setRiskWarnings(readStringArray(suggestionNode.path("riskWarnings")));
        suggestion.setAnomalies(readStringArray(suggestionNode.path("anomalies")));
        suggestion.setSupplementaryInfo(readStringArray(suggestionNode.path("supplementaryInfo")));
        suggestion.setApprovalComment(suggestionNode.path("approvalComment").asText(""));
        suggestion.setSuggestedFormUpdates(readObjectMap(suggestionNode.path("suggestedFormUpdates")));
        suggestion.setModel(chatResult.model());
        return suggestion;
    }

    @Override
    public FormCommandResult parseFormCommand(FormCommandParseRequest request) {
        ChatResult chatResult = executeChat(List.of(
                Map.of("role", "system", "content", buildFormCommandSystemPrompt()),
                Map.of("role", "user", "content", buildFormCommandUserPrompt(request))
        ));

        JsonNode resultNode = parseJsonNode(chatResult.content());
        JsonNode formDataNode = resultNode.path("formData");
        Map<String, Object> formData = formDataNode.isObject()
                ? objectMapper.convertValue(formDataNode, new TypeReference<Map<String, Object>>() {})
                : Map.of();

        FormCommandResult result = new FormCommandResult();
        result.setFormData(formData);
        result.setConfidence(resultNode.path("confidence").asDouble(0.0));
        result.setReasoning(resultNode.path("reasoning").asText(""));
        result.setModel(chatResult.model());
        return result;
    }

    @Override
    public FollowUpAnswer answerFollowUp(FollowUpRequest request) {
        ChatResult chatResult = executeChat(List.of(
                Map.of("role", "system", "content", buildFollowUpSystemPrompt()),
                Map.of("role", "user", "content", buildFollowUpUserPrompt(request))
        ));

        JsonNode answerNode = parseJsonNode(chatResult.content());
        String answer = answerNode.path("answer").asText("");
        if (answer.isBlank()) {
            answer = chatResult.content() == null ? "" : chatResult.content().trim();
        }

        FollowUpAnswer followUpAnswer = new FollowUpAnswer();
        followUpAnswer.setAnswer(answer);
        followUpAnswer.setModel(chatResult.model());
        return followUpAnswer;
    }

    private ChatResult executeChat(List<Map<String, Object>> messages) {
        AiProviderSettingsService.OpenAiRuntimeSettings runtimeSettings = resolveRuntimeSettings();
        String resolvedApiKey = runtimeSettings.apiKey();
        String resolvedModel = runtimeSettings.model();
        if (resolvedApiKey == null || resolvedApiKey.isBlank()) {
            throw new IllegalStateException("OpenAI api-key is required when ai.llm.provider=openai");
        }
        String endpoint = normalizeBaseUrl(runtimeSettings.baseUrl()) + "/chat/completions";

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("model", resolvedModel);
        payload.put("temperature", temperature);
        payload.put("messages", messages);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(resolvedApiKey);

        ResponseEntity<String> response;
        try {
            response = restTemplate.postForEntity(endpoint, new HttpEntity<>(payload, headers), String.class);
        } catch (RestClientException ex) {
            throw new IllegalStateException("OpenAI request failed", ex);
        }

        return parseChatResult(response.getBody(), resolvedModel);
    }

    private ChatResult parseChatResult(String rawBody, String defaultModel) {
        try {
            JsonNode root = objectMapper.readTree(rawBody);
            String content = extractAssistantContent(root);
            return new ChatResult(content, root.path("model").asText(defaultModel));
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to parse OpenAI response", ex);
        }
    }

    private String extractAssistantContent(JsonNode root) {
        JsonNode contentNode = root.path("choices").path(0).path("message").path("content");
        if (contentNode.isTextual()) {
            return contentNode.asText("");
        }
        if (contentNode.isArray()) {
            StringBuilder merged = new StringBuilder();
            for (JsonNode item : contentNode) {
                String text = null;
                if (item.isTextual()) {
                    text = item.asText();
                } else if (item.isObject()) {
                    if (item.path("text").isTextual()) {
                        text = item.path("text").asText();
                    } else if (item.path("content").isTextual()) {
                        text = item.path("content").asText();
                    } else if (item.path("value").isTextual()) {
                        text = item.path("value").asText();
                    }
                }
                if (text != null && !text.isBlank()) {
                    if (merged.length() > 0) {
                        merged.append('\n');
                    }
                    merged.append(text.trim());
                }
            }
            if (merged.length() > 0) {
                return merged.toString();
            }
        }

        String fallback = root.path("choices").path(0).path("text").asText("");
        if (!fallback.isBlank()) {
            return fallback;
        }
        return root.path("output_text").asText("");
    }

    private JsonNode parseJsonNode(String text) {
        String jsonText = extractJsonObject(text);
        try {
            return jsonText == null ? objectMapper.createObjectNode() : objectMapper.readTree(jsonText);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to parse OpenAI JSON payload", ex);
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

    private Map<String, Object> readObjectMap(JsonNode node) {
        if (node == null || !node.isObject()) {
            return Map.of();
        }
        return objectMapper.convertValue(node, new TypeReference<Map<String, Object>>() {
        });
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

    private String buildSuggestionSystemPrompt() {
        return "You are an approval assistant. Return strict JSON only with keys: "
                + "decision, recommendation, summary, riskWarnings, anomalies, supplementaryInfo, approvalComment, suggestedFormUpdates. "
                + "decision must be APPROVE or REJECT. Arrays must be arrays of strings. suggestedFormUpdates must be a JSON object.";
    }

    private String buildFollowUpSystemPrompt() {
        return "You are an approval assistant answering follow-up questions about an existing approval suggestion. "
                + "Return strict JSON only with key: answer.";
    }

    private String buildFormCommandSystemPrompt() {
        return """
                You are a precise form-filling assistant. Given a user's natural language command \
                and a list of form fields with their types, extract structured field values.

                Rules:
                1. Extract the value for each field from the command if present.
                2. For date/datetime fields: normalize to "YYYY-MM-DD" or "YYYY-MM-DD HH:MM:SS" format.
                3. For number fields: return the numeric value (not the unit text). If a number is written in Chinese (e.g. 两天), convert to digits (2).
                4. For select fields: match the command against available options (label or value), return the matched option value.
                5. For string fields: extract the relevant phrase, remove surrounding noise.
                6. If a field cannot be found in the command, do NOT include it in formData.
                7. Assign a confidence score (0.0 to 1.0) reflecting how well the command matches the fields.

                Return strict JSON only with keys: formData (object of fieldKey->value), confidence (number), reasoning (brief string).
                """;
    }

    private String buildFormCommandUserPrompt(FormCommandParseRequest request) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("command", request.getCommand());
        payload.put("fields", request.getFields().stream()
                .map(f -> {
                    Map<String, Object> field = new LinkedHashMap<>();
                    field.put("fieldKey", f.getFieldKey());
                    field.put("fieldType", f.getFieldType());
                    field.put("label", f.getLabel());
                    field.put("required", f.isRequired());
                    if (f.getOptions() != null && !f.getOptions().isEmpty()) {
                        field.put("options", f.getOptions());
                    }
                    return field;
                })
                .toList());
        return toJson(payload);
    }

    private String buildSuggestionUserPrompt(SuggestionRequest request) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("taskId", safe(request.getTaskId()));
        payload.put("taskName", safe(request.getTaskName()));
        payload.put("processInstanceId", safe(request.getProcessInstanceId()));
        payload.put("businessKey", safe(request.getBusinessKey()));
        payload.put("title", safe(request.getTitle()));
        payload.put("applicantId", request.getApplicantId());
        payload.put("variables", request.getVariables() == null ? Map.of() : request.getVariables());
        payload.put("applicantStats", request.getApplicantStats());
        payload.put("similarCaseStats", request.getSimilarCaseStats());
        payload.put("policyReferences", request.getPolicyReferences() == null ? List.of() : request.getPolicyReferences());
        payload.put("heuristicRiskWarnings", request.getHeuristicRiskWarnings() == null ? List.of() : request.getHeuristicRiskWarnings());
        payload.put("heuristicAnomalies", request.getHeuristicAnomalies() == null ? List.of() : request.getHeuristicAnomalies());
        return "审批上下文如下，请基于申请内容、申请人历史、同类案例、通用审批常识给出建议。\n"
                + toJson(payload);
    }

    private String buildFollowUpUserPrompt(FollowUpRequest request) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("taskId", safe(request.getTaskId()));
        payload.put("taskName", safe(request.getTaskName()));
        payload.put("processInstanceId", safe(request.getProcessInstanceId()));
        payload.put("businessKey", safe(request.getBusinessKey()));
        payload.put("title", safe(request.getTitle()));
        payload.put("variables", request.getVariables() == null ? Map.of() : request.getVariables());
        payload.put("currentSuggestion", request.getCurrentSuggestion());
        payload.put("conversationTurns", request.getConversationTurns() == null ? List.of() : request.getConversationTurns());
        payload.put("question", safe(request.getQuestion()));
        return "基于以下已有审批建议和对话历史，回答追问。\n"
                + toJson(payload);
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            return "{}";
        }
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

    private AiProviderSettingsService.OpenAiRuntimeSettings resolveRuntimeSettings() {
        if (aiProviderSettingsService == null) {
            return new AiProviderSettingsService.OpenAiRuntimeSettings(baseUrl, apiKey, fallbackModel);
        }
        return aiProviderSettingsService.resolveOpenAiRuntimeSettings(baseUrl, apiKey, fallbackModel);
    }

    private record ChatResult(String content, String model) {
    }
}
