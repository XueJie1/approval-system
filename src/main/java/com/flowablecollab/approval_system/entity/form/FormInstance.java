package com.flowablecollab.approval_system.entity.form;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "form_instance")
public class FormInstance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "form_version_id", nullable = false)
    private Long formVersionId;

    @Column(name = "business_key", length = 64, nullable = false)
    private String businessKey;

    @Lob
    @Column(name = "data_json", nullable = false, columnDefinition = "TEXT")
    private String dataJson;
}
