package com.flowablecollab.approval_system.entity.workflow;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "request_template")
public class RequestTemplate {

    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_INACTIVE = "INACTIVE";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "template_key", nullable = false, length = 64, unique = true)
    private String templateKey;

    @Column(name = "template_name", nullable = false, length = 128)
    private String templateName;

    @Column(name = "category", length = 64)
    private String category;

    @Column(name = "description", length = 512)
    private String description;

    @Column(name = "form_key", length = 64)
    private String formKey;

    @Column(name = "form_name", length = 128)
    private String formName;

    @Column(name = "process_key", nullable = false, length = 64)
    private String processKey;

    @Column(name = "countersign_mode", nullable = false, length = 32)
    private String countersignMode;

    @Column(name = "pass_ratio", nullable = false, length = 16)
    private String passRatio;

    @Column(name = "flow_summary", length = 512)
    private String flowSummary;

    @Column(name = "approval_config_json", columnDefinition = "TEXT")
    private String approvalConfigJson;

    @Column(name = "allow_manual_approver_select", nullable = false)
    private Integer allowManualApproverSelect;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    @Column(name = "status", nullable = false, length = 32)
    private String status;

    @Column(name = "created_by", nullable = false)
    private Long createdBy;

    @Column(name = "updated_by")
    private Long updatedBy;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (status == null || status.isBlank()) {
            status = STATUS_ACTIVE;
        }
        if (sortOrder == null) {
            sortOrder = 0;
        }
        if (allowManualApproverSelect == null) {
            allowManualApproverSelect = 0;
        }
        if (countersignMode == null || countersignMode.isBlank()) {
            countersignMode = "ALL";
        }
        if (passRatio == null || passRatio.isBlank()) {
            passRatio = "1.0";
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTemplateKey() {
        return templateKey;
    }

    public void setTemplateKey(String templateKey) {
        this.templateKey = templateKey;
    }

    public String getTemplateName() {
        return templateName;
    }

    public void setTemplateName(String templateName) {
        this.templateName = templateName;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getFormKey() {
        return formKey;
    }

    public void setFormKey(String formKey) {
        this.formKey = formKey;
    }

    public String getFormName() {
        return formName;
    }

    public void setFormName(String formName) {
        this.formName = formName;
    }

    public String getProcessKey() {
        return processKey;
    }

    public void setProcessKey(String processKey) {
        this.processKey = processKey;
    }

    public String getCountersignMode() {
        return countersignMode;
    }

    public void setCountersignMode(String countersignMode) {
        this.countersignMode = countersignMode;
    }

    public String getPassRatio() {
        return passRatio;
    }

    public void setPassRatio(String passRatio) {
        this.passRatio = passRatio;
    }

    public String getFlowSummary() {
        return flowSummary;
    }

    public void setFlowSummary(String flowSummary) {
        this.flowSummary = flowSummary;
    }

    public String getApprovalConfigJson() {
        return approvalConfigJson;
    }

    public void setApprovalConfigJson(String approvalConfigJson) {
        this.approvalConfigJson = approvalConfigJson;
    }

    public Integer getAllowManualApproverSelect() {
        return allowManualApproverSelect;
    }

    public void setAllowManualApproverSelect(Integer allowManualApproverSelect) {
        this.allowManualApproverSelect = allowManualApproverSelect;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(Integer sortOrder) {
        this.sortOrder = sortOrder;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Long getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(Long createdBy) {
        this.createdBy = createdBy;
    }

    public Long getUpdatedBy() {
        return updatedBy;
    }

    public void setUpdatedBy(Long updatedBy) {
        this.updatedBy = updatedBy;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
