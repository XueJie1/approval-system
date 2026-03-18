package com.flowablecollab.approval_system;

import com.fasterxml.jackson.databind.JsonNode;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void login_returnsAccessToken_andWritesLoginLog() throws Exception {
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "%s",
                                  "password": "Password@123"
                                }
                                """.formatted(employee.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isString())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.twoFactorRequired").value(false));

        assertThat(sysLoginLogRepository.findAll())
                .anyMatch(log -> employee.getUsername().equals(log.getUsername()) && Integer.valueOf(0).equals(log.getLoginStatus()));
    }

    @Test
    void login_withTwoFactorEnabled_requiresChallenge_andCanBeVerified() throws Exception {
        SysUser employee = createUser("twofa", "Password@123", null, "EMPLOYEE");
        String secret = "JBSWY3DPEHPK3PXP";
        employee.setTwoFactorSecret(secret);
        employee.setTwoFactorEnabled(1);
        sysUserRepository.save(employee);

        String loginResponse = mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "%s",
                                  "password": "Password@123"
                                }
                                """.formatted(employee.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.twoFactorRequired").value(true))
                .andExpect(jsonPath("$.challengeToken").isString())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode loginBody = json(loginResponse);

        mockMvc.perform(post("/api/auth/login/2fa")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "challengeToken": "%s",
                                  "code": "%s"
                                }
                                """.formatted(loginBody.get("challengeToken").asText(), currentTotpCode(secret))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isString())
                .andExpect(jsonPath("$.twoFactorRequired").value(false));
    }

    @Test
    void authenticatedUser_canSetupEnableGenerateRecoveryCodes_andDisableTwoFactor() throws Exception {
        SysUser employee = createUser("secure-user", "Password@123", null, "EMPLOYEE");
        String token = accessToken(employee, "EMPLOYEE");

        String setupResponse = mockMvc.perform(post("/api/auth/2fa/setup")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.secret").isString())
                .andExpect(jsonPath("$.otpAuthUri").isString())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode setupBody = json(setupResponse);
        String secret = setupBody.get("secret").asText();

        mockMvc.perform(post("/api/auth/2fa/enable")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "code": "%s"
                                }
                                """.formatted(currentTotpCode(secret))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("2FA enabled"));

        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.twoFactorEnabled").value(true));

        String recoveryResponse = mockMvc.perform(post("/api/auth/2fa/recovery/generate")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recoveryCodes").isString())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode recoveryBody = json(recoveryResponse);
        String recoveryCode = recoveryBody.get("recoveryCodes").asText().split(",")[0];
        String persistedSecret = recoveryBody.get("secret").asText();
        assertThat(persistedSecret).isEqualTo(secret);

        mockMvc.perform(post("/api/auth/2fa/recovery/validate")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "code": "%s"
                                }
                                """.formatted(recoveryCode)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Recovery code validated successfully"));

        mockMvc.perform(post("/api/auth/2fa/disable")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "code": "%s"
                                }
                                """.formatted(currentTotpCode(secret))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("2FA disabled"));
    }
}
