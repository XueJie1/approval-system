package com.flowablecollab.approval_system.entity.form;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "form_field")
public class FormField {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "form_version_id", nullable = false)
    private Long formVersionId;

    @Column(name = "field_key", length = 64, nullable = false)
    private String fieldKey;

    @Column(name = "variable_key", length = 64)
    private String variableKey;

    @Column(name = "field_type", length = 32, nullable = false)
    private String fieldType;

    @Column(name = "label", length = 128)
    private String label;

    @Column(name = "required", nullable = false)
    private Integer required;

    @Lob
    @Column(name = "visible_rule", columnDefinition = "TEXT")
    private String visibleRule;

    @Lob
    @Column(name = "validate_rule", columnDefinition = "TEXT")
    private String validateRule;

    @Lob
    @Column(name = "options_json", columnDefinition = "TEXT")
    private String optionsJson;

    @Lob
    @Column(name = "default_value", columnDefinition = "TEXT")
    private String defaultValue;

    @Column(name = "sort_order")
    private Integer sortOrder;
}
