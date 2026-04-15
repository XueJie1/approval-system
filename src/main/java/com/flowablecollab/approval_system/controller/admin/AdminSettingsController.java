package com.flowablecollab.approval_system.controller.admin;

import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.settings.AiProviderSettingsService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/settings")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SYS_ADMIN')")
public class AdminSettingsController {

    private final AiProviderSettingsService aiProviderSettingsService;

    @GetMapping("/ai/openai")
    public ResponseEntity<AiProviderSettingsService.OpenAiAdminSettingsView> getOpenAiSettings() {
        return ResponseEntity.ok(aiProviderSettingsService.getOpenAiAdminSettings());
    }

    @PutMapping("/ai/openai")
    public ResponseEntity<AiProviderSettingsService.OpenAiAdminSettingsView> updateOpenAiSettings(
            @RequestBody UpdateOpenAiSettingsRequest request) {
        Long operatorId = SecurityUtils.currentUserId();
        if (operatorId == null) {
            throw new IllegalArgumentException("operator not found");
        }

        AiProviderSettingsService.OpenAiAdminSettingsUpdate command = new AiProviderSettingsService.OpenAiAdminSettingsUpdate(
                request.getBaseUrl(),
                request.getApiKey(),
                request.getClearApiKey());

        return ResponseEntity.ok(aiProviderSettingsService.saveOpenAiAdminSettings(command, operatorId));
    }

    @Data
    public static class UpdateOpenAiSettingsRequest {
        private String baseUrl;
        private String apiKey;
        private Boolean clearApiKey;
    }
}
