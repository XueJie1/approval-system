package com.flowablecollab.approval_system.entity.form;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "form_attachment")
public class FormAttachment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "form_instance_id")
    private Long formInstanceId;

    @Column(name = "field_key", length = 64, nullable = false)
    private String fieldKey;

    @Column(name = "file_name", length = 255, nullable = false)
    private String fileName;

    @Column(name = "original_name", length = 255, nullable = false)
    private String originalName;

    @Column(name = "file_path", length = 512, nullable = false)
    private String filePath;

    @Column(name = "file_size", nullable = false)
    private Long fileSize;

    @Column(name = "content_type", length = 128, nullable = false)
    private String contentType;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
