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
@Table(name = "workflow_definition_version")
public class WorkflowDefinitionVersion {

    public static final String STATUS_DRAFT = "DRAFT";
    public static final String STATUS_PUBLISHED = "PUBLISHED";
    public static final String STATUS_INACTIVE = "INACTIVE";
    public static final String STATUS_RETIRED = "RETIRED";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "definition_id", nullable = false)
    private Long definitionId;

    @Column(name = "version_no", nullable = false)
    private Integer versionNo;

    @Column(name = "version_label", length = 64)
    private String versionLabel;

    @Column(name = "status", nullable = false, length = 32)
    private String status;

    @Lob
    @Column(name = "bpmn_xml", nullable = false, columnDefinition = "LONGTEXT")
    private String bpmnXml;

    @Column(name = "bpmn_checksum", length = 64)
    private String bpmnChecksum;

    @Column(name = "flowable_deployment_id", length = 64)
    private String flowableDeploymentId;

    @Column(name = "flowable_process_definition_id", length = 128)
    private String flowableProcessDefinitionId;

    @Column(name = "form_key", length = 64)
    private String formKey;

    @Column(name = "form_version_id")
    private Long formVersionId;

    @Column(name = "change_summary", length = 1000)
    private String changeSummary;

    @Column(name = "published_by")
    private Long publishedBy;

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    @Column(name = "created_by", nullable = false)
    private Long createdBy;

    @Column(name = "updated_by")
    private Long updatedBy;

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
        if (status == null) {
            status = STATUS_DRAFT;
        }
        if (bpmnXml == null) {
            bpmnXml = "";
        }
        if (isDeleted == null) {
            isDeleted = 0;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
