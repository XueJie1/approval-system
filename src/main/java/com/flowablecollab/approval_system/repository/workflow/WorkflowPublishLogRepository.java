package com.flowablecollab.approval_system.repository.workflow;

import com.flowablecollab.approval_system.entity.workflow.WorkflowPublishLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;

public interface WorkflowPublishLogRepository extends JpaRepository<WorkflowPublishLog, Long>, JpaSpecificationExecutor<WorkflowPublishLog> {

    List<WorkflowPublishLog> findByDefinitionVersionIdOrderByOperatedAtDesc(Long definitionVersionId);
}
