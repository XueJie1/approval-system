package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysDept;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SysDeptRepository extends JpaRepository<SysDept, Long> {
    Optional<SysDept> findByDeptCode(String deptCode);

    List<SysDept> findAllByOrderByDeptNameAsc();
}
