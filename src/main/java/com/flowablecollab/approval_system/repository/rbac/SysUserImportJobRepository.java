package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysUserImportJob;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SysUserImportJobRepository extends JpaRepository<SysUserImportJob, Long> {
    List<SysUserImportJob> findAllByOrderByCreatedAtDesc();
}
