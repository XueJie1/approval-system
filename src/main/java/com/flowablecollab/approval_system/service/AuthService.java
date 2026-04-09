package com.flowablecollab.approval_system.service;

import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.entity.rbac.SysUserRole;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.repository.rbac.SysRoleRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRoleRepository;
import com.flowablecollab.approval_system.security.JwtService;
import com.flowablecollab.approval_system.security.TotpService;
import com.flowablecollab.approval_system.service.LoginLogService;
import io.jsonwebtoken.Claims;
import jakarta.servlet.http.HttpServletRequest;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final SysUserRepository sysUserRepository;
    private final SysUserRoleRepository sysUserRoleRepository;
    private final SysRoleRepository sysRoleRepository;
    private final JwtService jwtService;
    private final TotpService totpService;
    private final RbacService rbacService;
    private final LoginLogService loginLogService;
    private final HttpServletRequest httpRequest;

    public LoginResult bootstrapAdmin(String username, String password) {
        if (!rbacService.isBootstrapModeActive()) {
            throw new ForbiddenOperationException("bootstrap is disabled after admin initialization");
        }
        if (username == null || username.isBlank() || password == null || password.isBlank()) {
            throw new IllegalArgumentException("username and password are required");
        }

        SysRole adminRole = sysRoleRepository.findByRoleCode("ADMIN")
                .orElseGet(() -> rbacService.createRole("ADMIN", "Business Administrator"));
        SysRole sysAdminRole = sysRoleRepository.findByRoleCode("SYS_ADMIN")
                .orElseGet(() -> rbacService.createRole("SYS_ADMIN", "System Administrator"));

        SysUser user = sysUserRepository.findByUsername(username.trim())
                .orElseGet(() -> rbacService.createUser(username.trim(), password, null, 1));

        if (!sysUserRoleRepository.existsByUserIdAndRoleId(user.getId(), adminRole.getId())) {
            rbacService.assignRole(user.getId(), adminRole.getId());
        }
        if (!sysUserRoleRepository.existsByUserIdAndRoleId(user.getId(), sysAdminRole.getId())) {
            rbacService.assignRole(user.getId(), sysAdminRole.getId());
        }

        // Log bootstrap success
        loginLogService.logLoginSuccess(user.getId(), user.getUsername(),
                loginLogService.getIpAddress(httpRequest), loginLogService.getUserAgent(httpRequest));

        return issueAccessToken(user);
    }

    public LoginResult login(String username, String password) {
        String ipAddress = loginLogService.getIpAddress(httpRequest);
        String userAgent = loginLogService.getUserAgent(httpRequest);

        if (username == null || username.isBlank() || password == null || password.isBlank()) {
            loginLogService.logLoginFailure(username, "invalid username or password", ipAddress, userAgent);
            throw new IllegalArgumentException("username and password are required");
        }

        SysUser user = sysUserRepository.findByUsername(username.trim())
                .orElseThrow(() -> {
                    loginLogService.logLoginFailure(username, "user not found", ipAddress, userAgent);
                    return new IllegalArgumentException("invalid username or password");
                });

        if (!isActive(user)) {
            loginLogService.logLoginFailure(username, "user is disabled", ipAddress, userAgent);
            throw new IllegalArgumentException("user is disabled");
        }

        // Check account lock status
        if (isAccountLocked(user)) {
            loginLogService.logLoginFailure(username, "account is locked", ipAddress, userAgent);
            throw new IllegalArgumentException("account is locked. please contact administrator");
        }

        if (user.getPassword() == null || !BCrypt.checkpw(password, user.getPassword())) {
            // Increment login failures
            int failures = user.getLoginFailures() != null ? user.getLoginFailures() : 0;
            if (failures >= 4) {
                // Lock account after 5 failed attempts
                user.setLockedUntil(java.time.LocalDateTime.now().plusMinutes(30));
                sysUserRepository.save(user);
            } else {
                user.setLoginFailures(failures + 1);
                sysUserRepository.save(user);
            }
            loginLogService.logLoginFailure(username, "invalid password", ipAddress, userAgent);
            throw new IllegalArgumentException("invalid username or password");
        }

        // Reset login failures on successful login
        user.setLoginFailures(0);
        user.setLockedUntil(null);
        user.setLastLoginAt(java.time.LocalDateTime.now());
        sysUserRepository.save(user);

        loginLogService.logLoginSuccess(user.getId(), user.getUsername(), ipAddress, userAgent);

        if (isTwoFactorEnabled(user)) {
            LoginResult result = new LoginResult();
            result.setTwoFactorRequired(true);
            result.setChallengeToken(jwtService.generateTwoFactorChallengeToken(user.getId(), user.getUsername()));
            result.setExpiresIn(5 * 60L);
            return result;
        }

        return issueAccessToken(user);
    }

    public LoginResult verifyTwoFactor(String challengeToken, String code) {
        if (challengeToken == null || challengeToken.isBlank()) {
            throw new IllegalArgumentException("challengeToken is required");
        }
        Claims claims = jwtService.parseChallengeToken(challengeToken);
        Long userId = jwtService.getUserId(claims);
        if (userId == null) {
            throw new IllegalArgumentException("invalid challenge token");
        }
        SysUser user = sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));
        if (!isActive(user)) {
            throw new IllegalArgumentException("user is disabled");
        }
        if (!isTwoFactorEnabled(user)) {
            throw new IllegalArgumentException("2FA is not enabled");
        }
        if (!totpService.verifyCode(user.getTwoFactorSecret(), code)) {
            loginLogService.logLoginFailure(user.getUsername(), "invalid 2FA code",
                    loginLogService.getIpAddress(httpRequest), loginLogService.getUserAgent(httpRequest));
            throw new IllegalArgumentException("invalid 2FA code");
        }

        // Log successful 2FA verification
        user.setLastLoginAt(java.time.LocalDateTime.now());
        sysUserRepository.save(user);
        loginLogService.logLoginSuccess(user.getId(), user.getUsername(),
                loginLogService.getIpAddress(httpRequest), loginLogService.getUserAgent(httpRequest));

        return issueAccessToken(user);
    }

    public TwoFactorSetup setupTwoFactor(Long userId) {
        SysUser user = sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));
        String secret = user.getTwoFactorSecret();
        if (secret == null || secret.isBlank()) {
            secret = totpService.generateSecret();
            user.setTwoFactorSecret(secret);
            if (user.getTwoFactorEnabled() == null) {
                user.setTwoFactorEnabled(0);
            }
            sysUserRepository.save(user);
        }

        TwoFactorSetup setup = new TwoFactorSetup();
        setup.setSecret(secret);
        setup.setOtpAuthUri(totpService.buildOtpAuthUri(user.getUsername(), secret));
        return setup;
    }

    public void enableTwoFactor(Long userId, String code) {
        SysUser user = sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));
        String secret = user.getTwoFactorSecret();
        if (secret == null || secret.isBlank()) {
            throw new IllegalArgumentException("2FA secret is not initialized");
        }
        if (!totpService.verifyCode(secret, code)) {
            throw new IllegalArgumentException("invalid 2FA code");
        }
        user.setTwoFactorEnabled(1);
        sysUserRepository.save(user);
    }

    public void disableTwoFactor(Long userId, String code) {
        SysUser user = sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));
        if (!isTwoFactorEnabled(user)) {
            return;
        }
        if (!totpService.verifyCode(user.getTwoFactorSecret(), code)) {
            throw new IllegalArgumentException("invalid 2FA code");
        }
        user.setTwoFactorEnabled(0);
        user.setTwoFactorSecret(null);
        user.setRecoveryCodes(null);
        sysUserRepository.save(user);
    }

    public TwoFactorSetup enableTwoFactorWithRecovery(Long userId) {
        SysUser user = sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));
        String secret = user.getTwoFactorSecret();
        if (secret == null || secret.isBlank()) {
            secret = totpService.generateSecret();
            user.setTwoFactorSecret(secret);
        }
        String recoveryCodes = totpService.generateRecoveryCodes();
        user.setRecoveryCodes(recoveryCodes);
        if (user.getTwoFactorEnabled() == null) {
            user.setTwoFactorEnabled(0);
        }
        sysUserRepository.save(user);

        TwoFactorSetup setup = new TwoFactorSetup();
        setup.setSecret(secret);
        setup.setOtpAuthUri(totpService.buildOtpAuthUri(user.getUsername(), secret));
        setup.setRecoveryCodes(recoveryCodes);
        return setup;
    }

    public boolean validateRecoveryCode(Long userId, String code) {
        SysUser user = sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));
        if (user.getRecoveryCodes() == null || user.getRecoveryCodes().isBlank()) {
            throw new IllegalArgumentException("recovery codes not initialized");
        }
        if (totpService.validateRecoveryCode(user.getRecoveryCodes(), code)) {
            // Clear recovery codes after use
            user.setRecoveryCodes(null);
            sysUserRepository.save(user);
            return true;
        }
        return false;
    }

    public String getRecoveryCodes(Long userId) {
        SysUser user = sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));
        if (user.getRecoveryCodes() == null || user.getRecoveryCodes().isBlank()) {
            throw new IllegalArgumentException("recovery codes not initialized");
        }
        return user.getRecoveryCodes();
    }

    public Profile getProfile(Long userId) {
        SysUser user = sysUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));
        Profile profile = new Profile();
        profile.setUserId(user.getId());
        profile.setUsername(user.getUsername());
        profile.setRoles(loadRoleCodes(user.getId()));
        profile.setTwoFactorEnabled(isTwoFactorEnabled(user));
        profile.setHasRecoveryCodes(user.getRecoveryCodes() != null && !user.getRecoveryCodes().isBlank());
        return profile;
    }

    private LoginResult issueAccessToken(SysUser user) {
        Set<String> roles = ensureInitialSysAdminForLegacyAdmin(user);

        LoginResult result = new LoginResult();
        result.setTwoFactorRequired(false);
        result.setAccessToken(jwtService.generateAccessToken(user.getId(), user.getUsername(), roles));
        result.setTokenType("Bearer");
        result.setExpiresIn(jwtService.getAccessTokenExpiresInSeconds());
        result.setRoles(roles);
        result.setUserId(user.getId());
        result.setUsername(user.getUsername());
        return result;
    }

    private Set<String> loadRoleCodes(Long userId) {
        List<SysUserRole> mappings = sysUserRoleRepository.findByUserId(userId);
        if (mappings.isEmpty()) {
            return Set.of();
        }
        Set<Long> roleIds = mappings.stream().map(SysUserRole::getRoleId).collect(Collectors.toSet());
        return sysRoleRepository.findByIdIn(roleIds).stream()
                .map(SysRole::getRoleCode)
                .collect(Collectors.toSet());
    }

    private Set<String> ensureInitialSysAdminForLegacyAdmin(SysUser user) {
        Set<String> roles = loadRoleCodes(user.getId());
        if (roles.contains("SYS_ADMIN") || !roles.contains("ADMIN")) {
            return roles;
        }

        SysRole adminRole = sysRoleRepository.findByRoleCode("ADMIN").orElse(null);
        if (adminRole == null || !"System Administrator".equals(adminRole.getRoleName())) {
            return roles;
        }

        SysRole sysAdminRole = sysRoleRepository.findByRoleCode("SYS_ADMIN").orElse(null);
        if (sysAdminRole != null && sysUserRoleRepository.existsByRoleId(sysAdminRole.getId())) {
            return roles;
        }

        if (sysAdminRole == null) {
            sysAdminRole = rbacService.createRole("SYS_ADMIN", "System Administrator");
        }
        if (!sysUserRoleRepository.existsByUserIdAndRoleId(user.getId(), sysAdminRole.getId())) {
            rbacService.assignRole(user.getId(), sysAdminRole.getId());
        }

        return loadRoleCodes(user.getId());
    }

    private boolean isTwoFactorEnabled(SysUser user) {
        return user.getTwoFactorEnabled() != null && user.getTwoFactorEnabled() == 1;
    }

    private boolean isActive(SysUser user) {
        return user.getStatus() != null && user.getStatus() == 1;
    }

    private boolean isAccountLocked(SysUser user) {
        if (user.getLoginFailures() == null || user.getLoginFailures() == 0) {
            return false;
        }
        if (user.getLockedUntil() == null) {
            return false;
        }
        return user.getLockedUntil().isAfter(java.time.LocalDateTime.now());
    }

    @Data
    public static class LoginResult {
        private boolean twoFactorRequired;
        private String challengeToken;
        private String accessToken;
        private String tokenType;
        private Long expiresIn;
        private Long userId;
        private String username;
        private Set<String> roles;
        private String recoveryCode;
    }

    @Data
    public static class TwoFactorSetup {
        private String secret;
        private String otpAuthUri;
        private String recoveryCodes;
    }

    @Data
    public static class Profile {
        private Long userId;
        private String username;
        private Set<String> roles;
        private boolean twoFactorEnabled;
        private boolean hasRecoveryCodes;
    }
}
