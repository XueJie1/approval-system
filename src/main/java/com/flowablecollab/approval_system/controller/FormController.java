package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.entity.form.FormDefinition;
import com.flowablecollab.approval_system.entity.form.FormInstance;
import com.flowablecollab.approval_system.entity.form.FormVersion;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.FormService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/forms")
@RequiredArgsConstructor
public class FormController {

    private final FormService formService;

    @PostMapping("/definitions")
    public ResponseEntity<FormDefinition> createDefinition(@RequestBody CreateFormDefinitionRequest request) {
        ensureRequestUserMatchesLogin(request.getUserId());
        return ResponseEntity.ok(formService.createFormDefinition(request.getFormKey(), request.getFormName()));
    }

    @PostMapping("/versions")
    public ResponseEntity<FormVersion> createVersion(@RequestBody CreateFormVersionRequest request) {
        ensureRequestUserMatchesLogin(request.getUserId());
        return ResponseEntity.ok(formService.createFormVersion(request.getFormId(), request.getSchemaJson()));
    }

    @PostMapping("/fields")
    public ResponseEntity<ActionResponse> replaceFields(@RequestBody ReplaceFieldsRequest request) {
        ensureRequestUserMatchesLogin(request.getUserId());
        formService.replaceFields(request.getFormVersionId(), request.getFields());
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

    @PostMapping("/instances")
    public ResponseEntity<FormInstance> createInstance(@RequestBody CreateFormInstanceRequest request) {
        ensureRequestUserMatchesLogin(request.getUserId());
        return ResponseEntity.ok(formService.createFormInstance(request.getFormVersionId(), request.getBusinessKey(), request.getData()));
    }

    @PostMapping("/validate")
    public ResponseEntity<ActionResponse> validateInstance(@RequestBody ValidateFormInstanceRequest request) {
        ensureRequestUserMatchesLogin(request.getUserId());
        formService.validateFormInstance(request.getFormVersionId(), request.getData());
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

    @Data
    public static class CreateFormDefinitionRequest {
        private Long userId;
        private String formKey;
        private String formName;
    }

    @Data
    public static class CreateFormVersionRequest {
        private Long userId;
        private Long formId;
        private String schemaJson;
    }

    @Data
    public static class CreateFormInstanceRequest {
        private Long userId;
        private Long formVersionId;
        private String businessKey;
        private Map<String, Object> data;
    }

    @Data
    public static class ValidateFormInstanceRequest {
        private Long userId;
        private Long formVersionId;
        private Map<String, Object> data;
    }

    @Data
    public static class ReplaceFieldsRequest {
        private Long userId;
        private Long formVersionId;
        private List<FormService.FormFieldRequest> fields;
    }

    @Data
    public static class ActionResponse {
        private boolean success;
        private String message;

        public static ActionResponse ok(String message) {
            ActionResponse response = new ActionResponse();
            response.setSuccess(true);
            response.setMessage(message);
            return response;
        }
    }
}
