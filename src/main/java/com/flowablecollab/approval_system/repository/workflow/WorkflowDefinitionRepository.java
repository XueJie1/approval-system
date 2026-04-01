package com.flowablecollab.approval_system.repository.workflow;

import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.Optional;

public interface WorkflowDefinitionRepository extends JpaRepository<WorkflowDefinition, Long>, JpaSpecificationExecutor<WorkflowDefinition> {

    Optional<WorkflowDefinition> findByProcessKeyAndIsDeleted(String processKey, Integer isDeleted);

    Optional<WorkflowDefinition> findByIdAndIsDeleted(Long id, Integer isDeleted);

    boolean existsByProcessKeyAndIsDeleted(String processKey, Integer isDeleted);
}
