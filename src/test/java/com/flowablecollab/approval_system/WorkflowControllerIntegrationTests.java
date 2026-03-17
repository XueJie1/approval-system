package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.flowable.task.api.Task;
import org.flowable.engine.RuntimeService;
import org.flowable.engine.TaskService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

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
}
