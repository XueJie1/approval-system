package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WorkflowManagementIntegrationTests extends AbstractIntegrationTestSupport {

    @Autowired
    private WorkflowDefinitionRepository workflowDefinitionRepository;

    @Autowired
    private WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;

    @Autowired
    private BizRequestRepository bizRequestRepository;

    @Test
    void publishVersion_andStartProcess_bindsCurrentVersionToBizRequest() throws Exception {
        SysUser admin = createUser("wf-admin", "Password@123", null, "SYS_ADMIN");
        SysUser designer = createUser("wf-designer", "Password@123", null, "DESIGNER");
        SysUser applicant = createUser("wf-applier", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("wf-approver", "Password@123", null, "EMPLOYEE");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String designerToken = accessToken(designer, "DESIGNER");
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        String processKey = unique("wfdef").replace('-', '_');
        Long formVersionId = createFormVersionForWorkflow(designer, designerToken, processKey + "_form");

        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Approval Single Managed",
                                  "category": "OA"
                                }
                                """.formatted(processKey)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processKey").value(processKey))
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        Long versionId = json(mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DRAFT"))
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "versionLabel": "v1",
                                  "bpmnXml": %s,
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "changeSummary": "initial publish"
                                }
                                """.formatted(objectMapper.writeValueAsString(managedApprovalSingleBpmn(processKey)), processKey + "_form", formVersionId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.formVersionId").value(formVersionId));

        syncNodeConfigs(adminToken, versionId);

        mockMvc.perform(post("/api/admin/workflow-definition-versions/{versionId}/publish", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{" + "\"comment\":\"publish v1\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PUBLISHED"));

        String businessKey = unique("wf-launch");
        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "Managed request",
                                  "applicantId": %d,
                                  "processKey": "%s",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(businessKey, applicant.getId(), processKey, approver.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());

        BizRequest request = bizRequestRepository.findByBusinessKey(businessKey).orElseThrow();
        assertThat(request.getWorkflowDefinitionId()).isEqualTo(definitionId);
        assertThat(request.getWorkflowDefinitionVersionId()).isEqualTo(versionId);
        assertThat(request.getFormVersionId()).isEqualTo(formVersionId);
        assertThat(request.getProcessDefinitionId()).isNotBlank();
    }

    @Test
    void publishSecondVersion_inactivatesPreviousPublishedVersion() throws Exception {
        SysUser admin = createUser("wf-admin2", "Password@123", null, "SYS_ADMIN");
        SysUser designer = createUser("wf-des2", "Password@123", null, "DESIGNER");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String designerToken = accessToken(designer, "DESIGNER");
        String processKey = unique("wfpub").replace('-', '_');
        Long formVersionId = createFormVersionForWorkflow(designer, designerToken, processKey + "_form");

        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Managed Workflow"
                                }
                                """.formatted(processKey)))
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        Long version1 = createAndPublishVersion(adminToken, definitionId, processKey, processKey + "_form", formVersionId, "v1");
        Long version2 = json(mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{\"copyFromVersionId\":" + version1 + "}"))
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        mockMvc.perform(post("/api/admin/workflow-definition-versions/{versionId}/publish", version2)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{" + "\"comment\":\"publish v2\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PUBLISHED"));

        assertThat(workflowDefinitionVersionRepository.findById(version1).orElseThrow().getStatus()).isEqualTo("INACTIVE");
        assertThat(workflowDefinitionVersionRepository.findById(version2).orElseThrow().getStatus()).isEqualTo("PUBLISHED");
        assertThat(workflowDefinitionRepository.findById(definitionId).orElseThrow().getCurrentVersionId()).isEqualTo(version2);
    }

    @Test
    void inactiveDefinition_blocksNewLaunch() throws Exception {
        SysUser admin = createUser("wf-admin3", "Password@123", null, "SYS_ADMIN");
        SysUser designer = createUser("wf-des3", "Password@123", null, "DESIGNER");
        SysUser applicant = createUser("wf-app3", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("wf-aprv3", "Password@123", null, "EMPLOYEE");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String designerToken = accessToken(designer, "DESIGNER");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String processKey = unique("wfinact").replace('-', '_');
        Long formVersionId = createFormVersionForWorkflow(designer, designerToken, processKey + "_form");

        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Inactive Workflow"
                                }
                                """.formatted(processKey)))
                .andReturn().getResponse().getContentAsString()).get("id").asLong();
        Long versionId = createAndPublishVersion(adminToken, definitionId, processKey, processKey + "_form", formVersionId, "v1");

        mockMvc.perform(post("/api/admin/workflow-definition-versions/{versionId}/inactivate", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Blocked request",
                                  "applicantId": %d,
                                  "processKey": "%s",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(applicant.getId(), processKey, approver.getUsername())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("workflow definition is not active"));
    }

    @Test
    void createDraft_withoutCopy_generatesDefaultBpmnSkeleton() throws Exception {
        SysUser admin = createUser("wf-admin-skel", "Password@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        String processKey = unique("wfskel").replace('-', '_');
        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Skeleton Workflow"
                                }
                                """.formatted(processKey)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bpmnXml").isString())
                .andExpect(jsonPath("$.bpmnXml").value(containsString("<bpmn:process id=\"%s\"".formatted(processKey))))
                .andExpect(jsonPath("$.bpmnXml").value(containsString("Activity_Approve")));
    }

    @Test
    void saveDraft_withProcessKeyMismatch_returnsStructuredCode() throws Exception {
        SysUser admin = createUser("wf-admin-key", "Password@123", null, "SYS_ADMIN");
        SysUser designer = createUser("wf-des-key", "Password@123", null, "DESIGNER");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String designerToken = accessToken(designer, "DESIGNER");

        String processKey = unique("wfkey").replace('-', '_');
        Long formVersionId = createFormVersionForWorkflow(designer, designerToken, processKey + "_form");

        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Key Mismatch Workflow"
                                }
                                """.formatted(processKey)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        Long versionId = json(mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "versionLabel": "v1",
                                  "bpmnXml": %s,
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "changeSummary": "key mismatch"
                                }
                                """.formatted(objectMapper.writeValueAsString(managedApprovalSingleBpmn(processKey + "_other")), processKey + "_form", formVersionId)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("BPMN_KEY_MISMATCH"));
    }

    @Test
    void saveDraft_withMultipleProcesses_returnsStructuredCode() throws Exception {
        SysUser admin = createUser("wf-admin-multi", "Password@123", null, "SYS_ADMIN");
        SysUser designer = createUser("wf-des-multi", "Password@123", null, "DESIGNER");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String designerToken = accessToken(designer, "DESIGNER");

        String processKey = unique("wfmulti").replace('-', '_');
        Long formVersionId = createFormVersionForWorkflow(designer, designerToken, processKey + "_form");

        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Multi Process Workflow"
                                }
                                """.formatted(processKey)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        Long versionId = json(mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        String multiProcessXml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL" targetNamespace="http://flowable.org/examples">
                  <process id="%s" isExecutable="true">
                    <startEvent id="start1" />
                  </process>
                  <process id="%s_2" isExecutable="true">
                    <startEvent id="start2" />
                  </process>
                </definitions>
                """.formatted(processKey, processKey);

        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "versionLabel": "v1",
                                  "bpmnXml": %s,
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "changeSummary": "multi process"
                                }
                                """.formatted(objectMapper.writeValueAsString(multiProcessXml), processKey + "_form", formVersionId)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("BPMN_PROCESS_COUNT_INVALID"));
    }

    @Test
    void saveDraft_withoutFormVersion_returnsStructuredCode() throws Exception {
        SysUser admin = createUser("wf-admin-form", "Password@123", null, "SYS_ADMIN");
        String adminToken = accessToken(admin, "SYS_ADMIN");

        String processKey = unique("wfform").replace('-', '_');
        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Form Required Workflow"
                                }
                                """.formatted(processKey)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        Long versionId = json(mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "versionLabel": "v1",
                                  "bpmnXml": %s,
                                  "changeSummary": "missing form version"
                                }
                                """.formatted(objectMapper.writeValueAsString(managedApprovalSingleBpmn(processKey)))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("FORM_VERSION_REQUIRED"));
    }

    @Test
    void publish_withoutNodeConfig_returnsNodeMismatchCode() throws Exception {
        SysUser admin = createUser("wf-admin-node", "Password@123", null, "SYS_ADMIN");
        SysUser designer = createUser("wf-des-node", "Password@123", null, "DESIGNER");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String designerToken = accessToken(designer, "DESIGNER");

        String processKey = unique("wfnode").replace('-', '_');
        Long formVersionId = createFormVersionForWorkflow(designer, designerToken, processKey + "_form");

        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Node Mismatch Workflow"
                                }
                                """.formatted(processKey)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        Long versionId = json(mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "versionLabel": "v1",
                                  "bpmnXml": %s,
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "changeSummary": "node mismatch"
                                }
                                """.formatted(objectMapper.writeValueAsString(managedApprovalSingleBpmn(processKey)), processKey + "_form", formVersionId)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/admin/workflow-definition-versions/{versionId}/publish", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("NODE_CONFIG_MISMATCH"));
    }

    @Test
    void publish_withNodeConfigContainingUnknownNode_returnsNodeMismatchCode() throws Exception {
        SysUser admin = createUser("wf-admin-node", "Password@123", null, "SYS_ADMIN");
        SysUser designer = createUser("wf-des-node", "Password@123", null, "DESIGNER");
        String adminToken = accessToken(admin, "SYS_ADMIN");
        String designerToken = accessToken(designer, "DESIGNER");

        String processKey = unique("wfnode").replace('-', '_');
        Long formVersionId = createFormVersionForWorkflow(designer, designerToken, processKey + "_form");

        Long definitionId = json(mockMvc.perform(post("/api/admin/workflow-definitions")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "%s",
                                  "processName": "Node Mismatch Workflow"
                                }
                                """.formatted(processKey)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        Long versionId = json(mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("id").asLong();

        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "versionLabel": "v1",
                                  "bpmnXml": %s,
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "changeSummary": "node mismatch"
                                }
                                """.formatted(objectMapper.writeValueAsString(managedApprovalSingleBpmn(processKey)), processKey + "_form", formVersionId)))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}/nodes", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "nodes": [
                                    {
                                      "nodeId": "UNKNOWN_NODE",
                                      "nodeName": "Unknown",
                                      "nodeType": "USER_TASK"
                                    }
                                  ]
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("NODE_CONFIG_MISMATCH"));
    }

    private Long createAndPublishVersion(String adminToken, Long definitionId, String processKey, String formKey,
            Long formVersionId, String label) throws Exception {
        Long versionId = json(mockMvc.perform(post("/api/admin/workflow-definitions/{definitionId}/versions", definitionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andReturn().getResponse().getContentAsString()).get("id").asLong();
        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "versionLabel": "%s",
                                  "bpmnXml": %s,
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "changeSummary": "publish %s"
                                }
                                """.formatted(label, objectMapper.writeValueAsString(managedApprovalSingleBpmn(processKey)), formKey, formVersionId, label)))
                .andExpect(status().isOk());
        syncNodeConfigs(adminToken, versionId);
        mockMvc.perform(post("/api/admin/workflow-definition-versions/{versionId}/publish", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());
        return versionId;
    }

    private void syncNodeConfigs(String adminToken, Long versionId) throws Exception {
        String nodesJson = mockMvc.perform(get("/api/admin/workflow-definition-versions/{versionId}/nodes", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        mockMvc.perform(put("/api/admin/workflow-definition-versions/{versionId}/nodes", versionId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("{\"nodes\":" + nodesJson + "}"))
                .andExpect(status().isOk());
    }

    private Long createFormVersionForWorkflow(SysUser designer, String designerToken, String formKey) throws Exception {
        Long formId = json(mockMvc.perform(post("/api/forms/definitions")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formKey": "%s",
                                  "formName": "Workflow Form"
                                }
                                """.formatted(designer.getId(), formKey)))
                .andReturn().getResponse().getContentAsString()).get("id").asLong();
        return json(mockMvc.perform(post("/api/forms/versions")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formId": %d,
                                  "schemaJson": %s
                                }
                                """.formatted(
                                designer.getId(),
                                formId,
                                objectMapper.writeValueAsString("{\"fields\":[{\"key\":\"approverId\",\"type\":\"string\",\"required\":true}]}"))))
                .andReturn().getResponse().getContentAsString()).get("id").asLong();
    }

    private String managedApprovalSingleBpmn(String processKey) {
        return """
                <?xml version="1.0" encoding="UTF-8"?>
                <definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
                             xmlns:flowable="http://flowable.org/bpmn"
                             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                             targetNamespace="http://flowable.org/examples">
                  <process id="%s" name="Managed Approval Single" isExecutable="true">
                    <startEvent id="start" name="Start"/>
                    <sequenceFlow id="flow1" sourceRef="start" targetRef="singleApprovalTask"/>
                    <userTask id="singleApprovalTask" name="Single Approval Task" flowable:assignee="${approverId}">
                      <extensionElements>
                        <flowable:taskListener event="complete" delegateExpression="${singleApprovalTaskListener}"/>
                      </extensionElements>
                    </userTask>
                    <userTask id="applicantRework" name="Applicant Rework" flowable:assignee="${applicantId}"/>
                    <sequenceFlow id="flowReworkToApproval" sourceRef="applicantRework" targetRef="singleApprovalTask"/>
                    <sequenceFlow id="flow2" sourceRef="singleApprovalTask" targetRef="decision"/>
                    <exclusiveGateway id="decision" name="Decision"/>
                    <sequenceFlow id="flow3" sourceRef="decision" targetRef="approveEnd" name="Approve">
                      <conditionExpression xsi:type="tFormalExpression">${approvalResult == 'APPROVE'}</conditionExpression>
                    </sequenceFlow>
                    <sequenceFlow id="flow4" sourceRef="decision" targetRef="rejectEnd" name="Reject">
                      <conditionExpression xsi:type="tFormalExpression">${approvalResult == 'REJECT'}</conditionExpression>
                    </sequenceFlow>
                    <endEvent id="approveEnd" name="Approved"/>
                    <endEvent id="rejectEnd" name="Rejected"/>
                  </process>
                </definitions>
                """.formatted(processKey);
    }
}
