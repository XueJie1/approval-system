package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowNodeConfigRepository;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowCatalogBootstrapService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

class WorkflowCatalogBootstrapIntegrationTests extends AbstractIntegrationTestSupport {

    @Autowired
    private WorkflowDefinitionRepository workflowDefinitionRepository;

    @Autowired
    private WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;

    @Autowired
    private WorkflowNodeConfigRepository workflowNodeConfigRepository;

    @Autowired
    private WorkflowCatalogBootstrapService workflowCatalogBootstrapService;

    @Test
    void startupBootstrapsBuiltInBpmnResourcesIntoWorkflowCatalog() {
        workflowCatalogBootstrapService.bootstrapCatalog();

        WorkflowDefinition definition = workflowDefinitionRepository.findByProcessKeyAndIsDeleted("approvalSingle", 0)
                .orElseThrow();
        WorkflowDefinitionVersion version = workflowDefinitionVersionRepository.findByIdAndIsDeleted(definition.getCurrentVersionId(), 0)
                .orElseThrow();

        assertThat(definition.getProcessName()).isEqualTo("Approval Single");
        assertThat(definition.getStatus()).isEqualTo(WorkflowDefinition.STATUS_ACTIVE);
        assertThat(definition.getCurrentVersionId()).isNotNull();

        assertThat(version.getStatus()).isEqualTo(WorkflowDefinitionVersion.STATUS_PUBLISHED);
        assertThat(version.getFlowableProcessDefinitionId()).isNotBlank();
        assertThat(version.getFlowableDeploymentId()).isNotBlank();
        assertThat(version.getBpmnXml()).contains("<process id=\"approvalSingle\"");

        assertThat(workflowNodeConfigRepository.findByDefinitionVersionIdOrderBySortOrderAscIdAsc(version.getId()))
                .isNotEmpty();
    }

    @Test
    void bootstrapIsIdempotentForAlreadyImportedBuiltInProcesses() {
        long beforeDefinitions = workflowDefinitionRepository.count();
        long beforeVersions = workflowDefinitionVersionRepository.count();

        workflowCatalogBootstrapService.bootstrapCatalog();

        assertThat(workflowDefinitionRepository.count()).isEqualTo(beforeDefinitions);
        assertThat(workflowDefinitionVersionRepository.count()).isEqualTo(beforeVersions);
    }
}
