package com.flowablecollab.approval_system.controller.admin.workflow;

import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowManageDtos;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowNodeConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@PreAuthorize("hasRole('SYS_ADMIN')")
public class WorkflowNodeConfigAdminController {

    private final WorkflowNodeConfigService workflowNodeConfigService;

    @GetMapping("/api/admin/workflow-definition-versions/{versionId}/nodes")
    public ResponseEntity<List<WorkflowManageDtos.WorkflowNodeConfigView>> listNodes(@PathVariable Long versionId) {
        return ResponseEntity.ok(workflowNodeConfigService.listNodeConfigs(versionId));
    }

    @PutMapping("/api/admin/workflow-definition-versions/{versionId}/nodes")
    public ResponseEntity<List<WorkflowManageDtos.WorkflowNodeConfigView>> saveNodes(
            @PathVariable Long versionId,
            @RequestBody WorkflowManageDtos.BatchSaveWorkflowNodeConfigRequest request) {
        return ResponseEntity.ok(workflowNodeConfigService.saveNodeConfigs(versionId, request, requireOperatorId()));
    }

    private Long requireOperatorId() {
        Long operatorId = SecurityUtils.currentUserId();
        if (operatorId == null) {
            throw new IllegalArgumentException("operator not found");
        }
        return operatorId;
    }
}
