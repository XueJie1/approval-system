package com.flowablecollab.approval_system.entity.rbac;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(
        name = "sys_user_post",
        uniqueConstraints = @UniqueConstraint(name = "uk_sys_user_post_user_post", columnNames = {"user_id", "post_id"})
)
public class SysUserPost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "post_id", nullable = false)
    private Long postId;
}
