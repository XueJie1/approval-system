package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysRoleDataScope;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SysRoleDataScopeRepository extends JpaRepository<SysRoleDataScope, Long> {
    List<SysRoleDataScope> findByRoleId(Long roleId);
}
