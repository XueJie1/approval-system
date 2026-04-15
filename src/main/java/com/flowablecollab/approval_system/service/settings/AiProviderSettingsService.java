package com.flowablecollab.approval_system.service.settings;

import com.flowablecollab.approval_system.entity.settings.SystemSetting;
import com.flowablecollab.approval_system.repository.settings.SystemSettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AiProviderSettingsService {

    public static final String OPENAI_BASE_URL_KEY = "ai.llm.openai.base-url";
    public static final String OPENAI_API_KEY_KEY = "ai.llm.openai.api-key";

    private final SystemSettingRepository systemSettingRepository;
    private final SettingsCryptoService settingsCryptoService;

    @Value("${ai.llm.openai.base-url:https://api.openai.com/v1}")
    private String defaultOpenAiBaseUrl;

    @Value("${ai.llm.openai.api-key:}")
    private String defaultOpenAiApiKey;

    @Transactional(readOnly = true)
    public OpenAiRuntimeSettings resolveOpenAiRuntimeSettings(String fallbackBaseUrl, String fallbackApiKey) {
        Map<String, SystemSetting> settingMap = systemSettingRepository
                .findBySettingKeyIn(List.of(OPENAI_BASE_URL_KEY, OPENAI_API_KEY_KEY))
                .stream()
                .collect(Collectors.toMap(SystemSetting::getSettingKey, Function.identity()));

        String baseUrl = normalizeBaseUrl(resolveSettingValue(settingMap.get(OPENAI_BASE_URL_KEY)));
        if (baseUrl == null || baseUrl.isBlank()) {
            baseUrl = normalizeBaseUrl(fallbackBaseUrl);
        }
        if (baseUrl == null || baseUrl.isBlank()) {
            baseUrl = normalizeBaseUrl(defaultOpenAiBaseUrl);
        }

        String apiKey = resolveApiKey(settingMap.get(OPENAI_API_KEY_KEY));
        if (apiKey == null || apiKey.isBlank()) {
            apiKey = fallbackApiKey;
        }
        if (apiKey == null || apiKey.isBlank()) {
            apiKey = defaultOpenAiApiKey;
        }

        return new OpenAiRuntimeSettings(baseUrl, normalizeApiKey(apiKey));
    }

    @Transactional(readOnly = true)
    public OpenAiAdminSettingsView getOpenAiAdminSettings() {
        OpenAiRuntimeSettings runtimeSettings = resolveOpenAiRuntimeSettings(defaultOpenAiBaseUrl, defaultOpenAiApiKey);
        String apiKey = runtimeSettings.apiKey();
        return new OpenAiAdminSettingsView(
                runtimeSettings.baseUrl(),
                apiKey != null && !apiKey.isBlank(),
                maskSecret(apiKey),
                loadLatestUpdatedAt());
    }

    @Transactional
    public OpenAiAdminSettingsView saveOpenAiAdminSettings(OpenAiAdminSettingsUpdate update, Long operatorId) {
        if (update == null) {
            throw new IllegalArgumentException("settings payload is required");
        }

        String normalizedBaseUrl = normalizeBaseUrl(update.baseUrl());
        if (normalizedBaseUrl == null || normalizedBaseUrl.isBlank()) {
            systemSettingRepository.deleteBySettingKey(OPENAI_BASE_URL_KEY);
        } else {
            upsertSetting(OPENAI_BASE_URL_KEY, normalizedBaseUrl, false, operatorId);
        }

        if (Boolean.TRUE.equals(update.clearApiKey())) {
            systemSettingRepository.deleteBySettingKey(OPENAI_API_KEY_KEY);
        } else {
            String normalizedApiKey = normalizeApiKey(update.apiKey());
            if (normalizedApiKey != null && !normalizedApiKey.isBlank()) {
                String encryptedApiKey = settingsCryptoService.encrypt(normalizedApiKey);
                upsertSetting(OPENAI_API_KEY_KEY, encryptedApiKey, true, operatorId);
            }
        }

        return getOpenAiAdminSettings();
    }

    private void upsertSetting(String key, String value, boolean encrypted, Long operatorId) {
        SystemSetting setting = systemSettingRepository.findBySettingKey(key).orElseGet(SystemSetting::new);
        setting.setSettingKey(key);
        setting.setSettingValue(value);
        setting.setEncrypted(encrypted ? 1 : 0);
        setting.setUpdatedBy(operatorId);
        systemSettingRepository.save(setting);
    }

    private String resolveSettingValue(SystemSetting setting) {
        if (setting == null) {
            return null;
        }
        if (setting.isEncrypted()) {
            return settingsCryptoService.decrypt(setting.getSettingValue());
        }
        return setting.getSettingValue();
    }

    private String resolveApiKey(SystemSetting setting) {
        String value = resolveSettingValue(setting);
        return normalizeApiKey(value);
    }

    private String maskSecret(String secret) {
        if (secret == null || secret.isBlank()) {
            return null;
        }
        String value = secret.trim();
        if (value.length() <= 8) {
            return "********";
        }
        String prefix = value.substring(0, 4);
        String suffix = value.substring(value.length() - 4);
        return prefix + "****" + suffix;
    }

    private String normalizeBaseUrl(String raw) {
        if (raw == null) {
            return null;
        }
        String value = raw.trim();
        if (value.isBlank()) {
            return null;
        }
        while (value.endsWith("/")) {
            value = value.substring(0, value.length() - 1);
        }
        return value;
    }

    private String normalizeApiKey(String raw) {
        if (raw == null) {
            return null;
        }
        String value = raw.trim();
        return value.isBlank() ? null : value;
    }

    private LocalDateTime loadLatestUpdatedAt() {
        return systemSettingRepository.findBySettingKeyIn(List.of(OPENAI_BASE_URL_KEY, OPENAI_API_KEY_KEY))
                .stream()
                .map(SystemSetting::getUpdatedAt)
                .filter(Objects::nonNull)
                .max(LocalDateTime::compareTo)
                .orElse(null);
    }

    public record OpenAiRuntimeSettings(String baseUrl, String apiKey) {
    }

    public record OpenAiAdminSettingsUpdate(String baseUrl, String apiKey, Boolean clearApiKey) {
    }

    public record OpenAiAdminSettingsView(
            String baseUrl,
            boolean hasApiKey,
            String apiKeyMasked,
            LocalDateTime updatedAt) {
    }
}
