package com.flowablecollab.approval_system.service.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.ExpectedCount.once;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class OpenAiLlmClientTests {

    @Test
    void suggestApproval_parsesStructuredJsonContent() {
        RestTemplate restTemplate = new RestTemplate();
        MockRestServiceServer server = MockRestServiceServer.bindTo(restTemplate).build();
        ObjectMapper objectMapper = new ObjectMapper();

        OpenAiLlmClient client = new OpenAiLlmClient(
                restTemplate,
                objectMapper,
                "https://api.openai.com/v1",
                "test-key",
                "gpt-5.4-mini",
                0.2
        );

        server.expect(once(), requestTo("https://api.openai.com/v1/chat/completions"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("Authorization", "Bearer test-key"))
                .andRespond(withSuccess("""
                        {
                          "id": "chatcmpl-1",
                          "model": "gpt-5.4-mini",
                          "choices": [
                            {
                              "index": 0,
                              "message": {
                                "role": "assistant",
                                "content": "{\\"decision\\":\\"REVIEW\\",\\"summary\\":\\"Needs additional receipt\\",\\"riskFlags\\":[\\"amount too high\\"],\\"followUpChecks\\":[\\"request invoice\\"]}"
                              }
                            }
                          ]
                        }
                        """, MediaType.APPLICATION_JSON));

        LlmClient.SuggestionRequest request = new LlmClient.SuggestionRequest();
        request.setTaskId("task-1");
        request.setVariables(Map.of("amount", 12000));
        LlmClient.Suggestion suggestion = client.suggestApproval(request);

        assertThat(suggestion.getDecision()).isEqualTo("REVIEW");
        assertThat(suggestion.getSummary()).isEqualTo("Needs additional receipt");
        assertThat(suggestion.getRiskFlags()).containsExactly("amount too high");
        assertThat(suggestion.getFollowUpChecks()).containsExactly("request invoice");
        assertThat(suggestion.getModel()).isEqualTo("gpt-5.4-mini");
        server.verify();
    }

    @Test
    void suggestApproval_supportsMarkdownWrappedJsonResponse() {
        RestTemplate restTemplate = new RestTemplate();
        MockRestServiceServer server = MockRestServiceServer.bindTo(restTemplate).build();
        ObjectMapper objectMapper = new ObjectMapper();

        OpenAiLlmClient client = new OpenAiLlmClient(
                restTemplate,
                objectMapper,
                "https://mock-llm.local/v1/",
                "k2",
                "gpt-5.4-mini",
                0.2
        );

        server.expect(once(), requestTo("https://mock-llm.local/v1/chat/completions"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withSuccess("""
                        {
                          "model": "gpt-5.4-mini",
                          "choices": [
                            {
                              "message": {
                                "content": "```json\\n{\\"decision\\":\\"APPROVE\\",\\"summary\\":\\"Looks good\\",\\"riskFlags\\":[],\\"followUpChecks\\":[\\"spot check docs\\"]}\\n```"
                              }
                            }
                          ]
                        }
                        """, MediaType.APPLICATION_JSON));

        LlmClient.Suggestion suggestion = client.suggestApproval(new LlmClient.SuggestionRequest());

        assertThat(suggestion.getDecision()).isEqualTo("APPROVE");
        assertThat(suggestion.getSummary()).isEqualTo("Looks good");
        assertThat(suggestion.getRiskFlags()).isEmpty();
        assertThat(suggestion.getFollowUpChecks()).containsExactly("spot check docs");
        server.verify();
    }

    @Test
    void suggestApproval_requiresApiKey() {
        OpenAiLlmClient client = new OpenAiLlmClient(
                new RestTemplate(),
                new ObjectMapper(),
                "https://api.openai.com/v1",
                "",
                "gpt-5.4-mini",
                0.2
        );

        assertThatThrownBy(() -> client.suggestApproval(new LlmClient.SuggestionRequest()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("api-key is required");
    }
}
