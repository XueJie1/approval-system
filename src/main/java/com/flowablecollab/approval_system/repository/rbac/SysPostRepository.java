package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysPost;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SysPostRepository extends JpaRepository<SysPost, Long> {
    Optional<SysPost> findByPostCode(String postCode);
}
