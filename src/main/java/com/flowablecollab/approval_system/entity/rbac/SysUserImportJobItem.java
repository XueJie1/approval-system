package com.flowablecollab.approval_system.entity.rbac;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "sys_user_import_job_item")
public class SysUserImportJobItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "row_no", nullable = false)
    private Integer rowNo;

    @Column(name = "username", length = 64)
    private String username;

    @Lob
    @Column(name = "raw_payload")
    private String rawPayload;

    @Column(name = "result", length = 32, nullable = false)
    private String result;

    @Column(name = "error_message", length = 512)
    private String errorMessage;

    @Column(name = "created_user_id")
    private Long createdUserId;

    @Lob
    @Column(name = "before_snapshot")
    private String beforeSnapshot;

    @Lob
    @Column(name = "after_snapshot")
    private String afterSnapshot;
}
