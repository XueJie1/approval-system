package com.flowablecollab.approval_system.entity.form;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "form_definition")
public class FormDefinition {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "form_name", length = 128, nullable = false)
    private String formName;

    @Column(name = "form_key", length = 64, nullable = false, unique = true)
    private String formKey;

    @Column(name = "status", nullable = false)
    private Integer status;
}
