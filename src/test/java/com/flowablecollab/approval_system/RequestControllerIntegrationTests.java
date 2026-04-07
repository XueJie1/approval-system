package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.rbac.SysRole;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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

    @Test
    void listAiSuggestions_returnsGeneratedSuggestionForVisibleRequest() throws Exception {
        SysUser viewer = createUser("ai-viewer", "Password@123", null, "EMPLOYEE");
        SysRole selfRole = ensureRole(unique("AI_SELF").toUpperCase().replace('-', '_'));
        rbacService.assignRole(viewer.getId(), selfRole.getId());
        rbacService.addRoleDataScope(selfRole.getId(), "SELF", null);
        String viewerToken = accessToken(viewer, "EMPLOYEE");
        String businessKey = unique("req-ai");

        startSingleApproval(viewerToken, viewer.getId(), businessKey, viewer.getUsername());
        String taskId = json(mockMvc.perform(get("/api/workflow/tasks")
                        .header("Authorization", authorization(viewerToken)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get(0).get("taskId").asText();

        mockMvc.perform(get("/api/workflow/tasks/{taskId}/ai-suggestion", taskId)
                        .header("Authorization", authorization(viewerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recordId").isNumber());

        mockMvc.perform(get("/api/requests/ai-suggestions")
                        .header("Authorization", authorization(viewerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].businessKey").value(businessKey))
                .andExpect(jsonPath("$[0].recordId").isNumber());
    }

    @Test
    void activeTemplateEndpoint_hidesInactiveTemplates() throws Exception {
        SysUser admin = createUser("template-admin", "Password@123", null, "ADMIN");
        String adminToken = accessToken(admin, "ADMIN");

        mockMvc.perform(post("/api/admin/request-templates")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "templateKey": "inactive_demo",
                                  "templateName": "停用模板",
                                  "processKey": "approvalSingle",
                                  "countersignMode": "ALL",
                                  "passRatio": "1.0",
                                  "sortOrder": 999,
                                  "status": "INACTIVE"
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/request-templates")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.templateKey=='inactive_demo')]").doesNotExist());
    }

    @Test
    void adminTemplateList_returnsUsageCountForTemplate() throws Exception {
        SysUser admin = createUser("template-usage-admin", "Password@123", null, "ADMIN");
        SysUser applicant = createUser("template-usage-employee", "Password@123", null, "EMPLOYEE");
        String adminToken = accessToken(admin, "ADMIN");
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        mockMvc.perform(post("/api/admin/request-templates")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "templateKey": "usage_demo",
                                  "templateName": "使用统计测试模板",
                                  "processKey": "approvalSingle",
                                  "countersignMode": "ALL",
                                  "passRatio": "1.0",
                                  "allowManualApproverSelect": true,
                                  "sortOrder": 999,
                                  "status": "ACTIVE"
                                }
                                """))
                .andExpect(status().isOk());

        startSingleApproval(applicantToken, applicant.getId(), unique("req-template-usage"), applicant.getUsername(), "usage_demo");

        mockMvc.perform(get("/api/admin/request-templates")
                        .header("Authorization", authorization(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.templateKey=='usage_demo')].usageCount").value(org.hamcrest.Matchers.hasItem(1)));
    }

    @Test
    void activeTemplateEndpoint_returnsBuiltInTemplatesWithManualApproverDisabled() throws Exception {
        SysUser employee = createUser("template-reader", "Password@123", null, "EMPLOYEE");
        String token = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(get("/api/request-templates")
                        .header("Authorization", authorization(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.templateKey=='leave')].allowManualApproverSelect").value(org.hamcrest.Matchers.hasItem(false)))
                .andExpect(jsonPath("$[?(@.templateKey=='leave')].approvalConfig[0].rules[0].steps[0].type").doesNotExist())
                .andExpect(jsonPath("$[?(@.templateKey=='expense')].allowManualApproverSelect").value(org.hamcrest.Matchers.hasItem(false)));
    }

    @Test
    void adminTemplateUpdate_persistsApprovalConfigAndManualApproverFlag() throws Exception {
        SysUser admin = createUser("template-config-admin", "Password@123", null, "ADMIN");
        SysUser reviewer = createUser("template-fixed-reviewer", "Password@123", null, "EMPLOYEE");
        String adminToken = accessToken(admin, "ADMIN");

        String templateKey = unique("template-config-demo").replace('-', '_');
        Long templateId = json(mockMvc.perform(post("/api/admin/request-templates")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "templateKey": "%s",
                                  "templateName": "测试模板",
                                  "category": "测试",
                                  "description": "用于测试审批规则配置保存。",
                                  "processKey": "approvalSequential",
                                  "countersignMode": "ALL",
                                  "passRatio": "1.0",
                                  "flowSummary": "测试模板初始配置",
                                  "sortOrder": 10,
                                  "status": "ACTIVE"
                                }
                                """.formatted(templateKey)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get("id").asLong();

        mockMvc.perform(put("/api/admin/request-templates/{id}", templateId)
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "templateKey": "%s",
                                  "templateName": "测试模板",
                                  "category": "测试",
                                  "description": "用于测试审批规则配置保存。",
                                  "processKey": "approvalSequential",
                                  "countersignMode": "ALL",
                                  "passRatio": "1.0",
                                  "flowSummary": "测试审批规则配置",
                                  "allowManualApproverSelect": true,
                                  "approvalConfig": {
                                    "rules": [
                                      {
                                        "name": "测试规则",
                                        "conditions": [],
                                        "steps": [
                                          { "type": "SPECIFIC_USER", "userId": %d },
                                          { "type": "DEPT_LEADER" }
                                        ]
                                      }
                                    ]
                                  },
                                  "sortOrder": 10,
                                  "status": "ACTIVE"
                                }
                                """.formatted(templateKey, reviewer.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.allowManualApproverSelect").value(true))
                .andExpect(jsonPath("$.approvalConfig.rules[0].steps[0].type").value("SPECIFIC_USER"))
                .andExpect(jsonPath("$.approvalConfig.rules[0].steps[0].userId").value(reviewer.getId()));
    }

    private String startSingleApproval(String applicantToken, Long applicantId, String businessKey, String approverId) throws Exception {
        return startSingleApproval(applicantToken, applicantId, businessKey, approverId, null);
    }

    private String startSingleApproval(String applicantToken, Long applicantId, String businessKey, String approverId, String requestTemplateKey) throws Exception {
        return json(mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "Request visibility test",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "requestTemplateKey": %s,
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(
                                        businessKey,
                                        applicantId,
                                        requestTemplateKey == null ? "null" : ("\"" + requestTemplateKey + "\""),
                                        approverId)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get("processInstanceId").asText();
    }
}
