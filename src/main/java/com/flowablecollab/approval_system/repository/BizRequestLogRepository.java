package com.flowablecollab.approval_system.repository;

import com.flowablecollab.approval_system.entity.BizRequestLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BizRequestLogRepository extends JpaRepository<BizRequestLog, Long> {
    List<BizRequestLog> findByBusinessKeyIn(List<String> businessKeys);
}
