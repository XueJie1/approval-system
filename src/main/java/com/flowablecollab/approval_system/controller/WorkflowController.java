package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.service.WorkflowService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/workflow")
@RequiredArgsConstructor
public class WorkflowController {

    private final WorkflowService workflowService;

    @PostMapping("/start")
    public ResponseEntity<StartProcessResponse> startProcess(@RequestBody StartProcessRequest request) {
        log.info("Starting approval process for request: {}", request.getRequestId());

        String processInstanceId = workflowService.startApprovalProcess(
                request.getRequestId(),
                request.getRequester(),
                request.getAmount()
        );

        StartProcessResponse response = new StartProcessResponse();
        response.setProcessInstanceId(processInstanceId);
        response.setMessage("Process started successfully");

        return ResponseEntity.ok(response);
    }

    @GetMapping("/tasks")
    public ResponseEntity<List<WorkflowService.TaskInfo>> getTasks(@RequestParam String assignee) {
        log.info("Fetching tasks for assignee: {}", assignee);

        List<WorkflowService.TaskInfo> tasks = workflowService.getTasksForAssignee(assignee);

        return ResponseEntity.ok(tasks);
    }

    @PostMapping("/tasks/{taskId}/complete")
    public ResponseEntity<CompleteTaskResponse> completeTask(
            @PathVariable String taskId,
            @RequestBody CompleteTaskRequest request) {
        log.info("Completing task: {} with approval: {}", taskId, request.isApproved());

        workflowService.completeTask(taskId, request.isApproved(), request.getComments());

        CompleteTaskResponse response = new CompleteTaskResponse();
        response.setCompleted(true);
        response.setMessage("Task completed successfully");

        return ResponseEntity.ok(response);
    }

    @Data
    public static class StartProcessRequest {
        private String requestId;
        private String requester;
        private BigDecimal amount;
    }

    @Data
    public static class StartProcessResponse {
        private String processInstanceId;
        private String message;
    }

    @Data
    public static class CompleteTaskRequest {
        private boolean approved;
        private String comments;
    }

    @Data
    public static class CompleteTaskResponse {
        private boolean completed;
        private String message;
    }
}
