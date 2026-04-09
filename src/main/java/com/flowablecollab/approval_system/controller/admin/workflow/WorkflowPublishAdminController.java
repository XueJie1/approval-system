package com.flowablecollab.approval_system.controller.admin.workflow;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowManageDtos;
import com.flowablecollab.approval_system.service.workflow.manage.WorkflowPublishService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@PreAuthorize("hasRole('SYS_ADMIN')")
public class WorkflowPublishAdminController {

    private final WorkflowPublishService workflowPublishService;
    private final BizRequestRepository bizRequestRepository;

    @PostMapping("/api/admin/workflow-definition-versions/{versionId}/publish")
    public ResponseEntity<WorkflowManageDtos.WorkflowDefinitionVersionView> publish(
            @PathVariable Long versionId,
            @RequestBody(required = false) WorkflowManageDtos.ChangeVersionStatusRequest request) {
        return ResponseEntity.ok(workflowPublishService.publish(versionId, requireOperatorId(), comment(request)));
    }

    @PostMapping("/api/admin/workflow-definition-versions/{versionId}/inactivate")
    public ResponseEntity<WorkflowDefinitionAdminController.ActionResponse> inactivate(
            @PathVariable Long versionId,
            @RequestBody(required = false) WorkflowManageDtos.ChangeVersionStatusRequest request) {
        workflowPublishService.inactivateVersion(versionId, requireOperatorId(), comment(request));
        return ResponseEntity.ok(WorkflowDefinitionAdminController.ActionResponse.ok("Workflow version inactivated"));
    }

    @PostMapping("/api/admin/workflow-definition-versions/{versionId}/activate")
    public ResponseEntity<WorkflowManageDtos.WorkflowDefinitionVersionView> activate(
            @PathVariable Long versionId,
            @RequestBody(required = false) WorkflowManageDtos.ChangeVersionStatusRequest request) {
        return ResponseEntity.ok(workflowPublishService.activateVersion(versionId, requireOperatorId(), comment(request)));
    }

    @PostMapping("/api/admin/workflow-definition-versions/{versionId}/retire")
    public ResponseEntity<WorkflowDefinitionAdminController.ActionResponse> retire(
            @PathVariable Long versionId,
            @RequestBody(required = false) WorkflowManageDtos.ChangeVersionStatusRequest request) {
        workflowPublishService.retireVersion(versionId, requireOperatorId(), comment(request));
        return ResponseEntity.ok(WorkflowDefinitionAdminController.ActionResponse.ok("Workflow version retired"));
    }

    @GetMapping("/api/admin/workflow-definition-versions/{versionId}/publish-logs")
    public ResponseEntity<List<WorkflowManageDtos.WorkflowPublishLogView>> listLogs(@PathVariable Long versionId) {
        return ResponseEntity.ok(workflowPublishService.listLogs(versionId));
    }

    @GetMapping("/api/admin/workflow-definition-versions/{versionId}/usage")
    public ResponseEntity<WorkflowManageDtos.WorkflowVersionUsageView> usage(@PathVariable Long versionId) {
        WorkflowManageDtos.WorkflowVersionUsageView view = new WorkflowManageDtos.WorkflowVersionUsageView();
        long total = bizRequestRepository.countByWorkflowDefinitionVersionId(versionId);
        long running = bizRequestRepository.countByWorkflowDefinitionVersionIdAndFinishTimeIsNull(versionId);
        List<BizRequest> recent = bizRequestRepository.findTop10ByWorkflowDefinitionVersionIdOrderBySubmitTimeDescIdDesc(versionId);
        view.setDefinitionVersionId(versionId);
        view.setTotalCount(total);
        view.setRunningCount(running);
        view.setFinishedCount(Math.max(total - running, 0));
        view.setRecentRequests(recent.stream().map(this::toUsageItem).toList());
        return ResponseEntity.ok(view);
    }

    private WorkflowManageDtos.WorkflowInstanceUsageItem toUsageItem(BizRequest request) {
        WorkflowManageDtos.WorkflowInstanceUsageItem item = new WorkflowManageDtos.WorkflowInstanceUsageItem();
        item.setRequestId(request.getId());
        item.setBusinessKey(request.getBusinessKey());
        item.setProcessInstanceId(request.getProcessInstanceId());
        item.setTitle(request.getTitle());
        item.setStatus(request.getStatus());
        item.setSubmitTime(request.getSubmitTime());
        item.setFinishTime(request.getFinishTime());
        return item;
    }

    private String comment(WorkflowManageDtos.ChangeVersionStatusRequest request) {
        return request == null ? null : request.getComment();
    }

    private Long requireOperatorId() {
        Long operatorId = SecurityUtils.currentUserId();
        if (operatorId == null) {
            throw new IllegalArgumentException("operator not found");
        }
        return operatorId;
    }
}
