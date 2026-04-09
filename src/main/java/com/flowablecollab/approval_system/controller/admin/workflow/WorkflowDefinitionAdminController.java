package com.flowablecollab.approval_system.controller.admin.workflow;

import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowDefinitionService;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowManageDtos;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/workflow-definitions")
@RequiredArgsConstructor
public class WorkflowDefinitionAdminController {

    private final WorkflowDefinitionService workflowDefinitionService;

    @PostMapping
    @PreAuthorize("hasRole('SYS_ADMIN')")
    public ResponseEntity<WorkflowManageDtos.WorkflowDefinitionView> createDefinition(
            @RequestBody WorkflowManageDtos.CreateWorkflowDefinitionRequest request) {
        return ResponseEntity.ok(workflowDefinitionService.createDefinition(request, requireOperatorId()));
    }

    @GetMapping
    @PreAuthorize("hasRole('SYS_ADMIN')")
    public ResponseEntity<WorkflowManageDtos.PageResult<WorkflowManageDtos.WorkflowDefinitionView>> listDefinitions(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        WorkflowManageDtos.QueryWorkflowDefinitionRequest request = new WorkflowManageDtos.QueryWorkflowDefinitionRequest();
        request.setKeyword(keyword);
        request.setCategory(category);
        request.setStatus(status);
        request.setPage(page);
        request.setSize(size);
        return ResponseEntity.ok(workflowDefinitionService.listDefinitions(request));
    }

    @GetMapping("/launchable")
    @PreAuthorize("hasAnyRole('ADMIN','SYS_ADMIN')")
    public ResponseEntity<java.util.List<WorkflowManageDtos.WorkflowDefinitionView>> listLaunchableDefinitions() {
        return ResponseEntity.ok(workflowDefinitionService.listLaunchableDefinitions());
    }

    @GetMapping("/{definitionId}")
    @PreAuthorize("hasRole('SYS_ADMIN')")
    public ResponseEntity<WorkflowManageDtos.WorkflowDefinitionView> getDefinition(@PathVariable Long definitionId) {
        return ResponseEntity.ok(workflowDefinitionService.getDefinition(definitionId));
    }

    @PutMapping("/{definitionId}")
    @PreAuthorize("hasRole('SYS_ADMIN')")
    public ResponseEntity<WorkflowManageDtos.WorkflowDefinitionView> updateDefinition(
            @PathVariable Long definitionId,
            @RequestBody WorkflowManageDtos.UpdateWorkflowDefinitionRequest request) {
        return ResponseEntity.ok(workflowDefinitionService.updateDefinition(definitionId, request, requireOperatorId()));
    }

    @PostMapping("/{definitionId}/inactivate")
    @PreAuthorize("hasRole('SYS_ADMIN')")
    public ResponseEntity<ActionResponse> inactivateDefinition(
            @PathVariable Long definitionId,
            @RequestBody(required = false) WorkflowManageDtos.ChangeVersionStatusRequest request) {
        workflowDefinitionService.inactivateDefinition(
                definitionId,
                requireOperatorId(),
                request == null ? null : request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Workflow definition inactivated"));
    }

    @PostMapping("/{definitionId}/archive")
    @PreAuthorize("hasRole('SYS_ADMIN')")
    public ResponseEntity<ActionResponse> archiveDefinition(
            @PathVariable Long definitionId,
            @RequestBody(required = false) WorkflowManageDtos.ChangeVersionStatusRequest request) {
        workflowDefinitionService.archiveDefinition(
                definitionId,
                requireOperatorId(),
                request == null ? null : request.getComment());
        return ResponseEntity.ok(ActionResponse.ok("Workflow definition archived"));
    }

    private Long requireOperatorId() {
        Long operatorId = SecurityUtils.currentUserId();
        if (operatorId == null) {
            throw new IllegalArgumentException("operator not found");
        }
        return operatorId;
    }

    public record ActionResponse(boolean success, String message) {
        public static ActionResponse ok(String message) {
            return new ActionResponse(true, message);
        }
    }
}
