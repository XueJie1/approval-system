package com.flowablecollab.approval_system.service.workflow.manage;

import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.entity.workflow.WorkflowPublishLog;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowPublishLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class WorkflowPublishService {

    private static final int NOT_DELETED = 0;

    private final WorkflowDefinitionRepository workflowDefinitionRepository;
    private final WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;
    private final WorkflowPublishLogRepository workflowPublishLogRepository;
    private final WorkflowDefinitionService workflowDefinitionService;
    private final WorkflowDefinitionVersionService workflowDefinitionVersionService;
    private final WorkflowNodeConfigService workflowNodeConfigService;
    private final FlowableDeploymentService flowableDeploymentService;

    @Transactional
    public WorkflowManageDtos.WorkflowDefinitionVersionView publish(Long versionId, Long operatorId, String comment) {
        WorkflowDefinitionVersion version = workflowDefinitionVersionService.getVersionEntity(versionId);
        workflowDefinitionVersionService.ensureDraft(version);
        WorkflowDefinition definition = workflowDefinitionService.getDefinitionEntity(version.getDefinitionId());
        if (WorkflowDefinition.STATUS_ARCHIVED.equals(definition.getStatus())) {
            throw new IllegalArgumentException("archived workflow definition cannot publish");
        }
        validatePublish(version);
        try {
            FlowableDeploymentService.FlowableDeploymentResult deployment = flowableDeploymentService
                    .deploy(definition.getProcessKey(), version.getBpmnXml());
            WorkflowDefinitionVersion current = workflowDefinitionVersionService.getCurrentPublishedVersion(definition.getId());
            if (current != null) {
                current.setStatus(WorkflowDefinitionVersion.STATUS_INACTIVE);
                workflowDefinitionVersionRepository.save(current);
            }
            version.setStatus(WorkflowDefinitionVersion.STATUS_PUBLISHED);
            version.setFlowableDeploymentId(deployment.getDeploymentId());
            version.setFlowableProcessDefinitionId(deployment.getProcessDefinitionId());
            version.setPublishedBy(operatorId);
            version.setPublishedAt(LocalDateTime.now());
            version.setUpdatedBy(operatorId);
            workflowDefinitionVersionRepository.save(version);

            definition.setCurrentVersionId(version.getId());
            definition.setStatus(WorkflowDefinition.STATUS_ACTIVE);
            definition.setUpdatedBy(operatorId);
            workflowDefinitionRepository.save(definition);
            saveLog(version, operatorId, WorkflowPublishLog.ACTION_PUBLISH, WorkflowPublishLog.RESULT_SUCCESS,
                    comment, version.getFlowableDeploymentId(), version.getFlowableProcessDefinitionId());
            return workflowDefinitionVersionService.toVersionView(version);
        } catch (RuntimeException ex) {
            saveLog(version, operatorId, WorkflowPublishLog.ACTION_PUBLISH, WorkflowPublishLog.RESULT_FAIL,
                    ex.getMessage(), null, null);
            throw ex;
        }
    }

    @Transactional
    public void inactivateVersion(Long versionId, Long operatorId, String comment) {
        WorkflowDefinitionVersion version = workflowDefinitionVersionService.getVersionEntity(versionId);
        if (!WorkflowDefinitionVersion.STATUS_PUBLISHED.equals(version.getStatus())) {
            throw new IllegalArgumentException("only published version can be inactivated");
        }
        WorkflowDefinition definition = workflowDefinitionService.getDefinitionEntity(version.getDefinitionId());
        version.setStatus(WorkflowDefinitionVersion.STATUS_INACTIVE);
        version.setUpdatedBy(operatorId);
        workflowDefinitionVersionRepository.save(version);
        if (version.getId().equals(definition.getCurrentVersionId())) {
            definition.setCurrentVersionId(null);
            definition.setStatus(WorkflowDefinition.STATUS_INACTIVE);
            definition.setUpdatedBy(operatorId);
            workflowDefinitionRepository.save(definition);
        }
        saveLog(version, operatorId, WorkflowPublishLog.ACTION_INACTIVATE, WorkflowPublishLog.RESULT_SUCCESS,
                comment, version.getFlowableDeploymentId(), version.getFlowableProcessDefinitionId());
    }

    @Transactional
    public WorkflowManageDtos.WorkflowDefinitionVersionView activateVersion(Long versionId, Long operatorId, String comment) {
        WorkflowDefinitionVersion version = workflowDefinitionVersionService.getVersionEntity(versionId);
        if (!WorkflowDefinitionVersion.STATUS_INACTIVE.equals(version.getStatus())) {
            throw new IllegalArgumentException("only inactive version can be activated");
        }
        if (version.getFlowableProcessDefinitionId() == null || version.getFlowableProcessDefinitionId().isBlank()) {
            throw new IllegalArgumentException("inactive version is not deployable");
        }
        WorkflowDefinition definition = workflowDefinitionService.getDefinitionEntity(version.getDefinitionId());
        WorkflowDefinitionVersion current = workflowDefinitionVersionService.getCurrentPublishedVersion(definition.getId());
        if (current != null) {
            current.setStatus(WorkflowDefinitionVersion.STATUS_INACTIVE);
            workflowDefinitionVersionRepository.save(current);
        }
        version.setStatus(WorkflowDefinitionVersion.STATUS_PUBLISHED);
        version.setUpdatedBy(operatorId);
        workflowDefinitionVersionRepository.save(version);
        definition.setCurrentVersionId(version.getId());
        definition.setStatus(WorkflowDefinition.STATUS_ACTIVE);
        definition.setUpdatedBy(operatorId);
        workflowDefinitionRepository.save(definition);
        saveLog(version, operatorId, WorkflowPublishLog.ACTION_ACTIVATE, WorkflowPublishLog.RESULT_SUCCESS,
                comment, version.getFlowableDeploymentId(), version.getFlowableProcessDefinitionId());
        return workflowDefinitionVersionService.toVersionView(version);
    }

    @Transactional
    public void retireVersion(Long versionId, Long operatorId, String comment) {
        WorkflowDefinitionVersion version = workflowDefinitionVersionService.getVersionEntity(versionId);
        if (!List.of(WorkflowDefinitionVersion.STATUS_PUBLISHED, WorkflowDefinitionVersion.STATUS_INACTIVE).contains(version.getStatus())) {
            throw new IllegalArgumentException("only published or inactive version can be retired");
        }
        WorkflowDefinition definition = workflowDefinitionService.getDefinitionEntity(version.getDefinitionId());
        if (version.getId().equals(definition.getCurrentVersionId())) {
            throw new IllegalArgumentException("current published version cannot be retired directly");
        }
        version.setStatus(WorkflowDefinitionVersion.STATUS_RETIRED);
        version.setUpdatedBy(operatorId);
        workflowDefinitionVersionRepository.save(version);
        saveLog(version, operatorId, WorkflowPublishLog.ACTION_RETIRE, WorkflowPublishLog.RESULT_SUCCESS,
                comment, version.getFlowableDeploymentId(), version.getFlowableProcessDefinitionId());
    }

    @Transactional(readOnly = true)
    public List<WorkflowManageDtos.WorkflowPublishLogView> listLogs(Long versionId) {
        workflowDefinitionVersionService.getVersionEntity(versionId);
        return workflowPublishLogRepository.findByDefinitionVersionIdOrderByOperatedAtDesc(versionId)
                .stream()
                .map(this::toLogView)
                .toList();
    }

    private void validatePublish(WorkflowDefinitionVersion version) {
        if (version.getBpmnXml() == null || version.getBpmnXml().isBlank()) {
            throw new IllegalArgumentException("draft version bpmnXml is required");
        }
        workflowNodeConfigService.parseBpmnNodes(version.getBpmnXml());
        if (version.getFormVersionId() == null) {
            throw new IllegalArgumentException("draft version formVersionId is required");
        }
        workflowNodeConfigService.validateNodeConfigs(version.getId());
    }

    private void saveLog(WorkflowDefinitionVersion version, Long operatorId, String action, String result,
            String message, String deploymentId, String processDefinitionId) {
        WorkflowPublishLog log = new WorkflowPublishLog();
        log.setDefinitionId(version.getDefinitionId());
        log.setDefinitionVersionId(version.getId());
        log.setAction(action);
        log.setResult(result);
        log.setMessage(message);
        log.setFlowableDeploymentId(deploymentId);
        log.setFlowableProcessDefinitionId(processDefinitionId);
        log.setOperatorId(operatorId);
        workflowPublishLogRepository.save(log);
    }

    private WorkflowManageDtos.WorkflowPublishLogView toLogView(WorkflowPublishLog log) {
        WorkflowManageDtos.WorkflowPublishLogView view = new WorkflowManageDtos.WorkflowPublishLogView();
        view.setId(log.getId());
        view.setDefinitionId(log.getDefinitionId());
        view.setDefinitionVersionId(log.getDefinitionVersionId());
        view.setAction(log.getAction());
        view.setResult(log.getResult());
        view.setMessage(log.getMessage());
        view.setFlowableDeploymentId(log.getFlowableDeploymentId());
        view.setFlowableProcessDefinitionId(log.getFlowableProcessDefinitionId());
        view.setOperatorId(log.getOperatorId());
        view.setOperatedAt(log.getOperatedAt());
        return view;
    }
}
