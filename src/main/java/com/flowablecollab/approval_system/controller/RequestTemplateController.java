package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.service.workflow.manage.RequestTemplateService;
import com.flowablecollab.approval_system.service.RequestTemplateApprovalResolverService;
import com.flowablecollab.approval_system.security.SecurityUtils;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/request-templates")
public class RequestTemplateController {

    private final RequestTemplateService requestTemplateService;
    private final RequestTemplateApprovalResolverService requestTemplateApprovalResolverService;

    public RequestTemplateController(RequestTemplateService requestTemplateService,
                                     RequestTemplateApprovalResolverService requestTemplateApprovalResolverService) {
        this.requestTemplateService = requestTemplateService;
        this.requestTemplateApprovalResolverService = requestTemplateApprovalResolverService;
    }

    @GetMapping
    public ResponseEntity<List<RequestTemplateService.TemplateView>> listActiveTemplates() {
        return ResponseEntity.ok(requestTemplateService.listActiveTemplatesForRoles(SecurityUtils.currentRoleCodes()));
    }

    @PostMapping("/{templateKey}/approval-preview")
    public ResponseEntity<List<RequestTemplateApprovalResolverService.PreviewStepView>> previewApprovalChain(
            @org.springframework.web.bind.annotation.PathVariable String templateKey,
            @RequestBody ApprovalPreviewRequest request) {
        Long applicantId = request.getApplicantId() != null ? request.getApplicantId() : SecurityUtils.currentUserId();
        if (applicantId == null) {
            throw new IllegalArgumentException("applicantId is required");
        }
        return ResponseEntity.ok(requestTemplateApprovalResolverService.describeApprovalChain(
                templateKey,
                applicantId,
                request.getVariables() == null ? Map.of() : request.getVariables()));
    }

    public static class ApprovalPreviewRequest {
        private Long applicantId;
        private Map<String, Object> variables;

        public Long getApplicantId() {
            return applicantId;
        }

        public void setApplicantId(Long applicantId) {
            this.applicantId = applicantId;
        }

        public Map<String, Object> getVariables() {
            return variables;
        }

        public void setVariables(Map<String, Object> variables) {
            this.variables = variables;
        }
    }
}
