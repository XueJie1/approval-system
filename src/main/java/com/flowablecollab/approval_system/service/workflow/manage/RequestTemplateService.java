package com.flowablecollab.approval_system.service.workflow.manage;

import com.flowablecollab.approval_system.entity.workflow.RequestTemplate;
import com.flowablecollab.approval_system.exception.ResourceConflictException;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.repository.workflow.RequestTemplateRepository;
import com.flowablecollab.approval_system.service.RequestTemplateApprovalResolverService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class RequestTemplateService {

    private static final long SYSTEM_OPERATOR_ID = 0L;

    private final RequestTemplateRepository requestTemplateRepository;
    private final BizRequestRepository bizRequestRepository;
    private final RequestTemplateApprovalResolverService requestTemplateApprovalResolverService;

    public RequestTemplateService(RequestTemplateRepository requestTemplateRepository,
                                  BizRequestRepository bizRequestRepository,
                                  RequestTemplateApprovalResolverService requestTemplateApprovalResolverService) {
        this.requestTemplateRepository = requestTemplateRepository;
        this.bizRequestRepository = bizRequestRepository;
        this.requestTemplateApprovalResolverService = requestTemplateApprovalResolverService;
    }

    @Transactional(readOnly = true)
    public List<TemplateView> listActiveTemplates() {
        return requestTemplateRepository.findByStatusOrderBySortOrderAscIdAsc(RequestTemplate.STATUS_ACTIVE)
                .stream()
                .map(this::toView)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TemplateView> listAllTemplates() {
        return requestTemplateRepository.findAllByOrderBySortOrderAscIdAsc()
                .stream()
                .map(this::toView)
                .toList();
    }

    @Transactional
    public TemplateView createTemplate(TemplateUpsertRequest request, Long operatorId) {
        validateRequest(request);
        if (requestTemplateRepository.existsByTemplateKey(request.getTemplateKey())) {
            throw new ResourceConflictException("templateKey already exists");
        }
        RequestTemplate entity = new RequestTemplate();
        applyRequest(entity, request, operatorId, true);
        return toView(requestTemplateRepository.save(entity));
    }

    @Transactional
    public TemplateView updateTemplate(Long templateId, TemplateUpsertRequest request, Long operatorId) {
        validateRequest(request);
        RequestTemplate entity = requestTemplateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("request template not found"));
        if (!entity.getTemplateKey().equals(request.getTemplateKey())
                && requestTemplateRepository.existsByTemplateKey(request.getTemplateKey())) {
            throw new ResourceConflictException("templateKey already exists");
        }
        applyRequest(entity, request, operatorId, false);
        return toView(requestTemplateRepository.save(entity));
    }

    @Transactional
    public void bootstrapDefaults() {
        List<TemplateSeed> seeds = List.of(
                new TemplateSeed("leave", "请假申请", "行政人事", "用于员工提交事假、病假、年假等请假申请。", "leave_request", "请假申请表", "approvalSequential", "ALL", "1.0", "直属主管顺序审批，必要时追加部门负责人审批", 10, 0),
                new TemplateSeed("expense", "报销申请", "财务", "用于日常费用报销、差旅报销和票据提交。", "expense_request", "报销申请表", "approvalSequential", "ALL", "1.0", "直属主管和财务顺序审批，大额报销可追加更高级别审批", 20, 0),
                new TemplateSeed("travel", "出差申请", "行政人事", "用于出差行程、预算与出差事由审批。", "travel_request", "出差申请表", "approvalSequential", "ALL", "1.0", "直属主管审批，必要时增加部门负责人和财务审批", 30, 0),
                new TemplateSeed("purchase", "采购申请", "采购", "用于办公物资、设备与业务采购审批。", "purchase_request", "采购申请表", "approvalCountersign", "MAJORITY", "0.5", "采购相关审批人并行会签，超过预算阈值时追加高级审批", 40, 0),
                new TemplateSeed("seal", "用章申请", "行政", "用于文件盖章、资料用印和外发材料审批。", "seal_request", "用章申请表", "approvalSingle", "ALL", "1.0", "由印章管理员或指定负责人单人审批", 50, 0),
                new TemplateSeed("contract", "合同审批", "法务", "用于合同评审、法务审查和金额审批。", "contract_request", "合同审批表", "approvalCountersign", "ALL", "1.0", "法务、业务和财务协同会签，重大合同再提交高层审批", 60, 0)
        );

        for (TemplateSeed seed : seeds) {
            RequestTemplate entity = requestTemplateRepository.findByTemplateKey(seed.templateKey())
                    .orElseGet(RequestTemplate::new);
            String existingApprovalConfigJson = entity.getApprovalConfigJson();
            entity.setTemplateKey(seed.templateKey());
            entity.setTemplateName(seed.templateName());
            entity.setCategory(seed.category());
            entity.setDescription(seed.description());
            entity.setFormKey(seed.formKey());
            entity.setFormName(seed.formName());
            entity.setProcessKey(seed.processKey());
            entity.setCountersignMode(seed.countersignMode());
            entity.setPassRatio(seed.passRatio());
            entity.setFlowSummary(seed.flowSummary());
            entity.setApprovalConfigJson(existingApprovalConfigJson == null || existingApprovalConfigJson.isBlank()
                    ? defaultApprovalConfigJson(seed.templateKey())
                    : existingApprovalConfigJson);
            entity.setAllowManualApproverSelect(seed.allowManualApproverSelect());
            entity.setSortOrder(seed.sortOrder());
            entity.setStatus(RequestTemplate.STATUS_ACTIVE);
            if (entity.getId() == null) {
                entity.setCreatedBy(SYSTEM_OPERATOR_ID);
            }
            entity.setUpdatedBy(SYSTEM_OPERATOR_ID);
            requestTemplateRepository.save(entity);
        }
    }

    private void validateRequest(TemplateUpsertRequest request) {
        if (request.getTemplateKey() == null || request.getTemplateKey().isBlank()) {
            throw new IllegalArgumentException("templateKey is required");
        }
        if (!request.getTemplateKey().matches("[a-z][a-z0-9_]*")) {
            throw new IllegalArgumentException("templateKey format is invalid");
        }
        if (request.getTemplateName() == null || request.getTemplateName().isBlank()) {
            throw new IllegalArgumentException("templateName is required");
        }
        if (request.getProcessKey() == null || request.getProcessKey().isBlank()) {
            throw new IllegalArgumentException("processKey is required");
        }
        if (request.getStatus() == null || request.getStatus().isBlank()) {
            throw new IllegalArgumentException("status is required");
        }
    }

    private void applyRequest(RequestTemplate entity, TemplateUpsertRequest request, Long operatorId, boolean creating) {
        entity.setTemplateKey(request.getTemplateKey().trim());
        entity.setTemplateName(request.getTemplateName().trim());
        entity.setCategory(blankToNull(request.getCategory()));
        entity.setDescription(blankToNull(request.getDescription()));
        entity.setFormKey(blankToNull(request.getFormKey()));
        entity.setFormName(blankToNull(request.getFormName()));
        entity.setProcessKey(request.getProcessKey().trim());
        entity.setCountersignMode(request.getCountersignMode() == null || request.getCountersignMode().isBlank()
                ? "ALL"
                : request.getCountersignMode().trim());
        entity.setPassRatio(request.getPassRatio() == null || request.getPassRatio().isBlank()
                ? "1.0"
                : request.getPassRatio().trim());
        entity.setFlowSummary(blankToNull(request.getFlowSummary()));
        entity.setApprovalConfigJson(normalizeApprovalConfig(request.getApprovalConfig()));
        entity.setAllowManualApproverSelect(Boolean.TRUE.equals(request.getAllowManualApproverSelect()) ? 1 : 0);
        entity.setSortOrder(request.getSortOrder() == null ? 0 : request.getSortOrder());
        entity.setStatus(request.getStatus().trim());
        if (creating) {
            entity.setCreatedBy(operatorId);
        }
        entity.setUpdatedBy(operatorId);
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private String defaultApprovalConfigJson(String templateKey) {
        return switch (templateKey) {
            case "leave" -> requestTemplateApprovalResolverService.writeApprovalConfig(
                    requestTemplateApprovalResolverService.leaveDefaultConfig());
            case "expense" -> requestTemplateApprovalResolverService.writeApprovalConfig(
                    requestTemplateApprovalResolverService.expenseDefaultConfig());
            case "travel" -> requestTemplateApprovalResolverService.writeApprovalConfig(
                    requestTemplateApprovalResolverService.travelDefaultConfig());
            case "purchase" -> requestTemplateApprovalResolverService.writeApprovalConfig(
                    requestTemplateApprovalResolverService.purchaseDefaultConfig());
            case "contract" -> requestTemplateApprovalResolverService.writeApprovalConfig(
                    requestTemplateApprovalResolverService.contractDefaultConfig());
            default -> requestTemplateApprovalResolverService.writeApprovalConfig(
                    requestTemplateApprovalResolverService.sealDefaultConfig());
        };
    }

    private String normalizeApprovalConfig(RequestTemplateApprovalConfig approvalConfig) {
        return requestTemplateApprovalResolverService.writeApprovalConfig(approvalConfig);
    }

    private TemplateView toView(RequestTemplate entity) {
        TemplateView view = new TemplateView();
        view.setId(entity.getId());
        view.setTemplateKey(entity.getTemplateKey());
        view.setTemplateName(entity.getTemplateName());
        view.setCategory(entity.getCategory());
        view.setDescription(entity.getDescription());
        view.setFormKey(entity.getFormKey());
        view.setFormName(entity.getFormName());
        view.setProcessKey(entity.getProcessKey());
        view.setCountersignMode(entity.getCountersignMode());
        view.setPassRatio(entity.getPassRatio());
        view.setFlowSummary(entity.getFlowSummary());
        view.setApprovalConfig(requestTemplateApprovalResolverService.readApprovalConfig(entity.getApprovalConfigJson()));
        view.setAllowManualApproverSelect(entity.getAllowManualApproverSelect() != null && entity.getAllowManualApproverSelect() == 1);
        view.setSortOrder(entity.getSortOrder());
        view.setStatus(entity.getStatus());
        view.setUsageCount(bizRequestRepository.countByRequestTemplateKey(entity.getTemplateKey()));
        view.setCreatedAt(entity.getCreatedAt());
        view.setUpdatedAt(entity.getUpdatedAt());
        return view;
    }

    public record TemplateSeed(
            String templateKey,
            String templateName,
            String category,
            String description,
            String formKey,
            String formName,
            String processKey,
            String countersignMode,
            String passRatio,
            String flowSummary,
            Integer sortOrder,
            Integer allowManualApproverSelect) {
    }

    public static class TemplateView {
        private Long id;
        private String templateKey;
        private String templateName;
        private String category;
        private String description;
        private String formKey;
        private String formName;
        private String processKey;
        private String countersignMode;
        private String passRatio;
        private String flowSummary;
        private RequestTemplateApprovalConfig approvalConfig;
        private Boolean allowManualApproverSelect;
        private Integer sortOrder;
        private String status;
        private Long usageCount;
        private java.time.LocalDateTime createdAt;
        private java.time.LocalDateTime updatedAt;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getTemplateKey() { return templateKey; }
        public void setTemplateKey(String templateKey) { this.templateKey = templateKey; }
        public String getTemplateName() { return templateName; }
        public void setTemplateName(String templateName) { this.templateName = templateName; }
        public String getCategory() { return category; }
        public void setCategory(String category) { this.category = category; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public String getFormKey() { return formKey; }
        public void setFormKey(String formKey) { this.formKey = formKey; }
        public String getFormName() { return formName; }
        public void setFormName(String formName) { this.formName = formName; }
        public String getProcessKey() { return processKey; }
        public void setProcessKey(String processKey) { this.processKey = processKey; }
        public String getCountersignMode() { return countersignMode; }
        public void setCountersignMode(String countersignMode) { this.countersignMode = countersignMode; }
        public String getPassRatio() { return passRatio; }
        public void setPassRatio(String passRatio) { this.passRatio = passRatio; }
        public String getFlowSummary() { return flowSummary; }
        public void setFlowSummary(String flowSummary) { this.flowSummary = flowSummary; }
        public RequestTemplateApprovalConfig getApprovalConfig() { return approvalConfig; }
        public void setApprovalConfig(RequestTemplateApprovalConfig approvalConfig) { this.approvalConfig = approvalConfig; }
        public Boolean getAllowManualApproverSelect() { return allowManualApproverSelect; }
        public void setAllowManualApproverSelect(Boolean allowManualApproverSelect) { this.allowManualApproverSelect = allowManualApproverSelect; }
        public Integer getSortOrder() { return sortOrder; }
        public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Long getUsageCount() { return usageCount; }
        public void setUsageCount(Long usageCount) { this.usageCount = usageCount; }
        public java.time.LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(java.time.LocalDateTime createdAt) { this.createdAt = createdAt; }
        public java.time.LocalDateTime getUpdatedAt() { return updatedAt; }
        public void setUpdatedAt(java.time.LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    }

    public static class TemplateUpsertRequest {
        private String templateKey;
        private String templateName;
        private String category;
        private String description;
        private String formKey;
        private String formName;
        private String processKey;
        private String countersignMode;
        private String passRatio;
        private String flowSummary;
        private RequestTemplateApprovalConfig approvalConfig;
        private Boolean allowManualApproverSelect;
        private Integer sortOrder;
        private String status;

        public String getTemplateKey() { return templateKey; }
        public void setTemplateKey(String templateKey) { this.templateKey = templateKey; }
        public String getTemplateName() { return templateName; }
        public void setTemplateName(String templateName) { this.templateName = templateName; }
        public String getCategory() { return category; }
        public void setCategory(String category) { this.category = category; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public String getFormKey() { return formKey; }
        public void setFormKey(String formKey) { this.formKey = formKey; }
        public String getFormName() { return formName; }
        public void setFormName(String formName) { this.formName = formName; }
        public String getProcessKey() { return processKey; }
        public void setProcessKey(String processKey) { this.processKey = processKey; }
        public String getCountersignMode() { return countersignMode; }
        public void setCountersignMode(String countersignMode) { this.countersignMode = countersignMode; }
        public String getPassRatio() { return passRatio; }
        public void setPassRatio(String passRatio) { this.passRatio = passRatio; }
        public String getFlowSummary() { return flowSummary; }
        public void setFlowSummary(String flowSummary) { this.flowSummary = flowSummary; }
        public RequestTemplateApprovalConfig getApprovalConfig() { return approvalConfig; }
        public void setApprovalConfig(RequestTemplateApprovalConfig approvalConfig) { this.approvalConfig = approvalConfig; }
        public Boolean getAllowManualApproverSelect() { return allowManualApproverSelect; }
        public void setAllowManualApproverSelect(Boolean allowManualApproverSelect) { this.allowManualApproverSelect = allowManualApproverSelect; }
        public Integer getSortOrder() { return sortOrder; }
        public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
    }
}
