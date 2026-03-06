package com.flowablecollab.approval_system.entity.form;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "form_version")
public class FormVersion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "form_id", nullable = false)
    private Long formId;

    @Column(name = "version", nullable = false)
    private Integer version;

    @Lob
    @Column(name = "schema_json", nullable = false, columnDefinition = "TEXT")
    private String schemaJson;
}
