package com.flowablecollab.approval_system.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "biz_request_log")
public class BizRequestLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "business_key", length = 64, nullable = false)
    private String businessKey;

    @Column(name = "process_instance_id", length = 64, nullable = false)
    private String processInstanceId;

    @Column(name = "task_id", length = 64)
    private String taskId;

    @Column(name = "operator_id", nullable = false)
    private Long operatorId;

    @Column(name = "action", length = 32, nullable = false)
    private String action;

    @Column(name = "comment", length = 512)
    private String comment;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        createdAt = LocalDateTime.now();
    }
}
