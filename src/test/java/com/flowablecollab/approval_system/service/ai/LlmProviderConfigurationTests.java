package com.flowablecollab.approval_system.service.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

import static org.assertj.core.api.Assertions.assertThat;

class LlmProviderConfigurationTests {

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
            .withUserConfiguration(TestAiConfig.class);

    @Test
    void providerMock_loadsMockClientOnly() {
        contextRunner
                .withPropertyValues("ai.llm.provider=mock")
                .run(context -> {
                    assertThat(context).hasSingleBean(LlmClient.class);
                    assertThat(context.getBean(LlmClient.class)).isInstanceOf(MockLlmClient.class);
                    assertThat(context).doesNotHaveBean(OpenAiLlmClient.class);
                });
    }

    @Test
    void providerOpenAi_loadsOpenAiClientOnly() {
        contextRunner
                .withPropertyValues(
                        "ai.llm.provider=openai",
                        "ai.llm.openai.api-key=test-key",
                        "ai.llm.openai.base-url=https://api.openai.com/v1",
                        "ai.llm.openai.model=gpt-5.4-mini"
                )
                .run(context -> {
                    assertThat(context).hasSingleBean(LlmClient.class);
                    assertThat(context.getBean(LlmClient.class)).isInstanceOf(OpenAiLlmClient.class);
                    assertThat(context).doesNotHaveBean(MockLlmClient.class);
                });
    }

    @Configuration
    @ComponentScan(basePackageClasses = {MockLlmClient.class, OpenAiLlmClient.class})
    static class TestAiConfig {
        @Bean
        ObjectMapper objectMapper() {
            return new ObjectMapper();
        }

        @Bean
        RestTemplateBuilder restTemplateBuilder() {
            return new RestTemplateBuilder();
        }
    }
}
