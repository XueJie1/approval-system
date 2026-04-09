package com.flowablecollab.approval_system.controller.admin.workflow;

import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowDefinitionVersionService;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowManageDtos;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@PreAuthorize("hasRole('SYS_ADMIN')")
public class WorkflowDefinitionVersionAdminController {

    private final WorkflowDefinitionVersionService workflowDefinitionVersionService;

    public WorkflowDefinitionVersionAdminController(WorkflowDefinitionVersionService workflowDefinitionVersionService) {
        this.workflowDefinitionVersionService = workflowDefinitionVersionService;
    }

    @PostMapping("/api/admin/workflow-definitions/{definitionId}/versions")
    public ResponseEntity<WorkflowManageDtos.WorkflowDefinitionVersionView> createDraft(
            @PathVariable Long definitionId,
            @RequestBody WorkflowManageDtos.CreateWorkflowVersionRequest request) {
        return ResponseEntity.ok(workflowDefinitionVersionService.createDraft(definitionId, request, requireOperatorId()));
    }

    @GetMapping("/api/admin/workflow-definitions/{definitionId}/versions")
    public ResponseEntity<List<WorkflowManageDtos.WorkflowDefinitionVersionView>> listVersions(@PathVariable Long definitionId) {
        return ResponseEntity.ok(workflowDefinitionVersionService.listVersions(definitionId));
    }

    @GetMapping("/api/admin/workflow-definition-versions/{versionId}")
    public ResponseEntity<WorkflowManageDtos.WorkflowDefinitionVersionView> getVersion(@PathVariable Long versionId) {
        return ResponseEntity.ok(workflowDefinitionVersionService.getVersion(versionId));
    }

    @PutMapping("/api/admin/workflow-definition-versions/{versionId}")
    public ResponseEntity<WorkflowManageDtos.WorkflowDefinitionVersionView> updateDraft(
            @PathVariable Long versionId,
            @RequestBody WorkflowManageDtos.UpdateWorkflowVersionRequest request) {
        return ResponseEntity.ok(workflowDefinitionVersionService.updateDraft(versionId, request, requireOperatorId()));
    }

    @DeleteMapping("/api/admin/workflow-definition-versions/{versionId}")
    public ResponseEntity<WorkflowDefinitionAdminController.ActionResponse> deleteDraft(@PathVariable Long versionId) {
        workflowDefinitionVersionService.deleteDraft(versionId, requireOperatorId());
        return ResponseEntity.ok(WorkflowDefinitionAdminController.ActionResponse.ok("Workflow draft deleted"));
    }

    private Long requireOperatorId() {
        Long operatorId = SecurityUtils.currentUserId();
        if (operatorId == null) {
            throw new IllegalArgumentException("operator not found");
        }
        return operatorId;
    }
}
