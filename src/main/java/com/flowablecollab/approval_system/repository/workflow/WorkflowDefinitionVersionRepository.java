package com.flowablecollab.approval_system.repository.workflow;

import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface WorkflowDefinitionVersionRepository extends JpaRepository<WorkflowDefinitionVersion, Long> {

    List<WorkflowDefinitionVersion> findByDefinitionIdAndIsDeletedOrderByVersionNoDesc(Long definitionId, Integer isDeleted);

    Optional<WorkflowDefinitionVersion> findByIdAndIsDeleted(Long id, Integer isDeleted);

    Optional<WorkflowDefinitionVersion> findByDefinitionIdAndStatusAndIsDeleted(Long definitionId, String status, Integer isDeleted);

    Optional<WorkflowDefinitionVersion> findByFlowableProcessDefinitionIdAndIsDeleted(String flowableProcessDefinitionId, Integer isDeleted);

    boolean existsByDefinitionIdAndVersionNoAndIsDeleted(Long definitionId, Integer versionNo, Integer isDeleted);

    long countByDefinitionIdAndIsDeleted(Long definitionId, Integer isDeleted);
}
