package com.flowablecollab.approval_system.repository.workflow;

import com.flowablecollab.approval_system.entity.workflow.WorkflowNodeConfig;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface WorkflowNodeConfigRepository extends JpaRepository<WorkflowNodeConfig, Long> {

    List<WorkflowNodeConfig> findByDefinitionVersionIdOrderBySortOrderAscIdAsc(Long definitionVersionId);

    Optional<WorkflowNodeConfig> findByDefinitionVersionIdAndNodeId(Long definitionVersionId, String nodeId);

    void deleteByDefinitionVersionId(Long definitionVersionId);
}
