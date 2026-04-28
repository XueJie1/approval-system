package com.flowablecollab.approval_system.service;

import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.repository.rbac.SysDeptRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.flowablecollab.approval_system.service.workflow.manage.RequestTemplateApprovalConfig;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
public class RequestApprovalResolverService {

    private final SysUserRepository sysUserRepository;
    private final SysDeptRepository sysDeptRepository;

    public RequestApprovalResolverService(SysUserRepository sysUserRepository,
                                         SysDeptRepository sysDeptRepository) {
        this.sysUserRepository = sysUserRepository;
        this.sysDeptRepository = sysDeptRepository;
    }

    public Resolution resolveLeaveApprovers(Long applicantId, Double leaveDays) {
        RequestTemplateApprovalConfig config = new RequestTemplateApprovalConfig();
        config.setRules(List.of(
                createRule("LEAVE_BASE", null, List.of(createStep("MANAGER", null))),
                createRule("LEAVE_DEPT", List.of(createCondition("days", "GT", 1D)), List.of(createStep("DEPT_LEADER", null))),
                createRule("LEAVE_PARENT", List.of(createCondition("days", "GT", 3D)), List.of(createStep("PARENT_DEPT_LEADER", null)))
        ));
        return resolveByTemplateConfig(applicantId, leaveDays == null ? Map.of() : Map.of("days", leaveDays), config);
    }

    public Resolution resolveByTemplateConfig(Long applicantId,
                                              Map<String, Object> variables,
                                              RequestTemplateApprovalConfig config) {
        ResolutionDetail detail = resolveDetail(applicantId, variables, config);
        return new Resolution(detail.approverIds(), detail.strategy());
    }

    public PreviewResolution previewByTemplateConfig(Long applicantId,
                                                     Map<String, Object> variables,
                                                     RequestTemplateApprovalConfig config) {
        ResolutionDetail detail = resolveDetail(applicantId, variables, config);
        return new PreviewResolution(detail.approverIds(), detail.stepRuleNames());
    }

    private ResolutionDetail resolveDetail(Long applicantId,
                                           Map<String, Object> variables,
                                           RequestTemplateApprovalConfig config) {
        if (applicantId == null) {
            throw new IllegalArgumentException("applicantId is required");
        }
        if (config == null || config.getRules() == null || config.getRules().isEmpty()) {
            throw new IllegalArgumentException("approval config is required");
        }
        SysUser applicant = sysUserRepository.findById(applicantId)
                .orElseThrow(() -> new IllegalArgumentException("applicant not found: " + applicantId));
        SysDept dept = applicant.getDeptId() == null ? null : sysDeptRepository.findById(applicant.getDeptId()).orElse(null);
        SysDept parentDept = dept != null && dept.getParentId() != null
                ? sysDeptRepository.findById(dept.getParentId()).orElse(null)
                : null;

        ArrayList<String> approverIds = new ArrayList<>();
        ArrayList<String> stepRuleNames = new ArrayList<>();
        String strategy = null;
        for (RequestTemplateApprovalConfig.ApprovalRule rule : config.getRules()) {
            if (!matchesConditions(rule, variables) || rule.getSteps() == null || rule.getSteps().isEmpty()) {
                continue;
            }
            strategy = rule.getName();
            for (RequestTemplateApprovalConfig.ApprovalStep step : rule.getSteps()) {
                if (step == null || step.getType() == null || step.getType().isBlank()) {
                    continue;
                }
                Long resolvedUserId = switch (step.getType().trim().toUpperCase()) {
                    case "MANAGER" -> applicant.getManagerUserId();
                    case "DEPT_LEADER" -> dept == null ? null : dept.getLeaderUserId();
                    case "PARENT_DEPT_LEADER" -> parentDept == null ? null : parentDept.getLeaderUserId();
                    case "SPECIFIC_USER" -> step.getUserId();
                    default -> throw new IllegalArgumentException("unsupported approval step type: " + step.getType());
                };
                if (resolvedUserId != null && !Objects.equals(resolvedUserId, applicantId)) {
                    addApproverIfAbsent(approverIds, stepRuleNames, resolvedUserId, rule.getName());
                }
            }
        }

        if (!approverIds.isEmpty()) {
            return new ResolutionDetail(
                    List.copyOf(approverIds),
                    List.copyOf(stepRuleNames),
                    strategy == null || strategy.isBlank() ? "TEMPLATE_CONFIG" : strategy);
        }
        throw new IllegalArgumentException("approver is not configured for applicant");
    }

    private boolean matchesConditions(RequestTemplateApprovalConfig.ApprovalRule rule, Map<String, Object> variables) {
        if (rule == null) {
            return false;
        }
        if (rule.getConditions() == null || rule.getConditions().isEmpty()) {
            return true;
        }
        for (RequestTemplateApprovalConfig.ApprovalCondition condition : rule.getConditions()) {
            if (condition == null || condition.getField() == null || condition.getField().isBlank()) {
                continue;
            }
            Double actual = resolveNumericValue(variables, condition.getField());
            Double expected = condition.getValue();
            if (actual == null || expected == null) {
                return false;
            }
            String operator = condition.getOperator() == null ? "GTE" : condition.getOperator().trim().toUpperCase();
            boolean matched = switch (operator) {
                case "GT" -> actual > expected;
                case "GTE" -> actual >= expected;
                case "LT" -> actual < expected;
                case "LTE" -> actual <= expected;
                case "EQ" -> Objects.equals(actual, expected);
                default -> throw new IllegalArgumentException("unsupported approval condition operator: " + operator);
            };
            if (!matched) {
                return false;
            }
        }
        return true;
    }

    private Double resolveNumericValue(Map<String, Object> variables, String field) {
        if (variables == null || variables.isEmpty()) {
            return null;
        }
        Object raw = variables.get(field);
        if (raw == null && "days".equals(field)) {
            raw = variables.get("leaveDays");
        }
        if (raw == null) {
            return null;
        }
        if (raw instanceof Number number) {
            return number.doubleValue();
        }
        if (raw instanceof String stringValue && !stringValue.isBlank()) {
            try {
                return Double.parseDouble(stringValue.trim());
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    private RequestTemplateApprovalConfig.ApprovalRule createRule(String name,
                                                                  List<RequestTemplateApprovalConfig.ApprovalCondition> conditions,
                                                                  List<RequestTemplateApprovalConfig.ApprovalStep> steps) {
        RequestTemplateApprovalConfig.ApprovalRule rule = new RequestTemplateApprovalConfig.ApprovalRule();
        rule.setName(name);
        rule.setConditions(conditions);
        rule.setSteps(steps);
        return rule;
    }

    private RequestTemplateApprovalConfig.ApprovalCondition createCondition(String field, String operator, Double value) {
        RequestTemplateApprovalConfig.ApprovalCondition condition = new RequestTemplateApprovalConfig.ApprovalCondition();
        condition.setField(field);
        condition.setOperator(operator);
        condition.setValue(value);
        return condition;
    }

    private RequestTemplateApprovalConfig.ApprovalStep createStep(String type, Long userId) {
        RequestTemplateApprovalConfig.ApprovalStep step = new RequestTemplateApprovalConfig.ApprovalStep();
        step.setType(type);
        step.setUserId(userId);
        return step;
    }

    private void addApproverIfAbsent(List<String> approverIds, List<String> stepRuleNames, Long approverId, String ruleName) {
        if (approverId == null) {
            return;
        }
        String normalized = String.valueOf(approverId);
        if (!approverIds.contains(normalized)) {
            approverIds.add(normalized);
            stepRuleNames.add(ruleName == null || ruleName.isBlank() ? "自动审批" : ruleName);
        }
    }

    public record Resolution(List<String> approverIds, String strategy) {
    }

    public record PreviewResolution(List<String> approverIds, List<String> stepRuleNames) {
    }

    private record ResolutionDetail(List<String> approverIds, List<String> stepRuleNames, String strategy) {
    }
}
