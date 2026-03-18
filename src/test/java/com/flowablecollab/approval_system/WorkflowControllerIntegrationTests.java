package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.BizRequestTask;
import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.flowable.task.api.Task;
import org.flowable.engine.RuntimeService;
import org.flowable.engine.TaskService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WorkflowControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Autowired
    private TaskService taskService;

    @Autowired
    private RuntimeService runtimeService;

    @Test
    void startProcess_andQueryTasks_exposesSingleApprovalInRuntime() throws Exception {
        SysUser applicant = createUser("applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String businessKey = unique("wf-start");

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "Single approval request",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(businessKey, applicant.getId(), approver.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());

        mockMvc.perform(get("/api/workflow/tasks")
                        .header("Authorization", authorization(authorizationUserToken(approver)))
                        .param("assignee", approver.getUsername()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].assignee").value(approver.getUsername()));

        mockMvc.perform(get("/api/workflow/tasks")
                        .header("Authorization", authorization(authorizationUserToken(approver))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].assignee").value(approver.getUsername()));
    }

    @Test
    void getTasks_forbidsNonAdminQueryingOthersAssignee() throws Exception {
        SysUser alice = createUser("alice", "Password@123", null, "EMPLOYEE");
        SysUser bob = createUser("bob", "Password@123", null, "EMPLOYEE");

        mockMvc.perform(get("/api/workflow/tasks")
                        .header("Authorization", authorization(accessToken(alice, "EMPLOYEE")))
                        .param("assignee", bob.getUsername()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("assignee must match current login user"));
    }

    @Test
    void saveDraft_andSubmitDraft_startsProcessFromDraft() throws Exception {
        SysUser applicant = createUser("draft-applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("draft-approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        String businessKey = json(mockMvc.perform(post("/api/workflow/drafts")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Draft title",
                                  "applicantId": %d
                                }
                                """.formatted(applicant.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Draft saved"))
                .andReturn()
                .getResponse()
                .getContentAsString()).get("businessKey").asText();

        mockMvc.perform(post("/api/workflow/drafts/{businessKey}/submit", businessKey)
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "approvalSingle",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(approver.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Draft submitted successfully"))
                .andExpect(jsonPath("$.processInstanceId").isString());

        BizRequest request = bizRequestRepository.findByBusinessKey(businessKey).orElseThrow();
        assertThat(request.getStatus()).isEqualTo(2);
        assertThat(request.getProcessInstanceId()).isNotBlank();
    }

    @Test
    void saveDraft_withFormVersionLock_usesSnapshotOnSubmit() throws Exception {
        SysUser designer = createUser("draft-form-designer", "Password@123", null, "DESIGNER");
        String designerToken = accessToken(designer, "DESIGNER");
        SysUser applicant = createUser("draft-form-applicant", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String formKey = unique("draft-form");
        Long formVersionId = createFormVersionForDraft(
                designer,
                designerToken,
                formKey,
                "{\"fields\":[{\"key\":\"approverId\",\"type\":\"string\",\"required\":true}]}");

        String approverFromSnapshot = applicant.getUsername();
        String businessKey = json(mockMvc.perform(post("/api/workflow/drafts")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Draft with form snapshot",
                                  "applicantId": %d,
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "formData": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(applicant.getId(), formKey, formVersionId, approverFromSnapshot)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get("businessKey").asText();

        mockMvc.perform(post("/api/workflow/drafts/{businessKey}/submit", businessKey)
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "processKey": "approvalSingle"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());

        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();
        assertThat(task).isNotNull();
        assertThat(task.getAssignee()).isEqualTo(approverFromSnapshot);
    }

    @Test
    void startProcess_withExplicitFormVersion_usesSpecifiedVersionInsteadOfLatest() throws Exception {
        SysUser designer = createUser("start-form-designer", "Password@123", null, "DESIGNER");
        SysUser applicant = createUser("start-form-applicant", "Password@123", null, "EMPLOYEE");
        String designerToken = accessToken(designer, "DESIGNER");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String formKey = unique("start-form");

        Long v1 = createFormVersionForDraft(
                designer,
                designerToken,
                formKey,
                "{\"fields\":[{\"key\":\"approverId\",\"type\":\"string\",\"required\":true}]}");

        Long formId = formVersionRepository.findById(v1).orElseThrow().getFormId();
        // v2 adds another required field. If controller ignores explicit formVersionId, this request should fail.
        mockMvc.perform(post("/api/forms/versions")
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
                                objectMapper.writeValueAsString(
                                        "{\"fields\":[{\"key\":\"approverId\",\"type\":\"string\",\"required\":true},{\"key\":\"extraRequired\",\"type\":\"string\",\"required\":true}]}"
                                ))))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Start with explicit version",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "formData": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(applicant.getId(), formKey, v1, applicant.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());
    }

    @Test
    void claim_andComplete_endpoints_updateWorkflowState() throws Exception {
        SysUser applicant = createUser("applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String approverToken = accessToken(approver, "EMPLOYEE");
        String businessKey = unique("wf-complete");

        startSingleApproval(applicantToken, applicant.getId(), businessKey, approver.getUsername());

        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();
        taskService.setAssignee(task.getId(), null);

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/claim", task.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task claimed"));

        Task claimed = taskService.createTaskQuery().taskId(task.getId()).singleResult();
        assertThat(claimed.getAssignee()).isEqualTo(String.valueOf(approver.getId()));

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/complete", task.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "approvalResult": "APPROVE",
                                  "comments": "approved"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task completed"));

        BizRequest request = bizRequestRepository.findByBusinessKey(businessKey).orElseThrow();
        assertThat(request.getStatus()).isEqualTo(3);
    }

    @Test
    void completeTask_requiresComments() throws Exception {
        SysUser applicant = createUser("applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String approverToken = accessToken(approver, "EMPLOYEE");
        String businessKey = unique("wf-comment");

        startSingleApproval(applicantToken, applicant.getId(), businessKey, approver.getUsername());
        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/complete", task.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "approvalResult": "APPROVE",
                                  "comments": ""
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Validation failed"));
    }

    @Test
    void delegate_resolve_andReassign_endpoints_workOnActiveTask() throws Exception {
        SysUser applicant = createUser("applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("approver", "Password@123", null, "EMPLOYEE");
        SysUser delegateUser = createUser("delegate", "Password@123", null, "EMPLOYEE");
        SysUser reassignedUser = createUser("reassigned", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String approverToken = accessToken(approver, "EMPLOYEE");
        String delegateToken = accessToken(delegateUser, "EMPLOYEE");
        String businessKey = unique("wf-delegate");

        startSingleApproval(applicantToken, applicant.getId(), businessKey, approver.getUsername());
        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/delegate", task.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "delegateUserId": "%s",
                                  "comment": "please handle"
                                }
                                """.formatted(delegateUser.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task delegated"));

        Task delegated = taskService.createTaskQuery().taskId(task.getId()).singleResult();
        assertThat(delegated.getAssignee()).isEqualTo(delegateUser.getUsername());

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/resolve", task.getId())
                        .header("Authorization", authorization(delegateToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "approvalResult": "APPROVE",
                                  "comment": "checked"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task resolved"));

        Task resolved = taskService.createTaskQuery().taskId(task.getId()).singleResult();
        assertThat(resolved.getAssignee()).isEqualTo(approver.getUsername());

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/reassign", task.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "newAssigneeId": "%s",
                                  "comment": "handoff"
                                }
                                """.formatted(reassignedUser.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task reassigned"));

        Task reassigned = taskService.createTaskQuery().taskId(task.getId()).singleResult();
        assertThat(reassigned.getAssignee()).isEqualTo(reassignedUser.getUsername());
    }

    @Test
    void delegatedAssignee_cannotCompleteBeforeOwnerResolves() throws Exception {
        SysUser applicant = createUser("applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("approver", "Password@123", null, "EMPLOYEE");
        SysUser delegateUser = createUser("delegate", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String approverToken = accessToken(approver, "EMPLOYEE");
        String delegateToken = accessToken(delegateUser, "EMPLOYEE");
        String businessKey = unique("wf-delegate-complete");

        startSingleApproval(applicantToken, applicant.getId(), businessKey, approver.getUsername());
        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/delegate", task.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "delegateUserId": "%s",
                                  "comment": "please handle"
                                }
                                """.formatted(delegateUser.getUsername())))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/complete", task.getId())
                        .header("Authorization", authorization(delegateToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "approvalResult": "APPROVE",
                                  "comments": "try complete"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("delegated task can only be completed by owner"));
    }

    @Test
    void orSignCompletion_marksRemainingTasksAsAutoComplete() throws Exception {
        SysUser applicant = createUser("applicant", "Password@123", null, "EMPLOYEE");
        SysUser approverA = createUser("approver-a", "Password@123", null, "EMPLOYEE");
        SysUser approverB = createUser("approver-b", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String approverAToken = accessToken(approverA, "EMPLOYEE");
        String businessKey = unique("wf-orsign");

        String processInstanceId = json(mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "Or sign auto-complete test",
                                  "applicantId": %d,
                                  "processKey": "approvalOrSign",
                                  "countersignUsers": ["%s", "%s"]
                                }
                                """.formatted(businessKey, applicant.getId(), approverA.getUsername(), approverB.getUsername())))
                .andReturn()
                .getResponse()
                .getContentAsString()).get("processInstanceId").asText();

        Task approverTask = taskService.createTaskQuery()
                .processInstanceId(processInstanceId)
                .taskAssignee(approverA.getUsername())
                .singleResult();
        assertThat(approverTask).isNotNull();

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/complete", approverTask.getId())
                        .header("Authorization", authorization(approverAToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "approvalResult": "APPROVE",
                                  "comments": "approved"
                                }
                                """))
                .andExpect(status().isOk());

        assertThat(runtimeService.createProcessInstanceQuery().processInstanceId(processInstanceId).singleResult()).isNull();
        List<BizRequestTask> taskRecords = bizRequestTaskRepository.findByBusinessKey(businessKey);
        assertThat(taskRecords).hasSize(2);
        assertThat(taskRecords.stream().anyMatch(record -> "APPROVE".equals(record.getAction()))).isTrue();
        assertThat(taskRecords.stream().anyMatch(record -> "AUTO_COMPLETE".equals(record.getAction()))).isTrue();
        assertThat(taskRecords.stream().allMatch(record -> Integer.valueOf(3).equals(record.getStatus()))).isTrue();
    }

    @Test
    void suspendAndActivate_shouldSwitchRequestStatus() throws Exception {
        SysUser applicant = createUser("suspend-applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("suspend-approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String businessKey = unique("wf-suspend");

        String processInstanceId = startSingleApproval(applicantToken, applicant.getId(), businessKey, approver.getUsername());

        mockMvc.perform(post("/api/workflow/process/{processInstanceId}/suspend", processInstanceId)
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "comment": "pause"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Process suspended"));

        BizRequest suspended = bizRequestRepository.findByBusinessKey(businessKey).orElseThrow();
        assertThat(suspended.getStatus()).isEqualTo(7);

        mockMvc.perform(post("/api/workflow/process/{processInstanceId}/activate", processInstanceId)
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "comment": "resume"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Process activated"));

        BizRequest activated = bizRequestRepository.findByBusinessKey(businessKey).orElseThrow();
        assertThat(activated.getStatus()).isEqualTo(2);
    }

    @Test
    void suspendProcess_forbiddenForNonApplicantAndNonAdmin() throws Exception {
        SysUser applicant = createUser("suspend-owner", "Password@123", null, "EMPLOYEE");
        SysUser other = createUser("suspend-other", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String otherToken = accessToken(other, "EMPLOYEE");
        String processInstanceId = startSingleApproval(
                applicantToken,
                applicant.getId(),
                unique("wf-suspend-forbid"),
                applicant.getUsername());

        mockMvc.perform(post("/api/workflow/process/{processInstanceId}/suspend", processInstanceId)
                        .header("Authorization", authorization(otherToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "comment": "try suspend"
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("only applicant or admin can operate this request"));
    }

    @Test
    void returnAndCancelEndpoints_keepProcessControllable() throws Exception {
        SysUser applicant = createUser("applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String approverToken = accessToken(approver, "EMPLOYEE");
        String businessKey = unique("wf-return");

        String processInstanceId = startSingleApproval(applicantToken, applicant.getId(), businessKey, approver.getUsername());
        Task task = taskService.createTaskQuery().processInstanceId(processInstanceId).singleResult();

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/return", task.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "comment": "rework"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task returned"));

        Task applicantRework = taskService.createTaskQuery().processInstanceId(processInstanceId).singleResult();
        assertThat(applicantRework.getTaskDefinitionKey()).isEqualTo("singleApprovalTask");

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/return/applicant", applicantRework.getId())
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "comment": "back to applicant"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task returned to applicant"));

        Task applicantTask = taskService.createTaskQuery().processInstanceId(processInstanceId).singleResult();
        assertThat(applicantTask.getTaskDefinitionKey()).isEqualTo("applicantRework");

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/return/target", applicantTask.getId())
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "targetActivityId": "singleApprovalTask",
                                  "comment": "resubmit"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task returned to target"));

        Task returnedToTarget = taskService.createTaskQuery().processInstanceId(processInstanceId).singleResult();
        assertThat(returnedToTarget.getTaskDefinitionKey()).isEqualTo("singleApprovalTask");

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/return/previous", returnedToTarget.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "comment": "previous"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Task returned to previous"));

        mockMvc.perform(post("/api/workflow/process/{processInstanceId}/cancel", processInstanceId)
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "comment": "cancelled"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Process cancelled"));

        assertThat(runtimeService.createProcessInstanceQuery().processInstanceId(processInstanceId).singleResult()).isNull();
        assertThat(bizRequestRepository.findByProcessInstanceId(processInstanceId).orElseThrow().getStatus()).isEqualTo(6);
    }

    private String startSingleApproval(String applicantToken, Long applicantId, String businessKey, String approverId) throws Exception {
        return json(mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "Workflow test",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(businessKey, applicantId, approverId)))
                .andReturn()
                .getResponse()
                .getContentAsString()).get("processInstanceId").asText();
    }

    private String authorizationUserToken(SysUser user) {
        return accessToken(user, "EMPLOYEE");
    }

    private Long createFormVersionForDraft(SysUser designer, String designerToken, String formKey, String schemaJson) throws Exception {
        Long formId = json(mockMvc.perform(post("/api/forms/definitions")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formKey": "%s",
                                  "formName": "Draft Form"
                                }
                                """.formatted(designer.getId(), formKey)))
                .andReturn()
                .getResponse()
                .getContentAsString()).get("id").asLong();

        return json(mockMvc.perform(post("/api/forms/versions")
                        .header("Authorization", authorization(designerToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "userId": %d,
                                  "formId": %d,
                                  "schemaJson": %s
                                }
                                """.formatted(designer.getId(), formId, objectMapper.writeValueAsString(schemaJson))))
                .andReturn()
                .getResponse()
                .getContentAsString()).get("id").asLong();
    }
}
