package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class RequestControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void selfScope_onlySeesOwnRequestsTasksLogsAndProcesses() throws Exception {
        SysUser viewer = createUser("viewer", "Password@123", null, "EMPLOYEE");
        SysUser other = createUser("other", "Password@123", null, "EMPLOYEE");
        SysRole selfRole = ensureRole(unique("SELF_SCOPE").toUpperCase().replace('-', '_'));
        rbacService.assignRole(viewer.getId(), selfRole.getId());
        rbacService.addRoleDataScope(selfRole.getId(), "SELF", null);

        String viewerToken = accessToken(viewer, "EMPLOYEE");
        String otherToken = accessToken(other, "EMPLOYEE");
        startSingleApproval(viewerToken, viewer.getId(), unique("req-viewer"), viewer.getUsername());
        startSingleApproval(otherToken, other.getId(), unique("req-other"), other.getUsername());

        mockMvc.perform(get("/api/requests")
                        .header("Authorization", authorization(viewerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].applicantId").value(viewer.getId()));

        mockMvc.perform(get("/api/requests/tasks")
                        .header("Authorization", authorization(viewerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));

        mockMvc.perform(get("/api/requests/logs")
                        .header("Authorization", authorization(viewerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));

        mockMvc.perform(get("/api/requests/processes")
                        .header("Authorization", authorization(viewerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void admin_canQueryAnotherUsersRequests() throws Exception {
        SysUser admin = createUser("admin", "Admin@123", null, "ADMIN");
        SysUser employee = createUser("employee", "Password@123", null, "EMPLOYEE");
        SysRole selfRole = ensureRole(unique("EMP_SELF").toUpperCase().replace('-', '_'));
        rbacService.assignRole(employee.getId(), selfRole.getId());
        rbacService.addRoleDataScope(selfRole.getId(), "SELF", null);
        String adminToken = accessToken(admin, "ADMIN");
        String employeeToken = accessToken(employee, "EMPLOYEE");
        String businessKey = unique("req-admin-view");
        startSingleApproval(employeeToken, employee.getId(), businessKey, employee.getUsername());

        mockMvc.perform(get("/api/requests")
                        .header("Authorization", authorization(adminToken))
                        .param("userId", String.valueOf(employee.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].businessKey").value(businessKey));
    }

    @Test
    void listRequests_canFilterBySuspendedStatus() throws Exception {
        SysUser applicant = createUser("status-applicant", "Password@123", null, "EMPLOYEE");
        SysRole selfRole = ensureRole(unique("STATUS_SELF").toUpperCase().replace('-', '_'));
        rbacService.assignRole(applicant.getId(), selfRole.getId());
        rbacService.addRoleDataScope(selfRole.getId(), "SELF", null);
        String token = accessToken(applicant, "EMPLOYEE");

        String suspendedProcessId = startSingleApproval(token, applicant.getId(), unique("req-suspended"), applicant.getUsername());
        startSingleApproval(token, applicant.getId(), unique("req-running"), applicant.getUsername());

        mockMvc.perform(post("/api/workflow/process/{processInstanceId}/suspend", suspendedProcessId)
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "comment": "pause for review"
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/requests")
                        .header("Authorization", authorization(token))
                        .param("status", "7"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].status").value(7));

        mockMvc.perform(get("/api/requests/processes")
                        .header("Authorization", authorization(token))
                        .param("status", "7"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].processInstanceId").value(suspendedProcessId));
    }

    private String startSingleApproval(String applicantToken, Long applicantId, String businessKey, String approverId) throws Exception {
        return json(mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "Request visibility test",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(businessKey, applicantId, approverId)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get("processInstanceId").asText();
    }
}
