package com.flowablecollab.approval_system.entity.rbac;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "sys_user_import_job")
public class SysUserImportJob {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "file_name", length = 255, nullable = false)
    private String fileName;

    @Column(name = "file_type", length = 16, nullable = false)
    private String fileType;

    @Column(name = "file_checksum", length = 128, nullable = false)
    private String fileChecksum;

    @Column(name = "strategy", length = 32, nullable = false)
    private String strategy;

    @Column(name = "status", length = 32, nullable = false)
    private String status;

    @Column(name = "total_rows", nullable = false)
    private Integer totalRows;

    @Column(name = "success_rows", nullable = false)
    private Integer successRows;

    @Column(name = "failed_rows", nullable = false)
    private Integer failedRows;

    @Column(name = "operator_id", nullable = false)
    private Long operatorId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "finished_at")
    private LocalDateTime finishedAt;
}
