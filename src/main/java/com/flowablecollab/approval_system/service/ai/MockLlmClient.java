package com.flowablecollab.approval_system.service.ai;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class MockLlmClient implements LlmClient {

    @Value("${ai.llm.mock-model:mock-approval-advisor-v2}")
    private String mockModel;

    private static final String HEURISTIC_MODEL = "heuristic-form-parser-v2";
    private static final Pattern FIRST_NUMBER_PATTERN = Pattern.compile("-?\\d+(?:\\.\\d+)?");
    private static final Pattern NUMBER_WITH_DAY_UNIT_PATTERN = Pattern.compile(
            "(-?\\d+(?:\\.\\d+)?)\\s*(?:天|day|days)", Pattern.CASE_INSENSITIVE);
    private static final Pattern CHINESE_DAY_PATTERN = Pattern.compile("([零〇一二两三四五六七八九十百半]+)\\s*天");
    private static final Pattern AMOUNT_BY_KEYWORD_PATTERN = Pattern.compile(
            "(?:金额|预算|费用|报销|总计|price|cost|amount|budget)\\D{0,8}([+-]?\\d+(?:,\\d{3})*(?:\\.\\d+)?)",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern CURRENCY_PREFIX_PATTERN = Pattern.compile("[¥￥$]\\s*([+-]?\\d+(?:,\\d{3})*(?:\\.\\d+)?)");
    private static final Pattern CURRENCY_SUFFIX_PATTERN = Pattern.compile(
            "([+-]?\\d+(?:,\\d{3})*(?:\\.\\d+)?)\\s*(?:元|块|人民币|rmb|cny)", Pattern.CASE_INSENSITIVE);
    private static final Pattern DATE_TOKEN_PATTERN = Pattern.compile(
            "\\d{4}[-/]\\d{1,2}[-/]\\d{1,2}(?:[ T]\\d{1,2}:\\d{2}(?::\\d{2})?)?"
                    + "|\\d{4}年\\d{1,2}月\\d{1,2}日?(?:\\s*\\d{1,2}(?:[:：时点]\\d{1,2})?(?:[:：]\\d{1,2})?)?"
    );
    private static final Pattern ISO_DATE_TIME_PATTERN = Pattern.compile(
            "(\\d{4})[-/](\\d{1,2})[-/](\\d{1,2})(?:[ T](\\d{1,2}):(\\d{2})(?::(\\d{2}))?)?");
    private static final Pattern CHINESE_DATE_TIME_PATTERN = Pattern.compile(
            "(\\d{4})年(\\d{1,2})月(\\d{1,2})日?(?:\\s*(\\d{1,2})(?:[:：时点](\\d{1,2}))?(?:[:：](\\d{1,2}))?)?");
    private static final Pattern CHINESE_DATE_PATTERN = Pattern.compile("\\d{4}年\\d{1,2}月\\d{1,2}日?");
    private static final Pattern CHINESE_YEAR_MONTH_PATTERN = Pattern.compile("\\d{4}年\\d{1,2}月");

    @Override
    public Suggestion suggestApproval(SuggestionRequest request) {
        Map<String, Object> variables = request.getVariables() == null ? Map.of() : request.getVariables();
        List<String> riskWarnings = new ArrayList<>(defaultList(request.getHeuristicRiskWarnings()));
        List<String> anomalies = new ArrayList<>(defaultList(request.getHeuristicAnomalies()));
        List<String> supplementaryInfo = new ArrayList<>();
        Map<String, Object> suggestedFormUpdates = new LinkedHashMap<>();

        Double amount = extractNumber(variables, "amount", "totalAmount", "cost", "fee", "reimbursementAmount");
        String description = extractString(variables, "description", "reason", "content", "remark", "comment");
        Boolean urgent = extractBoolean(variables, "urgent", "isUrgent", "emergency");

        if (amount != null && amount < 0) {
            anomalies.add("申请金额为负数，表单数据明显异常。");
        }
        if ((description == null || description.isBlank()) && !containsText(anomalies, "说明")) {
            anomalies.add("缺少申请说明，难以判断业务必要性。");
            suggestedFormUpdates.put("description", "请补充业务背景、用途与费用构成");
        }

        ApplicantStats applicantStats = request.getApplicantStats();
        if (applicantStats != null) {
            supplementaryInfo.add("申请人本月累计申请 " + safeInt(applicantStats.getMonthlyRequestCount()) + " 笔，累计金额 ¥"
                    + formatMoney(applicantStats.getMonthlyTotalAmount()) + "，平均金额 ¥" + formatMoney(applicantStats.getAverageAmount()) + "。");
            if (applicantStats.getMonthlySameTypeCount() != null && applicantStats.getMonthlySameTypeCount() >= 3
                    && !containsText(riskWarnings, "频率")) {
                riskWarnings.add("频率异常：申请人本月同类型申请已达 " + applicantStats.getMonthlySameTypeCount() + " 笔。");
            }
            if (amount != null && applicantStats.getAverageAmount() != null
                    && applicantStats.getAverageAmount() > 0
                    && amount >= applicantStats.getAverageAmount() * 2
                    && !containsText(riskWarnings, "金额")) {
                riskWarnings.add("金额异常：本次金额 ¥" + formatMoney(amount) + " 明显高于申请人历史均值 ¥"
                        + formatMoney(applicantStats.getAverageAmount()) + "。");
            }
        }

        SimilarCaseStats similarCaseStats = request.getSimilarCaseStats();
        if (similarCaseStats != null) {
            supplementaryInfo.add("同类申请样本 " + safeInt(similarCaseStats.getSampleCount()) + " 笔，平均处理时间 "
                    + safeText(similarCaseStats.getAverageProcessingTime(), "暂无历史数据") + "。");
            supplementaryInfo.add("同类申请通过 " + safeInt(similarCaseStats.getApprovedCount()) + " 笔，拒绝 "
                    + safeInt(similarCaseStats.getRejectedCount()) + " 笔。");
        }

        for (String policyReference : defaultList(request.getPolicyReferences())) {
            supplementaryInfo.add(policyReference);
        }

        if (Boolean.TRUE.equals(urgent) && !containsText(riskWarnings, "紧急")) {
            riskWarnings.add("时间异常：申请标记为紧急，请核实紧急原因与业务影响。");
        }

        if (amount != null && amount >= 10000 && !containsText(riskWarnings, "预算")) {
            riskWarnings.add("金额异常：大额申请需要重点核对预算余额、发票与合同依据。");
            suggestedFormUpdates.put("budgetCheckRequired", true);
        }

        String decision = decide(amount, anomalies, riskWarnings);
        String recommendation = buildRecommendation(decision, amount, description, riskWarnings, anomalies);
        String approvalComment = ("APPROVE".equals(decision) ? "建议通过：" : "建议拒绝：") + recommendation;

        Suggestion suggestion = new Suggestion();
        suggestion.setDecision(decision);
        suggestion.setRecommendation(recommendation);
        suggestion.setSummary(recommendation);
        suggestion.setRiskWarnings(riskWarnings);
        suggestion.setAnomalies(anomalies);
        suggestion.setSupplementaryInfo(supplementaryInfo);
        suggestion.setApprovalComment(approvalComment);
        suggestion.setSuggestedFormUpdates(suggestedFormUpdates);
        suggestion.setModel(mockModel);
        return suggestion;
    }

    @Override
    public ChatResult chat(ChatRequest request) {
        if (request.getMessage() == null || request.getMessage().isBlank()) {
            ChatResult result = new ChatResult();
            result.setReply("请问有什么可以帮助您的？");
            result.setModel(mockModel);
            return result;
        }
        String message = request.getMessage().toLowerCase(Locale.ROOT).trim();
        String reply;
        if (message.contains("审批") || message.contains("approval")) {
            reply = "审批流程分为单人审批、会签和或签三种模式。单人审批只需一人同意，会签需要所有人同意，或签只需一人同意即可。您可以在发起申请时选择审批模式。";
        } else if (message.contains("表单") || message.contains("form") || message.contains("字段")) {
            reply = "表单由管理员在后台配置，支持文本、数字、日期、下拉选择和附件等字段类型。发起申请时填写表单数据，审批人可查看表单内容。";
        } else if (message.contains("委派") || message.contains("delegate")) {
            reply = "任务委派是将任务临时交给他人处理，处理完成后会返回给原委派人确认。在待办任务详情中点击「委派给他人」即可操作。";
        } else if (message.contains("回退") || message.contains("退回") || message.contains("return")) {
            reply = "回退操作可以将任务退回到上一个环节、退回到发起人，或者指定退回到某个节点。回退后需要重新处理该环节。";
        } else if (message.contains("你好") || message.contains("hello") || message.contains("hi")) {
            reply = "您好！我是智能审批系统的 AI 助手，可以帮您解答关于审批流程、表单填写、任务处理等方面的问题。请问有什么需要帮助的？";
        } else {
            reply = "好的，我理解您的问题。作为审批系统助手，我可以帮您了解审批流程、解释表单字段、说明任务操作方法等。请您更具体地描述遇到的问题，我会尽力解答。";
        }
        ChatResult result = new ChatResult();
        result.setReply(reply);
        result.setModel(mockModel);
        return result;
    }

    @Override
    public ChatWithToolsResult chatWithTools(ChatWithToolsRequest request) {
        String lastUser = "";
        if (request.getMessages() != null) {
            for (int i = request.getMessages().size() - 1; i >= 0; i--) {
                ChatMessage m = request.getMessages().get(i);
                if ("user".equals(m.getRole()) && m.getContent() != null) {
                    lastUser = m.getContent();
                    break;
                }
            }
        }
        ChatRequest legacy = new ChatRequest();
        legacy.setMessage(lastUser);
        ChatResult basic = chat(legacy);
        ChatWithToolsResult result = new ChatWithToolsResult();
        result.setContent(basic.getReply() + "\n\n（提示：当前 AI 处于 mock 模式，无法自动调用工具。请配置 OpenAI/DeepSeek API key 后获得完整能力。）");
        result.setModel(basic.getModel());
        return result;
    }

    @Override
    public FormCommandResult parseFormCommand(FormCommandParseRequest request) {
        if (request.getCommand() == null || request.getCommand().isBlank()) {
            throw new IllegalArgumentException("command is required");
        }
        if (request.getFields() == null || request.getFields().isEmpty()) {
            throw new IllegalArgumentException("fields are required for parsing");
        }

        String command = request.getCommand().trim();
        List<FieldDefinition> fields = request.getFields();

        List<String> dateTokens = findDateTokens(command);
        Map<String, Object> formData = new LinkedHashMap<>();

        for (FieldDefinition field : fields) {
            if (field.getFieldKey() == null || field.getFieldKey().isBlank()) {
                continue;
            }
            Object parsed = parseFieldValue(command, field, dateTokens);
            if (parsed != null) {
                formData.put(field.getFieldKey(), parsed);
            }
        }

        int filledCount = formData.size();
        double confidence = (double) filledCount / Math.max(1, fields.size());

        FormCommandResult result = new FormCommandResult();
        result.setFormData(formData);
        result.setConfidence(Math.min(confidence, 1.0));
        result.setReasoning("Heuristic parser extracted " + filledCount + " of " + fields.size()
                + " fields from natural language command.");
        result.setModel(HEURISTIC_MODEL);
        return result;
    }

    @Override
    public FollowUpAnswer answerFollowUp(FollowUpRequest request) {
        String question = safeText(request.getQuestion(), "").toLowerCase(Locale.ROOT);
        Suggestion currentSuggestion = request.getCurrentSuggestion();

        String answer;
        if (question.contains("风险")) {
            answer = explainList("风险主要来自：", currentSuggestion == null ? List.of() : currentSuggestion.getRiskWarnings(), "当前没有明显风险预警。");
        } else if (question.contains("异常")) {
            answer = explainList("识别到的异常点包括：", currentSuggestion == null ? List.of() : currentSuggestion.getAnomalies(), "当前未识别到明确异常。");
        } else if (question.contains("规定") || question.contains("制度") || question.contains("政策")) {
            answer = explainList("本次建议参考了以下补充依据：", currentSuggestion == null ? List.of() : currentSuggestion.getSupplementaryInfo(), "当前仅能基于通用审批常识判断，建议人工核对内部制度。");
        } else if (question.contains("为什么") || question.contains("理由")) {
            answer = currentSuggestion == null || currentSuggestion.getRecommendation() == null || currentSuggestion.getRecommendation().isBlank()
                    ? "当前没有足够上下文给出更具体理由。"
                    : currentSuggestion.getRecommendation();
        } else {
            answer = "建议结合当前审批意见、风险预警和异常检测继续人工复核。如需精确判断，请补充更具体的问题。";
        }

        FollowUpAnswer followUpAnswer = new FollowUpAnswer();
        followUpAnswer.setAnswer(answer);
        followUpAnswer.setModel(mockModel);
        return followUpAnswer;
    }

    private String decide(Double amount, List<String> anomalies, List<String> riskWarnings) {
        if (!anomalies.isEmpty()) {
            return "REJECT";
        }
        if (amount != null && amount < 0) {
            return "REJECT";
        }
        if (riskWarnings.size() >= 3) {
            return "REJECT";
        }
        return "APPROVE";
    }

    private String buildRecommendation(String decision, Double amount, String description, List<String> riskWarnings, List<String> anomalies) {
        if ("REJECT".equals(decision)) {
            if (!anomalies.isEmpty()) {
                return anomalies.get(0);
            }
            if (!riskWarnings.isEmpty()) {
                return riskWarnings.get(0);
            }
            return "当前申请存在无法忽略的异常或风险，建议驳回后补充材料。";
        }
        if (amount != null) {
            return "该申请金额 ¥" + formatMoney(amount) + "，当前未发现足以阻断审批的异常，建议通过。";
        }
        if (description != null && !description.isBlank()) {
            return "申请说明较完整，当前未发现明显异常，建议通过。";
        }
        if (!riskWarnings.isEmpty()) {
            return "当前风险可控，但建议在通过前做必要复核。";
        }
        return "申请信息基本完整，符合常规审批预期，建议通过。";
    }

    private List<String> defaultList(List<String> values) {
        return values == null ? List.of() : values;
    }

    private boolean containsText(List<String> values, String needle) {
        return values.stream().anyMatch(item -> item != null && item.contains(needle));
    }

    private String explainList(String prefix, List<String> values, String fallback) {
        if (values == null || values.isEmpty()) {
            return fallback;
        }
        return prefix + String.join("；", values);
    }

    private String extractString(Map<String, Object> variables, String... keys) {
        for (String key : keys) {
            Object value = variables.get(key);
            if (value instanceof String str && !str.isBlank()) {
                return str.trim();
            }
        }
        return null;
    }

    private Double extractNumber(Map<String, Object> variables, String... keys) {
        for (String key : keys) {
            Object value = variables.get(key);
            if (value instanceof Number number) {
                return number.doubleValue();
            }
            if (value instanceof String str && !str.isBlank()) {
                try {
                    return Double.parseDouble(str.trim());
                } catch (NumberFormatException ignored) {
                    // ignore non-numeric values and continue
                }
            }
        }
        return null;
    }

    private Boolean extractBoolean(Map<String, Object> variables, String... keys) {
        for (String key : keys) {
            Object value = variables.get(key);
            if (value instanceof Boolean b) {
                return b;
            }
            if (value instanceof String str && !str.isBlank()) {
                if ("true".equalsIgnoreCase(str)) {
                    return true;
                }
                if ("false".equalsIgnoreCase(str)) {
                    return false;
                }
            }
        }
        return null;
    }

    private int safeInt(Integer value) {
        return value == null ? 0 : value;
    }

    private String safeText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private String formatMoney(Double value) {
        return value == null ? "0.00" : String.format(Locale.ROOT, "%.2f", value);
    }

    // ── heuristic form-command parsing ──

    private Object parseFieldValue(String command, FieldDefinition field, List<String> dateTokens) {
        String type = field.getFieldType() == null ? "string" : field.getFieldType().trim().toLowerCase(Locale.ROOT);
        String explicit = extractByAliases(command, aliases(field));

        return switch (type) {
            case "number" -> parseNumberValue(field, command, explicit, dateTokens);
            case "date", "datetime" -> parseTemporalValue(field, command, explicit, dateTokens, "datetime".equals(type));
            case "select" -> parseSelectValue(field, command, explicit);
            case "table" -> normalizeString(explicit);
            case "file" -> null; // file fields not extractable from text
            default -> normalizeString(explicit);
        };
    }

    private Object parseNumberValue(FieldDefinition field, String command, String explicit, List<String> dateTokens) {
        Double explicitNumber = parseFirstNumber(explicit);
        if (explicitNumber != null) {
            return explicitNumber;
        }
        String indicator = (field.getFieldKey() + " " + safeStr(field.getLabel())).toLowerCase(Locale.ROOT);
        if (isDurationField(indicator)) {
            return parseDurationNumber(command, dateTokens);
        }
        if (isAmountField(indicator)) {
            return parseAmountNumber(command);
        }
        return parseFirstNumber(stripDateTokens(command, dateTokens));
    }

    private Object parseTemporalValue(FieldDefinition field, String command, String explicit,
                                       List<String> dateTokens, boolean withTime) {
        String candidate = normalizeDateToken(explicit, withTime);
        if (candidate != null) {
            return candidate;
        }
        String indicator = (field.getFieldKey() + " " + safeStr(field.getLabel())).toLowerCase(Locale.ROOT);
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

    private Object parseSelectValue(FieldDefinition field, String command, String explicit) {
        List<String> options = field.getOptions();
        if (options != null && !options.isEmpty()) {
            String source = (command + " " + safeStr(explicit)).toLowerCase(Locale.ROOT);
            for (String option : options) {
                if (option != null && source.contains(option.toLowerCase(Locale.ROOT))) {
                    return option;
                }
            }
        }
        return normalizeString(explicit);
    }

    private String extractByAliases(String command, List<String> aliases) {
        for (String alias : aliases) {
            if (alias == null || alias.isBlank()) {
                continue;
            }
            Pattern pattern = Pattern.compile(
                    Pattern.quote(alias) + "\\s*(?:为|是|:|：)?\\s*([^，,。；;\\n]+)",
                    Pattern.CASE_INSENSITIVE);
            Matcher matcher = pattern.matcher(command);
            if (matcher.find()) {
                return matcher.group(1).trim();
            }
        }
        return null;
    }

    private List<String> aliases(FieldDefinition field) {
        List<String> list = new ArrayList<>();
        if (field.getLabel() != null && !field.getLabel().isBlank()) {
            list.add(field.getLabel().trim());
        }
        if (field.getFieldKey() != null && !field.getFieldKey().isBlank()) {
            list.add(field.getFieldKey().trim());
            list.add(field.getFieldKey().replace("_", " ").trim());
        }
        return list;
    }

    // ── number helpers ──

    private Double parseFirstNumber(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        Matcher matcher = FIRST_NUMBER_PATTERN.matcher(text);
        if (!matcher.find()) {
            return null;
        }
        try {
            return Double.parseDouble(matcher.group());
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private boolean isDurationField(String indicator) {
        return indicator.contains("days") || indicator.contains("day")
                || indicator.contains("duration") || indicator.contains("天") || indicator.contains("时长");
    }

    private boolean isAmountField(String indicator) {
        return indicator.contains("amount") || indicator.contains("budget")
                || indicator.contains("price") || indicator.contains("cost")
                || indicator.contains("金额") || indicator.contains("费用")
                || indicator.contains("预算") || indicator.contains("报销");
    }

    private Double parseDurationNumber(String command, List<String> dateTokens) {
        Matcher numericDays = NUMBER_WITH_DAY_UNIT_PATTERN.matcher(command);
        if (numericDays.find()) {
            return parseFirstNumber(numericDays.group(1));
        }
        Matcher chineseDays = CHINESE_DAY_PATTERN.matcher(command);
        if (chineseDays.find()) {
            Double chineseNumber = parseChineseNumber(chineseDays.group(1));
            if (chineseNumber != null) {
                return chineseNumber;
            }
        }
        return parseDurationFromDateRange(dateTokens);
    }

    private Double parseAmountNumber(String command) {
        Double keywordAmount = extractCapturedNumber(command, AMOUNT_BY_KEYWORD_PATTERN);
        if (keywordAmount != null) return keywordAmount;
        Double prefixedAmount = extractCapturedNumber(command, CURRENCY_PREFIX_PATTERN);
        if (prefixedAmount != null) return prefixedAmount;
        return extractCapturedNumber(command, CURRENCY_SUFFIX_PATTERN);
    }

    private Double extractCapturedNumber(String text, Pattern pattern) {
        Matcher matcher = pattern.matcher(text);
        if (!matcher.find()) {
            return null;
        }
        return parseFirstNumber(matcher.group(1).replace(",", ""));
    }

    // ── date helpers ──

    private List<String> findDateTokens(String command) {
        List<String> tokens = new ArrayList<>();
        Matcher matcher = DATE_TOKEN_PATTERN.matcher(command);
        while (matcher.find()) {
            tokens.add(matcher.group());
        }
        return tokens;
    }

    private Double parseDurationFromDateRange(List<String> dateTokens) {
        if (dateTokens == null || dateTokens.size() < 2) {
            return null;
        }
        LocalDate start = parseDateOnly(dateTokens.get(0));
        LocalDate end = parseDateOnly(dateTokens.get(dateTokens.size() - 1));
        if (start == null || end == null || end.isBefore(start)) {
            return null;
        }
        return (double) (end.toEpochDay() - start.toEpochDay() + 1);
    }

    private LocalDate parseDateOnly(String token) {
        String normalized = normalizeDateToken(token, false);
        if (normalized == null) {
            return null;
        }
        try {
            return LocalDate.parse(normalized);
        } catch (Exception ignored) {
            return null;
        }
    }

    private String stripDateTokens(String text, List<String> dateTokens) {
        if (text == null || text.isBlank()) {
            return text;
        }
        String cleaned = text;
        if (dateTokens != null) {
            for (String token : dateTokens) {
                if (token != null && !token.isBlank()) {
                    cleaned = cleaned.replace(token, " ");
                }
            }
        }
        cleaned = CHINESE_DATE_PATTERN.matcher(cleaned).replaceAll(" ");
        cleaned = CHINESE_YEAR_MONTH_PATTERN.matcher(cleaned).replaceAll(" ");
        return cleaned;
    }

    private String normalizeDateToken(String token, boolean withTime) {
        if (token == null || token.isBlank()) {
            return null;
        }
        String normalized = tryNormalizeDateToken(token.trim(), withTime, ISO_DATE_TIME_PATTERN);
        if (normalized != null) return normalized;
        return tryNormalizeDateToken(token.trim(), withTime, CHINESE_DATE_TIME_PATTERN);
    }

    private String tryNormalizeDateToken(String token, boolean withTime, Pattern pattern) {
        Matcher matcher = pattern.matcher(token);
        if (!matcher.find()) {
            return null;
        }
        Integer year = parseIntegerGroup(matcher, 1);
        Integer month = parseIntegerGroup(matcher, 2);
        Integer day = parseIntegerGroup(matcher, 3);
        if (year == null || month == null || day == null) {
            return null;
        }
        LocalDate date;
        try {
            date = LocalDate.of(year, month, day);
        } catch (Exception ignored) {
            return null;
        }
        if (!withTime) {
            return date.toString();
        }
        Integer hour = parseIntegerGroup(matcher, 4);
        Integer minute = parseIntegerGroup(matcher, 5);
        Integer second = parseIntegerGroup(matcher, 6);
        if (hour == null) {
            return date + " 00:00:00";
        }
        if (minute == null) minute = 0;
        if (second == null) second = 0;
        try {
            LocalTime time = LocalTime.of(hour, minute, second);
            return date + " %02d:%02d:%02d".formatted(time.getHour(), time.getMinute(), time.getSecond());
        } catch (Exception ignored) {
            return null;
        }
    }

    private Integer parseIntegerGroup(Matcher matcher, int group) {
        if (matcher.groupCount() < group) return null;
        String raw = matcher.group(group);
        if (raw == null || raw.isBlank()) return null;
        try {
            return Integer.parseInt(raw);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    // ── Chinese number helpers ──

    private Double parseChineseNumber(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        String normalized = token.trim();
        if ("半".equals(normalized)) {
            return 0.5d;
        }
        if (normalized.contains("百")) {
            String[] parts = normalized.split("百", 2);
            Integer hundred = parseChineseDigit(parts[0].isBlank() ? "一" : parts[0]);
            Integer tail = parts.length < 2 || parts[1].isBlank() ? 0 : parseChineseInteger(parts[1]);
            if (hundred == null || tail == null) return null;
            return (double) (hundred * 100 + tail);
        }
        Integer integer = parseChineseInteger(normalized);
        return integer == null ? null : integer.doubleValue();
    }

    private Integer parseChineseInteger(String token) {
        if (token == null || token.isBlank()) return null;
        if (token.contains("十")) {
            String[] parts = token.split("十", 2);
            int tens;
            if (parts.length > 0 && !parts[0].isBlank()) {
                Integer parsed = parseChineseDigit(parts[0]);
                if (parsed == null) return null;
                tens = parsed;
            } else {
                tens = 1;
            }
            int units = 0;
            if (parts.length == 2 && !parts[1].isBlank()) {
                Integer parsed = parseChineseDigit(parts[1]);
                if (parsed == null) return null;
                units = parsed;
            }
            return tens * 10 + units;
        }
        return parseChineseDigit(token);
    }

    private Integer parseChineseDigit(String token) {
        return switch (token) {
            case "零", "〇" -> 0;
            case "一" -> 1;
            case "二", "两" -> 2;
            case "三" -> 3;
            case "四" -> 4;
            case "五" -> 5;
            case "六" -> 6;
            case "七" -> 7;
            case "八" -> 8;
            case "九" -> 9;
            default -> null;
        };
    }

    private String normalizeString(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }

    private String safeStr(String text) {
        return text == null ? "" : text;
    }
}
