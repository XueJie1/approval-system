package com.flowablecollab.approval_system.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.form.FormDefinition;
import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.entity.form.FormInstance;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.exception.ResourceNotFoundException;
import com.flowablecollab.approval_system.repository.form.FormDefinitionRepository;
import com.flowablecollab.approval_system.repository.form.FormFieldRepository;
import com.flowablecollab.approval_system.repository.form.FormInstanceRepository;
import com.flowablecollab.approval_system.repository.form.FormVersionRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class FormService {

    private final FormDefinitionRepository formDefinitionRepository;
    private final FormVersionRepository formVersionRepository;
    private final FormInstanceRepository formInstanceRepository;
    private final FormFieldRepository formFieldRepository;
    private final ObjectMapper objectMapper;

    public FormDefinition createFormDefinition(String formKey, String formName) {
        if (formKey == null || formKey.isBlank()) {
            throw new IllegalArgumentException("formKey is required");
        }
        if (formName == null || formName.isBlank()) {
            throw new IllegalArgumentException("formName is required");
        }
        String normalizedKey = formKey.trim();
        if (formDefinitionRepository.findByFormKey(normalizedKey).isPresent()) {
            throw new IllegalArgumentException("formKey already exists");
        }
        FormDefinition definition = new FormDefinition();
        definition.setFormKey(normalizedKey);
        definition.setFormName(formName.trim());
        definition.setStatus(1);
        return formDefinitionRepository.save(definition);
    }

    public FormDefinition updateFormDefinition(Long formDefinitionId, String formName, Integer status) {
        FormDefinition definition = formDefinitionRepository.findById(formDefinitionId)
                .orElseThrow(() -> new IllegalArgumentException("Form definition not found"));
        if (formName != null && !formName.isBlank()) {
            definition.setFormName(formName.trim());
        }
        if (status != null) {
            definition.setStatus(status);
        }
        return formDefinitionRepository.save(definition);
    }

    public FormVersion createFormVersion(Long formId, String schemaJson) {
        if (formId == null) {
            throw new IllegalArgumentException("formId is required");
        }
        formDefinitionRepository.findById(formId)
                .orElseThrow(() -> new IllegalArgumentException("Form definition not found"));
        int nextVersion = formVersionRepository.findTopByFormIdOrderByVersionDesc(formId)
                .map(FormVersion::getVersion)
                .orElse(0) + 1;
        FormVersion version = new FormVersion();
        version.setFormId(formId);
        version.setVersion(nextVersion);
        version.setSchemaJson(schemaJson == null ? "{\"fields\":[]}" : schemaJson);
        version.setStatus(FormVersion.STATUS_DRAFT);
        version.setPublishedAt(null);
        version.setPublishedBy(null);
        return formVersionRepository.save(version);
    }

    @Transactional
    public FormVersion createFormVersionByCopy(Long formId, Long copyFromVersionId, String schemaJson) {
        FormVersion source = getVersion(copyFromVersionId);
        if (!Objects.equals(source.getFormId(), formId)) {
            throw new IllegalArgumentException("copy source does not belong to target form");
        }
        FormVersion created = createFormVersion(formId, schemaJson == null ? source.getSchemaJson() : schemaJson);
        List<FormFieldRequest> sourceFields = formFieldRepository.findByFormVersionIdOrderBySortOrderAscIdAsc(copyFromVersionId)
                .stream()
                .map(field -> {
                    FormFieldRequest request = new FormFieldRequest();
                    request.setFieldKey(field.getFieldKey());
                    request.setVariableKey(field.getVariableKey());
                    request.setFieldType(field.getFieldType());
                    request.setLabel(field.getLabel());
                    request.setRequired(field.getRequired() != null && field.getRequired() == 1);
                    request.setVisibleRule(field.getVisibleRule());
                    request.setValidateRule(field.getValidateRule());
                    request.setOptionsJson(field.getOptionsJson());
                    request.setDefaultValue(field.getDefaultValue());
                    request.setSortOrder(field.getSortOrder());
                    return request;
                })
                .toList();
        replaceFields(created.getId(), sourceFields);
        return created;
    }

    @Transactional
    public FormVersion publishVersion(Long formVersionId, Long operatorId) {
        FormVersion target = getVersion(formVersionId);
        FormDefinition definition = formDefinitionRepository.findById(target.getFormId())
                .orElseThrow(() -> new IllegalArgumentException("Form definition not found"));
        if (definition.getStatus() == null || definition.getStatus() != 1) {
            throw new IllegalArgumentException("Form definition is not available");
        }
        String targetStatus = normalizeStatus(target);
        if (FormVersion.STATUS_ARCHIVED.equals(targetStatus)) {
            throw new IllegalArgumentException("Archived form version cannot be published");
        }

        List<FormVersion> versions = formVersionRepository.findByFormIdOrderByVersionDesc(target.getFormId());
        for (FormVersion version : versions) {
            if (FormVersion.STATUS_PUBLISHED.equals(normalizeStatus(version)) && !version.getId().equals(target.getId())) {
                version.setStatus(FormVersion.STATUS_ARCHIVED);
                formVersionRepository.save(version);
            }
        }

        target.setStatus(FormVersion.STATUS_PUBLISHED);
        target.setPublishedBy(operatorId);
        target.setPublishedAt(LocalDateTime.now());
        return formVersionRepository.save(target);
    }

    @Transactional
    public FormVersion archiveVersion(Long formVersionId) {
        FormVersion target = getVersion(formVersionId);
        if (target.getStatus() == null || target.getStatus().isBlank()) {
            target.setStatus(FormVersion.STATUS_ARCHIVED);
        } else {
            target.setStatus(FormVersion.STATUS_ARCHIVED);
        }
        return formVersionRepository.save(target);
    }

    @Transactional
    public void replaceFields(Long formVersionId, List<FormFieldRequest> fields) {
        FormVersion version = getVersion(formVersionId);
        if (!FormVersion.STATUS_DRAFT.equals(normalizeStatus(version))) {
            throw new IllegalArgumentException("Only draft form version can update fields");
        }
        formFieldRepository.deleteByFormVersionId(formVersionId);
        List<FormFieldRequest> normalizedFields = fields == null ? List.of() : fields;
        for (int index = 0; index < normalizedFields.size(); index++) {
            FormFieldRequest request = normalizedFields.get(index);
            if (request.getFieldKey() == null || request.getFieldKey().isBlank()) {
                continue;
            }
            FormField field = new FormField();
            field.setFormVersionId(formVersionId);
            field.setFieldKey(request.getFieldKey().trim());
            field.setVariableKey(blankToNull(request.getVariableKey()));
            field.setFieldType(request.getFieldType() == null || request.getFieldType().isBlank()
                    ? "string"
                    : request.getFieldType().trim());
            field.setLabel(blankToNull(request.getLabel()));
            field.setRequired(request.isRequired() ? 1 : 0);
            field.setVisibleRule(blankToNull(request.getVisibleRule()));
            field.setValidateRule(blankToNull(request.getValidateRule()));
            field.setOptionsJson(blankToNull(request.getOptionsJson()));
            field.setDefaultValue(blankToNull(request.getDefaultValue()));
            field.setSortOrder(request.getSortOrder() == null ? index : request.getSortOrder());
            formFieldRepository.save(field);
        }
    }

    public List<FormField> getFields(Long formVersionId) {
        return formFieldRepository.findByFormVersionIdOrderBySortOrderAscIdAsc(formVersionId);
    }

    public FormVersion getLatestVersion(String formKey) {
        FormDefinition definition = formDefinitionRepository.findByFormKey(formKey)
                .orElseThrow(() -> new ResourceNotFoundException("Form definition not found"));
        FormVersion published = formVersionRepository
                .findTopByFormIdAndStatusOrderByVersionDesc(definition.getId(), FormVersion.STATUS_PUBLISHED)
                .orElse(null);
        if (published != null) {
            return published;
        }
        return formVersionRepository.findTopByFormIdOrderByVersionDesc(definition.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Form version not found"));
    }

    public FormVersion getLatestPublishedVersion(String formKey) {
        FormDefinition definition = formDefinitionRepository.findByFormKey(formKey)
                .orElseThrow(() -> new ResourceNotFoundException("Form definition not found"));
        return formVersionRepository
                .findTopByFormIdAndStatusOrderByVersionDesc(definition.getId(), FormVersion.STATUS_PUBLISHED)
                .orElseThrow(() -> new ResourceNotFoundException("Published form version not found"));
    }

    public FormVersion getVersion(Long formVersionId) {
        return formVersionRepository.findById(formVersionId)
                .orElseThrow(() -> new IllegalArgumentException("Form version not found"));
    }

    public BoundFormVersion resolveBoundFormVersion(Long formVersionId) {
        FormVersion version = getVersion(formVersionId);
        FormDefinition definition = formDefinitionRepository.findById(version.getFormId())
                .orElseThrow(() -> new IllegalArgumentException("Form definition not found"));
        if (definition.getStatus() == null || definition.getStatus() != 1) {
            throw new IllegalArgumentException("Form definition is not available");
        }
        if (FormVersion.STATUS_ARCHIVED.equals(normalizeStatus(version))) {
            throw new IllegalArgumentException("Form version is archived");
        }
        BoundFormVersion bound = new BoundFormVersion();
        bound.setFormDefinition(definition);
        bound.setFormVersion(version);
        return bound;
    }

    public List<FormDefinition> listDefinitions() {
        return formDefinitionRepository.findAllByOrderByFormNameAscIdAsc();
    }

    public List<FormVersion> listVersions(Long formId) {
        return formVersionRepository.findByFormIdOrderByVersionDesc(formId);
    }

    public FormInstance createFormInstance(Long formVersionId, String businessKey, Map<String, Object> data) {
        FormVersion version = getVersion(formVersionId);
        Map<String, Object> normalizedData = applyDefaultValues(formVersionId, data);
        validateFormData(version, normalizedData);
        FormInstance instance = new FormInstance();
        instance.setFormVersionId(formVersionId);
        instance.setBusinessKey(businessKey);
        try {
            instance.setDataJson(objectMapper.writeValueAsString(normalizedData));
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid form data");
        }
        return formInstanceRepository.save(instance);
    }

    public FormInstance getFormInstance(Long formInstanceId) {
        return formInstanceRepository.findById(formInstanceId)
                .orElseThrow(() -> new IllegalArgumentException("Form instance not found"));
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> readFormInstanceData(Long formInstanceId) {
        FormInstance instance = getFormInstance(formInstanceId);
        try {
            return objectMapper.readValue(instance.getDataJson(), Map.class);
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid form instance data");
        }
    }

    public void validateFormInstance(Long formVersionId, Map<String, Object> data) {
        FormVersion version = getVersion(formVersionId);
        validateFormData(version, applyDefaultValues(formVersionId, data));
    }

    public Map<String, Object> applyDefaultValues(Long formVersionId, Map<String, Object> data) {
        Map<String, Object> normalized = new LinkedHashMap<>();
        if (data != null) {
            normalized.putAll(data);
        }
        List<FormField> fields = formFieldRepository.findByFormVersionIdOrderBySortOrderAscIdAsc(formVersionId);
        for (FormField field : fields) {
            String key = field.getFieldKey();
            if (key == null || key.isBlank()) {
                continue;
            }
            if (normalized.containsKey(key)) {
                continue;
            }
            Object defaultValue = parseDefaultValue(field);
            if (defaultValue != null) {
                normalized.put(key, defaultValue);
            }
        }
        return normalized;
    }

    public Map<String, Object> mapToWorkflowVariables(Long formVersionId, Map<String, Object> formData) {
        if (formData == null || formData.isEmpty()) {
            return Map.of();
        }
        List<FormField> fields = formFieldRepository.findByFormVersionIdOrderBySortOrderAscIdAsc(formVersionId);
        if (fields.isEmpty()) {
            return Map.copyOf(formData);
        }
        Map<String, String> variableKeyByFieldKey = new LinkedHashMap<>();
        for (FormField field : fields) {
            if (field.getFieldKey() == null || field.getFieldKey().isBlank()) {
                continue;
            }
            variableKeyByFieldKey.put(field.getFieldKey(),
                    field.getVariableKey() == null || field.getVariableKey().isBlank()
                            ? field.getFieldKey()
                            : field.getVariableKey().trim());
        }
        Map<String, Object> variables = new LinkedHashMap<>();
        for (Map.Entry<String, Object> entry : formData.entrySet()) {
            String mappedKey = variableKeyByFieldKey.getOrDefault(entry.getKey(), entry.getKey());
            variables.put(mappedKey, entry.getValue());
        }
        return variables;
    }

    @Data
    public static class FormFieldRequest {
        private String fieldKey;
        private String variableKey;
        private String fieldType;
        private String label;
        private boolean required;
        private String visibleRule;
        private String validateRule;
        private String optionsJson;
        private String defaultValue;
        private Integer sortOrder;
    }

    @Data
    public static class BoundFormVersion {
        private FormDefinition formDefinition;
        private FormVersion formVersion;
    }

    private void validateFormData(FormVersion version, Map<String, Object> data) {
        List<FormField> configuredFields = formFieldRepository.findByFormVersionIdOrderBySortOrderAscIdAsc(version.getId());
        if (!configuredFields.isEmpty()) {
            validateByFieldConfig(configuredFields, data);
            return;
        }
        validateBySchema(version.getSchemaJson(), data);
    }

    private void validateByFieldConfig(List<FormField> fields, Map<String, Object> data) {
        List<FieldError> errors = new ArrayList<>();
        Map<String, Object> safeData = data == null ? Map.of() : data;
        for (FormField field : fields) {
            if (field.getFieldKey() == null || field.getFieldKey().isBlank()) {
                continue;
            }
            JsonNode visibleRule = parseJsonNode(field.getVisibleRule());
            boolean visible = isVisible(visibleRule, safeData);
            Object value = safeData.get(field.getFieldKey());
            boolean required = field.getRequired() != null && field.getRequired() == 1;
            if (visible && required && isBlankValue(value)) {
                errors.add(new FieldError(field.getFieldKey(), "REQUIRED", "Field required"));
                continue;
            }
            if (!visible || value == null) {
                continue;
            }

            String fieldType = field.getFieldType() == null || field.getFieldType().isBlank()
                    ? "string"
                    : field.getFieldType().trim();
            if (!typeMatches(fieldType, value)) {
                errors.add(new FieldError(field.getFieldKey(), "TYPE_MISMATCH", "Field type mismatch"));
                continue;
            }
            if ("select".equals(fieldType) && field.getOptionsJson() != null && !field.getOptionsJson().isBlank()) {
                if (!selectOptionMatches(field.getOptionsJson(), value)) {
                    errors.add(new FieldError(field.getFieldKey(), "OPTION_INVALID", "Field option is invalid"));
                    continue;
                }
            }

            JsonNode validateRule = parseJsonNode(field.getValidateRule());
            if (validateRule != null && !validateRule.isMissingNode() && !validateRule.isNull()) {
                FieldError err = validateValue(validateRule, value, fieldType, field.getFieldKey());
                if (err != null) {
                    errors.add(err);
                }
            }
        }
        if (!errors.isEmpty()) {
            throw new FormValidationException(errors);
        }
    }

    private boolean selectOptionMatches(String optionsJson, Object value) {
        try {
            JsonNode options = objectMapper.readTree(optionsJson);
            if (!options.isArray() || options.isEmpty()) {
                return true;
            }
            String target = String.valueOf(value);
            for (JsonNode option : options) {
                if (option.isTextual() || option.isNumber()) {
                    if (target.equals(option.asText())) {
                        return true;
                    }
                    continue;
                }
                if (option.isObject()) {
                    String label = option.path("label").asText(null);
                    String optionValue = option.path("value").asText(null);
                    if (target.equals(label) || target.equals(optionValue)) {
                        return true;
                    }
                }
            }
            return false;
        } catch (JsonProcessingException ex) {
            return true;
        }
    }

    private void validateBySchema(String schemaJson, Map<String, Object> data) {
        try {
            List<FieldError> errors = new ArrayList<>();
            JsonNode root = objectMapper.readTree(schemaJson);
            JsonNode fields = root.get("fields");
            if (fields == null || !fields.isArray()) {
                return;
            }
            for (JsonNode field : fields) {
                String key = field.path("key").asText(null);
                if (key == null) {
                    continue;
                }
                boolean visible = isVisible(field.path("visibleRule"), data);
                Object value = data == null ? null : data.get(key);
                boolean required = field.path("required").asBoolean(false);
                if (visible && required && isBlankValue(value)) {
                    errors.add(new FieldError(key, "REQUIRED", "Field required"));
                    continue;
                }
                if (!visible || value == null) {
                    continue;
                }
                String type = field.path("type").asText("string");
                if (!typeMatches(type, value)) {
                    errors.add(new FieldError(key, "TYPE_MISMATCH", "Field type mismatch"));
                    continue;
                }
                JsonNode validateRule = field.path("validateRule");
                if (!validateRule.isMissingNode()) {
                    FieldError err = validateValue(validateRule, value, type, key);
                    if (err != null) {
                        errors.add(err);
                    }
                }
            }
            if (!errors.isEmpty()) {
                throw new FormValidationException(errors);
            }
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("Invalid form schema");
        }
    }

    private boolean isVisible(JsonNode visibleRule, Map<String, Object> data) {
        if (visibleRule == null || visibleRule.isMissingNode() || visibleRule.isNull()) {
            return true;
        }
        if (visibleRule.has("all") && visibleRule.get("all").isArray()) {
            for (JsonNode rule : visibleRule.get("all")) {
                if (!evaluateCondition(rule, data)) {
                    return false;
                }
            }
            return true;
        }
        if (visibleRule.has("any") && visibleRule.get("any").isArray()) {
            for (JsonNode rule : visibleRule.get("any")) {
                if (evaluateCondition(rule, data)) {
                    return true;
                }
            }
            return false;
        }
        return evaluateCondition(visibleRule, data);
    }

    private boolean evaluateCondition(JsonNode rule, Map<String, Object> data) {
        String dependsOn = rule.path("dependsOn").asText(null);
        if (dependsOn == null) {
            return true;
        }
        Object actual = data == null ? null : data.get(dependsOn);
        String operator = rule.path("operator").asText(null);
        if (operator == null) {
            if (rule.has("notEquals")) {
                operator = "notEquals";
            } else if (rule.has("in")) {
                operator = "in";
            } else if (rule.has("equals")) {
                operator = "equals";
            }
        }
        String actualText = actual == null ? null : String.valueOf(actual);
        if (operator == null) {
            return actualText != null;
        }
        return switch (operator) {
            case "notEquals" -> {
                String notEquals = rule.path("notEquals").asText(null);
                if (notEquals == null) {
                    yield actualText != null;
                }
                yield actualText == null || !notEquals.equals(actualText);
            }
            case "in" -> {
                if (rule.has("in") && rule.get("in").isArray()) {
                    boolean found = false;
                    for (JsonNode item : rule.get("in")) {
                        if (item.asText().equals(actualText)) {
                            found = true;
                            break;
                        }
                    }
                    yield found;
                }
                yield false;
            }
            case "equals" -> {
                String equals = rule.path("equals").asText(null);
                if (equals == null) {
                    yield actualText != null;
                }
                yield equals.equals(actualText);
            }
            default -> actualText != null;
        };
    }

    private boolean typeMatches(String type, Object value) {
        return switch (type) {
            case "number" -> value instanceof Number;
            case "string" -> value instanceof String;
            case "date", "datetime" -> value instanceof String;
            case "select" -> value instanceof String || value instanceof Number;
            case "table" -> value instanceof List || value instanceof Map;
            default -> true;
        };
    }

    private FieldError validateValue(JsonNode rule, Object value, String type, String key) {
        if ("number".equals(type) && value instanceof Number number) {
            if (rule.has("min") && number.doubleValue() < rule.get("min").asDouble()) {
                return new FieldError(key, "MIN", "Field min violation");
            }
            if (rule.has("max") && number.doubleValue() > rule.get("max").asDouble()) {
                return new FieldError(key, "MAX", "Field max violation");
            }
        }
        if (("string".equals(type) || "date".equals(type) || "datetime".equals(type)) && value instanceof String text) {
            if (rule.has("minLength") && text.length() < rule.get("minLength").asInt()) {
                return new FieldError(key, "MIN_LENGTH", "Field minLength violation");
            }
            if (rule.has("maxLength") && text.length() > rule.get("maxLength").asInt()) {
                return new FieldError(key, "MAX_LENGTH", "Field maxLength violation");
            }
            if (rule.has("pattern")) {
                String pattern = rule.get("pattern").asText();
                if (!text.matches(pattern)) {
                    return new FieldError(key, "PATTERN", "Field pattern violation");
                }
            }
        }
        return null;
    }

    private boolean isBlankValue(Object value) {
        if (value == null) {
            return true;
        }
        if (value instanceof String stringValue) {
            return stringValue.isBlank();
        }
        return false;
    }

    private String normalizeStatus(FormVersion version) {
        return (version.getStatus() == null || version.getStatus().isBlank())
                ? FormVersion.STATUS_PUBLISHED
                : version.getStatus();
    }

    private JsonNode parseJsonNode(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readTree(raw);
        } catch (JsonProcessingException ex) {
            return null;
        }
    }

    private Object parseDefaultValue(FormField field) {
        if (field.getDefaultValue() == null || field.getDefaultValue().isBlank()) {
            return null;
        }
        String raw = field.getDefaultValue().trim();
        String type = field.getFieldType() == null ? "string" : field.getFieldType().trim();
        try {
            return switch (type) {
                case "number" -> Double.parseDouble(raw);
                case "table" -> objectMapper.readValue(raw, Object.class);
                case "select", "string", "date", "datetime" -> raw;
                default -> raw;
            };
        } catch (Exception ignored) {
            return raw;
        }
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    @Data
    public static class FieldError {
        private final String field;
        private final String code;
        private final String message;
    }

    public static class FormValidationException extends RuntimeException {
        private final List<FieldError> errors;

        public FormValidationException(List<FieldError> errors) {
            super("Form validation failed");
            this.errors = errors;
        }

        public List<FieldError> getErrors() {
            return errors;
        }
    }
}
