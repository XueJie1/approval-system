package com.flowablecollab.approval_system.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "ai_suggestion_record")
public class AiSuggestionRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "business_key", length = 64, nullable = false)
    private String businessKey;

    @Column(name = "process_instance_id", length = 64, nullable = false)
    private String processInstanceId;

    @Column(name = "task_id", length = 64, nullable = false)
    private String taskId;

    @Column(name = "requester_id", nullable = false)
    private Long requesterId;

    @Column(name = "model", length = 128)
    private String model;

    @Lob
    @Column(name = "suggestion_json", nullable = false)
    private String suggestionJson;

    @Lob
    @Column(name = "conversation_json")
    private String conversationJson;

    @Column(name = "adopted", nullable = false)
    private Boolean adopted;

    @Column(name = "adopted_at")
    private LocalDateTime adoptedAt;

    @Column(name = "final_approval_result", length = 32)
    private String finalApprovalResult;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (adopted == null) {
            adopted = false;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
