package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysUserPost;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SysUserPostRepository extends JpaRepository<SysUserPost, Long> {
    List<SysUserPost> findByUserId(Long userId);

    boolean existsByUserIdAndPostId(Long userId, Long postId);

    void deleteByUserId(Long userId);

    Optional<SysUserPost> findByPostId(Long postId);
}
