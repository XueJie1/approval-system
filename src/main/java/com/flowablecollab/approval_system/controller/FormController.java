package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.form.FormAttachment;
import com.flowablecollab.approval_system.entity.form.FormDefinition;
import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.entity.form.FormInstance;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.FormService;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Path;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/forms")
public class FormController {

    private final FormService formService;

    public FormController(FormService formService) {
        this.formService = formService;
    }

    @PostMapping("/definitions")
    public ResponseEntity<FormDefinition> createDefinition(@RequestBody CreateFormDefinitionRequest request) {
        ensureRequestUserMatchesLogin(request.userId);
        return ResponseEntity.ok(formService.createFormDefinition(request.formKey, request.formName));
    }

    @PostMapping("/versions")
    public ResponseEntity<FormVersion> createVersion(@RequestBody CreateFormVersionRequest request) {
        ensureRequestUserMatchesLogin(request.userId);
        return ResponseEntity.ok(formService.createFormVersion(request.formId, request.schemaJson));
    }

    @PostMapping("/fields")
    public ResponseEntity<ActionResponse> replaceFields(@RequestBody ReplaceFieldsRequest request) {
        ensureRequestUserMatchesLogin(request.userId);
        formService.replaceFields(request.formVersionId, request.fields);
        return ResponseEntity.ok(ActionResponse.ok("Fields updated"));
    }

    @GetMapping("/versions/latest")
    public ResponseEntity<FormVersion> getLatest(@RequestParam String formKey) {
        return ResponseEntity.ok(formService.getLatestVersion(formKey));
    }

    @GetMapping("/fields")
    public ResponseEntity<List<com.flowablecollab.approval_system.entity.form.FormField>> getFields(@RequestParam Long formVersionId) {
        return ResponseEntity.ok(formService.getFields(formVersionId));
    }

    @GetMapping("/definitions")
    public ResponseEntity<List<FormDefinition>> listDefinitions() {
        return ResponseEntity.ok(formService.listDefinitions());
    }

    @GetMapping("/versions")
    public ResponseEntity<List<FormVersion>> listVersions(@RequestParam Long formId) {
        return ResponseEntity.ok(formService.listVersions(formId));
    }

    @PostMapping("/instances")
    public ResponseEntity<FormInstance> createInstance(@RequestBody CreateFormInstanceRequest request) {
        ensureRequestUserMatchesLogin(request.userId);
        return ResponseEntity.ok(formService.createFormInstance(request.formVersionId, request.businessKey, request.data));
    }

    @PostMapping("/validate")
    public ResponseEntity<ActionResponse> validateInstance(@RequestBody ValidateFormInstanceRequest request) {
        ensureRequestUserMatchesLogin(request.userId);
        formService.validateFormInstance(request.formVersionId, request.data);
        return ResponseEntity.ok(ActionResponse.ok("Validation passed"));
    }

    @PostMapping(value = "/attachments/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<FormAttachment> uploadAttachment(
            @RequestParam Long formVersionId,
            @RequestParam String fieldKey,
            @RequestPart("file") MultipartFile file) {
        return ResponseEntity.ok(formService.uploadAttachment(formVersionId, fieldKey, file));
    }

    @GetMapping("/attachments/{attachmentId}")
    public ResponseEntity<Resource> downloadAttachment(@PathVariable Long attachmentId) {
        FormAttachment attachment = formService.getAttachment(attachmentId);
        Path filePath = formService.resolveAttachmentFile(attachment);
        Resource resource = new FileSystemResource(filePath);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(
                        attachment.getContentType() != null ? attachment.getContentType() : "application/octet-stream"))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + attachment.getOriginalName() + "\"")
                .body(resource);
    }

    @GetMapping("/attachments/{attachmentId}/preview")
    public ResponseEntity<Resource> previewAttachment(@PathVariable Long attachmentId) {
        FormAttachment attachment = formService.getAttachment(attachmentId);
        Path filePath = formService.resolveAttachmentFile(attachment);
        Resource resource = new FileSystemResource(filePath);
        String contentType = attachment.getContentType() != null ? attachment.getContentType() : "application/octet-stream";
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + attachment.getOriginalName() + "\"")
                .body(resource);
    }

    @GetMapping("/instances/{formInstanceId}/attachments")
    public ResponseEntity<List<FormAttachment>> listInstanceAttachments(@PathVariable Long formInstanceId) {
        return ResponseEntity.ok(formService.getAttachmentsByFormInstance(formInstanceId));
    }

    @GetMapping("/instances/{formInstanceId}/data")
    public ResponseEntity<Map<String, Object>> getInstanceData(@PathVariable Long formInstanceId) {
        Map<String, Object> data = formService.readFormInstanceData(formInstanceId);
        FormInstance instance = formService.getFormInstance(formInstanceId);
        List<FormField> fields = formService.getFields(instance.getFormVersionId());
        if (fields.isEmpty()) {
            fields = formService.parseSchemaFields(instance.getFormVersionId());
        }
        List<FormAttachment> attachments = formService.getAttachmentsByFormInstance(formInstanceId);
        if (attachments.isEmpty() && data != null) {
            attachments = formService.resolveAttachmentsFromData(data);
        }
        Map<String, Object> result = new java.util.LinkedHashMap<>();
        result.put("formVersionId", instance.getFormVersionId());
        result.put("fields", fields);
        result.put("data", data);
        result.put("attachments", attachments);
        return ResponseEntity.ok(result);
    }

    @DeleteMapping("/attachments/{attachmentId}")
    public ResponseEntity<ActionResponse> deleteAttachment(@PathVariable Long attachmentId) {
        formService.deleteAttachment(attachmentId);
        return ResponseEntity.ok(ActionResponse.ok("Attachment deleted"));
    }

    private void ensureRequestUserMatchesLogin(Long requestUserId) {
        Long currentUserId = SecurityUtils.currentUserId();
        if (currentUserId == null) {
            throw new ForbiddenOperationException("Unauthorized");
        }
        if (requestUserId == null || requestUserId.equals(currentUserId) || SecurityUtils.hasAnyRole("ADMIN", "SYS_ADMIN")) {
            return;
        }
        throw new ForbiddenOperationException("userId must match current login user");
    }

    public static class CreateFormDefinitionRequest {
        public Long userId;
        public String formKey;
        public String formName;
    }

    public static class CreateFormVersionRequest {
        public Long userId;
        public Long formId;
        public String schemaJson;
    }

    public static class CreateFormInstanceRequest {
        public Long userId;
        public Long formVersionId;
        public String businessKey;
        public Map<String, Object> data;
    }

    public static class ValidateFormInstanceRequest {
        public Long userId;
        public Long formVersionId;
        public Map<String, Object> data;
    }

    public static class ReplaceFieldsRequest {
        public Long userId;
        public Long formVersionId;
        public List<FormService.FormFieldRequest> fields;
    }

    public static class ActionResponse {
        public boolean success;
        public String message;

        public static ActionResponse ok(String message) {
            ActionResponse response = new ActionResponse();
            response.success = true;
            response.message = message;
            return response;
        }
    }
}
