package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FormCommandAiControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Test
    void parse_returnsStructuredDraftData_forNaturalLanguageCommand() throws Exception {
        SysUser employee = createUser("employee-ai-parse", "Password@123", null, "EMPLOYEE");
        String token = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(post("/api/ai/form-commands/parse")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "formKey": "leave_request",
                                  "command": "请假类型事假，开始时间2026-05-01 09:00:00，结束时间2026-05-02 18:00:00，请假天数2天，请假原因家中有事"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.formKey").value("leave_request"))
                .andExpect(jsonPath("$.formData.leaveType").value("事假"))
                .andExpect(jsonPath("$.formData.days").value(2.0))
                .andExpect(jsonPath("$.missingRequiredFields").isArray())
                .andExpect(jsonPath("$.confidence").isNumber());
    }

    @Test
    void parseAndStart_startsWorkflowWithParsedFormData() throws Exception {
        SysUser employee = createUser("employee-ai-start", "Password@123", null, "EMPLOYEE");
        String token = accessToken(employee, "EMPLOYEE");

        String response = mockMvc.perform(post("/api/ai/form-commands/parse-and-start")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "AI 发起请假",
                                  "formKey": "leave_request",
                                  "command": "请假类型年假，开始时间2026-06-01 09:00:00，结束时间2026-06-03 18:00:00，请假天数3天，请假原因陪伴家人",
                                  "requireAllRequiredFields": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString())
                .andExpect(jsonPath("$.formVersionId").isNumber())
                .andReturn().getResponse().getContentAsString();

        String businessKey = json(response).get("businessKey").asText();
        BizRequest request = bizRequestRepository.findByBusinessKey(businessKey).orElseThrow();

        assertThat(request.getFormVersionId()).isNotNull();
        assertThat(request.getFormInstanceId()).isNotNull();
        assertThat(request.getTitle()).isEqualTo("AI 发起请假");
    }

    @Test
    void parseAndStart_rejectsWhenTemplateLaunchRoleNotMatched() throws Exception {
        SysUser admin = createUser("ai-launch-admin", "Password@123", null, "ADMIN");
        ensureRole("BACKEND_DEV");
        SysUser backendDev = createUser("ai-launch-backend", "Password@123", null, "BACKEND_DEV");
        String adminToken = accessToken(admin, "ADMIN");
        String backendDevToken = accessToken(backendDev, "BACKEND_DEV");
        String templateKey = unique("ai_launch_role").replace('-', '_');

        mockMvc.perform(post("/api/admin/request-templates")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "templateKey": "%s",
                                  "templateName": "AI 权限模板",
                                  "formKey": "leave_request",
                                  "formName": "请假申请表",
                                  "processKey": "approvalSequential",
                                  "countersignMode": "ALL",
                                  "passRatio": "1.0",
                                  "launchRoleCodes": ["EMPLOYEE"],
                                  "sortOrder": 10,
                                  "status": "ACTIVE"
                                }
                                """.formatted(templateKey)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/ai/form-commands/parse-and-start")
                        .header("Authorization", authorization(backendDevToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "requestTemplateKey": "%s",
                                  "command": "请假类型年假，开始时间2026-06-01 09:00:00，结束时间2026-06-03 18:00:00，请假天数3天，请假原因陪伴家人",
                                  "requireAllRequiredFields": true
                                }
                                """.formatted(templateKey)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("permission denied to launch request template: " + templateKey));
    }

    @Test
    void parse_leaveDays_withDateRangeAndChineseDays_shouldNotParseYearAsDays() throws Exception {
        SysUser employee = createUser("employee-ai-days", "Password@123", null, "EMPLOYEE");
        String token = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(post("/api/ai/form-commands/parse")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "formKey": "leave_request",
                                  "command": "我要请假，开始时间2026-05-01 09:00:00，结束时间2026-05-02 18:00:00，请两天事假，请假原因家中有事"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.formData.days").value(2.0));
    }

    @Test
    void parse_travelBudget_withDateRangeAndBudget_shouldNotParseYearAsBudget() throws Exception {
        SysUser employee = createUser("employee-ai-budget", "Password@123", null, "EMPLOYEE");
        String token = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(post("/api/ai/form-commands/parse")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "formKey": "travel_request",
                                  "command": "2026-07-01 09:00:00到2026-07-03 18:00:00去上海出差，预计预算3000元，出差事由客户拜访"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.formData.budget").value(3000.0));
    }

    @Test
    void parse_travelBudget_withoutBudget_shouldKeepBudgetEmptyInsteadOfYear() throws Exception {
        SysUser employee = createUser("employee-ai-no-budget", "Password@123", null, "EMPLOYEE");
        String token = accessToken(employee, "EMPLOYEE");

        mockMvc.perform(post("/api/ai/form-commands/parse")
                        .header("Authorization", authorization(token))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "formKey": "travel_request",
                                  "command": "2026-08-01 09:00:00到2026-08-03 18:00:00去深圳出差，出差事由客户会议"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.formData.budget").doesNotExist());
    }
}
