package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.BizRequestTask;
import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.rbac.SysDept;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.service.TaskAiSuggestionService;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WorkflowControllerIntegrationTests extends AbstractIntegrationTestSupport {

    @Autowired
    private TaskService taskService;

    @Autowired
    private RuntimeService runtimeService;

    @Autowired
    private TaskAiSuggestionService taskAiSuggestionService;

    private SysDept createDept(String code, String name) {
        SysDept dept = new SysDept();
        dept.setDeptCode(code);
        dept.setDeptName(name);
        return sysDeptRepository.save(dept);
    }

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
    void leaveRequest_autoAssignsManagerAsApprover() throws Exception {
        SysDept dept = sysDeptRepository.save(createDept("LEAVE_TEAM", "Leave Team"));
        SysUser manager = createUser("leave-manager", "Password@123", dept.getId(), "EMPLOYEE");
        SysUser applicant = createUser("leave-applicant", "Password@123", dept.getId(), "EMPLOYEE");
        applicant.setManagerUserId(manager.getId());
        sysUserRepository.save(applicant);
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        String businessKey = unique("leave-auto-manager");

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "请假申请",
                                  "applicantId": %d,
                                  "applicantDeptId": %d,
                                  "requestTemplateKey": "leave",
                                  "processKey": "approvalSequential",
                                  "variables": {}
                                }
                                """.formatted(businessKey, applicant.getId(), dept.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());

        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();
        assertThat(task).isNotNull();
        assertThat(task.getAssignee()).isEqualTo(String.valueOf(manager.getId()));
    }

    @Test
    void leaveRequest_fallsBackToDepartmentLeaderWhenManagerMissing() throws Exception {
        SysUser leader = createUser("leave-leader", "Password@123", null, "EMPLOYEE");
        SysDept dept = createDept("LEAVE_DEPT", "Leave Department");
        dept.setLeaderUserId(leader.getId());
        dept = sysDeptRepository.save(dept);
        SysUser applicant = createUser("leave-no-manager", "Password@123", dept.getId(), "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        String businessKey = unique("leave-auto-leader");

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "请假申请",
                                  "applicantId": %d,
                                  "applicantDeptId": %d,
                                  "requestTemplateKey": "leave",
                                  "processKey": "approvalSequential",
                                  "variables": {}
                                }
                                """.formatted(businessKey, applicant.getId(), dept.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());

        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();
        assertThat(task).isNotNull();
        assertThat(task.getAssignee()).isEqualTo(String.valueOf(leader.getId()));
    }

    @Test
    void leaveRequest_escalatesToSequentialApprovalWhenLeaveDaysExceedThreshold() throws Exception {
        SysUser parentLeader = createUser("parent-leader", "Password@123", null, "EMPLOYEE");
        SysDept parentDept = createDept("HQ", "Headquarters");
        parentDept.setLeaderUserId(parentLeader.getId());
        parentDept = sysDeptRepository.save(parentDept);

        SysUser deptLeader = createUser("dept-leader", "Password@123", null, "EMPLOYEE");
        SysDept dept = createDept("OPS", "Operations");
        dept.setParentId(parentDept.getId());
        dept.setLeaderUserId(deptLeader.getId());
        dept = sysDeptRepository.save(dept);

        SysUser manager = createUser("line-manager", "Password@123", dept.getId(), "EMPLOYEE");
        SysUser applicant = createUser("long-leave-applicant", "Password@123", dept.getId(), "EMPLOYEE");
        applicant.setManagerUserId(manager.getId());
        sysUserRepository.save(applicant);
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        String businessKey = unique("leave-sequential");

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "长请假申请",
                                  "applicantId": %d,
                                  "applicantDeptId": %d,
                                  "requestTemplateKey": "leave",
                                  "processKey": "approvalSequential",
                                  "variables": {
                                    "days": 4
                                  }
                                }
                                """.formatted(businessKey, applicant.getId(), dept.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());

        List<Task> tasks = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).list();
        assertThat(tasks).hasSize(1);
        assertThat(tasks.get(0).getAssignee()).isEqualTo(String.valueOf(manager.getId()));

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/complete", tasks.get(0).getId())
                        .header("Authorization", authorization(accessToken(manager, "EMPLOYEE")))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "approvalResult": "APPROVE",
                                  "comments": "agree"
                                }
                                """))
                .andExpect(status().isOk());

        Task secondTask = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();
        assertThat(secondTask).isNotNull();
        assertThat(secondTask.getAssignee()).isEqualTo(String.valueOf(deptLeader.getId()));
    }

    @Test
    void leaveTemplateSpecificApproverConfig_takesEffectAtRuntime() throws Exception {
        SysUser admin = createUser("leave-template-admin", "Password@123", null, "ADMIN");
        SysUser fixedApprover = createUser("leave-fixed-approver", "Password@123", null, "EMPLOYEE");
        SysDept dept = sysDeptRepository.save(createDept("LEAVE_CFG", "Leave Config Dept"));
        SysUser applicant = createUser("leave-config-applicant", "Password@123", dept.getId(), "EMPLOYEE");
        String adminToken = accessToken(admin, "ADMIN");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String templateKey = unique("runtime-template").replace('-', '_');

        mockMvc.perform(post("/api/admin/request-templates")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "templateKey": "%s",
                                  "templateName": "运行时审批模板",
                                  "category": "测试",
                                  "description": "用于测试动态审批人。",
                                  "processKey": "approvalSingle",
                                  "countersignMode": "ALL",
                                  "passRatio": "1.0",
                                  "flowSummary": "固定审批人测试",
                                  "allowManualApproverSelect": false,
                                  "approvalConfig": {
                                    "rules": [
                                      {
                                        "name": "固定审批人",
                                        "conditions": [],
                                        "steps": [
                                          { "type": "SPECIFIC_USER", "userId": %d }
                                        ]
                                      }
                                    ]
                                  },
                                  "sortOrder": 10,
                                  "status": "ACTIVE"
                                }
                                """.formatted(templateKey, fixedApprover.getId())))
                .andExpect(status().isOk());

        String businessKey = unique("leave-config-runtime");
        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "请假申请",
                                  "applicantId": %d,
                                  "applicantDeptId": %d,
                                  "requestTemplateKey": "%s",
                                  "processKey": "approvalSequential",
                                  "variables": {}
                                }
                                """.formatted(businessKey, applicant.getId(), dept.getId(), templateKey)))
                .andExpect(status().isOk());

        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();
        assertThat(task).isNotNull();
        assertThat(task.getAssignee()).isEqualTo(String.valueOf(fixedApprover.getId()));
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
    void startProcess_rejectsAdminAsSingleApprover() throws Exception {
        SysUser applicant = createUser("applicant-no-admin-approver", "Password@123", null, "EMPLOYEE");
        SysUser admin = createUser("admin-approver", "Password@123", null, "ADMIN");
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Single approval request",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(applicant.getId(), admin.getUsername())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("ADMIN accounts cannot be approvers"));
    }

    @Test
    void startProcess_rejectsAdminAsCountersignApprover() throws Exception {
        SysUser applicant = createUser("applicant-no-admin-countersign", "Password@123", null, "EMPLOYEE");
        SysUser reviewer = createUser("valid-reviewer", "Password@123", null, "EMPLOYEE");
        SysUser admin = createUser("admin-countersign", "Password@123", null, "ADMIN");
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Countersign request",
                                  "applicantId": %d,
                                  "processKey": "approvalCountersign",
                                  "countersignUsers": ["%d", "%d"]
                                }
                                """.formatted(applicant.getId(), reviewer.getId(), admin.getId())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("ADMIN accounts cannot be approvers"));
    }

    @Test
    void startProcess_withoutTemplateKey_requiresEmployeeRoleByDefault() throws Exception {
        ensureRole("BACKEND_DEV");
        SysUser applicant = createUser("backend-no-template", "Password@123", null, "BACKEND_DEV");
        String applicantToken = accessToken(applicant, "BACKEND_DEV");

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "No template launch",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "variables": {
                                    "approverId": "%d"
                                  }
                                }
                                """.formatted(applicant.getId(), applicant.getId())))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("permission denied: launch requires EMPLOYEE role"));
    }

    @Test
    void startProcess_allowsLaunchWhenTemplateRoleMatches() throws Exception {
        SysUser admin = createUser("launch-role-admin", "Password@123", null, "ADMIN");
        ensureRole("BACKEND_DEV");
        SysUser applicant = createUser("launch-role-backend", "Password@123", null, "BACKEND_DEV");
        SysUser approver = createUser("launch-role-approver", "Password@123", null, "EMPLOYEE");
        String adminToken = accessToken(admin, "ADMIN");
        String applicantToken = accessToken(applicant, "BACKEND_DEV");
        String templateKey = unique("launch_backend").replace('-', '_');
        String businessKey = unique("launch-role-pass");

        mockMvc.perform(post("/api/admin/request-templates")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "templateKey": "%s",
                                  "templateName": "后端发起模板",
                                  "processKey": "approvalSingle",
                                  "countersignMode": "ALL",
                                  "passRatio": "1.0",
                                  "launchRoleCodes": ["BACKEND_DEV"],
                                  "sortOrder": 10,
                                  "status": "ACTIVE"
                                }
                                """.formatted(templateKey)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/workflow/requests")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "businessKey": "%s",
                                  "title": "Template role launch",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "requestTemplateKey": "%s",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(businessKey, applicant.getId(), templateKey, approver.getUsername())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());
    }

    @Test
    void submitDraft_usesDraftTemplateKeyForLaunchPermission() throws Exception {
        SysUser admin = createUser("draft-role-admin", "Password@123", null, "ADMIN");
        ensureRole("BACKEND_DEV");
        SysUser applicant = createUser("draft-role-employee", "Password@123", null, "EMPLOYEE");
        String adminToken = accessToken(admin, "ADMIN");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String templateKey = unique("draft_backend").replace('-', '_');

        mockMvc.perform(post("/api/admin/request-templates")
                        .header("Authorization", authorization(adminToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "templateKey": "%s",
                                  "templateName": "草稿权限模板",
                                  "processKey": "approvalSingle",
                                  "countersignMode": "ALL",
                                  "passRatio": "1.0",
                                  "launchRoleCodes": ["BACKEND_DEV"],
                                  "sortOrder": 10,
                                  "status": "ACTIVE"
                                }
                                """.formatted(templateKey)))
                .andExpect(status().isOk());

        String businessKey = json(mockMvc.perform(post("/api/workflow/drafts")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Draft with restricted template",
                                  "applicantId": %d,
                                  "requestTemplateKey": "%s"
                                }
                                """.formatted(applicant.getId(), templateKey)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get("businessKey").asText();

        mockMvc.perform(post("/api/workflow/drafts/{businessKey}/submit", businessKey)
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Submit restricted draft",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "variables": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(applicant.getId(), applicant.getUsername())))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("permission denied to launch request template: " + templateKey));
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
    void submitDraft_withFrontendDefaultCountersignPayload_startsProcess() throws Exception {
        SysUser applicant = createUser("draft-default-countersign", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");

        String businessKey = json(mockMvc.perform(post("/api/workflow/drafts")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Draft default countersign",
                                  "applicantId": %d
                                }
                                """.formatted(applicant.getId())))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get("businessKey").asText();

        mockMvc.perform(post("/api/workflow/drafts/{businessKey}/submit", businessKey)
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Draft default countersign",
                                  "applicantId": %d,
                                  "applicantDeptId": null,
                                  "applicantPostId": null,
                                  "formInstanceId": null,
                                  "processKey": "approvalCountersign",
                                  "variables": {},
                                  "countersignUsers": [],
                                  "countersignMode": "ALL",
                                  "passRatio": 1.0
                                }
                                """.formatted(applicant.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Draft submitted successfully"))
                .andExpect(jsonPath("$.processInstanceId").isString());
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
    void submitDraft_withBlankRuntimeVariables_keepsDraftSnapshotValues() throws Exception {
        SysUser designer = createUser("draft-merge-designer", "Password@123", null, "DESIGNER");
        String designerToken = accessToken(designer, "DESIGNER");
        SysUser applicant = createUser("draft-merge-applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("draft-merge-approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String formKey = unique("draft-merge-form");
        Long formVersionId = createFormVersionForDraft(
                designer,
                designerToken,
                formKey,
                "{\"fields\":[{\"key\":\"approverId\",\"type\":\"string\",\"required\":true}]}"
        );

        String businessKey = json(mockMvc.perform(post("/api/workflow/drafts")
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Draft merge values",
                                  "applicantId": %d,
                                  "formKey": "%s",
                                  "formVersionId": %d,
                                  "formData": {
                                    "approverId": "%s"
                                  }
                                }
                                """.formatted(applicant.getId(), formKey, formVersionId, approver.getUsername())))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get("businessKey").asText();

        mockMvc.perform(post("/api/workflow/drafts/{businessKey}/submit", businessKey)
                        .header("Authorization", authorization(applicantToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Draft merge values",
                                  "applicantId": %d,
                                  "processKey": "approvalSingle",
                                  "variables": {
                                    "approverId": ""
                                  }
                                }
                                """.formatted(applicant.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processInstanceId").isString());

        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();
        assertThat(task).isNotNull();
        assertThat(task.getAssignee()).isEqualTo(approver.getUsername());
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
    void aiSuggestion_returnsReadOnlyAdviceForAssigneeTask() throws Exception {
        SysUser applicant = createUser("ai-applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("ai-approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String approverToken = accessToken(approver, "EMPLOYEE");
        String businessKey = unique("wf-ai");

        startSingleApproval(applicantToken, applicant.getId(), businessKey, approver.getUsername());
        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();

        mockMvc.perform(get("/api/workflow/tasks/{taskId}/ai-suggestion", task.getId())
                        .header("Authorization", authorization(approverToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recordId").isNumber())
                .andExpect(jsonPath("$.taskId").value(task.getId()))
                .andExpect(jsonPath("$.decision").isString())
                .andExpect(jsonPath("$.recommendation").isString())
                .andExpect(jsonPath("$.summary").isString())
                .andExpect(jsonPath("$.approvalComment").isString())
                .andExpect(jsonPath("$.model").isString());
    }

    @Test
    void aiSuggestion_supportsFollowUpAdoptAndHistoryFinalResult() throws Exception {
        SysUser applicant = createUser("ai-history-applicant", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("ai-history-approver", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String approverToken = accessToken(approver, "EMPLOYEE");
        String businessKey = unique("wf-ai-history");

        startSingleApproval(applicantToken, applicant.getId(), businessKey, approver.getUsername());
        Task task = taskService.createTaskQuery().processInstanceBusinessKey(businessKey).singleResult();

        long recordId = json(mockMvc.perform(get("/api/workflow/tasks/{taskId}/ai-suggestion", task.getId())
                        .header("Authorization", authorization(approverToken)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString()).get("recordId").asLong();

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/ai-suggestion/{recordId}/follow-up", task.getId(), recordId)
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "question": "为什么你认为这个申请有风险？"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.conversation[0].question").value("为什么你认为这个申请有风险？"))
                .andExpect(jsonPath("$.conversation[0].answer").isString());

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/ai-suggestion/{recordId}/adopt", task.getId(), recordId)
                        .header("Authorization", authorization(approverToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.adopted").value(true))
                .andExpect(jsonPath("$.adoptedAt").isString());

        mockMvc.perform(get("/api/workflow/tasks/{taskId}/ai-suggestion/history", task.getId())
                        .header("Authorization", authorization(approverToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].recordId").value(recordId))
                .andExpect(jsonPath("$[0].conversation[0].question").value("为什么你认为这个申请有风险？"))
                .andExpect(jsonPath("$[0].adopted").value(true));

        mockMvc.perform(post("/api/workflow/tasks/{taskId}/complete", task.getId())
                        .header("Authorization", authorization(approverToken))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "approvalResult": "APPROVE",
                                  "comments": "approved with ai suggestion"
                                }
                                """))
                .andExpect(status().isOk());

        List<TaskAiSuggestionService.SuggestionRecordView> records =
                taskAiSuggestionService.getHistoryForBusinessKeys(List.of(businessKey));
        assertThat(records).hasSize(1);
        assertThat(records.get(0).getRecordId()).isEqualTo(recordId);
        assertThat(records.get(0).isAdopted()).isTrue();
        assertThat(records.get(0).getFinalApprovalResult()).isEqualTo("APPROVE");
    }

    @Test
    void aiSuggestion_forbiddenForUnrelatedUser() throws Exception {
        SysUser applicant = createUser("ai-owner", "Password@123", null, "EMPLOYEE");
        SysUser approver = createUser("ai-approver", "Password@123", null, "EMPLOYEE");
        SysUser other = createUser("ai-other", "Password@123", null, "EMPLOYEE");
        String applicantToken = accessToken(applicant, "EMPLOYEE");
        String otherToken = accessToken(other, "EMPLOYEE");

        String processInstanceId = startSingleApproval(
                applicantToken,
                applicant.getId(),
                unique("wf-ai-forbid"),
                approver.getUsername());
        Task task = taskService.createTaskQuery().processInstanceId(processInstanceId).singleResult();

        mockMvc.perform(get("/api/workflow/tasks/{taskId}/ai-suggestion", task.getId())
                        .header("Authorization", authorization(otherToken)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("only assignee/candidate/admin can access ai suggestion"));
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

        mockMvc.perform(get("/api/workflow/tasks")
                        .header("Authorization", authorization(delegateToken))
                        .param("assignee", delegateUser.getUsername()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].assignee").value(delegateUser.getUsername()))
                .andExpect(jsonPath("$[0].owner").value(approver.getUsername()))
                .andExpect(jsonPath("$[0].delegationState").value("PENDING"));

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

        mockMvc.perform(get("/api/workflow/tasks")
                        .header("Authorization", authorization(approverToken))
                        .param("assignee", approver.getUsername()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].assignee").value(approver.getUsername()))
                .andExpect(jsonPath("$[0].owner").value(approver.getUsername()))
                .andExpect(jsonPath("$[0].delegationState").value("RESOLVED"));

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
