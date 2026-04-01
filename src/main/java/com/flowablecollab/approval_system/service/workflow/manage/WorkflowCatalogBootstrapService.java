package com.flowablecollab.approval_system.service.workflow.manage;

import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import lombok.RequiredArgsConstructor;
import org.flowable.engine.RepositoryService;
import org.flowable.engine.repository.ProcessDefinition;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;

@Service
@Order(100)
@RequiredArgsConstructor
public class WorkflowCatalogBootstrapService {

    private static final Logger log = LoggerFactory.getLogger(WorkflowCatalogBootstrapService.class);

    private static final int NOT_DELETED = 0;
    private static final long SYSTEM_OPERATOR_ID = 0L;

    private final RepositoryService repositoryService;
    private final WorkflowDefinitionRepository workflowDefinitionRepository;
    private final WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;
    private final WorkflowNodeConfigService workflowNodeConfigService;

    @Transactional
    public void bootstrapCatalog() {
        List<ProcessDefinition> deployedDefinitions = repositoryService.createProcessDefinitionQuery()
                .latestVersion()
                .list()
                .stream()
                .sorted(Comparator.comparing(ProcessDefinition::getKey))
                .toList();

        for (ProcessDefinition processDefinition : deployedDefinitions) {
            bootstrapProcessDefinition(processDefinition);
        }
    }

    private void bootstrapProcessDefinition(ProcessDefinition processDefinition) {
        if (workflowDefinitionVersionRepository.findByFlowableProcessDefinitionIdAndIsDeleted(
                processDefinition.getId(), NOT_DELETED).isPresent()) {
            return;
        }

        WorkflowDefinition definition = workflowDefinitionRepository
                .findByProcessKeyAndIsDeleted(processDefinition.getKey(), NOT_DELETED)
                .orElseGet(() -> createDefinitionSkeleton(processDefinition));

        WorkflowDefinitionVersion publishedVersion = workflowDefinitionVersionRepository
                .findByDefinitionIdAndStatusAndIsDeleted(definition.getId(), WorkflowDefinitionVersion.STATUS_PUBLISHED, NOT_DELETED)
                .orElse(null);
        if (publishedVersion != null) {
            log.info("Skip bootstrapping processKey={} because a published business version already exists", processDefinition.getKey());
            return;
        }

        String bpmnXml = loadProcessXml(processDefinition);
        WorkflowDefinitionVersion version = new WorkflowDefinitionVersion();
        version.setDefinitionId(definition.getId());
        version.setVersionNo(Math.max(definition.getLatestVersionNo(), 0) + 1);
        version.setVersionLabel("imported-v" + processDefinition.getVersion());
        version.setStatus(WorkflowDefinitionVersion.STATUS_PUBLISHED);
        version.setBpmnXml(bpmnXml);
        version.setBpmnChecksum(calculateChecksum(bpmnXml));
        version.setFlowableDeploymentId(processDefinition.getDeploymentId());
        version.setFlowableProcessDefinitionId(processDefinition.getId());
        version.setChangeSummary("Auto imported from existing BPMN deployment");
        version.setPublishedBy(SYSTEM_OPERATOR_ID);
        version.setPublishedAt(LocalDateTime.now());
        version.setCreatedBy(SYSTEM_OPERATOR_ID);
        version.setUpdatedBy(SYSTEM_OPERATOR_ID);
        workflowDefinitionVersionRepository.save(version);

        definition.setCurrentVersionId(version.getId());
        definition.setLatestVersionNo(version.getVersionNo());
        definition.setStatus(WorkflowDefinition.STATUS_ACTIVE);
        definition.setUpdatedBy(SYSTEM_OPERATOR_ID);
        workflowDefinitionRepository.save(definition);

        workflowNodeConfigService.bootstrapNodeConfigs(version.getId(), bpmnXml);
        log.info("Bootstrapped workflow catalog entry for processKey={}, versionId={}", processDefinition.getKey(), version.getId());
    }

    private WorkflowDefinition createDefinitionSkeleton(ProcessDefinition processDefinition) {
        WorkflowDefinition definition = new WorkflowDefinition();
        definition.setProcessKey(processDefinition.getKey());
        definition.setProcessName(processDefinition.getName() == null || processDefinition.getName().isBlank()
                ? processDefinition.getKey()
                : processDefinition.getName());
        definition.setDescription("Auto imported from Flowable deployed BPMN resource");
        definition.setStatus(WorkflowDefinition.STATUS_DRAFT);
        definition.setLatestVersionNo(0);
        definition.setCreatedBy(SYSTEM_OPERATOR_ID);
        definition.setUpdatedBy(SYSTEM_OPERATOR_ID);
        return workflowDefinitionRepository.save(definition);
    }

    private String loadProcessXml(ProcessDefinition processDefinition) {
        try (InputStream inputStream = repositoryService.getResourceAsStream(
                processDefinition.getDeploymentId(), processDefinition.getResourceName())) {
            if (inputStream == null) {
                throw new IllegalStateException("Unable to load BPMN resource: " + processDefinition.getResourceName());
            }
            return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to load BPMN XML for processKey=" + processDefinition.getKey(), ex);
        }
    }

    private String calculateChecksum(String content) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(content.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 not available", ex);
        }
    }
}
