package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.BizRequestLog;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.repository.BizRequestLogRepository;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.RbacService;
import com.flowablecollab.approval_system.service.TaskAiSuggestionService;
import com.flowablecollab.approval_system.service.WorkflowService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/requests")
@RequiredArgsConstructor
public class RequestController {

    private final BizRequestRepository bizRequestRepository;
    private final BizRequestLogRepository bizRequestLogRepository;
    private final WorkflowService workflowService;
    private final RbacService rbacService;
    private final TaskAiSuggestionService taskAiSuggestionService;
    private final SysUserRepository sysUserRepository;

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
        List<BizRequestLog> logs = bizRequestLogRepository.findByBusinessKeyIn(businessKeys);
        attachOperatorNames(logs);
        return ResponseEntity.ok(logs);
    }

    private void attachOperatorNames(List<BizRequestLog> logs) {
        Set<Long> userIds = logs.stream()
                .map(BizRequestLog::getOperatorId)
                .collect(Collectors.toSet());
        if (userIds.isEmpty()) return;
        Map<Long, String> userMap = sysUserRepository.findAllById(userIds).stream()
                .collect(Collectors.toMap(SysUser::getId, SysUser::getUsername));
        logs.forEach(log -> log.setOperatorName(userMap.get(log.getOperatorId())));
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

    @GetMapping("/approved-by-me")
    public ResponseEntity<List<ApprovedRequestView>> listApprovedByMe() {
        Long userId = SecurityUtils.currentUserId();
        if (userId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }

        List<BizRequestLog> logs = bizRequestLogRepository
                .findByOperatorIdAndActionIn(userId, List.of("APPROVE", "REJECT"));

        if (logs.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList());
        }

        Map<String, BizRequestLog> latestLogPerRequest = logs.stream()
                .collect(Collectors.toMap(
                        BizRequestLog::getBusinessKey,
                        log -> log,
                        (a, b) -> a.getCreatedAt().isAfter(b.getCreatedAt()) ? a : b
                ));

        List<String> businessKeys = new ArrayList<>(latestLogPerRequest.keySet());
        Map<String, BizRequest> requestMap = bizRequestRepository
                .findByBusinessKeyIn(businessKeys)
                .stream()
                .collect(Collectors.toMap(BizRequest::getBusinessKey, r -> r));

        List<ApprovedRequestView> result = new ArrayList<>();
        for (String bk : businessKeys) {
            BizRequest req = requestMap.get(bk);
            BizRequestLog log = latestLogPerRequest.get(bk);
            if (req == null) continue;

            result.add(new ApprovedRequestView(
                    req.getId(),
                    req.getBusinessKey(),
                    req.getProcessInstanceId(),
                    req.getTitle(),
                    req.getStatus(),
                    req.getApplicantId(),
                    req.getSubmitTime() != null ? req.getSubmitTime().toString() : null,
                    req.getFinishTime() != null ? req.getFinishTime().toString() : null,
                    req.getCreatedAt() != null ? req.getCreatedAt().toString() : null,
                    log.getAction(),
                    log.getComment(),
                    log.getCreatedAt() != null ? log.getCreatedAt().toString() : null
            ));
        }

        result.sort((a, b) -> b.actionTime().compareTo(a.actionTime()));

        return ResponseEntity.ok(result);
    }

    public record ApprovedRequestView(
            Long id,
            String businessKey,
            String processInstanceId,
            String title,
            Integer status,
            Long applicantId,
            String submitTime,
            String finishTime,
            String createdAt,
            String action,
            String comment,
            String actionTime
    ) {}

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
