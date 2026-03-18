package com.flowablecollab.approval_system.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.form.FormDefinition;
import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.entity.form.FormInstance;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.repository.form.FormDefinitionRepository;
import com.flowablecollab.approval_system.repository.form.FormFieldRepository;
import com.flowablecollab.approval_system.repository.form.FormInstanceRepository;
import com.flowablecollab.approval_system.repository.form.FormVersionRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class FormService {

    private final FormDefinitionRepository formDefinitionRepository;
    private final FormVersionRepository formVersionRepository;
    private final FormInstanceRepository formInstanceRepository;
    private final FormFieldRepository formFieldRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public FormDefinition createFormDefinition(String formKey, String formName) {
        FormDefinition definition = new FormDefinition();
        definition.setFormKey(formKey);
        definition.setFormName(formName);
        definition.setStatus(1);
        return formDefinitionRepository.save(definition);
    }

    public FormVersion createFormVersion(Long formId, String schemaJson) {
        int nextVersion = formVersionRepository.findTopByFormIdOrderByVersionDesc(formId)
                .map(FormVersion::getVersion)
                .orElse(0) + 1;
        FormVersion version = new FormVersion();
        version.setFormId(formId);
        version.setVersion(nextVersion);
        version.setSchemaJson(schemaJson);
        return formVersionRepository.save(version);
    }

    public void replaceFields(Long formVersionId, List<FormFieldRequest> fields) {
        formFieldRepository.deleteByFormVersionId(formVersionId);
        for (FormFieldRequest request : fields) {
            FormField field = new FormField();
            field.setFormVersionId(formVersionId);
            field.setFieldKey(request.getFieldKey());
            field.setFieldType(request.getFieldType());
            field.setLabel(request.getLabel());
            field.setRequired(request.isRequired() ? 1 : 0);
            field.setVisibleRule(request.getVisibleRule());
            field.setValidateRule(request.getValidateRule());
            field.setOptionsJson(request.getOptionsJson());
            formFieldRepository.save(field);
        }
    }

    public List<FormField> getFields(Long formVersionId) {
        return formFieldRepository.findByFormVersionId(formVersionId);
    }

    public FormVersion getLatestVersion(String formKey) {
        FormDefinition definition = formDefinitionRepository.findByFormKey(formKey)
                .orElseThrow();
        return formVersionRepository.findTopByFormIdOrderByVersionDesc(definition.getId())
                .orElseThrow();
    }

    public FormVersion getVersion(Long formVersionId) {
        return formVersionRepository.findById(formVersionId)
                .orElseThrow(() -> new IllegalArgumentException("Form version not found"));
    }

    public FormInstance createFormInstance(Long formVersionId, String businessKey, Map<String, Object> data) {
        FormVersion version = formVersionRepository.findById(formVersionId)
                .orElseThrow(() -> new IllegalArgumentException("Form version not found"));
        validateFormData(version.getSchemaJson(), data);
        FormInstance instance = new FormInstance();
        instance.setFormVersionId(formVersionId);
        instance.setBusinessKey(businessKey);
        try {
            instance.setDataJson(objectMapper.writeValueAsString(data));
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
        FormVersion version = formVersionRepository.findById(formVersionId)
                .orElseThrow(() -> new IllegalArgumentException("Form version not found"));
        validateFormData(version.getSchemaJson(), data);
    }

    @Data
    public static class FormFieldRequest {
        private String fieldKey;
        private String fieldType;
        private String label;
        private boolean required;
        private String visibleRule;
        private String validateRule;
        private String optionsJson;
    }

    private void validateFormData(String schemaJson, Map<String, Object> data) {
        try {
            List<FieldError> errors = new ArrayList<>();
            com.fasterxml.jackson.databind.JsonNode root = objectMapper.readTree(schemaJson);
            com.fasterxml.jackson.databind.JsonNode fields = root.get("fields");
            if (fields == null || !fields.isArray()) {
                return;
            }
            for (com.fasterxml.jackson.databind.JsonNode field : fields) {
                String key = field.path("key").asText(null);
                if (key == null) {
                    continue;
                }
                boolean visible = isVisible(field.path("visibleRule"), data);
                Object value = data.get(key);
                boolean required = field.path("required").asBoolean(false);
                if (visible && required && (value == null || String.valueOf(value).isBlank())) {
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
                com.fasterxml.jackson.databind.JsonNode validateRule = field.path("validateRule");
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
        } catch (com.fasterxml.jackson.core.JsonProcessingException ex) {
            throw new IllegalArgumentException("Invalid form schema");
        }
    }

    private boolean isVisible(com.fasterxml.jackson.databind.JsonNode visibleRule, Map<String, Object> data) {
        if (visibleRule == null || visibleRule.isMissingNode()) {
            return true;
        }
        if (visibleRule.has("all") && visibleRule.get("all").isArray()) {
            for (com.fasterxml.jackson.databind.JsonNode rule : visibleRule.get("all")) {
                if (!evaluateCondition(rule, data)) {
                    return false;
                }
            }
            return true;
        }
        if (visibleRule.has("any") && visibleRule.get("any").isArray()) {
            for (com.fasterxml.jackson.databind.JsonNode rule : visibleRule.get("any")) {
                if (evaluateCondition(rule, data)) {
                    return true;
                }
            }
            return false;
        }
        return evaluateCondition(visibleRule, data);
    }

    private boolean evaluateCondition(com.fasterxml.jackson.databind.JsonNode rule, Map<String, Object> data) {
        String dependsOn = rule.path("dependsOn").asText(null);
        if (dependsOn == null) {
            return true;
        }
        Object actual = data.get(dependsOn);
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
                    for (com.fasterxml.jackson.databind.JsonNode item : rule.get("in")) {
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
            case "date" -> value instanceof String;
            case "select" -> value instanceof String || value instanceof Number;
            case "table" -> value instanceof java.util.List || value instanceof java.util.Map;
            default -> true;
        };
    }

    private FieldError validateValue(com.fasterxml.jackson.databind.JsonNode rule, Object value, String type,
            String key) {
        if ("number".equals(type) && value instanceof Number number) {
            if (rule.has("min") && number.doubleValue() < rule.get("min").asDouble()) {
                return new FieldError(key, "MIN", "Field min violation");
            }
            if (rule.has("max") && number.doubleValue() > rule.get("max").asDouble()) {
                return new FieldError(key, "MAX", "Field max violation");
            }
        }
        if ("string".equals(type) && value instanceof String text) {
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
