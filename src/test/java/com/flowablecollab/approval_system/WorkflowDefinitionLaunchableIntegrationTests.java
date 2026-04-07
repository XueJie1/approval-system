package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WorkflowDefinitionLaunchableIntegrationTests extends AbstractIntegrationTestSupport {

    @Autowired
    private WorkflowDefinitionRepository workflowDefinitionRepository;

    @Autowired
    private WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;

    @Test
    void launchableEndpoint_returnsOnlyActivePublishedAndDeployedDefinitions() throws Exception {
        var admin = createUser("wf-launchable-admin", "Password@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        WorkflowDefinition okDefinition = createDefinition("launchable_ok", "可发起流程", WorkflowDefinition.STATUS_ACTIVE);
        WorkflowDefinitionVersion okVersion = createVersion(okDefinition, 1, WorkflowDefinitionVersion.STATUS_PUBLISHED, "flowable:ok");
        okDefinition.setCurrentVersionId(okVersion.getId());
        workflowDefinitionRepository.save(okDefinition);

        WorkflowDefinition noDeployment = createDefinition("launchable_nodeploy", "未部署流程", WorkflowDefinition.STATUS_ACTIVE);
        WorkflowDefinitionVersion noDeploymentVersion = createVersion(noDeployment, 1, WorkflowDefinitionVersion.STATUS_PUBLISHED, null);
        noDeployment.setCurrentVersionId(noDeploymentVersion.getId());
        workflowDefinitionRepository.save(noDeployment);

        WorkflowDefinition draftVersionDefinition = createDefinition("launchable_draft", "草稿版本流程", WorkflowDefinition.STATUS_ACTIVE);
        WorkflowDefinitionVersion draftVersion = createVersion(draftVersionDefinition, 1, WorkflowDefinitionVersion.STATUS_DRAFT, "flowable:draft");
        draftVersionDefinition.setCurrentVersionId(draftVersion.getId());
        workflowDefinitionRepository.save(draftVersionDefinition);

        WorkflowDefinition inactiveDefinition = createDefinition("launchable_inactive", "停用流程", WorkflowDefinition.STATUS_INACTIVE);
        WorkflowDefinitionVersion inactiveVersion = createVersion(inactiveDefinition, 1, WorkflowDefinitionVersion.STATUS_PUBLISHED, "flowable:inactive");
        inactiveDefinition.setCurrentVersionId(inactiveVersion.getId());
        workflowDefinitionRepository.save(inactiveDefinition);

        mockMvc.perform(get("/api/admin/workflow-definitions/launchable")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.processKey=='launchable_ok')]").exists())
                .andExpect(jsonPath("$[?(@.processKey=='launchable_nodeploy')]").doesNotExist())
                .andExpect(jsonPath("$[?(@.processKey=='launchable_draft')]").doesNotExist())
                .andExpect(jsonPath("$[?(@.processKey=='launchable_inactive')]").doesNotExist());
    }

    private WorkflowDefinition createDefinition(String processKey, String processName, String status) {
        WorkflowDefinition definition = new WorkflowDefinition();
        definition.setProcessKey(processKey);
        definition.setProcessName(processName);
        definition.setStatus(status);
        definition.setLatestVersionNo(1);
        definition.setCreatedBy(1L);
        definition.setUpdatedBy(1L);
        definition.setIsDeleted(0);
        return workflowDefinitionRepository.save(definition);
    }

    private WorkflowDefinitionVersion createVersion(WorkflowDefinition definition, int versionNo, String status, String flowableProcessDefinitionId) {
        WorkflowDefinitionVersion version = new WorkflowDefinitionVersion();
        version.setDefinitionId(definition.getId());
        version.setVersionNo(versionNo);
        version.setVersionLabel("v" + versionNo);
        version.setStatus(status);
        version.setBpmnXml("<definitions />");
        version.setFlowableProcessDefinitionId(flowableProcessDefinitionId);
        version.setCreatedBy(1L);
        version.setUpdatedBy(1L);
        version.setIsDeleted(0);
        return workflowDefinitionVersionRepository.save(version);
    }
}
