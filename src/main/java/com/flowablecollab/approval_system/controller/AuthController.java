package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.AuthService;
import com.flowablecollab.approval_system.service.RbacService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final RbacService rbacService;

    @GetMapping("/bootstrap-status")
    public ResponseEntity<Map<String, Boolean>> getBootstrapStatus() {
        boolean isBootstrapMode = rbacService.isBootstrapModeActive();
        return ResponseEntity.ok(Map.of("isBootstrapMode", isBootstrapMode));
    }

    @PostMapping("/bootstrap")
    public ResponseEntity<AuthService.LoginResult> bootstrap(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.bootstrapAdmin(request.getUsername(), request.getPassword()));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthService.LoginResult> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request.getUsername(), request.getPassword()));
    }

    @PostMapping("/login/2fa")
    public ResponseEntity<AuthService.LoginResult> verify2fa(@Valid @RequestBody Verify2FaRequest request) {
        return ResponseEntity.ok(authService.verifyTwoFactor(request.getChallengeToken(), request.getCode()));
    }

    @GetMapping("/me")
    public ResponseEntity<AuthService.Profile> me() {
        Long currentUserId = requireCurrentUserId();
        return ResponseEntity.ok(authService.getProfile(currentUserId));
    }

    @PostMapping("/2fa/setup")
    public ResponseEntity<AuthService.TwoFactorSetup> setup2fa() {
        Long currentUserId = requireCurrentUserId();
        return ResponseEntity.ok(authService.setupTwoFactor(currentUserId));
    }

    @PostMapping("/2fa/enable")
    public ResponseEntity<ActionResponse> enable2fa(@Valid @RequestBody Enable2FaRequest request) {
        Long currentUserId = requireCurrentUserId();
        authService.enableTwoFactor(currentUserId, request.getCode());
        return ResponseEntity.ok(ActionResponse.ok("2FA enabled"));
    }

    @PostMapping("/2fa/disable")
    public ResponseEntity<ActionResponse> disable2fa(@Valid @RequestBody Disable2FaRequest request) {
        Long currentUserId = requireCurrentUserId();
        authService.disableTwoFactor(currentUserId, request.getCode());
        return ResponseEntity.ok(ActionResponse.ok("2FA disabled"));
    }

    @PostMapping("/2fa/recovery/generate")
    public ResponseEntity<AuthService.TwoFactorSetup> generateRecoveryCodes() {
        Long currentUserId = requireCurrentUserId();
        return ResponseEntity.ok(authService.enableTwoFactorWithRecovery(currentUserId));
    }

    @PostMapping("/2fa/recovery/validate")
    public ResponseEntity<ActionResponse> validateRecoveryCode(@Valid @RequestBody ValidateRecoveryCodeRequest request) {
        Long currentUserId = requireCurrentUserId();
        boolean valid = authService.validateRecoveryCode(currentUserId, request.getCode());
        if (!valid) {
            throw new IllegalArgumentException("invalid recovery code");
        }
        return ResponseEntity.ok(ActionResponse.ok("Recovery code validated successfully"));
    }

    @PostMapping("/password/change")
    public ResponseEntity<ActionResponse> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        Long currentUserId = requireCurrentUserId();
        authService.changePassword(currentUserId, request.getCurrentPassword(), request.getNewPassword());
        return ResponseEntity.ok(ActionResponse.ok("Password changed"));
    }

    private Long requireCurrentUserId() {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new IllegalArgumentException("Unauthorized");
        }
        return currentUserId;
    }

    @Data
    public static class LoginRequest {
        @NotBlank(message = "username is required")
        private String username;

        @NotBlank(message = "password is required")
        private String password;
    }

    @Data
    public static class Verify2FaRequest {
        @NotBlank(message = "challengeToken is required")
        private String challengeToken;

        @NotBlank(message = "code is required")
        @Pattern(regexp = "\\d{6}", message = "code must be 6 digits")
        private String code;
    }

    @Data
    public static class Enable2FaRequest {
        @NotBlank(message = "code is required")
        @Pattern(regexp = "\\d{6}", message = "code must be 6 digits")
        private String code;
    }

    @Data
    public static class Disable2FaRequest {
        @NotBlank(message = "code is required")
        @Pattern(regexp = "\\d{6}", message = "code must be 6 digits")
        private String code;
    }

    @Data
    public static class ValidateRecoveryCodeRequest {
        @NotBlank(message = "code is required")
        private String code;
    }

    @Data
    public static class ChangePasswordRequest {
        @NotBlank(message = "currentPassword is required")
        private String currentPassword;

        @NotBlank(message = "newPassword is required")
        @Size(min = 8, max = 128, message = "password length must be between 8 and 128")
        private String newPassword;
    }

    @Data
    public static class ActionResponse {
        private boolean success;
        private String message;

        public static ActionResponse ok(String message) {
            ActionResponse response = new ActionResponse();
            response.setSuccess(true);
            response.setMessage(message);
            return response;
        }
    }
}
