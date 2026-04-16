package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.repository.settings.SystemSettingRepository;
import com.flowablecollab.approval_system.service.settings.AiProviderSettingsService;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AdminSettingsControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Autowired
    private SystemSettingRepository systemSettingRepository;

    @Test
    void sysAdmin_canSaveAndReadOpenAiSettings_withoutExposingPlainApiKey() throws Exception {
        String token = accessToken(createUser("sys-settings", "Password@123", null, "SYS_ADMIN"), "SYS_ADMIN");

        String rawApiKey = "sk-test-1234567890";
        mockMvc.perform(put("/api/admin/settings/ai/openai")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "baseUrl": "https://proxy.openai.internal/v1/",
                                  "apiKey": "%s",
                                  "model": "gpt-5.4"
                                }
                                """.formatted(rawApiKey)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.baseUrl").value("https://proxy.openai.internal/v1"))
                .andExpect(jsonPath("$.hasApiKey").value(true))
                .andExpect(jsonPath("$.apiKeyMasked").isString())
                .andExpect(jsonPath("$.model").value("gpt-5.4"))
                .andExpect(jsonPath("$.updatedAt").isString());

        String fetchResponse = mockMvc.perform(get("/api/admin/settings/ai/openai")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.baseUrl").value("https://proxy.openai.internal/v1"))
                .andExpect(jsonPath("$.hasApiKey").value(true))
                .andExpect(jsonPath("$.apiKeyMasked").value("sk-t****7890"))
                .andExpect(jsonPath("$.model").value("gpt-5.4"))
                .andReturn().getResponse().getContentAsString();

        assertThat(fetchResponse).doesNotContain(rawApiKey);

        var apiKeySetting = systemSettingRepository.findBySettingKey(AiProviderSettingsService.OPENAI_API_KEY_KEY).orElseThrow();
        assertThat(apiKeySetting.getEncrypted()).isEqualTo(1);
        assertThat(apiKeySetting.getSettingValue()).startsWith("v1:");
        assertThat(apiKeySetting.getSettingValue()).doesNotContain(rawApiKey);
    }

    @Test
    void sysAdmin_canClearPersistedApiKey() throws Exception {
        String token = accessToken(createUser("sys-settings-clear", "Password@123", null, "SYS_ADMIN"), "SYS_ADMIN");

        mockMvc.perform(put("/api/admin/settings/ai/openai")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "baseUrl": "https://api.openai.com/v1",
                                  "apiKey": "sk-test-clear-001",
                                  "model": "gpt-5.4-mini"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hasApiKey").value(true));

        mockMvc.perform(put("/api/admin/settings/ai/openai")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "baseUrl": "https://api.openai.com/v1",
                                  "clearApiKey": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hasApiKey").value(false))
                .andExpect(jsonPath("$.model").value("gpt-5.4-mini"));

        assertThat(systemSettingRepository.findBySettingKey(AiProviderSettingsService.OPENAI_API_KEY_KEY)).isEmpty();
    }

    @Test
    void nonSysAdmin_cannotAccessAdminSettingsEndpoints() throws Exception {
        String token = accessToken(createUser("admin-settings-denied", "Password@123", null, "ADMIN"), "ADMIN");

        mockMvc.perform(get("/api/admin/settings/ai/openai")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isForbidden());

        mockMvc.perform(put("/api/admin/settings/ai/openai")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/admin/settings/ai/openai/models")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void sysAdmin_canLoadModelListFromBaseUrlModelsEndpoint() throws Exception {
        String token = accessToken(createUser("sys-settings-models", "Password@123", null, "SYS_ADMIN"), "SYS_ADMIN");

        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/v1/models", exchange -> {
            String authorizationHeader = exchange.getRequestHeaders().getFirst("Authorization");
            if (!"Bearer sk-model-list".equals(authorizationHeader)) {
                exchange.sendResponseHeaders(401, -1);
                exchange.close();
                return;
            }
            byte[] responseBody = """
                    {
                      "object": "list",
                      "data": [
                        {"id": "gpt-5.4-mini"},
                        {"id": "gpt-5.4"},
                        {"id": "gpt-5.4-mini"}
                      ]
                    }
                    """.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, responseBody.length);
            exchange.getResponseBody().write(responseBody);
            exchange.close();
        });
        server.start();

        try {
            String baseUrl = "http://127.0.0.1:" + server.getAddress().getPort() + "/v1";
            mockMvc.perform(put("/api/admin/settings/ai/openai")
                            .header("Authorization", authorization(token))
                            .contentType(APPLICATION_JSON)
                            .content("""
                                    {
                                      "baseUrl": "%s",
                                      "apiKey": "sk-model-list",
                                      "model": "gpt-5.4-mini"
                                    }
                                    """.formatted(baseUrl)))
                    .andExpect(status().isOk());

            mockMvc.perform(post("/api/admin/settings/ai/openai/models")
                            .header("Authorization", authorization(token))
                            .contentType(APPLICATION_JSON)
                            .content("""
                                    {
                                      "baseUrl": "%s"
                                    }
                                    """.formatted(baseUrl)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.baseUrl").value(baseUrl))
                    .andExpect(jsonPath("$.selectedModel").value("gpt-5.4-mini"))
                    .andExpect(jsonPath("$.models[0]").value("gpt-5.4"))
                    .andExpect(jsonPath("$.models[1]").value("gpt-5.4-mini"));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void sysAdmin_modelListRequestWithHttpsLocalhost_canFallbackToHttp() throws Exception {
        String token = accessToken(createUser("sys-settings-models-fallback", "Password@123", null, "SYS_ADMIN"), "SYS_ADMIN");

        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/v1/models", exchange -> {
            String authorizationHeader = exchange.getRequestHeaders().getFirst("Authorization");
            if (!"Bearer sk-model-list".equals(authorizationHeader)) {
                exchange.sendResponseHeaders(401, -1);
                exchange.close();
                return;
            }
            byte[] responseBody = """
                    {
                      "object": "list",
                      "data": [
                        {"id": "gpt-5.4-mini"}
                      ]
                    }
                    """.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, responseBody.length);
            exchange.getResponseBody().write(responseBody);
            exchange.close();
        });
        server.start();

        try {
            String httpsBaseUrl = "https://localhost:" + server.getAddress().getPort() + "/v1";
            String expectedHttpBaseUrl = "http://localhost:" + server.getAddress().getPort() + "/v1";
            mockMvc.perform(post("/api/admin/settings/ai/openai/models")
                            .header("Authorization", authorization(token))
                            .contentType(APPLICATION_JSON)
                            .content("""
                                    {
                                      "baseUrl": "%s",
                                      "apiKey": "sk-model-list"
                                    }
                                    """.formatted(httpsBaseUrl)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.baseUrl").value(expectedHttpBaseUrl))
                    .andExpect(jsonPath("$.models[0]").value("gpt-5.4-mini"));
        } finally {
            server.stop(0);
        }
    }
}
