package com.flowablecollab.approval_system.repository.rbac;

import com.flowablecollab.approval_system.entity.rbac.SysLoginLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SysLoginLogRepository extends JpaRepository<SysLoginLog, Long> {

    Page<SysLoginLog> findByUserIdOrderByLoginTimeDesc(Long userId, Pageable pageable);

    Page<SysLoginLog> findByUsernameOrderByLoginTimeDesc(String username, Pageable pageable);

    Page<SysLoginLog> findByLoginTimeBetween(LocalDateTime startTime, LocalDateTime endTime, Pageable pageable);
}