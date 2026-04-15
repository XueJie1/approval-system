package com.flowablecollab.approval_system.service.workflow.manage;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.entity.workflow.WorkflowNodeConfig;
import com.flowablecollab.approval_system.exception.WorkflowValidationException;
import com.flowablecollab.approval_system.repository.workflow.WorkflowNodeConfigRepository;
import lombok.RequiredArgsConstructor;
import org.flowable.bpmn.converter.BpmnXMLConverter;
import org.flowable.bpmn.model.BpmnModel;
import org.flowable.bpmn.model.FlowElement;
import org.flowable.bpmn.model.Process;
import org.flowable.bpmn.model.StartEvent;
import org.flowable.bpmn.model.UserTask;
import org.flowable.bpmn.model.ServiceTask;
import org.flowable.bpmn.model.ExclusiveGateway;
import org.flowable.bpmn.model.ParallelGateway;
import org.flowable.bpmn.model.EndEvent;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamReader;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class WorkflowNodeConfigService {

    private final WorkflowDefinitionVersionService workflowDefinitionVersionService;
    private final WorkflowNodeConfigRepository workflowNodeConfigRepository;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public List<WorkflowManageDtos.WorkflowNodeConfigView> listNodeConfigs(Long versionId) {
        WorkflowDefinitionVersion version = workflowDefinitionVersionService.getVersionEntity(versionId);
        List<WorkflowManageDtos.BpmnNodeSnapshot> snapshots = parseBpmnNodes(version.getBpmnXml());
        Map<String, WorkflowNodeConfig> savedMap = new LinkedHashMap<>();
        for (WorkflowNodeConfig config : workflowNodeConfigRepository.findByDefinitionVersionIdOrderBySortOrderAscIdAsc(versionId)) {
            savedMap.put(config.getNodeId(), config);
        }
        List<WorkflowManageDtos.WorkflowNodeConfigView> result = new ArrayList<>();
        for (WorkflowManageDtos.BpmnNodeSnapshot snapshot : snapshots) {
            WorkflowNodeConfig saved = savedMap.get(snapshot.getNodeId());
            result.add(toNodeConfigView(snapshot, saved));
        }
        return result;
    }

    @Transactional
    public List<WorkflowManageDtos.WorkflowNodeConfigView> saveNodeConfigs(
            Long versionId,
            WorkflowManageDtos.BatchSaveWorkflowNodeConfigRequest request,
            Long operatorId) {
        WorkflowDefinitionVersion version = workflowDefinitionVersionService.getVersionEntity(versionId);
        workflowDefinitionVersionService.ensureDraft(version);
        List<WorkflowManageDtos.BpmnNodeSnapshot> snapshots = parseBpmnNodes(version.getBpmnXml());
        replaceNodeConfigs(versionId, request.getNodes(), snapshots);
        return listNodeConfigs(versionId);
    }

    @Transactional
    public void bootstrapNodeConfigs(Long versionId, String bpmnXml) {
        List<WorkflowManageDtos.BpmnNodeSnapshot> snapshots = parseBpmnNodes(bpmnXml);
        List<WorkflowManageDtos.WorkflowNodeConfigItemRequest> nodes = snapshots.stream().map(snapshot -> {
            WorkflowManageDtos.WorkflowNodeConfigItemRequest item = new WorkflowManageDtos.WorkflowNodeConfigItemRequest();
            item.setNodeId(snapshot.getNodeId());
            item.setNodeName(snapshot.getNodeName());
            item.setNodeType(snapshot.getNodeType());
            item.setSortOrder(snapshot.getSortOrder());
            return item;
        }).toList();
        replaceNodeConfigs(versionId, nodes, snapshots);
    }

    private void replaceNodeConfigs(
            Long versionId,
            List<WorkflowManageDtos.WorkflowNodeConfigItemRequest> requestNodes,
            List<WorkflowManageDtos.BpmnNodeSnapshot> snapshots) {
        Map<String, WorkflowManageDtos.BpmnNodeSnapshot> snapshotMap = new LinkedHashMap<>();
        for (WorkflowManageDtos.BpmnNodeSnapshot snapshot : snapshots) {
            snapshotMap.put(snapshot.getNodeId(), snapshot);
        }
        List<WorkflowManageDtos.WorkflowNodeConfigItemRequest> nodes = requestNodes == null ? List.of() : requestNodes;
        for (WorkflowManageDtos.WorkflowNodeConfigItemRequest item : nodes) {
            if (!snapshotMap.containsKey(item.getNodeId())) {
                throw new WorkflowValidationException(
                        WorkflowValidationException.NODE_CONFIG_MISMATCH,
                        "nodeId not found in BPMN",
                        Map.of("nodeId", item.getNodeId(), "reason", "CONFIG_NODE_NOT_IN_BPMN"));
            }
        }
        workflowNodeConfigRepository.deleteByDefinitionVersionId(versionId);
        for (WorkflowManageDtos.WorkflowNodeConfigItemRequest item : nodes) {
            WorkflowManageDtos.BpmnNodeSnapshot snapshot = snapshotMap.get(item.getNodeId());
            WorkflowNodeConfig entity = new WorkflowNodeConfig();
            entity.setDefinitionVersionId(versionId);
            entity.setNodeId(item.getNodeId());
            entity.setNodeName(item.getNodeName() == null || item.getNodeName().isBlank() ? snapshot.getNodeName() : item.getNodeName());
            entity.setNodeType(item.getNodeType() == null || item.getNodeType().isBlank() ? snapshot.getNodeType() : item.getNodeType());
            entity.setApprovalType(item.getApprovalType());
            entity.setAssigneeStrategy(item.getAssigneeStrategy());
            entity.setAssigneeConfigJson(writeJson(item.getAssigneeConfig()));
            entity.setCommentRequired(toFlag(item.getCommentRequired(), true));
            entity.setAllowDelegate(toFlag(item.getAllowDelegate(), true));
            entity.setAllowReassign(toFlag(item.getAllowReassign(), true));
            entity.setAllowReturnPrevious(toFlag(item.getAllowReturnPrevious(), true));
            entity.setAllowReturnApplicant(toFlag(item.getAllowReturnApplicant(), true));
            entity.setAiEnabled(toFlag(item.getAiEnabled(), false));
            entity.setTimeoutRuleJson(writeJson(item.getTimeoutRule()));
            entity.setExtraConfigJson(writeJson(item.getExtraConfig()));
            entity.setSortOrder(item.getSortOrder() == null ? snapshot.getSortOrder() : item.getSortOrder());
            workflowNodeConfigRepository.save(entity);
        }
    }

    @Transactional(readOnly = true)
    public void validateNodeConfigs(Long versionId) {
        WorkflowDefinitionVersion version = workflowDefinitionVersionService.getVersionEntity(versionId);
        Map<String, WorkflowManageDtos.BpmnNodeSnapshot> snapshotMap = new LinkedHashMap<>();
        for (WorkflowManageDtos.BpmnNodeSnapshot snapshot : parseBpmnNodes(version.getBpmnXml())) {
            snapshotMap.put(snapshot.getNodeId(), snapshot);
        }
        for (WorkflowNodeConfig config : workflowNodeConfigRepository.findByDefinitionVersionIdOrderBySortOrderAscIdAsc(versionId)) {
            if (!snapshotMap.containsKey(config.getNodeId())) {
                throw new WorkflowValidationException(
                        WorkflowValidationException.NODE_CONFIG_MISMATCH,
                        "node config does not match BPMN node",
                        Map.of("nodeId", config.getNodeId(), "reason", "CONFIG_NODE_NOT_IN_BPMN"));
            }
        }
        List<WorkflowNodeConfig> configs = workflowNodeConfigRepository.findByDefinitionVersionIdOrderBySortOrderAscIdAsc(versionId);
        List<String> missingNodeConfigs = snapshotsMissingConfig(configs, snapshotMap.keySet().stream().toList());
        if (!missingNodeConfigs.isEmpty()) {
            throw new WorkflowValidationException(
                    WorkflowValidationException.NODE_CONFIG_MISMATCH,
                    "BPMN nodes missing node config",
                    Map.of("missingNodeIds", missingNodeConfigs));
        }
    }

    private List<String> snapshotsMissingConfig(List<WorkflowNodeConfig> configs, List<String> bpmnNodeIds) {
        Map<String, Boolean> configMap = new LinkedHashMap<>();
        for (WorkflowNodeConfig config : configs) {
            configMap.put(config.getNodeId(), Boolean.TRUE);
        }
        List<String> missing = new ArrayList<>();
        for (String nodeId : bpmnNodeIds) {
            if (!configMap.containsKey(nodeId)) {
                missing.add(nodeId);
            }
        }
        return missing;
    }

    public List<WorkflowManageDtos.BpmnNodeSnapshot> parseBpmnNodes(String bpmnXml) {
        if (bpmnXml == null || bpmnXml.isBlank()) {
            return List.of();
        }
        try {
            XMLInputFactory factory = XMLInputFactory.newInstance();
            XMLStreamReader reader = factory.createXMLStreamReader(
                    new ByteArrayInputStream(bpmnXml.getBytes(StandardCharsets.UTF_8)));
            BpmnModel model = new BpmnXMLConverter().convertToBpmnModel(reader);
            List<WorkflowManageDtos.BpmnNodeSnapshot> snapshots = new ArrayList<>();
            int sortOrder = 0;
            for (Process process : model.getProcesses()) {
                for (FlowElement element : process.getFlowElements()) {
                    String nodeType = resolveNodeType(element);
                    if (nodeType == null) {
                        continue;
                    }
                    WorkflowManageDtos.BpmnNodeSnapshot snapshot = new WorkflowManageDtos.BpmnNodeSnapshot();
                    snapshot.setNodeId(element.getId());
                    snapshot.setNodeName(element.getName());
                    snapshot.setNodeType(nodeType);
                    snapshot.setSortOrder(sortOrder++);
                    snapshots.add(snapshot);
                }
            }
            if (snapshots.isEmpty()) {
                throw new WorkflowValidationException(
                        WorkflowValidationException.BPMN_XML_INVALID,
                        "BPMN contains no manageable nodes");
            }
            return snapshots;
        } catch (RuntimeException | javax.xml.stream.XMLStreamException ex) {
            throw new WorkflowValidationException(
                    WorkflowValidationException.BPMN_XML_INVALID,
                    "Invalid BPMN XML");
        }
    }

    private String resolveNodeType(FlowElement element) {
        if (element instanceof StartEvent) {
            return "START";
        }
        if (element instanceof UserTask) {
            return "USER_TASK";
        }
        if (element instanceof ServiceTask) {
            return "SERVICE_TASK";
        }
        if (element instanceof ExclusiveGateway || element instanceof ParallelGateway) {
            return "GATEWAY";
        }
        if (element instanceof EndEvent) {
            return "END";
        }
        return null;
    }

    private WorkflowManageDtos.WorkflowNodeConfigView toNodeConfigView(
            WorkflowManageDtos.BpmnNodeSnapshot snapshot,
            WorkflowNodeConfig saved) {
        WorkflowManageDtos.WorkflowNodeConfigView view = new WorkflowManageDtos.WorkflowNodeConfigView();
        view.setId(saved == null ? null : saved.getId());
        view.setDefinitionVersionId(saved == null ? null : saved.getDefinitionVersionId());
        view.setNodeId(snapshot.getNodeId());
        view.setNodeName(saved == null ? snapshot.getNodeName() : saved.getNodeName());
        view.setNodeType(saved == null ? snapshot.getNodeType() : saved.getNodeType());
        view.setApprovalType(saved == null ? null : saved.getApprovalType());
        view.setAssigneeStrategy(saved == null ? null : saved.getAssigneeStrategy());
        view.setAssigneeConfig(readJson(saved == null ? null : saved.getAssigneeConfigJson()));
        view.setCommentRequired(saved == null ? Boolean.TRUE : saved.getCommentRequired() == 1);
        view.setAllowDelegate(saved == null ? Boolean.TRUE : saved.getAllowDelegate() == 1);
        view.setAllowReassign(saved == null ? Boolean.TRUE : saved.getAllowReassign() == 1);
        view.setAllowReturnPrevious(saved == null ? Boolean.TRUE : saved.getAllowReturnPrevious() == 1);
        view.setAllowReturnApplicant(saved == null ? Boolean.TRUE : saved.getAllowReturnApplicant() == 1);
        view.setAiEnabled(saved != null && saved.getAiEnabled() == 1);
        view.setTimeoutRule(readJson(saved == null ? null : saved.getTimeoutRuleJson()));
        view.setExtraConfig(readJson(saved == null ? null : saved.getExtraConfigJson()));
        view.setSortOrder(saved == null ? snapshot.getSortOrder() : saved.getSortOrder());
        return view;
    }

    private String writeJson(Map<String, Object> data) {
        if (data == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(data);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("invalid node config json", ex);
        }
    }

    private Map<String, Object> readJson(String json) {
        if (json == null || json.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(json, new TypeReference<>() {});
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("invalid persisted node config json", ex);
        }
    }

    private int toFlag(Boolean value, boolean defaultValue) {
        return Boolean.TRUE.equals(value == null ? defaultValue : value) ? 1 : 0;
    }
}
