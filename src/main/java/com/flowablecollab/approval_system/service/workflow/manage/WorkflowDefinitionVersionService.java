package com.flowablecollab.approval_system.service.workflow.manage;

import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.entity.workflow.WorkflowNodeConfig;
import com.flowablecollab.approval_system.repository.form.FormVersionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowNodeConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;

@Service
@RequiredArgsConstructor
public class WorkflowDefinitionVersionService {

    private static final int NOT_DELETED = 0;

    private final WorkflowDefinitionRepository workflowDefinitionRepository;
    private final WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;
    private final WorkflowNodeConfigRepository workflowNodeConfigRepository;
    private final FormVersionRepository formVersionRepository;
    private final com.flowablecollab.approval_system.service.FormService formService;
    private final WorkflowDefinitionService workflowDefinitionService;

    @Transactional
    public WorkflowManageDtos.WorkflowDefinitionVersionView createDraft(
            Long definitionId,
            WorkflowManageDtos.CreateWorkflowVersionRequest request,
            Long operatorId) {
        WorkflowDefinition definition = workflowDefinitionService.getDefinitionEntity(definitionId);
        if (WorkflowDefinition.STATUS_ARCHIVED.equals(definition.getStatus())) {
            throw new IllegalArgumentException("archived workflow definition cannot create version");
        }

        int nextVersionNo = definition.getLatestVersionNo() + 1;
        WorkflowDefinitionVersion draft = new WorkflowDefinitionVersion();
        draft.setDefinitionId(definitionId);
        draft.setVersionNo(nextVersionNo);
        draft.setVersionLabel(request.getVersionLabel());
        draft.setChangeSummary(request.getChangeSummary());
        draft.setCreatedBy(operatorId);
        draft.setUpdatedBy(operatorId);

        if (request.getCopyFromVersionId() != null) {
            WorkflowDefinitionVersion source = getVersionEntity(request.getCopyFromVersionId());
            if (!source.getDefinitionId().equals(definitionId)) {
                throw new IllegalArgumentException("copy source version does not belong to definition");
            }
            draft.setBpmnXml(source.getBpmnXml());
            draft.setBpmnChecksum(source.getBpmnChecksum());
            draft.setFormKey(source.getFormKey());
            draft.setFormVersionId(source.getFormVersionId());
            if (draft.getChangeSummary() == null || draft.getChangeSummary().isBlank()) {
                draft.setChangeSummary(source.getChangeSummary());
            }
        }

        workflowDefinitionVersionRepository.save(draft);
        definition.setLatestVersionNo(nextVersionNo);
        definition.setUpdatedBy(operatorId);
        workflowDefinitionRepository.save(definition);

        if (request.getCopyFromVersionId() != null) {
            copyNodeConfigs(request.getCopyFromVersionId(), draft.getId());
        }

        return toVersionView(draft);
    }

    @Transactional(readOnly = true)
    public List<WorkflowManageDtos.WorkflowDefinitionVersionView> listVersions(Long definitionId) {
        workflowDefinitionService.getDefinitionEntity(definitionId);
        return workflowDefinitionVersionRepository.findByDefinitionIdAndIsDeletedOrderByVersionNoDesc(definitionId, NOT_DELETED)
                .stream()
                .map(this::toVersionView)
                .toList();
    }

    @Transactional(readOnly = true)
    public WorkflowManageDtos.WorkflowDefinitionVersionView getVersion(Long versionId) {
        return toVersionView(getVersionEntity(versionId));
    }

    @Transactional
    public WorkflowManageDtos.WorkflowDefinitionVersionView updateDraft(
            Long versionId,
            WorkflowManageDtos.UpdateWorkflowVersionRequest request,
            Long operatorId) {
        WorkflowDefinitionVersion version = getVersionEntity(versionId);
        ensureDraft(version);
        if (request.getBpmnXml() == null || request.getBpmnXml().isBlank()) {
            throw new IllegalArgumentException("bpmnXml is required");
        }
        if (request.getFormVersionId() == null) {
            throw new IllegalArgumentException("formVersionId is required");
        }
        com.flowablecollab.approval_system.service.FormService.BoundFormVersion boundForm =
                formService.resolveBoundFormVersion(request.getFormVersionId());
        FormVersion formVersion = boundForm.getFormVersion();
        version.setVersionLabel(request.getVersionLabel());
        version.setBpmnXml(request.getBpmnXml());
        version.setBpmnChecksum(calculateChecksum(request.getBpmnXml()));
        String formKey = request.getFormKey();
        if (formKey != null && !formKey.isBlank() && !formKey.equals(boundForm.getFormDefinition().getFormKey())) {
            throw new IllegalArgumentException("formKey does not match selected formVersionId");
        }
        version.setFormKey(boundForm.getFormDefinition().getFormKey());
        version.setFormVersionId(formVersion.getId());
        version.setChangeSummary(request.getChangeSummary());
        version.setUpdatedBy(operatorId);
        workflowDefinitionVersionRepository.save(version);
        return toVersionView(version);
    }

    @Transactional
    public void deleteDraft(Long versionId, Long operatorId) {
        WorkflowDefinitionVersion version = getVersionEntity(versionId);
        ensureDraft(version);
        version.setIsDeleted(1);
        version.setUpdatedBy(operatorId);
        workflowDefinitionVersionRepository.save(version);
    }

    @Transactional(readOnly = true)
    public WorkflowDefinitionVersion getVersionEntity(Long versionId) {
        return workflowDefinitionVersionRepository.findByIdAndIsDeleted(versionId, NOT_DELETED)
                .orElseThrow(() -> new IllegalArgumentException("workflow definition version not found"));
    }

    @Transactional(readOnly = true)
    public WorkflowDefinitionVersion getCurrentPublishedVersion(Long definitionId) {
        return workflowDefinitionVersionRepository.findByDefinitionIdAndStatusAndIsDeleted(
                definitionId,
                WorkflowDefinitionVersion.STATUS_PUBLISHED,
                NOT_DELETED).orElse(null);
    }

    void ensureDraft(WorkflowDefinitionVersion version) {
        if (!WorkflowDefinitionVersion.STATUS_DRAFT.equals(version.getStatus())) {
            throw new IllegalArgumentException("only draft version can be modified");
        }
    }

    WorkflowManageDtos.WorkflowDefinitionVersionView toVersionView(WorkflowDefinitionVersion version) {
        WorkflowManageDtos.WorkflowDefinitionVersionView view = new WorkflowManageDtos.WorkflowDefinitionVersionView();
        view.setId(version.getId());
        view.setDefinitionId(version.getDefinitionId());
        view.setVersionNo(version.getVersionNo());
        view.setVersionLabel(version.getVersionLabel());
        view.setStatus(version.getStatus());
        view.setBpmnXml(version.getBpmnXml());
        view.setBpmnChecksum(version.getBpmnChecksum());
        view.setFlowableDeploymentId(version.getFlowableDeploymentId());
        view.setFlowableProcessDefinitionId(version.getFlowableProcessDefinitionId());
        view.setFormKey(version.getFormKey());
        view.setFormVersionId(version.getFormVersionId());
        view.setChangeSummary(version.getChangeSummary());
        view.setPublishedBy(version.getPublishedBy());
        view.setPublishedAt(version.getPublishedAt());
        view.setCreatedAt(version.getCreatedAt());
        view.setUpdatedAt(version.getUpdatedAt());
        return view;
    }

    String calculateChecksum(String content) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(content.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 not available", ex);
        }
    }

    private void copyNodeConfigs(Long sourceVersionId, Long targetVersionId) {
        List<WorkflowNodeConfig> sourceConfigs = workflowNodeConfigRepository
                .findByDefinitionVersionIdOrderBySortOrderAscIdAsc(sourceVersionId);
        for (WorkflowNodeConfig source : sourceConfigs) {
            WorkflowNodeConfig target = new WorkflowNodeConfig();
            target.setDefinitionVersionId(targetVersionId);
            target.setNodeId(source.getNodeId());
            target.setNodeName(source.getNodeName());
            target.setNodeType(source.getNodeType());
            target.setApprovalType(source.getApprovalType());
            target.setAssigneeStrategy(source.getAssigneeStrategy());
            target.setAssigneeConfigJson(source.getAssigneeConfigJson());
            target.setCommentRequired(source.getCommentRequired());
            target.setAllowDelegate(source.getAllowDelegate());
            target.setAllowReassign(source.getAllowReassign());
            target.setAllowReturnPrevious(source.getAllowReturnPrevious());
            target.setAllowReturnApplicant(source.getAllowReturnApplicant());
            target.setAiEnabled(source.getAiEnabled());
            target.setTimeoutRuleJson(source.getTimeoutRuleJson());
            target.setExtraConfigJson(source.getExtraConfigJson());
            target.setSortOrder(source.getSortOrder());
            workflowNodeConfigRepository.save(target);
        }
    }
}
