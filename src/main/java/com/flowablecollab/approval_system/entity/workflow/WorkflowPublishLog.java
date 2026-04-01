package com.flowablecollab.approval_system.entity.workflow;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "workflow_publish_log")
public class WorkflowPublishLog {

    public static final String ACTION_PUBLISH = "PUBLISH";
    public static final String ACTION_INACTIVATE = "INACTIVATE";
    public static final String ACTION_ACTIVATE = "ACTIVATE";
    public static final String ACTION_RETIRE = "RETIRE";
    public static final String ACTION_ARCHIVE = "ARCHIVE";

    public static final String RESULT_SUCCESS = "SUCCESS";
    public static final String RESULT_FAIL = "FAIL";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "definition_id", nullable = false)
    private Long definitionId;

    @Column(name = "definition_version_id", nullable = false)
    private Long definitionVersionId;

    @Column(name = "action", nullable = false, length = 32)
    private String action;

    @Column(name = "result", nullable = false, length = 32)
    private String result;

    @Column(name = "message", length = 1000)
    private String message;

    @Column(name = "flowable_deployment_id", length = 64)
    private String flowableDeploymentId;

    @Column(name = "flowable_process_definition_id", length = 128)
    private String flowableProcessDefinitionId;

    @Column(name = "operator_id", nullable = false)
    private Long operatorId;

    @Column(name = "operated_at", nullable = false)
    private LocalDateTime operatedAt;

    @PrePersist
    public void prePersist() {
        if (operatedAt == null) {
            operatedAt = LocalDateTime.now();
        }
    }
}
