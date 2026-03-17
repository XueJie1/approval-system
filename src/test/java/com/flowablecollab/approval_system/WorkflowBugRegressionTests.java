package com.flowablecollab.approval_system;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.flowablecollab.approval_system.service.WorkflowService;
import org.flowable.task.api.Task;
import org.flowable.engine.TaskService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
@ActiveProfiles("test")
class WorkflowBugRegressionTests {

    private static final int REQUEST_STATUS_APPROVED = 3;

    @Autowired
    private WorkflowService workflowService;

    @Autowired
    private TaskService taskService;

    @Autowired
    private BizRequestRepository bizRequestRepository;

    @Autowired
    private SysUserRepository sysUserRepository;

    @Test
    void singleApprovalCompletion_shouldMarkRequestApproved() {
        SysUser applicant = createUser("applicant");
        SysUser approver = createUser("approver");
        String businessKey = "bug-single-" + UUID.randomUUID();

        WorkflowService.StartRequest request = new WorkflowService.StartRequest();
        request.setBusinessKey(businessKey);
        request.setTitle("Single approval regression");
        request.setApplicantId(applicant.getId());
        request.setProcessKey("approvalSingle");
        request.setVariables(Map.of("approverId", approver.getUsername()));

        String processInstanceId = workflowService.startApprovalProcess(request);
        Task task = taskService.createTaskQuery().processInstanceId(processInstanceId).singleResult();
        assertNotNull(task, "single approval should create exactly one active task");

        workflowService.completeTask(task.getId(), approver.getUsername(), "APPROVE", "approved");

        BizRequest bizRequest = bizRequestRepository.findByProcessInstanceId(processInstanceId).orElseThrow();
        assertEquals(REQUEST_STATUS_APPROVED, bizRequest.getStatus(),
                "single approval should end with APPROVED status in biz_request");
    }

    @Test
    void returnToCountersign_shouldWorkForSingleApprovalProcess() {
        SysUser applicant = createUser("applicant");
        SysUser approver = createUser("approver");

        WorkflowService.StartRequest request = new WorkflowService.StartRequest();
        request.setBusinessKey("bug-return-" + UUID.randomUUID());
        request.setTitle("Return regression");
        request.setApplicantId(applicant.getId());
        request.setProcessKey("approvalSingle");
        request.setVariables(Map.of("approverId", approver.getUsername()));

        String processInstanceId = workflowService.startApprovalProcess(request);
        Task task = taskService.createTaskQuery().processInstanceId(processInstanceId).singleResult();
        assertNotNull(task, "single approval should create exactly one active task");

        assertDoesNotThrow(() -> workflowService.returnToCountersign(task.getId(), approver.getUsername(), "return"),
                "return endpoint should not jump to a non-existent activity for approvalSingle");
    }

    private SysUser createUser(String prefix) {
        SysUser user = new SysUser();
        user.setUsername(prefix + "-" + UUID.randomUUID());
        user.setPassword("secret");
        user.setStatus(1);
        user.setTwoFactorEnabled(0);
        user.setLoginFailures(0);
        return sysUserRepository.save(user);
    }
}
