package com.flowablecollab.approval_system.entity.workflow;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "workflow_node_config")
public class WorkflowNodeConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "definition_version_id", nullable = false)
    private Long definitionVersionId;

    @Column(name = "node_id", nullable = false, length = 64)
    private String nodeId;

    @Column(name = "node_name", nullable = false, length = 128)
    private String nodeName;

    @Column(name = "node_type", nullable = false, length = 32)
    private String nodeType;

    @Column(name = "approval_type", length = 32)
    private String approvalType;

    @Column(name = "assignee_strategy", length = 32)
    private String assigneeStrategy;

    @Lob
    @Column(name = "assignee_config_json", columnDefinition = "TEXT")
    private String assigneeConfigJson;

    @Column(name = "comment_required", nullable = false)
    private Integer commentRequired;

    @Column(name = "allow_delegate", nullable = false)
    private Integer allowDelegate;

    @Column(name = "allow_reassign", nullable = false)
    private Integer allowReassign;

    @Column(name = "allow_return_previous", nullable = false)
    private Integer allowReturnPrevious;

    @Column(name = "allow_return_applicant", nullable = false)
    private Integer allowReturnApplicant;

    @Column(name = "ai_enabled", nullable = false)
    private Integer aiEnabled;

    @Lob
    @Column(name = "timeout_rule_json", columnDefinition = "TEXT")
    private String timeoutRuleJson;

    @Lob
    @Column(name = "extra_config_json", columnDefinition = "TEXT")
    private String extraConfigJson;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (commentRequired == null) {
            commentRequired = 1;
        }
        if (allowDelegate == null) {
            allowDelegate = 1;
        }
        if (allowReassign == null) {
            allowReassign = 1;
        }
        if (allowReturnPrevious == null) {
            allowReturnPrevious = 1;
        }
        if (allowReturnApplicant == null) {
            allowReturnApplicant = 1;
        }
        if (aiEnabled == null) {
            aiEnabled = 0;
        }
        if (sortOrder == null) {
            sortOrder = 0;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
