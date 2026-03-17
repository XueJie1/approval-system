package com.flowablecollab.approval_system;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.test.annotation.DirtiesContext;

import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_EACH_TEST_METHOD)
class BootstrapAuthIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void bootstrap_createsAdminAndReturnsUsableAccessToken() throws Exception {
        String response = mockMvc.perform(post("/api/auth/bootstrap")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "admin",
                                  "password": "Admin@123"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isString())
                .andExpect(jsonPath("$.twoFactorRequired").value(false))
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode body = json(response);
        String token = body.get("accessToken").asText();

        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("admin"))
                .andExpect(jsonPath("$.roles[0]").value("ADMIN"))
                .andExpect(jsonPath("$.twoFactorEnabled").value(false));
    }
}
