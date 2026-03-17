package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.security.JwtService;
import com.flowablecollab.approval_system.security.TotpService;
import com.flowablecollab.approval_system.service.LoginLogService;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mock.web.MockHttpServletRequest;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class SecurityServiceTests extends AbstractIntegrationTestSupport {

    @Autowired
    private JwtService jwtServiceBean;

    @Autowired
    private TotpService totpService;

    @Autowired
    private LoginLogService loginLogService;

    @Test
    void jwtService_roundTripsAccessAndChallengeTokens() {
        String accessToken = jwtServiceBean.generateAccessToken(42L, "alice", Set.of("ADMIN", "EMPLOYEE"));
        Claims accessClaims = jwtServiceBean.parseAccessToken(accessToken);
        assertThat(jwtServiceBean.getUserId(accessClaims)).isEqualTo(42L);
        assertThat(jwtServiceBean.getRoles(accessClaims)).containsExactlyInAnyOrder("ADMIN", "EMPLOYEE");

        String challengeToken = jwtServiceBean.generateTwoFactorChallengeToken(7L, "bob");
        Claims challengeClaims = jwtServiceBean.parseChallengeToken(challengeToken);
        assertThat(jwtServiceBean.getUserId(challengeClaims)).isEqualTo(7L);
    }

    @Test
    void totpService_generatesSecretUriAndRecoveryCodes() {
        String secret = totpService.generateSecret();
        String uri = totpService.buildOtpAuthUri("tester", secret);
        String recoveryCodes = totpService.generateRecoveryCodes();

        assertThat(secret).isNotBlank();
        assertThat(uri).contains("otpauth://totp/");
        assertThat(recoveryCodes.split(",")).hasSize(10);
        assertThat(totpService.validateRecoveryCode(recoveryCodes, recoveryCodes.split(",")[0])).isTrue();
    }

    @Test
    void loginLogService_prefersForwardedHeaders() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("X-Forwarded-For", "203.0.113.9");
        request.addHeader("User-Agent", "JUnit Agent");
        request.setRemoteAddr("127.0.0.1");

        assertThat(loginLogService.getIpAddress(request)).isEqualTo("203.0.113.9");
        assertThat(loginLogService.getUserAgent(request)).isEqualTo("JUnit Agent");
    }
}
