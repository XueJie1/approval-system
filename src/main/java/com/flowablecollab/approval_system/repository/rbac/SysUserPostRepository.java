package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysUserPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface SysUserPostRepository extends JpaRepository<SysUserPost, Long> {
    List<SysUserPost> findByUserId(Long userId);

    boolean existsByUserIdAndPostId(Long userId, Long postId);

    @Modifying
    @Query("DELETE FROM SysUserPost up WHERE up.userId = :userId")
    void deleteByUserId(Long userId);

    Optional<SysUserPost> findByPostId(Long postId);
}
