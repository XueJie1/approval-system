package com.flowablecollab.approval_system.service.ai;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Component
@ConditionalOnProperty(name = "ai.llm.provider", havingValue = "mock", matchIfMissing = true)
public class MockLlmClient implements LlmClient {

    @Value("${ai.llm.mock-model:mock-approval-advisor-v2}")
    private String mockModel;

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
    public FormCommandResult parseFormCommand(FormCommandParseRequest request) {
        throw new UnsupportedOperationException("MockLlmClient does not support form command parsing");
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
}
