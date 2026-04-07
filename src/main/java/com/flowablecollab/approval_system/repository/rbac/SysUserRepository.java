package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SysUserRepository extends JpaRepository<SysUser, Long> {
    Optional<SysUser> findByUsername(String username);

    List<SysUser> findByStatusOrderByUsernameAsc(Integer status);

    List<SysUser> findByUsernameContainingIgnoreCaseOrderByUsernameAsc(String username);

    List<SysUser> findByUsernameContainingIgnoreCaseAndStatusOrderByUsernameAsc(String username, Integer status);

    Optional<SysUser> findByDeptId(Long deptId);

    List<SysUser> findAllByOrderByUsernameAsc();
}
