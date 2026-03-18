package com.flowablecollab.approval_system.repository;

import com.flowablecollab.approval_system.entity.BizRequestTask;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BizRequestTaskRepository extends JpaRepository<BizRequestTask, Long> {
    Optional<BizRequestTask> findByTaskId(String taskId);
    List<BizRequestTask> findByBusinessKey(String businessKey);
    List<BizRequestTask> findByProcessInstanceId(String processInstanceId);
}
