package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysUserImportJobItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SysUserImportJobItemRepository extends JpaRepository<SysUserImportJobItem, Long> {
    List<SysUserImportJobItem> findByJobIdOrderByRowNoAsc(Long jobId);

    void deleteByJobId(Long jobId);
}
