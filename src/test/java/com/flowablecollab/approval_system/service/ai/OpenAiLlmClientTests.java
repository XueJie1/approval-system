package com.flowablecollab.approval_system.service.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.service.settings.AiProviderSettingsService;
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
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

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
                                "content": "{\\"decision\\":\\"REJECT\\",\\"recommendation\\":\\"金额明显偏高，建议补充票据后再审批\\",\\"summary\\":\\"金额明显偏高，建议补充票据后再审批\\",\\"riskWarnings\\":[\\"amount too high\\"],\\"anomalies\\":[\\"missing receipt\\"],\\"supplementaryInfo\\":[\\"similar cases avg 2 days\\"],\\"approvalComment\\":\\"建议拒绝：金额明显偏高，建议补充票据后再审批\\",\\"suggestedFormUpdates\\":{\\"receiptRequired\\":true}}"
                              }
                            }
                          ]
                        }
                        """, MediaType.APPLICATION_JSON));

        LlmClient.SuggestionRequest request = new LlmClient.SuggestionRequest();
        request.setTaskId("task-1");
        request.setVariables(Map.of("amount", 12000));
        LlmClient.Suggestion suggestion = client.suggestApproval(request);

        assertThat(suggestion.getDecision()).isEqualTo("REJECT");
        assertThat(suggestion.getRecommendation()).isEqualTo("金额明显偏高，建议补充票据后再审批");
        assertThat(suggestion.getSummary()).isEqualTo("金额明显偏高，建议补充票据后再审批");
        assertThat(suggestion.getRiskWarnings()).containsExactly("amount too high");
        assertThat(suggestion.getAnomalies()).containsExactly("missing receipt");
        assertThat(suggestion.getSupplementaryInfo()).containsExactly("similar cases avg 2 days");
        assertThat(suggestion.getApprovalComment()).contains("建议拒绝");
        assertThat(suggestion.getSuggestedFormUpdates()).containsEntry("receiptRequired", true);
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
                                "content": "```json\\n{\\"decision\\":\\"APPROVE\\",\\"recommendation\\":\\"材料齐全，建议通过\\",\\"summary\\":\\"材料齐全，建议通过\\",\\"riskWarnings\\":[],\\"anomalies\\":[],\\"supplementaryInfo\\":[\\"spot check docs\\"],\\"approvalComment\\":\\"建议通过：材料齐全，建议通过\\",\\"suggestedFormUpdates\\":{}}\\n```"
                              }
                            }
                          ]
                        }
                        """, MediaType.APPLICATION_JSON));

        LlmClient.Suggestion suggestion = client.suggestApproval(new LlmClient.SuggestionRequest());

        assertThat(suggestion.getDecision()).isEqualTo("APPROVE");
        assertThat(suggestion.getRecommendation()).isEqualTo("材料齐全，建议通过");
        assertThat(suggestion.getSummary()).isEqualTo("材料齐全，建议通过");
        assertThat(suggestion.getRiskWarnings()).isEmpty();
        assertThat(suggestion.getAnomalies()).isEmpty();
        assertThat(suggestion.getSupplementaryInfo()).containsExactly("spot check docs");
        server.verify();
    }

    @Test
    void suggestApproval_supportsArrayStructuredMessageContent() {
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
                .andRespond(withSuccess("""
                        {
                          "model": "gpt-5.4-mini",
                          "choices": [
                            {
                              "message": {
                                "content": [
                                  {"type":"text","text":"{\\"decision\\":\\"APPROVE\\",\\"recommendation\\":\\"信息完整\\",\\"summary\\":\\"信息完整\\",\\"riskWarnings\\":[],\\"anomalies\\":[],\\"supplementaryInfo\\":[],\\"approvalComment\\":\\"建议通过\\",\\"suggestedFormUpdates\\":{}}"}
                                ]
                              }
                            }
                          ]
                        }
                        """, MediaType.APPLICATION_JSON));

        LlmClient.Suggestion suggestion = client.suggestApproval(new LlmClient.SuggestionRequest());

        assertThat(suggestion.getDecision()).isEqualTo("APPROVE");
        assertThat(suggestion.getRecommendation()).isEqualTo("信息完整");
        assertThat(suggestion.getSummary()).isEqualTo("信息完整");
        server.verify();
    }

    @Test
    void answerFollowUp_parsesStructuredAnswer() {
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
                .andRespond(withSuccess("""
                        {
                          "model": "gpt-5.4-mini",
                          "choices": [
                            {
                              "message": {
                                "content": "{\\"answer\\":\\"因为金额高于历史均值且缺少票据。\\"}"
                              }
                            }
                          ]
                        }
                        """, MediaType.APPLICATION_JSON));

        LlmClient.FollowUpRequest request = new LlmClient.FollowUpRequest();
        request.setQuestion("为什么有风险？");
        LlmClient.FollowUpAnswer answer = client.answerFollowUp(request);

        assertThat(answer.getAnswer()).isEqualTo("因为金额高于历史均值且缺少票据。");
        assertThat(answer.getModel()).isEqualTo("gpt-5.4-mini");
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

    @Test
    void suggestApproval_usesPersistedRuntimeOpenAiSettingsWhenAvailable() {
        RestTemplate restTemplate = new RestTemplate();
        MockRestServiceServer server = MockRestServiceServer.bindTo(restTemplate).build();
        ObjectMapper objectMapper = new ObjectMapper();
        AiProviderSettingsService settingsService = mock(AiProviderSettingsService.class);
        when(settingsService.resolveOpenAiRuntimeSettings(anyString(), anyString(), anyString()))
                .thenReturn(new AiProviderSettingsService.OpenAiRuntimeSettings("https://runtime-gateway.local/v1", "runtime-key-001", "gpt-5.4-mini"));

        OpenAiLlmClient client = new OpenAiLlmClient(
                restTemplate,
                objectMapper,
                "https://api.openai.com/v1",
                "default-key",
                "gpt-5.4-mini",
                0.2,
                settingsService
        );

        server.expect(once(), requestTo("https://runtime-gateway.local/v1/chat/completions"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("Authorization", "Bearer runtime-key-001"))
                .andRespond(withSuccess("""
                        {
                          "model": "gpt-5.4-mini",
                          "choices": [
                            {
                              "message": {
                                "content": "{\\"decision\\":\\"APPROVE\\",\\"recommendation\\":\\"ok\\",\\"summary\\":\\"ok\\",\\"riskWarnings\\":[],\\"anomalies\\":[],\\"supplementaryInfo\\":[],\\"approvalComment\\":\\"ok\\",\\"suggestedFormUpdates\\":{}}"
                              }
                            }
                          ]
                        }
                        """, MediaType.APPLICATION_JSON));

        LlmClient.Suggestion suggestion = client.suggestApproval(new LlmClient.SuggestionRequest());
        assertThat(suggestion.getDecision()).isEqualTo("APPROVE");
        server.verify();
    }
}
