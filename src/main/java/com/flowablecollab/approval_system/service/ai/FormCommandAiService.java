package com.flowablecollab.approval_system.service.ai;

import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.FormService;
import com.flowablecollab.approval_system.service.WorkflowService;
import com.flowablecollab.approval_system.service.workflow.manage.RequestTemplateService;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowLaunchResolverService;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowManageDtos;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@ConditionalOnBean(FormService.class)
public class FormCommandAiService {

    private static final String MODEL_NAME = "heuristic-form-parser-v1";

    private final FormService formService;
    private final WorkflowService workflowService;
    private final RequestTemplateService requestTemplateService;
    private final WorkflowLaunchResolverService workflowLaunchResolverService;

    @Transactional(readOnly = true)
    public ParseResult parse(ParseRequest request) {
        if (request.getCommand() == null || request.getCommand().isBlank()) {
            throw new IllegalArgumentException("command is required");
        }
        String command = request.getCommand().trim();

        RequestTemplateService.TemplateView template = resolveTemplate(request, command);
        String formKey = request.getFormKey();
        if ((formKey == null || formKey.isBlank()) && template != null) {
            formKey = template.getFormKey();
        }
        if (formKey == null || formKey.isBlank()) {
            throw new IllegalArgumentException("formKey is required or cannot be inferred from command");
        }

        Long formVersionId = request.getFormVersionId();
        if (formVersionId == null) {
            formVersionId = formService.getLatestVersion(formKey).getId();
        }

        List<FormField> fields = formService.getFields(formVersionId);
        if (fields.isEmpty()) {
            throw new IllegalArgumentException("selected form version has no fields");
        }

        Map<String, Object> extractedData = extractFieldValues(command, fields);
        Map<String, Object> formData = formService.applyDefaultValues(formVersionId, extractedData);
        Map<String, Object> variables = formService.mapToWorkflowVariables(formVersionId, formData);

        List<String> missingRequiredFields = new ArrayList<>();
        int requiredCount = 0;
        int satisfiedRequiredCount = 0;
        for (FormField field : fields) {
            boolean required = field.getRequired() != null && field.getRequired() == 1;
            if (!required) {
                continue;
            }
            requiredCount++;
            Object value = formData.get(field.getFieldKey());
            if (value == null || (value instanceof String stringValue && stringValue.isBlank())) {
                missingRequiredFields.add(field.getFieldKey());
            } else {
                satisfiedRequiredCount++;
            }
        }

        double confidence;
        if (requiredCount > 0) {
            confidence = (double) satisfiedRequiredCount / requiredCount;
        } else {
            confidence = Math.min(1.0d, (double) formData.size() / Math.max(1, fields.size()));
        }

        ParseResult result = new ParseResult();
        result.setModel(MODEL_NAME);
        result.setTemplateKey(template == null ? null : template.getTemplateKey());
        result.setTemplateName(template == null ? null : template.getTemplateName());
        result.setFormKey(formKey);
        result.setFormVersionId(formVersionId);
        result.setProcessKey(template == null ? null : template.getProcessKey());
        result.setFormData(formData);
        result.setVariables(variables);
        result.setMissingRequiredFields(missingRequiredFields);
        result.setConfidence(confidence);
        result.setParsedAt(LocalDateTime.now());
        return result;
    }

    @Transactional
    public StartFromCommandResult parseAndStart(StartFromCommandRequest request, Long requesterId) {
        ParseRequest parseRequest = new ParseRequest();
        parseRequest.setCommand(request.getCommand());
        parseRequest.setRequestTemplateKey(request.getRequestTemplateKey());
        parseRequest.setFormKey(request.getFormKey());
        parseRequest.setFormVersionId(request.getFormVersionId());

        ParseResult parseResult = parse(parseRequest);
        if ((request.getRequireAllRequiredFields() == null || request.getRequireAllRequiredFields())
                && !parseResult.getMissingRequiredFields().isEmpty()) {
            throw new IllegalArgumentException("missing required fields: " + String.join(",", parseResult.getMissingRequiredFields()));
        }

        Long applicantId = request.getApplicantId() == null ? requesterId : request.getApplicantId();
        if (applicantId == null) {
            throw new IllegalArgumentException("applicantId is required");
        }
        String requestTemplateKey = resolveRequestTemplateKey(request, parseResult);
        requestTemplateService.requireLaunchPermission(requestTemplateKey, SecurityUtils.currentRoleCodes());

        String businessKey = request.getBusinessKey();
        if (businessKey == null || businessKey.isBlank()) {
            businessKey = UUID.randomUUID().toString();
        }

        Map<String, Object> formData = parseResult.getFormData();
        formService.validateFormInstance(parseResult.getFormVersionId(), formData);
        var formInstance = formService.createFormInstance(parseResult.getFormVersionId(), businessKey, formData);

        WorkflowService.StartRequest startRequest = new WorkflowService.StartRequest();
        startRequest.setBusinessKey(businessKey);
        startRequest.setApplicantId(applicantId);
        startRequest.setTitle(resolveTitle(request, parseResult));
        startRequest.setFormInstanceId(formInstance.getId());
        startRequest.setFormVersionId(parseResult.getFormVersionId());
        startRequest.setProcessKey(resolveProcessKey(request, parseResult));
        startRequest.setVariables(parseResult.getVariables());
        startRequest.setRequestTemplateKey(requestTemplateKey);

        WorkflowManageDtos.WorkflowLaunchDefinition launchDefinition = workflowLaunchResolverService
                .resolveCurrentLaunchDefinition(startRequest.getProcessKey());
        if (launchDefinition != null) {
            startRequest.setWorkflowDefinitionId(launchDefinition.getDefinitionId());
            startRequest.setWorkflowDefinitionVersionId(launchDefinition.getVersionId());
            startRequest.setFlowableProcessDefinitionId(launchDefinition.getFlowableProcessDefinitionId());
            if (startRequest.getFormVersionId() == null) {
                startRequest.setFormVersionId(launchDefinition.getFormVersionId());
            }
        }

        String processInstanceId = workflowService.startApprovalProcess(startRequest);

        StartFromCommandResult result = new StartFromCommandResult();
        result.setProcessInstanceId(processInstanceId);
        result.setBusinessKey(businessKey);
        result.setTitle(startRequest.getTitle());
        result.setApplicantId(applicantId);
        result.setFormVersionId(parseResult.getFormVersionId());
        result.setTemplateKey(parseResult.getTemplateKey());
        result.setMissingRequiredFields(parseResult.getMissingRequiredFields());
        result.setConfidence(parseResult.getConfidence());
        result.setStartedAt(LocalDateTime.now());
        return result;
    }

    private String resolveRequestTemplateKey(StartFromCommandRequest request, ParseResult parseResult) {
        if (request.getRequestTemplateKey() != null && !request.getRequestTemplateKey().isBlank()) {
            return request.getRequestTemplateKey();
        }
        if (Boolean.TRUE.equals(request.getUseDetectedTemplateForRouting())) {
            return parseResult.getTemplateKey();
        }
        return null;
    }

    private String resolveProcessKey(StartFromCommandRequest request, ParseResult parseResult) {
        if (request.getProcessKey() != null && !request.getProcessKey().isBlank()) {
            return request.getProcessKey();
        }
        if (parseResult.getProcessKey() != null && !parseResult.getProcessKey().isBlank()) {
            return parseResult.getProcessKey();
        }
        return "approvalWorkflow";
    }

    private String resolveTitle(StartFromCommandRequest request, ParseResult parseResult) {
        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            return request.getTitle();
        }
        if (parseResult.getTemplateName() != null && !parseResult.getTemplateName().isBlank()) {
            return parseResult.getTemplateName() + "（AI发起）";
        }
        return "智能发起申请";
    }

    private RequestTemplateService.TemplateView resolveTemplate(ParseRequest request, String command) {
        List<RequestTemplateService.TemplateView> templates = requestTemplateService.listActiveTemplates();
        if (templates.isEmpty()) {
            return null;
        }
        if (request.getRequestTemplateKey() != null && !request.getRequestTemplateKey().isBlank()) {
            return templates.stream()
                    .filter(item -> request.getRequestTemplateKey().equals(item.getTemplateKey()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("request template not found: " + request.getRequestTemplateKey()));
        }
        if (request.getFormKey() != null && !request.getFormKey().isBlank()) {
            return templates.stream()
                    .filter(item -> request.getFormKey().equals(item.getFormKey()))
                    .findFirst()
                    .orElse(null);
        }

        String normalized = command.toLowerCase(Locale.ROOT);
        for (RequestTemplateService.TemplateView template : templates) {
            if ((template.getTemplateName() != null && normalized.contains(template.getTemplateName().toLowerCase(Locale.ROOT)))
                    || (template.getTemplateKey() != null && normalized.contains(template.getTemplateKey().toLowerCase(Locale.ROOT)))) {
                return template;
            }
        }
        return templates.get(0);
    }

    private Map<String, Object> extractFieldValues(String command, List<FormField> fields) {
        Map<String, Object> values = new LinkedHashMap<>();
        List<String> dateTokens = findDateTokens(command);
        for (FormField field : fields) {
            if (field.getFieldKey() == null || field.getFieldKey().isBlank()) {
                continue;
            }
            Object parsed = parseFieldValue(command, field, dateTokens);
            if (parsed != null) {
                values.put(field.getFieldKey(), parsed);
            }
        }
        return values;
    }

    private Object parseFieldValue(String command, FormField field, List<String> dateTokens) {
        String type = field.getFieldType() == null ? "string" : field.getFieldType().trim().toLowerCase(Locale.ROOT);
        String explicit = extractByAliases(command, aliases(field));

        return switch (type) {
            case "number" -> parseNumberValue(field, command, explicit);
            case "date", "datetime" -> parseTemporalValue(field, command, explicit, dateTokens, "datetime".equals(type));
            case "select" -> parseSelectValue(field, command, explicit);
            case "table" -> parseTableValue(explicit);
            default -> normalizeString(explicit);
        };
    }

    private Object parseNumberValue(FormField field, String command, String explicit) {
        Double explicitNumber = parseFirstNumber(explicit);
        if (explicitNumber != null) {
            return explicitNumber;
        }
        String indicator = (field.getFieldKey() + " " + safe(field.getLabel())).toLowerCase(Locale.ROOT);
        if (indicator.contains("days") || indicator.contains("天")) {
            Matcher matcher = Pattern.compile("(\\d+(?:\\.\\d+)?)\\s*天").matcher(command);
            if (matcher.find()) {
                return parseFirstNumber(matcher.group(1));
            }
        }
        if (indicator.contains("amount") || indicator.contains("budget") || indicator.contains("金额") || indicator.contains("费用")) {
            Matcher matcher = Pattern.compile("(?:金额|预算|费用|报销|总计|amount|budget)\\D{0,3}(\\d+(?:\\.\\d+)?)", Pattern.CASE_INSENSITIVE)
                    .matcher(command);
            if (matcher.find()) {
                return parseFirstNumber(matcher.group(1));
            }
        }
        return parseFirstNumber(command);
    }

    private Object parseTemporalValue(FormField field,
                                      String command,
                                      String explicit,
                                      List<String> dateTokens,
                                      boolean withTime) {
        String candidate = normalizeDateToken(explicit, withTime);
        if (candidate != null) {
            return candidate;
        }
        String indicator = (field.getFieldKey() + " " + safe(field.getLabel())).toLowerCase(Locale.ROOT);
        if (dateTokens.isEmpty()) {
            return null;
        }
        if (indicator.contains("start") || indicator.contains("开始")) {
            return normalizeDateToken(dateTokens.get(0), withTime);
        }
        if (indicator.contains("end") || indicator.contains("结束")) {
            return normalizeDateToken(dateTokens.get(dateTokens.size() - 1), withTime);
        }
        return normalizeDateToken(dateTokens.get(0), withTime);
    }

    private Object parseSelectValue(FormField field, String command, String explicit) {
        List<OptionItem> options = parseOptions(field.getOptionsJson());
        if (!options.isEmpty()) {
            String source = (command + " " + safe(explicit)).toLowerCase(Locale.ROOT);
            for (OptionItem option : options) {
                if ((option.label() != null && source.contains(option.label().toLowerCase(Locale.ROOT)))
                        || (option.value() != null && source.contains(String.valueOf(option.value()).toLowerCase(Locale.ROOT)))) {
                    return option.value() == null ? option.label() : option.value();
                }
            }
        }
        return normalizeString(explicit);
    }

    private Object parseTableValue(String explicit) {
        if (explicit == null || explicit.isBlank()) {
            return null;
        }
        return explicit;
    }

    private String extractByAliases(String command, List<String> aliases) {
        for (String alias : aliases) {
            if (alias == null || alias.isBlank()) {
                continue;
            }
            Pattern pattern = Pattern.compile(Pattern.quote(alias) + "\\s*(?:为|是|:|：)?\\s*([^，,。；;\\n]+)", Pattern.CASE_INSENSITIVE);
            Matcher matcher = pattern.matcher(command);
            if (matcher.find()) {
                return matcher.group(1).trim();
            }
        }
        return null;
    }

    private List<String> aliases(FormField field) {
        List<String> aliases = new ArrayList<>();
        if (field.getLabel() != null && !field.getLabel().isBlank()) {
            aliases.add(field.getLabel().trim());
        }
        if (field.getFieldKey() != null && !field.getFieldKey().isBlank()) {
            aliases.add(field.getFieldKey().trim());
            aliases.add(field.getFieldKey().replace("_", " ").trim());
        }
        return aliases;
    }

    private Double parseFirstNumber(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        Matcher matcher = Pattern.compile("-?\\d+(?:\\.\\d+)?").matcher(text);
        if (!matcher.find()) {
            return null;
        }
        try {
            return Double.parseDouble(matcher.group());
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private List<String> findDateTokens(String command) {
        List<String> tokens = new ArrayList<>();
        Matcher matcher = Pattern.compile("\\d{4}[-/]\\d{1,2}[-/]\\d{1,2}(?:\\s+\\d{1,2}:\\d{2}(?::\\d{2})?)?").matcher(command);
        while (matcher.find()) {
            tokens.add(matcher.group());
        }
        return tokens;
    }

    private String normalizeDateToken(String token, boolean withTime) {
        if (token == null || token.isBlank()) {
            return null;
        }
        Matcher matcher = Pattern.compile("(\\d{4})[-/](\\d{1,2})[-/](\\d{1,2})(?:\\s+(\\d{1,2}):(\\d{2})(?::(\\d{2}))?)?").matcher(token.trim());
        if (!matcher.find()) {
            return null;
        }
        int month = Integer.parseInt(matcher.group(2));
        int day = Integer.parseInt(matcher.group(3));
        String normalizedDate = "%s-%02d-%02d".formatted(matcher.group(1), month, day);
        if (!withTime) {
            return normalizedDate;
        }
        String hour = matcher.group(4);
        String minute = matcher.group(5);
        String second = matcher.group(6);
        if (hour == null || minute == null) {
            return normalizedDate + " 00:00:00";
        }
        String normalizedSecond = second == null ? "00" : "%02d".formatted(Integer.parseInt(second));
        return normalizedDate + " %02d:%02d:%s".formatted(Integer.parseInt(hour), Integer.parseInt(minute), normalizedSecond);
    }

    private String normalizeString(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private String safe(String text) {
        return text == null ? "" : text;
    }

    private List<OptionItem> parseOptions(String optionsJson) {
        if (optionsJson == null || optionsJson.isBlank()) {
            return List.of();
        }
        try {
            var node = new com.fasterxml.jackson.databind.ObjectMapper().readTree(optionsJson);
            if (!node.isArray()) {
                return List.of();
            }
            List<OptionItem> options = new ArrayList<>();
            for (var item : node) {
                if (item.isObject()) {
                    String label = item.path("label").asText(null);
                    Object value = item.path("value").isMissingNode() || item.path("value").isNull()
                            ? label
                            : (item.path("value").isNumber() ? item.path("value").numberValue() : item.path("value").asText());
                    options.add(new OptionItem(label, value));
                } else if (item.isTextual()) {
                    options.add(new OptionItem(item.asText(), item.asText()));
                } else if (item.isNumber()) {
                    options.add(new OptionItem(item.asText(), item.numberValue()));
                }
            }
            return options;
        } catch (Exception ignored) {
            return List.of();
        }
    }

    private record OptionItem(String label, Object value) {
    }

    @Data
    public static class ParseRequest {
        private String command;
        private String requestTemplateKey;
        private String formKey;
        private Long formVersionId;
    }

    @Data
    public static class ParseResult {
        private String model;
        private String templateKey;
        private String templateName;
        private String formKey;
        private Long formVersionId;
        private String processKey;
        private Map<String, Object> formData;
        private Map<String, Object> variables;
        private List<String> missingRequiredFields;
        private Double confidence;
        private LocalDateTime parsedAt;
    }

    @Data
    public static class StartFromCommandRequest {
        private String command;
        private Long applicantId;
        private String businessKey;
        private String title;
        private String processKey;
        private String requestTemplateKey;
        private String formKey;
        private Long formVersionId;
        private Boolean requireAllRequiredFields;
        private Boolean useDetectedTemplateForRouting;
    }

    @Data
    public static class StartFromCommandResult {
        private String processInstanceId;
        private String businessKey;
        private String title;
        private Long applicantId;
        private Long formVersionId;
        private String templateKey;
        private List<String> missingRequiredFields;
        private Double confidence;
        private LocalDateTime startedAt;
    }
}
