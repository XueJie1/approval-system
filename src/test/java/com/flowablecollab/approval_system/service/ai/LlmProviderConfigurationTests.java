package com.flowablecollab.approval_system.service.ai;

import com.flowablecollab.approval_system.service.settings.AiProviderSettingsService;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Routing dispatches to the active provider returned by {@link AiProviderSettingsService}.
 * The two underlying impls are always present as beans; only the router decides which one runs.
 */
class LlmProviderConfigurationTests {

    @Test
    void routesToOpenAi_whenProviderIsOpenAi() {
        MockLlmClient mock = Mockito.mock(MockLlmClient.class);
        OpenAiLlmClient openai = Mockito.mock(OpenAiLlmClient.class);
        AiProviderSettingsService settings = Mockito.mock(AiProviderSettingsService.class);
        when(settings.getActiveProvider()).thenReturn(AiProviderSettingsService.PROVIDER_OPENAI);

        LlmClient.ChatResult expected = new LlmClient.ChatResult();
        expected.setReply("from-openai");
        when(openai.chat(Mockito.any())).thenReturn(expected);

        RoutingLlmClient router = new RoutingLlmClient(mock, openai, settings);
        LlmClient.ChatResult result = router.chat(new LlmClient.ChatRequest());

        assertThat(result.getReply()).isEqualTo("from-openai");
        Mockito.verifyNoInteractions(mock);
    }

    @Test
    void routesToMock_whenProviderIsMock() {
        MockLlmClient mock = Mockito.mock(MockLlmClient.class);
        OpenAiLlmClient openai = Mockito.mock(OpenAiLlmClient.class);
        AiProviderSettingsService settings = Mockito.mock(AiProviderSettingsService.class);
        when(settings.getActiveProvider()).thenReturn(AiProviderSettingsService.PROVIDER_MOCK);

        LlmClient.ChatResult expected = new LlmClient.ChatResult();
        expected.setReply("from-mock");
        when(mock.chat(Mockito.any())).thenReturn(expected);

        RoutingLlmClient router = new RoutingLlmClient(mock, openai, settings);
        LlmClient.ChatResult result = router.chat(new LlmClient.ChatRequest());

        assertThat(result.getReply()).isEqualTo("from-mock");
        Mockito.verifyNoInteractions(openai);
    }

    @Test
    void unknownProvider_fallsBackToMock() {
        MockLlmClient mock = Mockito.mock(MockLlmClient.class);
        OpenAiLlmClient openai = Mockito.mock(OpenAiLlmClient.class);
        AiProviderSettingsService settings = Mockito.mock(AiProviderSettingsService.class);
        when(settings.getActiveProvider()).thenReturn("garbage");

        LlmClient.ChatResult expected = new LlmClient.ChatResult();
        expected.setReply("from-mock");
        when(mock.chat(Mockito.any())).thenReturn(expected);

        RoutingLlmClient router = new RoutingLlmClient(mock, openai, settings);
        router.chat(new LlmClient.ChatRequest());

        Mockito.verifyNoInteractions(openai);
        Mockito.verify(mock).chat(Mockito.any());
    }

    @Test
    void settingsError_fallsBackToMock() {
        MockLlmClient mock = Mockito.mock(MockLlmClient.class);
        OpenAiLlmClient openai = Mockito.mock(OpenAiLlmClient.class);
        AiProviderSettingsService settings = Mockito.mock(AiProviderSettingsService.class);
        when(settings.getActiveProvider()).thenThrow(new RuntimeException("db down"));

        LlmClient.ChatResult expected = new LlmClient.ChatResult();
        expected.setReply("from-mock");
        when(mock.chat(Mockito.any())).thenReturn(expected);

        RoutingLlmClient router = new RoutingLlmClient(mock, openai, settings);
        router.chat(new LlmClient.ChatRequest());

        Mockito.verifyNoInteractions(openai);
        Mockito.verify(mock).chat(Mockito.any());
    }
}
