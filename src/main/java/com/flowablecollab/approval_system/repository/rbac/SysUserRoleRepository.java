package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysUserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface SysUserRoleRepository extends JpaRepository<SysUserRole, Long> {
    List<SysUserRole> findByUserId(Long userId);

    List<SysUserRole> findByRoleId(Long roleId);

    boolean existsByUserIdAndRoleId(Long userId, Long roleId);

    boolean existsByRoleId(Long roleId);

    @Modifying
    @Query("DELETE FROM SysUserRole ur WHERE ur.userId = :userId")
    void deleteByUserId(Long userId);
}
