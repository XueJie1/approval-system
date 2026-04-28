package com.flowablecollab.approval_system.service;

import com.flowablecollab.approval_system.entity.workflow.RequestTemplate;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.repository.workflow.RequestTemplateRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.flowablecollab.approval_system.service.workflow.manage.RequestTemplateApprovalConfig;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class RequestTemplateApprovalResolverService {

    private final RequestTemplateRepository requestTemplateRepository;
    private final RequestApprovalResolverService requestApprovalResolverService;
    private final SysUserRepository sysUserRepository;
    private final ObjectMapper objectMapper;

    public RequestTemplateApprovalResolverService(RequestTemplateRepository requestTemplateRepository,
                                                  RequestApprovalResolverService requestApprovalResolverService,
                                                  SysUserRepository sysUserRepository,
                                                  ObjectMapper objectMapper) {
        this.requestTemplateRepository = requestTemplateRepository;
        this.requestApprovalResolverService = requestApprovalResolverService;
        this.sysUserRepository = sysUserRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public RequestApprovalResolverService.Resolution resolve(String templateKey,
                                                             Long applicantId,
                                                             Map<String, Object> variables) {
        if (templateKey == null || templateKey.isBlank()) {
            return null;
        }
        RequestTemplate template = requestTemplateRepository.findByTemplateKey(templateKey)
                .orElseThrow(() -> new IllegalArgumentException("request template not found: " + templateKey));
        RequestTemplateApprovalConfig config = readApprovalConfig(template.getApprovalConfigJson());
        if (config == null || config.getRules() == null || config.getRules().isEmpty()) {
            return null;
        }
        return requestApprovalResolverService.resolveByTemplateConfig(applicantId, variables, config);
    }

    @Transactional(readOnly = true)
    public RequestApprovalResolverService.PreviewResolution preview(String templateKey,
                                                                    Long applicantId,
                                                                    Map<String, Object> variables) {
        if (templateKey == null || templateKey.isBlank()) {
            return null;
        }
        RequestTemplate template = requestTemplateRepository.findByTemplateKey(templateKey)
                .orElseThrow(() -> new IllegalArgumentException("request template not found: " + templateKey));
        RequestTemplateApprovalConfig config = readApprovalConfig(template.getApprovalConfigJson());
        if (config == null || config.getRules() == null || config.getRules().isEmpty()) {
            return null;
        }
        return requestApprovalResolverService.previewByTemplateConfig(applicantId, variables, config);
    }

    public RequestTemplateApprovalConfig readApprovalConfig(String approvalConfigJson) {
        if (approvalConfigJson == null || approvalConfigJson.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(approvalConfigJson, RequestTemplateApprovalConfig.class);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("approvalConfigJson is invalid", ex);
        }
    }

    public String writeApprovalConfig(RequestTemplateApprovalConfig config) {
        if (config == null || config.getRules() == null || config.getRules().isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(config);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("approvalConfigJson serialization failed", ex);
        }
    }

    public RequestTemplateApprovalConfig leaveDefaultConfig() {
        RequestTemplateApprovalConfig config = new RequestTemplateApprovalConfig();
        config.setRules(List.of(
                rule("1天及以下", null, List.of(step("MANAGER", null), step("DEPT_LEADER", null))),
                rule("超过1天", List.of(condition("days", "GT", 1D)), List.of(step("DEPT_LEADER", null))),
                rule("超过3天", List.of(condition("days", "GT", 3D)), List.of(step("PARENT_DEPT_LEADER", null)))
        ));
        return config;
    }

    public RequestTemplateApprovalConfig expenseDefaultConfig() {
        RequestTemplateApprovalConfig config = new RequestTemplateApprovalConfig();
        config.setRules(List.of(
                rule("基础审批", null, List.of(step("MANAGER", null), step("DEPT_LEADER", null))),
                rule("金额超过5000", List.of(condition("amount", "GT", 5000D)), List.of(step("PARENT_DEPT_LEADER", null)))
        ));
        return config;
    }

    public RequestTemplateApprovalConfig travelDefaultConfig() {
        RequestTemplateApprovalConfig config = new RequestTemplateApprovalConfig();
        config.setRules(List.of(
                rule("基础审批", null, List.of(step("MANAGER", null), step("DEPT_LEADER", null))),
                rule("预算超过3000", List.of(condition("budget", "GT", 3000D)), List.of(step("PARENT_DEPT_LEADER", null)))
        ));
        return config;
    }

    public RequestTemplateApprovalConfig purchaseDefaultConfig() {
        RequestTemplateApprovalConfig config = new RequestTemplateApprovalConfig();
        config.setRules(List.of(
                rule("基础审批", null, List.of(step("DEPT_LEADER", null))),
                rule("金额超过10000", List.of(condition("amount", "GT", 10000D)), List.of(step("PARENT_DEPT_LEADER", null)))
        ));
        return config;
    }

    public RequestTemplateApprovalConfig sealDefaultConfig() {
        return null;
    }

    public RequestTemplateApprovalConfig contractDefaultConfig() {
        RequestTemplateApprovalConfig config = new RequestTemplateApprovalConfig();
        config.setRules(List.of(rule("基础审批", null, List.of(step("DEPT_LEADER", null)))));
        return config;
    }

    public List<PreviewStepView> describeApprovalChain(String templateKey,
                                                       Long applicantId,
                                                       Map<String, Object> variables) {
        RequestApprovalResolverService.PreviewResolution preview;
        try {
            preview = preview(templateKey, applicantId, variables);
        } catch (IllegalArgumentException ex) {
            return List.of();
        }
        if (preview == null) {
            return List.of();
        }
        RequestTemplate template = requestTemplateRepository.findByTemplateKey(templateKey)
                .orElseThrow(() -> new IllegalArgumentException("request template not found: " + templateKey));
        RequestTemplateApprovalConfig config = readApprovalConfig(template.getApprovalConfigJson());
        Map<String, String> labels = new LinkedHashMap<>();
        for (RequestTemplateApprovalConfig.ApprovalRule rule : config.getRules()) {
            if (rule == null || rule.getSteps() == null) {
                continue;
            }
            for (RequestTemplateApprovalConfig.ApprovalStep step : rule.getSteps()) {
                if (step == null || step.getType() == null || step.getType().isBlank()) {
                    continue;
                }
                labels.putIfAbsent(step.getType(), stepLabel(step));
            }
        }
        java.util.ArrayList<PreviewStepView> views = new java.util.ArrayList<>();
        List<String> approverIds = preview.approverIds();
        List<String> stepRuleNames = preview.stepRuleNames();
        for (int i = 0; i < approverIds.size(); i++) {
            PreviewStepView view = new PreviewStepView();
            String approverId = approverIds.get(i);
            view.setOrderNo(i + 1);
            view.setApproverId(approverId);
            view.setApproverName(resolveApproverName(approverId));
            view.setLabel(i < stepRuleNames.size() && stepRuleNames.get(i) != null && !stepRuleNames.get(i).isBlank()
                    ? stepRuleNames.get(i)
                    : "自动审批");
            view.setResolverType(i < labels.size() ? labels.keySet().stream().toList().get(i) : null);
            view.setResolverLabel(i < labels.size() ? labels.values().stream().toList().get(i) : "自动审批人");
            view.setSourceDescription(buildSourceDescription(view));
            views.add(view);
        }
        return views;
    }

    private String resolveApproverName(String approverId) {
        if (approverId == null || approverId.isBlank()) {
            return null;
        }
        try {
            Long userId = Long.parseLong(approverId);
            SysUser user = sysUserRepository.findById(userId).orElse(null);
            return user == null ? null : user.getUsername();
        } catch (NumberFormatException ex) {
            return approverId;
        }
    }

    private String buildSourceDescription(PreviewStepView view) {
        if (view.getResolverLabel() == null || view.getResolverLabel().isBlank()) {
            return view.getLabel();
        }
        if (view.getLabel() == null || view.getLabel().isBlank() || "自动审批".equals(view.getLabel())) {
            return "来源：" + view.getResolverLabel();
        }
        return view.getLabel() + " · 来源：" + view.getResolverLabel();
    }

    private RequestTemplateApprovalConfig.ApprovalStep step(String type, Long userId) {
        RequestTemplateApprovalConfig.ApprovalStep step = new RequestTemplateApprovalConfig.ApprovalStep();
        step.setType(type);
        step.setUserId(userId);
        return step;
    }

    private RequestTemplateApprovalConfig.ApprovalRule rule(String name,
                                                            List<RequestTemplateApprovalConfig.ApprovalCondition> conditions,
                                                            List<RequestTemplateApprovalConfig.ApprovalStep> steps) {
        RequestTemplateApprovalConfig.ApprovalRule rule = new RequestTemplateApprovalConfig.ApprovalRule();
        rule.setName(name);
        rule.setConditions(conditions);
        rule.setSteps(steps);
        return rule;
    }

    private RequestTemplateApprovalConfig.ApprovalCondition condition(String field, String operator, Double value) {
        RequestTemplateApprovalConfig.ApprovalCondition condition = new RequestTemplateApprovalConfig.ApprovalCondition();
        condition.setField(field);
        condition.setOperator(operator);
        condition.setValue(value);
        return condition;
    }

    private String stepLabel(RequestTemplateApprovalConfig.ApprovalStep step) {
        return switch (step.getType()) {
            case "MANAGER" -> "直属主管";
            case "DEPT_LEADER" -> "部门负责人";
            case "PARENT_DEPT_LEADER" -> "上级部门负责人";
            case "SPECIFIC_USER" -> "指定用户";
            default -> step.getType();
        };
    }

    public static class PreviewStepView {
        private Integer orderNo;
        private String approverId;
        private String approverName;
        private String label;
        private String resolverType;
        private String resolverLabel;
        private String sourceDescription;

        public Integer getOrderNo() { return orderNo; }
        public void setOrderNo(Integer orderNo) { this.orderNo = orderNo; }
        public String getApproverId() { return approverId; }
        public void setApproverId(String approverId) { this.approverId = approverId; }
        public String getApproverName() { return approverName; }
        public void setApproverName(String approverName) { this.approverName = approverName; }
        public String getLabel() { return label; }
        public void setLabel(String label) { this.label = label; }
        public String getResolverType() { return resolverType; }
        public void setResolverType(String resolverType) { this.resolverType = resolverType; }
        public String getResolverLabel() { return resolverLabel; }
        public void setResolverLabel(String resolverLabel) { this.resolverLabel = resolverLabel; }
        public String getSourceDescription() { return sourceDescription; }
        public void setSourceDescription(String sourceDescription) { this.sourceDescription = sourceDescription; }
    }
}
