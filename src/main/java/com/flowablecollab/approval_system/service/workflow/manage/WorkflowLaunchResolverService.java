package com.flowablecollab.approval_system.service.workflow.manage;

import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WorkflowLaunchResolverService {

    private static final int NOT_DELETED = 0;

    private final WorkflowDefinitionRepository workflowDefinitionRepository;
    private final WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;

    @Transactional(readOnly = true)
    public WorkflowManageDtos.WorkflowLaunchDefinition resolveCurrentLaunchDefinition(String processKey) {
        WorkflowDefinition definition = workflowDefinitionRepository.findByProcessKeyAndIsDeleted(processKey, NOT_DELETED)
                .orElse(null);
        if (definition == null) {
            return null;
        }
        if (WorkflowDefinition.STATUS_ARCHIVED.equals(definition.getStatus())) {
            throw new IllegalArgumentException("workflow definition is archived");
        }
        if (!WorkflowDefinition.STATUS_ACTIVE.equals(definition.getStatus())) {
            throw new IllegalArgumentException("workflow definition is not active");
        }
        if (definition.getCurrentVersionId() == null) {
            throw new IllegalArgumentException("workflow definition has no published version");
        }
        WorkflowDefinitionVersion version = workflowDefinitionVersionRepository
                .findByIdAndIsDeleted(definition.getCurrentVersionId(), NOT_DELETED)
                .orElseThrow(() -> new IllegalArgumentException("workflow definition current version not found"));
        if (!WorkflowDefinitionVersion.STATUS_PUBLISHED.equals(version.getStatus())) {
            throw new IllegalArgumentException("workflow definition current version is not published");
        }
        if (version.getFlowableProcessDefinitionId() == null || version.getFlowableProcessDefinitionId().isBlank()) {
            throw new IllegalArgumentException("workflow definition current version is not deployed");
        }
        WorkflowManageDtos.WorkflowLaunchDefinition launch = new WorkflowManageDtos.WorkflowLaunchDefinition();
        launch.setDefinitionId(definition.getId());
        launch.setVersionId(version.getId());
        launch.setVersionNo(version.getVersionNo());
        launch.setProcessKey(definition.getProcessKey());
        launch.setFlowableProcessDefinitionId(version.getFlowableProcessDefinitionId());
        launch.setFormKey(version.getFormKey());
        launch.setFormVersionId(version.getFormVersionId());
        return launch;
    }
}
