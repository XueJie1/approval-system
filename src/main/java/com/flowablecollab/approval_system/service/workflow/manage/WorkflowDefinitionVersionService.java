package com.flowablecollab.approval_system.service.workflow.manage;

import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.entity.workflow.WorkflowNodeConfig;
import com.flowablecollab.approval_system.exception.WorkflowValidationException;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowNodeConfigRepository;
import lombok.RequiredArgsConstructor;
import org.flowable.bpmn.converter.BpmnXMLConverter;
import org.flowable.bpmn.model.BpmnModel;
import org.flowable.bpmn.model.Process;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamReader;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class WorkflowDefinitionVersionService {

    private static final int NOT_DELETED = 0;

    private final WorkflowDefinitionRepository workflowDefinitionRepository;
    private final WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;
    private final WorkflowNodeConfigRepository workflowNodeConfigRepository;
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
        } else {
            String defaultBpmnXml = buildDefaultBpmnXml(definition.getProcessKey(), definition.getProcessName());
            ParsedMainProcess parsedMainProcess = parseMainProcess(defaultBpmnXml);
            if (!definition.getProcessKey().equals(parsedMainProcess.processId())) {
                throw new WorkflowValidationException(
                        WorkflowValidationException.BPMN_KEY_MISMATCH,
                        "processKey does not match BPMN process id",
                        Map.of("processKey", definition.getProcessKey(), "processId", parsedMainProcess.processId()));
            }
            draft.setBpmnXml(defaultBpmnXml);
            draft.setBpmnChecksum(calculateChecksum(defaultBpmnXml));
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
            throw new WorkflowValidationException(
                    WorkflowValidationException.BPMN_XML_INVALID,
                    "bpmnXml is required");
        }
        if (request.getFormVersionId() == null) {
            throw new WorkflowValidationException(
                    WorkflowValidationException.FORM_VERSION_REQUIRED,
                    "formVersionId is required");
        }
        validateBpmnForSave(request.getBpmnXml(), version.getDefinitionId());
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

    private String buildDefaultBpmnXml(String processKey, String processName) {
        String safeProcessName = processName == null || processName.isBlank() ? processKey : processName;
        return """
                <?xml version="1.0" encoding="UTF-8"?>
                <bpmn:definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
                  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
                  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
                  xmlns:flowable="http://flowable.org/bpmn"
                  id="Definitions_1"
                  targetNamespace="http://www.flowable.org/processdef">
                  <bpmn:process id="%s" name="%s" isExecutable="true">
                    <bpmn:startEvent id="StartEvent_1" name="开始">
                      <bpmn:outgoing>Flow_1</bpmn:outgoing>
                    </bpmn:startEvent>
                    <bpmn:userTask id="Activity_Approve" name="审批">
                      <bpmn:incoming>Flow_1</bpmn:incoming>
                      <bpmn:outgoing>Flow_2</bpmn:outgoing>
                    </bpmn:userTask>
                    <bpmn:endEvent id="EndEvent_1" name="结束">
                      <bpmn:incoming>Flow_2</bpmn:incoming>
                    </bpmn:endEvent>
                    <bpmn:sequenceFlow id="Flow_1" sourceRef="StartEvent_1" targetRef="Activity_Approve" />
                    <bpmn:sequenceFlow id="Flow_2" sourceRef="Activity_Approve" targetRef="EndEvent_1" />
                  </bpmn:process>
                  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
                    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="%s">
                      <bpmndi:BPMNShape id="StartEvent_1_di" bpmnElement="StartEvent_1">
                        <dc:Bounds x="150" y="120" width="36" height="36" />
                      </bpmndi:BPMNShape>
                      <bpmndi:BPMNShape id="Activity_Approve_di" bpmnElement="Activity_Approve">
                        <dc:Bounds x="250" y="98" width="100" height="80" />
                      </bpmndi:BPMNShape>
                      <bpmndi:BPMNShape id="EndEvent_1_di" bpmnElement="EndEvent_1">
                        <dc:Bounds x="430" y="120" width="36" height="36" />
                      </bpmndi:BPMNShape>
                      <bpmndi:BPMNEdge id="Flow_1_di" bpmnElement="Flow_1">
                        <di:waypoint x="186" y="138" />
                        <di:waypoint x="250" y="138" />
                      </bpmndi:BPMNEdge>
                      <bpmndi:BPMNEdge id="Flow_2_di" bpmnElement="Flow_2">
                        <di:waypoint x="350" y="138" />
                        <di:waypoint x="430" y="138" />
                      </bpmndi:BPMNEdge>
                    </bpmndi:BPMNPlane>
                  </bpmndi:BPMNDiagram>
                </bpmn:definitions>
                """.formatted(processKey, safeProcessName, processKey);
    }

    private void validateBpmnForSave(String bpmnXml, Long definitionId) {
        ParsedMainProcess parsed = parseMainProcess(bpmnXml);
        WorkflowDefinition definition = workflowDefinitionService.getDefinitionEntity(definitionId);
        if (!definition.getProcessKey().equals(parsed.processId())) {
            throw new WorkflowValidationException(
                    WorkflowValidationException.BPMN_KEY_MISMATCH,
                    "processKey does not match BPMN process id",
                    Map.of("processKey", definition.getProcessKey(), "processId", parsed.processId()));
        }
    }

    ParsedMainProcess parseMainProcess(String bpmnXml) {
        try {
            XMLInputFactory factory = XMLInputFactory.newInstance();
            XMLStreamReader reader = factory.createXMLStreamReader(
                    new ByteArrayInputStream(bpmnXml.getBytes(StandardCharsets.UTF_8)));
            BpmnModel model = new BpmnXMLConverter().convertToBpmnModel(reader);
            List<Process> processes = model.getProcesses();
            if (processes == null || processes.size() != 1) {
                int count = processes == null ? 0 : processes.size();
                throw new WorkflowValidationException(
                        WorkflowValidationException.BPMN_PROCESS_COUNT_INVALID,
                        "BPMN must contain exactly 1 process",
                        Map.of("processCount", count));
            }
            Process process = processes.get(0);
            String processId = process.getId();
            if (processId == null || processId.isBlank()) {
                throw new WorkflowValidationException(
                        WorkflowValidationException.BPMN_XML_INVALID,
                        "BPMN process id is required");
            }
            return new ParsedMainProcess(processId);
        } catch (WorkflowValidationException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowValidationException(
                    WorkflowValidationException.BPMN_XML_INVALID,
                    "Invalid BPMN XML");
        }
    }

    record ParsedMainProcess(String processId) {
    }
}
