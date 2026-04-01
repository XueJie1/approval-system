package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.form.FormDefinition;
import com.flowablecollab.approval_system.entity.form.FormInstance;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.FormService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
