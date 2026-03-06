package com.flowablecollab.approval_system.entity.rbac;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "sys_post")
public class SysPost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "post_code", length = 64, nullable = false, unique = true)
    private String postCode;

    @Column(name = "post_name", length = 64, nullable = false)
    private String postName;
}
