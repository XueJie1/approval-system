package com.flowablecollab.approval_system.controller.admin;

import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.settings.AiProviderSettingsService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
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
                request.getModel(),
                request.getClearApiKey());

        return ResponseEntity.ok(aiProviderSettingsService.saveOpenAiAdminSettings(command, operatorId));
    }

    @PostMapping("/ai/openai/models")
    public ResponseEntity<AiProviderSettingsService.OpenAiModelListView> listOpenAiModels(
            @RequestBody(required = false) OpenAiModelListRequest request) {
        AiProviderSettingsService.OpenAiModelListQuery query = request == null
                ? new AiProviderSettingsService.OpenAiModelListQuery(null, null)
                : new AiProviderSettingsService.OpenAiModelListQuery(request.getBaseUrl(), request.getApiKey());
        return ResponseEntity.ok(aiProviderSettingsService.listOpenAiModels(query));
    }

    @Data
    public static class UpdateOpenAiSettingsRequest {
        private String baseUrl;
        private String apiKey;
        private String model;
        private Boolean clearApiKey;
    }

    @Data
    public static class OpenAiModelListRequest {
        private String baseUrl;
        private String apiKey;
    }
}
