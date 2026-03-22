package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.BizRequestLog;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.repository.BizRequestLogRepository;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.RbacService;
import com.flowablecollab.approval_system.service.TaskAiSuggestionService;
import com.flowablecollab.approval_system.service.WorkflowService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/requests")
@RequiredArgsConstructor
public class RequestController {

    private final BizRequestRepository bizRequestRepository;
    private final BizRequestLogRepository bizRequestLogRepository;
    private final WorkflowService workflowService;
    private final RbacService rbacService;
    private final TaskAiSuggestionService taskAiSuggestionService;

    @GetMapping
    public ResponseEntity<List<BizRequest>> listRequests(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer status) {
        Long actualUserId = resolveRequestedUserId(userId);
        Set<Long> deptIds = rbacService.getAccessibleDeptIds(actualUserId);
        Set<Long> postIds = rbacService.getUserPostIds(actualUserId);
        if (deptIds == null) {
            return ResponseEntity.ok(filterByStatus(bizRequestRepository.findAll(), status));
        }
        if (deptIds.size() == 1 && deptIds.contains(-1L)) {
            return ResponseEntity.ok(filterByStatus(bizRequestRepository.findByApplicantId(actualUserId), status));
        }
        if (deptIds.isEmpty()) {
            if (postIds.isEmpty()) {
                return ResponseEntity.ok(Collections.emptyList());
            }
            return ResponseEntity.ok(filterByStatus(
                    bizRequestRepository.findByApplicantDeptIdInOrApplicantPostIdIn(List.of(-1L), postIds.stream().toList()),
                    status));
        }
        if (postIds.isEmpty()) {
            return ResponseEntity.ok(filterByStatus(bizRequestRepository.findByApplicantDeptIdIn(deptIds.stream().toList()), status));
        }
        return ResponseEntity.ok(filterByStatus(
                bizRequestRepository.findByApplicantDeptIdInOrApplicantPostIdIn(deptIds.stream().toList(), postIds.stream().toList()),
                status));
    }

    @GetMapping("/tasks")
    public ResponseEntity<List<WorkflowService.TaskInfo>> listTasks(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer status) {
        List<BizRequest> requests = listRequests(userId, status).getBody();
        if (requests == null || requests.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList());
        }
        List<String> processIds = requests.stream()
                .map(BizRequest::getProcessInstanceId)
                .filter(id -> id != null && !id.isBlank())
                .toList();
        return ResponseEntity.ok(workflowService.getTasksByProcessInstanceIds(processIds));
    }

    @GetMapping("/logs")
    public ResponseEntity<List<BizRequestLog>> listLogs(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer status) {
        List<BizRequest> requests = listRequests(userId, status).getBody();
        if (requests == null || requests.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList());
        }
        List<String> businessKeys = requests.stream()
                .map(BizRequest::getBusinessKey)
                .filter(key -> key != null && !key.isBlank())
                .toList();
        return ResponseEntity.ok(bizRequestLogRepository.findByBusinessKeyIn(businessKeys));
    }

    @GetMapping("/processes")
    public ResponseEntity<List<WorkflowService.ProcessInfo>> listProcesses(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer status) {
        List<BizRequest> requests = listRequests(userId, status).getBody();
        if (requests == null || requests.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList());
        }
        List<String> processIds = requests.stream()
                .map(BizRequest::getProcessInstanceId)
                .filter(id -> id != null && !id.isBlank())
                .toList();
        return ResponseEntity.ok(workflowService.getProcessesByIds(processIds));
    }

    @GetMapping("/ai-suggestions")
    public ResponseEntity<List<TaskAiSuggestionService.SuggestionRecordView>> listAiSuggestions(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer status) {
        List<BizRequest> requests = listRequests(userId, status).getBody();
        if (requests == null || requests.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList());
        }
        List<String> businessKeys = requests.stream()
                .map(BizRequest::getBusinessKey)
                .filter(key -> key != null && !key.isBlank())
                .toList();
        return ResponseEntity.ok(taskAiSuggestionService.getHistoryForBusinessKeys(businessKeys));
    }

    private Long resolveRequestedUserId(Long requestedUserId) {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        if (requestedUserId == null || requestedUserId.equals(currentUserId) || SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN")) {
            return requestedUserId == null ? currentUserId : requestedUserId;
        }
        throw new ForbiddenOperationException("userId must match current login user");
    }

    private List<BizRequest> filterByStatus(List<BizRequest> requests, Integer status) {
        if (status == null) {
            return requests;
        }
        return requests.stream()
                .filter(request -> status.equals(request.getStatus()))
                .toList();
    }
}
