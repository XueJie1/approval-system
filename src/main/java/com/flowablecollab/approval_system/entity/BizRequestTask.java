package com.flowablecollab.approval_system.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "biz_request_task")
public class BizRequestTask {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "business_key", length = 64, nullable = false)
    private String businessKey;

    @Column(name = "process_instance_id", length = 64, nullable = false)
    private String processInstanceId;

    @Column(name = "task_id", length = 64, nullable = false, unique = true)
    private String taskId;

    @Column(name = "task_name", length = 128)
    private String taskName;

    @Column(name = "assignee_id")
    private Long assigneeId;

    @Column(name = "owner_id")
    private Long ownerId;

    @Column(name = "status", nullable = false)
    private Integer status;

    @Column(name = "action", length = 32)
    private String action;

    @Column(name = "comment", length = 512)
    private String comment;

    @Column(name = "start_time")
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
