package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysUserRole;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SysUserRoleRepository extends JpaRepository<SysUserRole, Long> {
    List<SysUserRole> findByUserId(Long userId);

    List<SysUserRole> findByRoleId(Long roleId);

    boolean existsByUserIdAndRoleId(Long userId, Long roleId);

    boolean existsByRoleId(Long roleId);

    void deleteByUserId(Long userId);
}
