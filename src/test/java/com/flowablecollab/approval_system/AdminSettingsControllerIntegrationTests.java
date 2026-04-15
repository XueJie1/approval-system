package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.repository.settings.SystemSettingRepository;
import com.flowablecollab.approval_system.service.settings.AiProviderSettingsService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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
                                  "apiKey": "%s"
                                }
                                """.formatted(rawApiKey)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.baseUrl").value("https://proxy.openai.internal/v1"))
                .andExpect(jsonPath("$.hasApiKey").value(true))
                .andExpect(jsonPath("$.apiKeyMasked").isString())
                .andExpect(jsonPath("$.updatedAt").isString());

        String fetchResponse = mockMvc.perform(get("/api/admin/settings/ai/openai")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.baseUrl").value("https://proxy.openai.internal/v1"))
                .andExpect(jsonPath("$.hasApiKey").value(true))
                .andExpect(jsonPath("$.apiKeyMasked").value("sk-t****7890"))
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
                                  "apiKey": "sk-test-clear-001"
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
                .andExpect(jsonPath("$.hasApiKey").value(false));

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
    }
}
