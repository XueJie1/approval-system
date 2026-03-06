package com.flowablecollab.approval_system.entity.rbac;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "sys_user")
public class SysUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "username", length = 64, nullable = false, unique = true)
    private String username;

    @Column(name = "password", length = 128)
    private String password;

    @Column(name = "dept_id")
    private Long deptId;

    @Column(name = "status", nullable = false)
    private Integer status;

    @Column(name = "two_factor_enabled", nullable = false)
    private Integer twoFactorEnabled;

    @Column(name = "two_factor_secret", length = 128)
    private String twoFactorSecret;

    @Column(name = "recovery_codes", length = 512)
    private String recoveryCodes;

    @Column(name = "last_login_at")
    private java.time.LocalDateTime lastLoginAt;

    @Column(name = "login_failures", nullable = false)
    private Integer loginFailures;

    @Column(name = "locked_until")
    private java.time.LocalDateTime lockedUntil;
}
