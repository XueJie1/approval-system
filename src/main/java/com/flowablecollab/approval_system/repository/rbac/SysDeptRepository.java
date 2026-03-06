package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysDept;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SysDeptRepository extends JpaRepository<SysDept, Long> {
}
