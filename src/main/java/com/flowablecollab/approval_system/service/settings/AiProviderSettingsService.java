package com.flowablecollab.approval_system.service.settings;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.settings.SystemSetting;
import com.flowablecollab.approval_system.repository.settings.SystemSettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.net.URI;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
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
    public static final String OPENAI_MODEL_KEY = "ai.llm.openai.model";
    public static final String PROVIDER_KEY = "ai.llm.provider";

    public static final String PROVIDER_MOCK = "mock";
    public static final String PROVIDER_OPENAI = "openai";

    private final SystemSettingRepository systemSettingRepository;
    private final SettingsCryptoService settingsCryptoService;
    private final RestTemplateBuilder restTemplateBuilder;
    private final ObjectMapper objectMapper;

    @Value("${ai.llm.provider:mock}")
    private String defaultProvider;

    @Value("${ai.llm.openai.base-url:https://api.openai.com/v1}")
    private String defaultOpenAiBaseUrl;

    @Value("${ai.llm.openai.api-key:}")
    private String defaultOpenAiApiKey;

    @Value("${ai.llm.openai.model:gpt-5.4-mini}")
    private String defaultOpenAiModel;

    @Value("${ai.llm.openai.connect-timeout-seconds:10}")
    private long connectTimeoutSeconds;

    @Value("${ai.llm.openai.read-timeout-seconds:30}")
    private long readTimeoutSeconds;

    @Transactional(readOnly = true)
    public OpenAiRuntimeSettings resolveOpenAiRuntimeSettings(String fallbackBaseUrl, String fallbackApiKey, String fallbackModel) {
        Map<String, SystemSetting> settingMap = systemSettingRepository
                .findBySettingKeyIn(List.of(OPENAI_BASE_URL_KEY, OPENAI_API_KEY_KEY, OPENAI_MODEL_KEY))
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

        String model = normalizeModel(resolveSettingValue(settingMap.get(OPENAI_MODEL_KEY)));
        if (model == null || model.isBlank()) {
            model = normalizeModel(fallbackModel);
        }
        if (model == null || model.isBlank()) {
            model = normalizeModel(defaultOpenAiModel);
        }

        return new OpenAiRuntimeSettings(baseUrl, normalizeApiKey(apiKey), model);
    }

    @Transactional(readOnly = true)
    public OpenAiAdminSettingsView getOpenAiAdminSettings() {
        OpenAiRuntimeSettings runtimeSettings = resolveOpenAiRuntimeSettings(defaultOpenAiBaseUrl, defaultOpenAiApiKey, defaultOpenAiModel);
        String apiKey = runtimeSettings.apiKey();
        return new OpenAiAdminSettingsView(
                runtimeSettings.baseUrl(),
                apiKey != null && !apiKey.isBlank(),
                maskSecret(apiKey),
                runtimeSettings.model(),
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

        if (update.model() != null) {
            String normalizedModel = normalizeModel(update.model());
            if (normalizedModel == null || normalizedModel.isBlank()) {
                systemSettingRepository.deleteBySettingKey(OPENAI_MODEL_KEY);
            } else {
                upsertSetting(OPENAI_MODEL_KEY, normalizedModel, false, operatorId);
            }
        }

        return getOpenAiAdminSettings();
    }

    @Transactional(readOnly = true)
    public OpenAiModelListView listOpenAiModels(OpenAiModelListQuery query) {
        OpenAiRuntimeSettings runtimeSettings = resolveOpenAiRuntimeSettings(defaultOpenAiBaseUrl, defaultOpenAiApiKey, defaultOpenAiModel);
        String baseUrl = normalizeBaseUrl(query == null ? null : query.baseUrl());
        if (baseUrl == null || baseUrl.isBlank()) {
            baseUrl = runtimeSettings.baseUrl();
        }

        String apiKey = normalizeApiKey(query == null ? null : query.apiKey());
        if (apiKey == null || apiKey.isBlank()) {
            apiKey = runtimeSettings.apiKey();
        }
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalArgumentException("OpenAI api-key is required");
        }

        String endpoint = baseUrl + "/models";

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(apiKey);
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        HttpEntity<Void> request = new HttpEntity<>(headers);

        ResponseEntity<String> response;
        String effectiveBaseUrl = baseUrl;
        try {
            response = fetchModelsResponse(endpoint, request);
        } catch (RestClientException firstEx) {
            String fallbackEndpoint = toHttpEndpointForLocalhost(endpoint);
            if (fallbackEndpoint != null) {
                try {
                    response = fetchModelsResponse(fallbackEndpoint, request);
                    effectiveBaseUrl = normalizeBaseUrlFromEndpoint(fallbackEndpoint);
                } catch (RestClientException secondEx) {
                    throw new IllegalArgumentException(buildModelFetchError(endpoint, secondEx));
                }
            } else {
                throw new IllegalArgumentException(buildModelFetchError(endpoint, firstEx));
            }
        }

        List<String> models = parseModelIds(response.getBody());
        return new OpenAiModelListView(effectiveBaseUrl, runtimeSettings.model(), models);
    }

    @Transactional(readOnly = true)
    public String getActiveProvider() {
        String raw = systemSettingRepository.findBySettingKey(PROVIDER_KEY)
                .map(SystemSetting::getSettingValue)
                .orElse(null);
        String normalized = normalizeProvider(raw);
        if (normalized != null) {
            return normalized;
        }
        normalized = normalizeProvider(defaultProvider);
        return normalized != null ? normalized : PROVIDER_MOCK;
    }

    @Transactional(readOnly = true)
    public AiProviderAdminView getAiProviderAdminView() {
        String provider = getActiveProvider();
        OpenAiAdminSettingsView openAi = getOpenAiAdminSettings();
        LocalDateTime updatedAt = systemSettingRepository.findBySettingKey(PROVIDER_KEY)
                .map(SystemSetting::getUpdatedAt)
                .orElse(null);
        return new AiProviderAdminView(provider, openAi.hasApiKey(), updatedAt);
    }

    @Transactional
    public AiProviderAdminView setActiveProvider(String rawProvider, Long operatorId) {
        String provider = normalizeProvider(rawProvider);
        if (provider == null) {
            throw new IllegalArgumentException("provider must be one of: mock, openai");
        }
        if (PROVIDER_OPENAI.equals(provider)) {
            OpenAiRuntimeSettings runtime = resolveOpenAiRuntimeSettings(defaultOpenAiBaseUrl, defaultOpenAiApiKey, defaultOpenAiModel);
            if (runtime.apiKey() == null || runtime.apiKey().isBlank()) {
                throw new IllegalArgumentException("请先在下方配置 OpenAI API Key 后再切换到 openai");
            }
        }
        upsertSetting(PROVIDER_KEY, provider, false, operatorId);
        return getAiProviderAdminView();
    }

    private String normalizeProvider(String raw) {
        if (raw == null) {
            return null;
        }
        String value = raw.trim().toLowerCase(java.util.Locale.ROOT);
        if (PROVIDER_MOCK.equals(value) || PROVIDER_OPENAI.equals(value)) {
            return value;
        }
        return null;
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

    private String normalizeModel(String raw) {
        if (raw == null) {
            return null;
        }
        String value = raw.trim();
        return value.isBlank() ? null : value;
    }

    private LocalDateTime loadLatestUpdatedAt() {
        return systemSettingRepository.findBySettingKeyIn(List.of(OPENAI_BASE_URL_KEY, OPENAI_API_KEY_KEY, OPENAI_MODEL_KEY))
                .stream()
                .map(SystemSetting::getUpdatedAt)
                .filter(Objects::nonNull)
                .max(LocalDateTime::compareTo)
                .orElse(null);
    }

    private RestTemplate createRestTemplate() {
        return restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(connectTimeoutSeconds))
                .setReadTimeout(Duration.ofSeconds(readTimeoutSeconds))
                .build();
    }

    private ResponseEntity<String> fetchModelsResponse(String endpoint, HttpEntity<Void> request) {
        return createRestTemplate().exchange(endpoint, HttpMethod.GET, request, String.class);
    }

    private String toHttpEndpointForLocalhost(String endpoint) {
        try {
            URI uri = URI.create(endpoint);
            if (!"https".equalsIgnoreCase(uri.getScheme())) {
                return null;
            }
            String host = uri.getHost();
            if (host == null) {
                return null;
            }
            if (!"localhost".equalsIgnoreCase(host) && !"127.0.0.1".equals(host)) {
                return null;
            }
            URI fallback = new URI(
                    "http",
                    uri.getUserInfo(),
                    host,
                    uri.getPort(),
                    uri.getPath(),
                    uri.getQuery(),
                    uri.getFragment());
            return fallback.toString();
        } catch (Exception ex) {
            return null;
        }
    }

    private String normalizeBaseUrlFromEndpoint(String endpoint) {
        if (endpoint == null || endpoint.isBlank()) {
            return endpoint;
        }
        int index = endpoint.lastIndexOf("/models");
        if (index <= 0) {
            return endpoint;
        }
        return normalizeBaseUrl(endpoint.substring(0, index));
    }

    private String buildModelFetchError(String endpoint, RestClientException ex) {
        String reason = ex.getMessage();
        if (reason == null || reason.isBlank()) {
            reason = ex.getClass().getSimpleName();
        }
        return "failed to load models from OpenAI provider: " + reason + " (endpoint: " + endpoint + ")";
    }

    private List<String> parseModelIds(String rawBody) {
        if (rawBody == null || rawBody.isBlank()) {
            return List.of();
        }
        try {
            JsonNode root = objectMapper.readTree(rawBody);
            JsonNode dataNode = root.path("data");
            if (!dataNode.isArray()) {
                return List.of();
            }
            List<String> models = new ArrayList<>();
            for (JsonNode node : dataNode) {
                String modelId = normalizeModel(node.path("id").asText(null));
                if (modelId != null && !modelId.isBlank()) {
                    models.add(modelId);
                }
            }
            return models.stream().distinct().sorted().toList();
        } catch (Exception ex) {
            throw new IllegalArgumentException("failed to parse models from provider response");
        }
    }

    public record OpenAiRuntimeSettings(String baseUrl, String apiKey, String model) {
    }

    public record OpenAiAdminSettingsUpdate(String baseUrl, String apiKey, String model, Boolean clearApiKey) {
    }

    public record OpenAiModelListQuery(String baseUrl, String apiKey) {
    }

    public record OpenAiModelListView(
            String baseUrl,
            String selectedModel,
            List<String> models) {
    }

    public record OpenAiAdminSettingsView(
            String baseUrl,
            boolean hasApiKey,
            String apiKeyMasked,
            String model,
            LocalDateTime updatedAt) {
    }

    public record AiProviderAdminView(
            String provider,
            boolean openAiReady,
            LocalDateTime updatedAt) {
    }
}
