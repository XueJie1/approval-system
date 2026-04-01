package com.flowablecollab.approval_system.service.workflow.manage;

import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.exception.ResourceConflictException;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class WorkflowDefinitionService {

    private static final int NOT_DELETED = 0;

    private final WorkflowDefinitionRepository workflowDefinitionRepository;
    private final WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;

    @Transactional
    public WorkflowManageDtos.WorkflowDefinitionView createDefinition(
            WorkflowManageDtos.CreateWorkflowDefinitionRequest request,
            Long operatorId) {
        validateDefinitionFields(request.getProcessKey(), request.getProcessName());
        if (workflowDefinitionRepository.existsByProcessKeyAndIsDeleted(request.getProcessKey(), NOT_DELETED)) {
            throw new ResourceConflictException("processKey already exists");
        }
        WorkflowDefinition definition = new WorkflowDefinition();
        definition.setProcessKey(request.getProcessKey());
        definition.setProcessName(request.getProcessName());
        definition.setCategory(request.getCategory());
        definition.setDescription(request.getDescription());
        definition.setStatus(WorkflowDefinition.STATUS_DRAFT);
        definition.setLatestVersionNo(0);
        definition.setCreatedBy(operatorId);
        definition.setUpdatedBy(operatorId);
        workflowDefinitionRepository.save(definition);
        return toDefinitionView(definition, null);
    }

    @Transactional(readOnly = true)
    public WorkflowManageDtos.PageResult<WorkflowManageDtos.WorkflowDefinitionView> listDefinitions(
            WorkflowManageDtos.QueryWorkflowDefinitionRequest request) {
        PageRequest pageable = PageRequest.of(
                Math.max(request.getPage(), 0),
                request.getSize() <= 0 ? 20 : request.getSize(),
                Sort.by(Sort.Direction.DESC, "updatedAt"));
        Specification<WorkflowDefinition> specification = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("isDeleted"), NOT_DELETED));
            if (request.getKeyword() != null && !request.getKeyword().isBlank()) {
                String keyword = "%" + request.getKeyword().trim() + "%";
                predicates.add(cb.or(
                        cb.like(root.get("processKey"), keyword),
                        cb.like(root.get("processName"), keyword)));
            }
            if (request.getCategory() != null && !request.getCategory().isBlank()) {
                predicates.add(cb.equal(root.get("category"), request.getCategory()));
            }
            if (request.getStatus() != null && !request.getStatus().isBlank()) {
                predicates.add(cb.equal(root.get("status"), request.getStatus()));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
        Page<WorkflowManageDtos.WorkflowDefinitionView> page = workflowDefinitionRepository.findAll(specification, pageable)
                .map(definition -> toDefinitionView(definition, resolveCurrentVersion(definition.getCurrentVersionId())));
        return WorkflowManageDtos.PageResult.from(page);
    }

    @Transactional(readOnly = true)
    public WorkflowManageDtos.WorkflowDefinitionView getDefinition(Long definitionId) {
        WorkflowDefinition definition = getDefinitionEntity(definitionId);
        return toDefinitionView(definition, resolveCurrentVersion(definition.getCurrentVersionId()));
    }

    @Transactional
    public WorkflowManageDtos.WorkflowDefinitionView updateDefinition(
            Long definitionId,
            WorkflowManageDtos.UpdateWorkflowDefinitionRequest request,
            Long operatorId) {
        WorkflowDefinition definition = getDefinitionEntity(definitionId);
        if (WorkflowDefinition.STATUS_ARCHIVED.equals(definition.getStatus())) {
            throw new IllegalArgumentException("archived workflow definition cannot be updated");
        }
        if (request.getProcessName() == null || request.getProcessName().isBlank()) {
            throw new IllegalArgumentException("processName is required");
        }
        definition.setProcessName(request.getProcessName());
        definition.setCategory(request.getCategory());
        definition.setDescription(request.getDescription());
        definition.setUpdatedBy(operatorId);
        workflowDefinitionRepository.save(definition);
        return toDefinitionView(definition, resolveCurrentVersion(definition.getCurrentVersionId()));
    }

    @Transactional
    public void inactivateDefinition(Long definitionId, Long operatorId, String comment) {
        WorkflowDefinition definition = getDefinitionEntity(definitionId);
        if (WorkflowDefinition.STATUS_ARCHIVED.equals(definition.getStatus())) {
            throw new IllegalArgumentException("archived workflow definition cannot be inactivated");
        }
        definition.setStatus(WorkflowDefinition.STATUS_INACTIVE);
        definition.setCurrentVersionId(null);
        definition.setUpdatedBy(operatorId);
        workflowDefinitionRepository.save(definition);
    }

    @Transactional
    public void archiveDefinition(Long definitionId, Long operatorId, String comment) {
        WorkflowDefinition definition = getDefinitionEntity(definitionId);
        WorkflowDefinitionVersion currentPublished = workflowDefinitionVersionRepository
                .findByDefinitionIdAndStatusAndIsDeleted(definitionId, WorkflowDefinitionVersion.STATUS_PUBLISHED, NOT_DELETED)
                .orElse(null);
        if (currentPublished != null) {
            throw new IllegalArgumentException("published version must be inactivated before archive");
        }
        definition.setStatus(WorkflowDefinition.STATUS_ARCHIVED);
        definition.setCurrentVersionId(null);
        definition.setUpdatedBy(operatorId);
        workflowDefinitionRepository.save(definition);
    }

    @Transactional(readOnly = true)
    public WorkflowDefinition getDefinitionEntity(Long definitionId) {
        return workflowDefinitionRepository.findByIdAndIsDeleted(definitionId, NOT_DELETED)
                .orElseThrow(() -> new IllegalArgumentException("workflow definition not found"));
    }

    private void validateDefinitionFields(String processKey, String processName) {
        if (processKey == null || processKey.isBlank()) {
            throw new IllegalArgumentException("processKey is required");
        }
        if (!processKey.matches("[A-Za-z][A-Za-z0-9_]*")) {
            throw new IllegalArgumentException("processKey format is invalid");
        }
        if (processName == null || processName.isBlank()) {
            throw new IllegalArgumentException("processName is required");
        }
    }

    private WorkflowDefinitionVersion resolveCurrentVersion(Long currentVersionId) {
        if (currentVersionId == null) {
            return null;
        }
        return workflowDefinitionVersionRepository.findByIdAndIsDeleted(currentVersionId, NOT_DELETED).orElse(null);
    }

    WorkflowManageDtos.WorkflowDefinitionView toDefinitionView(
            WorkflowDefinition definition,
            WorkflowDefinitionVersion currentVersion) {
        WorkflowManageDtos.WorkflowDefinitionView view = new WorkflowManageDtos.WorkflowDefinitionView();
        view.setId(definition.getId());
        view.setProcessKey(definition.getProcessKey());
        view.setProcessName(definition.getProcessName());
        view.setCategory(definition.getCategory());
        view.setDescription(definition.getDescription());
        view.setStatus(definition.getStatus());
        view.setCurrentVersionId(definition.getCurrentVersionId());
        view.setCurrentVersionNo(currentVersion == null ? null : currentVersion.getVersionNo());
        view.setLatestVersionNo(definition.getLatestVersionNo());
        view.setCreatedAt(definition.getCreatedAt());
        view.setUpdatedAt(definition.getUpdatedAt());
        return view;
    }
}
