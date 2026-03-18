package com.flowablecollab.approval_system.service.ai;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Component
@ConditionalOnProperty(name = "ai.llm.provider", havingValue = "mock", matchIfMissing = true)
public class MockLlmClient implements LlmClient {

    @Value("${ai.llm.mock-model:mock-approval-advisor-v1}")
    private String mockModel;

    @Override
    public Suggestion suggestApproval(SuggestionRequest request) {
        Map<String, Object> variables = request.getVariables() == null ? Map.of() : request.getVariables();
        List<String> riskFlags = new ArrayList<>();
        List<String> followUpChecks = new ArrayList<>();

        Double amount = extractNumber(variables, "amount", "totalAmount", "cost");
        if (amount != null && amount < 0) {
            riskFlags.add("检测到负数金额，建议先校验表单数据合法性。");
        } else if (amount != null && amount >= 10000) {
            riskFlags.add("申请金额较高，建议核对预算归属、发票与付款依据。");
            followUpChecks.add("确认预算科目是否有可用余额。");
            followUpChecks.add("核验金额与附件中的合同/报价是否一致。");
        }

        Boolean urgent = extractBoolean(variables, "urgent", "isUrgent");
        if (Boolean.TRUE.equals(urgent)) {
            riskFlags.add("该申请标记为紧急，建议复核紧急性说明和业务影响。");
            followUpChecks.add("补充紧急处理窗口和责任人。");
        }

        if (!variables.containsKey("approverId")) {
            followUpChecks.add("建议明确 approverId，避免任务路由到默认审批人。");
        }

        String decision;
        if (amount != null && amount < 0) {
            decision = "REJECT";
        } else if (riskFlags.isEmpty()) {
            decision = "APPROVE";
        } else {
            decision = "REVIEW";
        }

        Suggestion suggestion = new Suggestion();
        suggestion.setDecision(decision);
        suggestion.setSummary(buildSummary(request, decision, amount));
        suggestion.setRiskFlags(riskFlags);
        suggestion.setFollowUpChecks(followUpChecks);
        suggestion.setModel(mockModel);
        return suggestion;
    }

    private String buildSummary(SuggestionRequest request, String decision, Double amount) {
        String taskName = request.getTaskName() == null ? "审批任务" : request.getTaskName();
        String title = request.getTitle() == null ? "未命名申请" : request.getTitle();
        if (amount == null) {
            return "任务「" + taskName + "」针对申请「" + title + "」建议：" + decision + "。";
        }
        return "任务「" + taskName + "」针对申请「" + title + "」(金额 " + amount + ") 建议：" + decision + "。";
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
}
