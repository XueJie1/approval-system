package com.flowablecollab.approval_system.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "biz_request")
public class BizRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "business_key", length = 64, nullable = false, unique = true)
    private String businessKey;

    @Column(name = "process_instance_id", length = 64)
    private String processInstanceId;

    @Column(name = "process_definition_id", length = 64)
    private String processDefinitionId;

    @Column(name = "form_instance_id")
    private Long formInstanceId;

    @Column(name = "workflow_definition_id")
    private Long workflowDefinitionId;

    @Column(name = "workflow_definition_version_id")
    private Long workflowDefinitionVersionId;

    @Column(name = "form_version_id")
    private Long formVersionId;

    @Column(name = "applicant_id", nullable = false)
    private Long applicantId;

    @Column(name = "applicant_dept_id")
    private Long applicantDeptId;

    @Column(name = "applicant_post_id")
    private Long applicantPostId;

    @Column(name = "title", length = 128, nullable = false)
    private String title;

    @Column(name = "status", nullable = false)
    private Integer status;

    @Column(name = "current_task_id", length = 64)
    private String currentTaskId;

    @Column(name = "current_assignee_id")
    private Long currentAssigneeId;

    @Column(name = "submit_time")
    private LocalDateTime submitTime;

    @Column(name = "finish_time")
    private LocalDateTime finishTime;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "is_deleted", nullable = false)
    private Integer isDeleted;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (isDeleted == null) {
            isDeleted = 0;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
