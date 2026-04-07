package com.flowablecollab.approval_system.controller.admin.workflow;

import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.workflow.manage.RequestTemplateService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin/request-templates")
public class RequestTemplateAdminController {

    private final RequestTemplateService requestTemplateService;

    public RequestTemplateAdminController(RequestTemplateService requestTemplateService) {
        this.requestTemplateService = requestTemplateService;
    }

    @GetMapping
    public ResponseEntity<List<RequestTemplateService.TemplateView>> listTemplates() {
        return ResponseEntity.ok(requestTemplateService.listAllTemplates());
    }

    @PostMapping
    public ResponseEntity<RequestTemplateService.TemplateView> createTemplate(
            @RequestBody RequestTemplateService.TemplateUpsertRequest request) {
        return ResponseEntity.ok(requestTemplateService.createTemplate(request, requireOperatorId()));
    }

    @PutMapping("/{templateId}")
    public ResponseEntity<RequestTemplateService.TemplateView> updateTemplate(
            @PathVariable Long templateId,
            @RequestBody RequestTemplateService.TemplateUpsertRequest request) {
        return ResponseEntity.ok(requestTemplateService.updateTemplate(templateId, request, requireOperatorId()));
    }

    private Long requireOperatorId() {
        Long operatorId = SecurityUtils.currentUserId();
        if (operatorId == null) {
            throw new IllegalArgumentException("operator not found");
        }
        return operatorId;
    }
}
