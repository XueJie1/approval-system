package com.flowablecollab.approval_system.controller.admin;

import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.FormService;
import com.flowablecollab.approval_system.service.form.FormManagementService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/forms")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('DESIGNER','ADMIN','SYS_ADMIN')")
public class FormAdminController {

    private final FormManagementService formManagementService;

    @GetMapping("/definitions")
    public ResponseEntity<List<FormManagementService.FormDefinitionAdminView>> listDefinitions(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status) {
        return ResponseEntity.ok(formManagementService.listDefinitions(keyword, status));
    }

    @PostMapping("/definitions")
    public ResponseEntity<FormManagementService.FormDefinitionAdminView> createDefinition(
            @RequestBody FormManagementService.CreateFormDefinitionCommand command) {
        return ResponseEntity.ok(formManagementService.createDefinition(command));
    }

    @PutMapping("/definitions/{definitionId}")
    public ResponseEntity<FormManagementService.FormDefinitionAdminView> updateDefinition(
            @PathVariable Long definitionId,
            @RequestBody FormManagementService.UpdateFormDefinitionCommand command) {
        return ResponseEntity.ok(formManagementService.updateDefinition(definitionId, command));
    }

    @GetMapping("/definitions/{definitionId}/versions")
    public ResponseEntity<List<FormManagementService.FormVersionAdminView>> listVersions(@PathVariable Long definitionId) {
        return ResponseEntity.ok(formManagementService.listVersions(definitionId));
    }

    @PostMapping("/definitions/{definitionId}/versions")
    public ResponseEntity<FormManagementService.FormVersionAdminView> createVersion(
            @PathVariable Long definitionId,
            @RequestBody FormManagementService.CreateFormVersionCommand command) {
        return ResponseEntity.ok(formManagementService.createVersion(definitionId, command));
    }

    @PostMapping("/versions/{versionId}/publish")
    public ResponseEntity<FormManagementService.FormVersionAdminView> publishVersion(@PathVariable Long versionId) {
        return ResponseEntity.ok(formManagementService.publishVersion(versionId, requireOperatorId()));
    }

    @PostMapping("/versions/{versionId}/archive")
    public ResponseEntity<FormManagementService.FormVersionAdminView> archiveVersion(@PathVariable Long versionId) {
        return ResponseEntity.ok(formManagementService.archiveVersion(versionId));
    }

    @GetMapping("/versions/{versionId}/fields")
    public ResponseEntity<List<FormField>> listFields(@PathVariable Long versionId) {
        return ResponseEntity.ok(formManagementService.listFields(versionId));
    }

    @PutMapping("/versions/{versionId}/fields")
    public ResponseEntity<List<FormField>> replaceFields(
            @PathVariable Long versionId,
            @RequestBody ReplaceFieldsCommand command) {
        return ResponseEntity.ok(formManagementService.replaceFields(versionId, command.getFields()));
    }

    @GetMapping("/versions/{versionId}/impacts")
    public ResponseEntity<FormManagementService.FormVersionImpactView> impacts(@PathVariable Long versionId) {
        return ResponseEntity.ok(formManagementService.getImpacts(versionId));
    }

    @PostMapping("/versions/{versionId}/validate-sample")
    public ResponseEntity<FormManagementService.ValidationResult> validateSample(
            @PathVariable Long versionId,
            @RequestBody ValidateSampleCommand command) {
        return ResponseEntity.ok(formManagementService.validateSample(versionId,
                command.getData() == null ? Map.of() : command.getData()));
    }

    private Long requireOperatorId() {
        Long operatorId = SecurityUtils.currentUserId();
        if (operatorId == null) {
            throw new IllegalArgumentException("operator not found");
        }
        return operatorId;
    }

    @Data
    public static class ReplaceFieldsCommand {
        private List<FormService.FormFieldRequest> fields;
    }

    @Data
    public static class ValidateSampleCommand {
        private Map<String, Object> data;
    }
}
