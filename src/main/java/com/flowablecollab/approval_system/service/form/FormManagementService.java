package com.flowablecollab.approval_system.service.form;

import com.flowablecollab.approval_system.entity.form.FormDefinition;
import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.entity.workflow.RequestTemplate;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinition;
import com.flowablecollab.approval_system.entity.workflow.WorkflowDefinitionVersion;
import com.flowablecollab.approval_system.repository.form.FormDefinitionRepository;
import com.flowablecollab.approval_system.repository.form.FormVersionRepository;
import com.flowablecollab.approval_system.repository.workflow.RequestTemplateRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionRepository;
import com.flowablecollab.approval_system.repository.workflow.WorkflowDefinitionVersionRepository;
import com.flowablecollab.approval_system.service.FormService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FormManagementService {

    private static final int NOT_DELETED = 0;

    private final FormService formService;
    private final FormDefinitionRepository formDefinitionRepository;
    private final FormVersionRepository formVersionRepository;
    private final RequestTemplateRepository requestTemplateRepository;
    private final WorkflowDefinitionVersionRepository workflowDefinitionVersionRepository;
    private final WorkflowDefinitionRepository workflowDefinitionRepository;

    @Transactional(readOnly = true)
    public List<FormDefinitionAdminView> listDefinitions(String keyword, Integer status) {
        String normalizedKeyword = keyword == null ? "" : keyword.trim().toLowerCase();
        return formDefinitionRepository.findAllByOrderByFormNameAscIdAsc().stream()
                .filter(def -> normalizedKeyword.isBlank()
                        || containsIgnoreCase(def.getFormKey(), normalizedKeyword)
                        || containsIgnoreCase(def.getFormName(), normalizedKeyword))
                .filter(def -> status == null || status.equals(def.getStatus()))
                .map(this::toDefinitionView)
                .toList();
    }

    @Transactional
    public FormDefinitionAdminView createDefinition(CreateFormDefinitionCommand command) {
        FormDefinition definition = formService.createFormDefinition(command.getFormKey(), command.getFormName());
        return toDefinitionView(definition);
    }

    @Transactional
    public FormDefinitionAdminView updateDefinition(Long definitionId, UpdateFormDefinitionCommand command) {
        FormDefinition definition = formService.updateFormDefinition(definitionId, command.getFormName(), command.getStatus());
        return toDefinitionView(definition);
    }

    @Transactional(readOnly = true)
    public List<FormVersionAdminView> listVersions(Long formId) {
        formDefinitionRepository.findById(formId).orElseThrow(() -> new IllegalArgumentException("Form definition not found"));
        return formVersionRepository.findByFormIdOrderByVersionDesc(formId).stream()
                .map(this::toVersionView)
                .toList();
    }

    @Transactional
    public FormVersionAdminView createVersion(Long formId, CreateFormVersionCommand command) {
        FormVersion version;
        if (command.getCopyFromVersionId() != null) {
            version = formService.createFormVersionByCopy(formId, command.getCopyFromVersionId(), command.getSchemaJson());
        } else {
            version = formService.createFormVersion(formId, command.getSchemaJson());
        }
        return toVersionView(version);
    }

    @Transactional
    public FormVersionAdminView publishVersion(Long formVersionId, Long operatorId) {
        return toVersionView(formService.publishVersion(formVersionId, operatorId));
    }

    @Transactional
    public FormVersionAdminView archiveVersion(Long formVersionId) {
        return toVersionView(formService.archiveVersion(formVersionId));
    }

    @Transactional(readOnly = true)
    public List<FormField> listFields(Long formVersionId) {
        return formService.getFields(formVersionId);
    }

    @Transactional
    public List<FormField> replaceFields(Long formVersionId, List<FormService.FormFieldRequest> fields) {
        formService.replaceFields(formVersionId, fields);
        return formService.getFields(formVersionId);
    }

    @Transactional(readOnly = true)
    public ValidationResult validateSample(Long formVersionId, Map<String, Object> sampleData) {
        formService.validateFormInstance(formVersionId, sampleData == null ? Map.of() : sampleData);
        ValidationResult result = new ValidationResult();
        result.setValid(true);
        result.setValidatedAt(LocalDateTime.now());
        return result;
    }

    @Transactional(readOnly = true)
    public FormVersionImpactView getImpacts(Long formVersionId) {
        FormVersion version = formService.getVersion(formVersionId);
        FormDefinition definition = formDefinitionRepository.findById(version.getFormId())
                .orElseThrow(() -> new IllegalArgumentException("Form definition not found"));

        List<RequestTemplate> templates = requestTemplateRepository
                .findByFormKeyOrderBySortOrderAscIdAsc(definition.getFormKey());

        List<WorkflowDefinitionVersion> workflowVersions = workflowDefinitionVersionRepository
                .findByFormVersionIdAndIsDeletedOrderByUpdatedAtDesc(formVersionId, NOT_DELETED);

        Set<Long> definitionIds = workflowVersions.stream()
                .map(WorkflowDefinitionVersion::getDefinitionId)
                .collect(Collectors.toSet());
        Map<Long, WorkflowDefinition> definitionById = workflowDefinitionRepository.findAllById(definitionIds).stream()
                .collect(Collectors.toMap(WorkflowDefinition::getId, item -> item));

        FormVersionImpactView view = new FormVersionImpactView();
        view.setFormVersionId(formVersionId);
        view.setFormKey(definition.getFormKey());
        view.setRequestTemplateCount(templates.size());
        view.setWorkflowVersionCount(workflowVersions.size());
        view.setRequestTemplates(templates.stream().map(template -> {
            RequestTemplateImpactItem item = new RequestTemplateImpactItem();
            item.setTemplateId(template.getId());
            item.setTemplateKey(template.getTemplateKey());
            item.setTemplateName(template.getTemplateName());
            item.setStatus(template.getStatus());
            return item;
        }).toList());
        view.setWorkflowVersions(workflowVersions.stream().map(versionItem -> {
            WorkflowVersionImpactItem item = new WorkflowVersionImpactItem();
            item.setVersionId(versionItem.getId());
            item.setDefinitionId(versionItem.getDefinitionId());
            item.setDefinitionName(definitionById.get(versionItem.getDefinitionId()) == null
                    ? null
                    : definitionById.get(versionItem.getDefinitionId()).getProcessName());
            item.setProcessKey(definitionById.get(versionItem.getDefinitionId()) == null
                    ? null
                    : definitionById.get(versionItem.getDefinitionId()).getProcessKey());
            item.setVersionNo(versionItem.getVersionNo());
            item.setStatus(versionItem.getStatus());
            return item;
        }).toList());
        return view;
    }

    private FormDefinitionAdminView toDefinitionView(FormDefinition definition) {
        FormDefinitionAdminView view = new FormDefinitionAdminView();
        view.setId(definition.getId());
        view.setFormKey(definition.getFormKey());
        view.setFormName(definition.getFormName());
        view.setStatus(definition.getStatus());

        List<FormVersion> versions = formVersionRepository.findByFormIdOrderByVersionDesc(definition.getId());
        if (!versions.isEmpty()) {
            FormVersion latest = versions.get(0);
            view.setLatestVersionId(latest.getId());
            view.setLatestVersionNo(latest.getVersion());
            view.setLatestVersionStatus(normalizeStatus(latest));
            versions.stream()
                    .filter(item -> FormVersion.STATUS_PUBLISHED.equals(normalizeStatus(item)))
                    .findFirst()
                    .ifPresent(published -> {
                        view.setPublishedVersionId(published.getId());
                        view.setPublishedVersionNo(published.getVersion());
                    });
        }
        return view;
    }

    private FormVersionAdminView toVersionView(FormVersion version) {
        FormVersionAdminView view = new FormVersionAdminView();
        view.setId(version.getId());
        view.setFormId(version.getFormId());
        view.setVersion(version.getVersion());
        view.setSchemaJson(version.getSchemaJson());
        view.setStatus(normalizeStatus(version));
        view.setPublishedBy(version.getPublishedBy());
        view.setPublishedAt(version.getPublishedAt());
        view.setFieldCount(formService.getFields(version.getId()).size());
        return view;
    }

    private boolean containsIgnoreCase(String source, String keyword) {
        if (source == null || keyword == null || keyword.isBlank()) {
            return false;
        }
        return source.toLowerCase().contains(keyword);
    }

    private String normalizeStatus(FormVersion version) {
        return version.getStatus() == null || version.getStatus().isBlank()
                ? FormVersion.STATUS_PUBLISHED
                : version.getStatus();
    }

    @Data
    public static class CreateFormDefinitionCommand {
        private String formKey;
        private String formName;
    }

    @Data
    public static class UpdateFormDefinitionCommand {
        private String formName;
        private Integer status;
    }

    @Data
    public static class CreateFormVersionCommand {
        private String schemaJson;
        private Long copyFromVersionId;
    }

    @Data
    public static class FormDefinitionAdminView {
        private Long id;
        private String formKey;
        private String formName;
        private Integer status;
        private Long latestVersionId;
        private Integer latestVersionNo;
        private String latestVersionStatus;
        private Long publishedVersionId;
        private Integer publishedVersionNo;
    }

    @Data
    public static class FormVersionAdminView {
        private Long id;
        private Long formId;
        private Integer version;
        private String schemaJson;
        private String status;
        private Long publishedBy;
        private LocalDateTime publishedAt;
        private Integer fieldCount;
    }

    @Data
    public static class ValidationResult {
        private boolean valid;
        private LocalDateTime validatedAt;
    }

    @Data
    public static class FormVersionImpactView {
        private Long formVersionId;
        private String formKey;
        private Integer requestTemplateCount;
        private Integer workflowVersionCount;
        private List<RequestTemplateImpactItem> requestTemplates;
        private List<WorkflowVersionImpactItem> workflowVersions;
    }

    @Data
    public static class RequestTemplateImpactItem {
        private Long templateId;
        private String templateKey;
        private String templateName;
        private String status;
    }

    @Data
    public static class WorkflowVersionImpactItem {
        private Long versionId;
        private Long definitionId;
        private String definitionName;
        private String processKey;
        private Integer versionNo;
        private String status;
    }
}
