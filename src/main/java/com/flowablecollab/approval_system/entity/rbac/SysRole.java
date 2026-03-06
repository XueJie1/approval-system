package com.flowablecollab.approval_system.entity.rbac;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "sys_role")
public class SysRole {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "role_code", length = 64, nullable = false, unique = true)
    private String roleCode;

    @Column(name = "role_name", length = 64, nullable = false)
    private String roleName;

    @Column(name = "status", nullable = false)
    private Integer status;
}
