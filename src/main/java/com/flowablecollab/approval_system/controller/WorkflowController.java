package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.form.FormInstance;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.WorkflowService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/workflow")
@RequiredArgsConstructor
public class WorkflowController {

    private final WorkflowService workflowService;
    private final com.flowablecollab.approval_system.service.FormService formService;

    @PostMapping("/requests")
    public ResponseEntity<StartProcessResponse> startProcess(@RequestBody StartProcessRequest request) {
        log.info("Starting approval process for businessKey: {}", request.getBusinessKey());
        Long applicantId = resolveApplicantId(request.getApplicantId());

        WorkflowService.StartRequest startRequest = new WorkflowService.StartRequest();
        startRequest.setBusinessKey(request.getBusinessKey());
        startRequest.setTitle(request.getTitle());
        startRequest.setApplicantId(applicantId);
        startRequest.setApplicantDeptId(request.getApplicantDeptId());
        startRequest.setApplicantPostId(request.getApplicantPostId());
        startRequest.setFormInstanceId(request.getFormInstanceId());
        startRequest.setProcessKey(request.getProcessKey());
        startRequest.setVariables(request.getVariables());
        startRequest.setCountersignUsers(request.getCountersignUsers());
        startRequest.setCountersignMode(request.getCountersignMode());
        startRequest.setPassRatio(request.getPassRatio());

        if (request.getFormKey() != null && request.getFormData() != null) {
            FormVersion latest = formService.getLatestVersion(request.getFormKey());
            FormInstance instance = formService.createFormInstance(latest.getId(), request.getBusinessKey(), request.getFormData());
            startRequest.setFormInstanceId(instance.getId());
            if (startRequest.getVariables() == null) {
                startRequest.setVariables(new java.util.HashMap<>());
            }
            startRequest.getVariables().putAll(request.getFormData());
        }

        String processInstanceId = workflowService.startApprovalProcess(startRequest);

        StartProcessResponse response = new StartProcessResponse();
        response.setProcessInstanceId(processInstanceId);
        response.setMessage("Process started successfully");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/tasks")
    public ResponseEntity<List<WorkflowService.TaskInfo>> getTasks(
            @RequestParam String assignee,
            @RequestParam(defaultValue = "false") boolean includeCandidate) {
        log.info("Fetching tasks for assignee: {}", assignee);
        List<WorkflowService.TaskInfo> tasks = workflowService.getTasksForAssignee(assignee, includeCandidate);
        return ResponseEntity.ok(tasks);
    }

    @PostMapping("/tasks/{taskId}/claim")
    public ResponseEntity<ActionResponse> claimTask(@PathVariable String taskId, @RequestBody ClaimTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.claimTask(taskId, userId);
        return ResponseEntity.ok(ActionResponse.ok("Task claimed"));
    }

    @PostMapping("/tasks/{taskId}/complete")
    public ResponseEntity<ActionResponse> completeTask(
            @PathVariable String taskId,
            @RequestBody CompleteTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.completeTask(taskId, userId, request.getApprovalResult(), request.getComments());
        return ResponseEntity.ok(ActionResponse.ok("Task completed"));
    }

    @PostMapping("/tasks/{taskId}/delegate")
    public ResponseEntity<ActionResponse> delegateTask(
            @PathVariable String taskId,
            @RequestBody DelegateTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.delegateTask(taskId, userId, request.getDelegateUserId(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task delegated"));
    }

    @PostMapping("/tasks/{taskId}/resolve")
    public ResponseEntity<ActionResponse> resolveTask(
            @PathVariable String taskId,
            @RequestBody ResolveTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.resolveTask(taskId, userId, request.getApprovalResult(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task resolved"));
    }

    @PostMapping("/tasks/{taskId}/reassign")
    public ResponseEntity<ActionResponse> reassignTask(
            @PathVariable String taskId,
            @RequestBody ReassignTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.reassignTask(taskId, userId, request.getNewAssigneeId(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task reassigned"));
    }

    @PostMapping("/tasks/{taskId}/return")
    public ResponseEntity<ActionResponse> returnTask(
            @PathVariable String taskId,
            @RequestBody ReturnTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.returnToCountersign(taskId, userId, request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task returned"));
    }

    @PostMapping("/tasks/{taskId}/return/previous")
    public ResponseEntity<ActionResponse> returnToPrevious(
            @PathVariable String taskId,
            @RequestBody ReturnTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.returnToPrevious(taskId, userId, request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task returned to previous"));
    }

    @PostMapping("/tasks/{taskId}/return/target")
    public ResponseEntity<ActionResponse> returnToTarget(
            @PathVariable String taskId,
            @RequestBody ReturnToTargetRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.returnToActivityId(taskId, userId, request.getTargetActivityId(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task returned to target"));
    }

    @PostMapping("/tasks/{taskId}/return/applicant")
    public ResponseEntity<ActionResponse> returnToApplicant(
            @PathVariable String taskId,
            @RequestBody ReturnTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.returnToApplicant(taskId, userId, request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task returned to applicant"));
    }

    @PostMapping("/process/{processInstanceId}/cancel")
    public ResponseEntity<ActionResponse> cancelProcess(
            @PathVariable String processInstanceId,
            @RequestBody CancelProcessRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.cancelProcess(processInstanceId, userId, request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Process cancelled"));
    }

    private Long resolveApplicantId(Long requestedApplicantId) {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        if (requestedApplicantId == null) {
            return currentUserId;
        }
        if (requestedApplicantId.equals(currentUserId) || SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN")) {
            return requestedApplicantId;
        }
        throw new ForbiddenOperationException("applicantId must match current login user");
    }

    private String resolveActionUserId(String requestedUserId) {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        if (requestedUserId == null || requestedUserId.isBlank()) {
            return String.valueOf(currentUserId);
        }
        if (String.valueOf(currentUserId).equals(requestedUserId) || SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN")) {
            return requestedUserId;
        }
        throw new ForbiddenOperationException("userId must match current login user");
    }

    @Data
    public static class StartProcessRequest {
        private String businessKey;
        private String title;
        private Long applicantId;
        private Long applicantDeptId;
        private Long applicantPostId;
        private Long formInstanceId;
        private String formKey;
        private Map<String, Object> formData;
        private String processKey;
        private Map<String, Object> variables;
        private List<String> countersignUsers;
        private String countersignMode;
        private BigDecimal passRatio;
    }

    @Data
    public static class StartProcessResponse {
        private String processInstanceId;
        private String message;
    }

    @Data
    public static class ClaimTaskRequest {
        private String userId;
    }

    @Data
    public static class CompleteTaskRequest {
        private String userId;
        private String approvalResult;
        private String comments;
    }

    @Data
    public static class DelegateTaskRequest {
        private String userId;
        private String delegateUserId;
        private String comment;
    }

    @Data
    public static class ResolveTaskRequest {
        private String userId;
        private String approvalResult;
        private String comment;
    }

    @Data
    public static class ReassignTaskRequest {
        private String userId;
        private String newAssigneeId;
        private String comment;
    }

    @Data
    public static class ReturnTaskRequest {
        private String userId;
        private String comment;
    }

    @Data
    public static class ReturnToTargetRequest {
        private String userId;
        private String targetActivityId;
        private String comment;
    }

    @Data
    public static class CancelProcessRequest {
        private String userId;
        private String comment;
    }

    @Data
    public static class ActionResponse {
        private boolean success;
        private String message;

        public static ActionResponse ok(String message) {
            ActionResponse response = new ActionResponse();
            response.setSuccess(true);
            response.setMessage(message);
            return response;
        }
    }
}
