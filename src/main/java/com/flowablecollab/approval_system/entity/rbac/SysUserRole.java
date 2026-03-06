package com.flowablecollab.approval_system.entity.rbac;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(
        name = "sys_user_role",
        uniqueConstraints = @UniqueConstraint(name = "uk_sys_user_role_user_role", columnNames = {"user_id", "role_id"})
)
public class SysUserRole {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "role_id", nullable = false)
    private Long roleId;
}
