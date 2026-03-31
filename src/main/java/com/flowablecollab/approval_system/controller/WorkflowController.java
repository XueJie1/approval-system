package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.form.FormInstance;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.RbacService;
import com.flowablecollab.approval_system.service.TaskAiSuggestionService;
import com.flowablecollab.approval_system.service.WorkflowService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/workflow")
@RequiredArgsConstructor
public class WorkflowController {

    private final WorkflowService workflowService;
    private final com.flowablecollab.approval_system.service.FormService formService;
    private final TaskAiSuggestionService taskAiSuggestionService;
    private final RbacService rbacService;

    @PostMapping("/requests")
    public ResponseEntity<StartProcessResponse> startProcess(@Valid @RequestBody StartProcessRequest request) {
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
        validateApproverEligibility(request.getVariables(), request.getCountersignUsers());

        if (request.getFormKey() != null && request.getFormData() != null) {
            Long formVersionId = request.getFormVersionId();
            if (formVersionId == null) {
                formVersionId = formService.getLatestVersion(request.getFormKey()).getId();
            } else {
                formService.getVersion(formVersionId);
            }
            String businessKey = request.getBusinessKey();
            if (businessKey == null || businessKey.isBlank()) {
                businessKey = UUID.randomUUID().toString();
                request.setBusinessKey(businessKey);
                startRequest.setBusinessKey(businessKey);
            }
            FormInstance instance = formService.createFormInstance(formVersionId, businessKey, request.getFormData());
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

    @PostMapping("/drafts")
    public ResponseEntity<SaveDraftResponse> saveDraft(@Valid @RequestBody SaveDraftRequest request) {
        Long applicantId = resolveApplicantId(request.getApplicantId());
        String businessKey = request.getBusinessKey();
        if (businessKey == null || businessKey.isBlank()) {
            businessKey = UUID.randomUUID().toString();
            request.setBusinessKey(businessKey);
        }
        Long formInstanceId = request.getFormInstanceId();
        if (request.getFormKey() != null && request.getFormData() != null) {
            Long formVersionId = request.getFormVersionId();
            if (formVersionId == null) {
                FormVersion latest = formService.getLatestVersion(request.getFormKey());
                formVersionId = latest.getId();
            } else {
                formService.getVersion(formVersionId);
            }
            FormInstance instance = formService.createFormInstance(formVersionId, businessKey, request.getFormData());
            formInstanceId = instance.getId();
        }

        WorkflowService.DraftRequest draftRequest = new WorkflowService.DraftRequest();
        draftRequest.setBusinessKey(businessKey);
        draftRequest.setTitle(request.getTitle());
        draftRequest.setApplicantId(applicantId);
        draftRequest.setApplicantDeptId(request.getApplicantDeptId());
        draftRequest.setApplicantPostId(request.getApplicantPostId());
        draftRequest.setFormInstanceId(formInstanceId);

        businessKey = workflowService.saveDraft(draftRequest);
        SaveDraftResponse response = new SaveDraftResponse();
        response.setBusinessKey(businessKey);
        response.setMessage("Draft saved");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/drafts/{businessKey}/submit")
    public ResponseEntity<StartProcessResponse> submitDraft(
            @PathVariable String businessKey,
            @Valid @RequestBody SubmitDraftRequest request) {
        BizRequest draft = workflowService.getRequestByBusinessKey(businessKey);
        ensureRequestOperatorAllowed(draft);

        WorkflowService.StartRequest startRequest = new WorkflowService.StartRequest();
        startRequest.setTitle(request.getTitle());
        startRequest.setApplicantId(request.getApplicantId());
        startRequest.setApplicantDeptId(request.getApplicantDeptId());
        startRequest.setApplicantPostId(request.getApplicantPostId());
        startRequest.setFormInstanceId(request.getFormInstanceId());
        startRequest.setProcessKey(request.getProcessKey());
        Map<String, Object> variables = request.getVariables();
        if (draft.getFormInstanceId() != null) {
            variables = mergeDraftVariables(
                    formService.readFormInstanceData(draft.getFormInstanceId()),
                    variables);
            startRequest.setFormInstanceId(draft.getFormInstanceId());
        }
        startRequest.setVariables(variables);
        startRequest.setCountersignUsers(request.getCountersignUsers());
        startRequest.setCountersignMode(request.getCountersignMode());
        startRequest.setPassRatio(request.getPassRatio());
        validateApproverEligibility(variables, request.getCountersignUsers());

        String processInstanceId = workflowService.submitDraft(businessKey, startRequest);
        StartProcessResponse response = new StartProcessResponse();
        response.setProcessInstanceId(processInstanceId);
        response.setMessage("Draft submitted successfully");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/tasks")
    public ResponseEntity<List<WorkflowService.TaskInfo>> getTasks(
            @RequestParam(required = false) String assignee,
            @RequestParam(defaultValue = "false") boolean includeCandidate) {
        Long currentUserId = requireCurrentUserId();
        String currentUsername = SecurityUtils.currentUsername();

        List<WorkflowService.TaskInfo> tasks;
        if (assignee == null || assignee.isBlank()) {
            LinkedHashSet<String> identities = new LinkedHashSet<>();
            if (currentUsername != null && !currentUsername.isBlank()) {
                identities.add(currentUsername);
            }
            identities.add(String.valueOf(currentUserId));
            tasks = workflowService.getTasksForAssignees(List.copyOf(identities), includeCandidate);
        } else {
            boolean sameIdentity = assignee.equals(String.valueOf(currentUserId))
                    || (currentUsername != null && assignee.equals(currentUsername));
            if (!sameIdentity && !SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN")) {
                throw new ForbiddenOperationException("assignee must match current login user");
            }
            tasks = workflowService.getTasksForAssignee(assignee, includeCandidate);
        }

        log.info("Fetched {} tasks for requester {}", tasks.size(), currentUserId);
        return ResponseEntity.ok(tasks);
    }

    @PostMapping("/tasks/{taskId}/claim")
    public ResponseEntity<ActionResponse> claimTask(@PathVariable String taskId, @Valid @RequestBody ClaimTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.claimTask(taskId, userId);
        return ResponseEntity.ok(ActionResponse.ok("Task claimed"));
    }

    @PostMapping("/tasks/{taskId}/complete")
    public ResponseEntity<ActionResponse> completeTask(
            @PathVariable String taskId,
            @Valid @RequestBody CompleteTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.completeTask(taskId, userId, request.getApprovalResult(), request.getComments());
        return ResponseEntity.ok(ActionResponse.ok("Task completed"));
    }

    @PostMapping("/tasks/{taskId}/delegate")
    public ResponseEntity<ActionResponse> delegateTask(
            @PathVariable String taskId,
            @Valid @RequestBody DelegateTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.delegateTask(taskId, userId, request.getDelegateUserId(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task delegated"));
    }

    @PostMapping("/tasks/{taskId}/resolve")
    public ResponseEntity<ActionResponse> resolveTask(
            @PathVariable String taskId,
            @Valid @RequestBody ResolveTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.resolveTask(taskId, userId, request.getApprovalResult(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task resolved"));
    }

    @PostMapping("/tasks/{taskId}/reassign")
    public ResponseEntity<ActionResponse> reassignTask(
            @PathVariable String taskId,
            @Valid @RequestBody ReassignTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.reassignTask(taskId, userId, request.getNewAssigneeId(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task reassigned"));
    }

    @PostMapping("/tasks/{taskId}/return")
    public ResponseEntity<ActionResponse> returnTask(
            @PathVariable String taskId,
            @Valid @RequestBody ReturnTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.returnToCountersign(taskId, userId, request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task returned"));
    }

    @PostMapping("/tasks/{taskId}/return/previous")
    public ResponseEntity<ActionResponse> returnToPrevious(
            @PathVariable String taskId,
            @Valid @RequestBody ReturnTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.returnToPrevious(taskId, userId, request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task returned to previous"));
    }

    @PostMapping("/tasks/{taskId}/return/target")
    public ResponseEntity<ActionResponse> returnToTarget(
            @PathVariable String taskId,
            @Valid @RequestBody ReturnToTargetRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.returnToActivityId(taskId, userId, request.getTargetActivityId(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task returned to target"));
    }

    @PostMapping("/tasks/{taskId}/return/applicant")
    public ResponseEntity<ActionResponse> returnToApplicant(
            @PathVariable String taskId,
            @Valid @RequestBody ReturnTaskRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.returnToApplicant(taskId, userId, request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Task returned to applicant"));
    }

    @PostMapping("/process/{processInstanceId}/cancel")
    public ResponseEntity<ActionResponse> cancelProcess(
            @PathVariable String processInstanceId,
            @Valid @RequestBody CancelProcessRequest request) {
        String userId = resolveActionUserId(request.getUserId());
        workflowService.cancelProcess(processInstanceId, userId, request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Process cancelled"));
    }

    @PostMapping("/process/{processInstanceId}/suspend")
    public ResponseEntity<ActionResponse> suspendProcess(
            @PathVariable String processInstanceId,
            @Valid @RequestBody SuspendProcessRequest request) {
        BizRequest bizRequest = workflowService.getRequestByProcessInstanceId(processInstanceId);
        ensureRequestOperatorAllowed(bizRequest);
        workflowService.suspendProcess(processInstanceId, requireCurrentUserId(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Process suspended"));
    }

    @PostMapping("/process/{processInstanceId}/activate")
    public ResponseEntity<ActionResponse> activateProcess(
            @PathVariable String processInstanceId,
            @Valid @RequestBody ActivateProcessRequest request) {
        BizRequest bizRequest = workflowService.getRequestByProcessInstanceId(processInstanceId);
        ensureRequestOperatorAllowed(bizRequest);
        workflowService.activateProcess(processInstanceId, requireCurrentUserId(), request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Process activated"));
    }

    @GetMapping("/tasks/{taskId}/ai-suggestion")
    public ResponseEntity<AiSuggestionResponse> getAiSuggestion(@PathVariable String taskId) {
        Long currentUserId = requireCurrentUserId();
        WorkflowService.ApprovalSuggestion suggestion = workflowService.suggestForTask(
                taskId,
                currentUserId,
                SecurityUtils.currentUsername(),
                SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN"));
        return ResponseEntity.ok(toAiSuggestionResponse(suggestion));
    }

    @PostMapping("/tasks/{taskId}/ai-suggestion/{recordId}/follow-up")
    public ResponseEntity<AiSuggestionResponse> followUpAiSuggestion(
            @PathVariable String taskId,
            @PathVariable Long recordId,
            @Valid @RequestBody AiSuggestionFollowUpRequest request) {
        Long currentUserId = requireCurrentUserId();
        TaskAiSuggestionService.SuggestionRecordView suggestion = taskAiSuggestionService.followUp(
                taskId,
                recordId,
                request.getQuestion(),
                currentUserId,
                SecurityUtils.currentUsername(),
                SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN"));
        return ResponseEntity.ok(toAiSuggestionResponse(suggestion));
    }

    @PostMapping("/tasks/{taskId}/ai-suggestion/{recordId}/adopt")
    public ResponseEntity<AiSuggestionResponse> adoptAiSuggestion(
            @PathVariable String taskId,
            @PathVariable Long recordId) {
        Long currentUserId = requireCurrentUserId();
        TaskAiSuggestionService.SuggestionRecordView suggestion = taskAiSuggestionService.markAdopted(
                taskId,
                recordId,
                currentUserId,
                SecurityUtils.currentUsername(),
                SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN"));
        return ResponseEntity.ok(toAiSuggestionResponse(suggestion));
    }

    @GetMapping("/tasks/{taskId}/ai-suggestion/history")
    public ResponseEntity<List<AiSuggestionResponse>> getAiSuggestionHistory(@PathVariable String taskId) {
        Long currentUserId = requireCurrentUserId();
        List<AiSuggestionResponse> responses = taskAiSuggestionService.getTaskHistory(
                        taskId,
                        currentUserId,
                        SecurityUtils.currentUsername(),
                        SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN"))
                .stream()
                .map(this::toAiSuggestionResponse)
                .toList();
        return ResponseEntity.ok(responses);
    }

    private AiSuggestionResponse toAiSuggestionResponse(WorkflowService.ApprovalSuggestion suggestion) {
        AiSuggestionResponse response = new AiSuggestionResponse();
        response.setRecordId(suggestion.getRecordId());
        response.setBusinessKey(suggestion.getBusinessKey());
        response.setProcessInstanceId(suggestion.getProcessInstanceId());
        response.setTaskId(suggestion.getTaskId());
        response.setDecision(suggestion.getDecision());
        response.setRecommendation(suggestion.getRecommendation());
        response.setSummary(suggestion.getSummary());
        response.setRiskWarnings(suggestion.getRiskWarnings());
        response.setAnomalies(suggestion.getAnomalies());
        response.setSupplementaryInfo(suggestion.getSupplementaryInfo());
        response.setApprovalComment(suggestion.getApprovalComment());
        response.setSuggestedFormUpdates(suggestion.getSuggestedFormUpdates());
        response.setConversation(suggestion.getConversation());
        response.setAdopted(suggestion.isAdopted());
        response.setAdoptedAt(suggestion.getAdoptedAt());
        response.setFinalApprovalResult(suggestion.getFinalApprovalResult());
        response.setModel(suggestion.getModel());
        response.setGeneratedAt(suggestion.getGeneratedAt());
        return response;
    }

    private AiSuggestionResponse toAiSuggestionResponse(TaskAiSuggestionService.SuggestionRecordView suggestion) {
        AiSuggestionResponse response = new AiSuggestionResponse();
        response.setRecordId(suggestion.getRecordId());
        response.setBusinessKey(suggestion.getBusinessKey());
        response.setProcessInstanceId(suggestion.getProcessInstanceId());
        response.setTaskId(suggestion.getTaskId());
        response.setDecision(suggestion.getDecision());
        response.setRecommendation(suggestion.getRecommendation());
        response.setSummary(suggestion.getSummary());
        response.setRiskWarnings(suggestion.getRiskWarnings());
        response.setAnomalies(suggestion.getAnomalies());
        response.setSupplementaryInfo(suggestion.getSupplementaryInfo());
        response.setApprovalComment(suggestion.getApprovalComment());
        response.setSuggestedFormUpdates(suggestion.getSuggestedFormUpdates());
        response.setConversation(suggestion.getConversation());
        response.setAdopted(suggestion.isAdopted());
        response.setAdoptedAt(suggestion.getAdoptedAt());
        response.setFinalApprovalResult(suggestion.getFinalApprovalResult());
        response.setModel(suggestion.getModel());
        response.setGeneratedAt(suggestion.getGeneratedAt());
        return response;
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

    private Long requireCurrentUserId() {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        return currentUserId;
    }

    private void ensureRequestOperatorAllowed(BizRequest request) {
        Long currentUserId = requireCurrentUserId();
        if (SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN")) {
            return;
        }
        if (!currentUserId.equals(request.getApplicantId())) {
            throw new ForbiddenOperationException("only applicant or admin can operate this request");
        }
    }

    private Map<String, Object> mergeDraftVariables(Map<String, Object> draftVariables, Map<String, Object> requestVariables) {
        if ((draftVariables == null || draftVariables.isEmpty()) && (requestVariables == null || requestVariables.isEmpty())) {
            return requestVariables;
        }

        Map<String, Object> merged = new HashMap<>();
        if (draftVariables != null && !draftVariables.isEmpty()) {
            merged.putAll(draftVariables);
        }
        if (requestVariables != null && !requestVariables.isEmpty()) {
            requestVariables.forEach((key, value) -> {
                if (value == null) {
                    return;
                }
                if (value instanceof String stringValue && stringValue.isBlank()) {
                    return;
                }
                merged.put(key, value);
            });
        }
        return merged;
    }

    private void validateApproverEligibility(Map<String, Object> variables, List<String> countersignUsers) {
        if (variables != null) {
            Object approverId = variables.get("approverId");
            if (approverId instanceof String approver && !rbacService.isApproverEligible(approver)) {
                throw new IllegalArgumentException("ADMIN accounts cannot be approvers");
            }
        }
        if (countersignUsers == null || countersignUsers.isEmpty()) {
            return;
        }
        boolean containsAdminApprover = countersignUsers.stream()
                .anyMatch(userIdentity -> !rbacService.isApproverEligible(userIdentity));
        if (containsAdminApprover) {
            throw new IllegalArgumentException("ADMIN accounts cannot be approvers");
        }
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
        private Long formVersionId;
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
    public static class SaveDraftRequest {
        private String businessKey;
        @NotBlank(message = "title is required")
        private String title;
        private Long applicantId;
        private Long applicantDeptId;
        private Long applicantPostId;
        private Long formInstanceId;
        private String formKey;
        private Long formVersionId;
        private Map<String, Object> formData;
    }

    @Data
    public static class SaveDraftResponse {
        private String businessKey;
        private String message;
    }

    @Data
    public static class SubmitDraftRequest {
        private String title;
        private Long applicantId;
        private Long applicantDeptId;
        private Long applicantPostId;
        private Long formInstanceId;
        private String processKey;
        private Map<String, Object> variables;
        private List<String> countersignUsers;
        private String countersignMode;
        private BigDecimal passRatio;
    }

    @Data
    public static class ClaimTaskRequest {
        private String userId;
    }

    @Data
    public static class CompleteTaskRequest {
        private String userId;
        @NotBlank(message = "approvalResult is required")
        @Pattern(regexp = "APPROVE|REJECT", message = "approvalResult must be APPROVE or REJECT")
        private String approvalResult;
        @NotBlank(message = "comments is required")
        private String comments;
    }

    @Data
    public static class DelegateTaskRequest {
        private String userId;
        @NotBlank(message = "delegateUserId is required")
        private String delegateUserId;
        @NotBlank(message = "comment is required")
        private String comment;
    }

    @Data
    public static class ResolveTaskRequest {
        private String userId;
        @NotBlank(message = "approvalResult is required")
        @Pattern(regexp = "APPROVE|REJECT", message = "approvalResult must be APPROVE or REJECT")
        private String approvalResult;
        @NotBlank(message = "comment is required")
        private String comment;
    }

    @Data
    public static class ReassignTaskRequest {
        private String userId;
        @NotBlank(message = "newAssigneeId is required")
        private String newAssigneeId;
        @NotBlank(message = "comment is required")
        private String comment;
    }

    @Data
    public static class ReturnTaskRequest {
        private String userId;
        @NotBlank(message = "comment is required")
        private String comment;
    }

    @Data
    public static class ReturnToTargetRequest {
        private String userId;
        @NotBlank(message = "targetActivityId is required")
        private String targetActivityId;
        @NotBlank(message = "comment is required")
        private String comment;
    }

    @Data
    public static class CancelProcessRequest {
        private String userId;
        @NotBlank(message = "comment is required")
        private String comment;
    }

    @Data
    public static class SuspendProcessRequest {
        @NotBlank(message = "comment is required")
        private String comment;
    }

    @Data
    public static class ActivateProcessRequest {
        @NotBlank(message = "comment is required")
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

    @Data
    public static class AiSuggestionResponse {
        private Long recordId;
        private String businessKey;
        private String processInstanceId;
        private String taskId;
        private String decision;
        private String recommendation;
        private String summary;
        private List<String> riskWarnings;
        private List<String> anomalies;
        private List<String> supplementaryInfo;
        private String approvalComment;
        private Map<String, Object> suggestedFormUpdates;
        private List<TaskAiSuggestionService.ConversationTurnView> conversation;
        private boolean adopted;
        private java.time.LocalDateTime adoptedAt;
        private String finalApprovalResult;
        private String model;
        private java.time.LocalDateTime generatedAt;
    }

    @Data
    public static class AiSuggestionFollowUpRequest {
        @NotBlank(message = "question is required")
        private String question;
    }
}
