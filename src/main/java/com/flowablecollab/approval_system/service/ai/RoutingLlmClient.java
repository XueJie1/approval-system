package com.flowablecollab.approval_system.service.ai;

import com.flowablecollab.approval_system.service.settings.AiProviderSettingsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

@Slf4j
@Primary
@Component
public class RoutingLlmClient implements LlmClient {

    private final MockLlmClient mockLlmClient;
    private final OpenAiLlmClient openAiLlmClient;
    private final AiProviderSettingsService settingsService;

    public RoutingLlmClient(MockLlmClient mockLlmClient,
                            OpenAiLlmClient openAiLlmClient,
                            AiProviderSettingsService settingsService) {
        this.mockLlmClient = mockLlmClient;
        this.openAiLlmClient = openAiLlmClient;
        this.settingsService = settingsService;
    }

    private LlmClient active() {
        String provider;
        try {
            provider = settingsService.getActiveProvider();
        } catch (Exception ex) {
            log.warn("Failed to resolve active LLM provider, falling back to mock", ex);
            return mockLlmClient;
        }
        if (AiProviderSettingsService.PROVIDER_OPENAI.equals(provider)) {
            return openAiLlmClient;
        }
        if (!AiProviderSettingsService.PROVIDER_MOCK.equals(provider)) {
            log.warn("Unknown LLM provider '{}', falling back to mock", provider);
        }
        return mockLlmClient;
    }

    @Override
    public Suggestion suggestApproval(SuggestionRequest request) {
        return active().suggestApproval(request);
    }

    @Override
    public FollowUpAnswer answerFollowUp(FollowUpRequest request) {
        return active().answerFollowUp(request);
    }

    @Override
    public FormCommandResult parseFormCommand(FormCommandParseRequest request) {
        return active().parseFormCommand(request);
    }

    @Override
    public ChatResult chat(ChatRequest request) {
        return active().chat(request);
    }

    @Override
    public ChatWithToolsResult chatWithTools(ChatWithToolsRequest request) {
        return active().chatWithTools(request);
    }
}
