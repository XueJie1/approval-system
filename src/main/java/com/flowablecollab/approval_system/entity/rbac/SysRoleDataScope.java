package com.flowablecollab.approval_system.entity.rbac;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "sys_role_data_scope")
public class SysRoleDataScope {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "role_id", nullable = false)
    private Long roleId;

    @Column(name = "dept_id")
    private Long deptId;

    @Column(name = "scope_type", length = 32, nullable = false)
    private String scopeType;
}
