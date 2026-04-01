package com.flowablecollab.approval_system.service.workflow.manage;

import lombok.Data;
import org.springframework.data.domain.Page;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public final class WorkflowManageDtos {

    private WorkflowManageDtos() {
    }

    @Data
    public static class CreateWorkflowDefinitionRequest {
        private String processKey;
        private String processName;
        private String category;
        private String description;
    }

    @Data
    public static class UpdateWorkflowDefinitionRequest {
        private String processName;
        private String category;
        private String description;
    }

    @Data
    public static class QueryWorkflowDefinitionRequest {
        private String keyword;
        private String category;
        private String status;
        private int page = 0;
        private int size = 20;
    }

    @Data
    public static class CreateWorkflowVersionRequest {
        private Long copyFromVersionId;
        private String versionLabel;
        private String changeSummary;
    }

    @Data
    public static class UpdateWorkflowVersionRequest {
        private String versionLabel;
        private String bpmnXml;
        private String formKey;
        private Long formVersionId;
        private String changeSummary;
    }

    @Data
    public static class WorkflowNodeConfigItemRequest {
        private String nodeId;
        private String nodeName;
        private String nodeType;
        private String approvalType;
        private String assigneeStrategy;
        private Map<String, Object> assigneeConfig;
        private Boolean commentRequired;
        private Boolean allowDelegate;
        private Boolean allowReassign;
        private Boolean allowReturnPrevious;
        private Boolean allowReturnApplicant;
        private Boolean aiEnabled;
        private Map<String, Object> timeoutRule;
        private Map<String, Object> extraConfig;
        private Integer sortOrder;
    }

    @Data
    public static class BatchSaveWorkflowNodeConfigRequest {
        private List<WorkflowNodeConfigItemRequest> nodes;
    }

    @Data
    public static class ChangeVersionStatusRequest {
        private String comment;
    }

    @Data
    public static class WorkflowDefinitionView {
        private Long id;
        private String processKey;
        private String processName;
        private String category;
        private String description;
        private String status;
        private Long currentVersionId;
        private Integer currentVersionNo;
        private Integer latestVersionNo;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
    }

    @Data
    public static class WorkflowDefinitionVersionView {
        private Long id;
        private Long definitionId;
        private Integer versionNo;
        private String versionLabel;
        private String status;
        private String bpmnXml;
        private String bpmnChecksum;
        private String flowableDeploymentId;
        private String flowableProcessDefinitionId;
        private String formKey;
        private Long formVersionId;
        private String changeSummary;
        private Long publishedBy;
        private LocalDateTime publishedAt;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
    }

    @Data
    public static class WorkflowNodeConfigView {
        private Long id;
        private Long definitionVersionId;
        private String nodeId;
        private String nodeName;
        private String nodeType;
        private String approvalType;
        private String assigneeStrategy;
        private Map<String, Object> assigneeConfig;
        private Boolean commentRequired;
        private Boolean allowDelegate;
        private Boolean allowReassign;
        private Boolean allowReturnPrevious;
        private Boolean allowReturnApplicant;
        private Boolean aiEnabled;
        private Map<String, Object> timeoutRule;
        private Map<String, Object> extraConfig;
        private Integer sortOrder;
    }

    @Data
    public static class WorkflowPublishLogView {
        private Long id;
        private Long definitionId;
        private Long definitionVersionId;
        private String action;
        private String result;
        private String message;
        private String flowableDeploymentId;
        private String flowableProcessDefinitionId;
        private Long operatorId;
        private LocalDateTime operatedAt;
    }

    @Data
    public static class WorkflowVersionUsageView {
        private Long definitionVersionId;
        private long totalCount;
        private long runningCount;
        private long finishedCount;
        private List<WorkflowInstanceUsageItem> recentRequests;
    }

    @Data
    public static class WorkflowInstanceUsageItem {
        private Long requestId;
        private String businessKey;
        private String processInstanceId;
        private String title;
        private Integer status;
        private LocalDateTime submitTime;
        private LocalDateTime finishTime;
    }

    @Data
    public static class BpmnNodeSnapshot {
        private String nodeId;
        private String nodeName;
        private String nodeType;
        private Integer sortOrder;
    }

    @Data
    public static class WorkflowLaunchDefinition {
        private Long definitionId;
        private Long versionId;
        private Integer versionNo;
        private String processKey;
        private String flowableProcessDefinitionId;
        private String formKey;
        private Long formVersionId;
    }

    @Data
    public static class PageResult<T> {
        private List<T> content;
        private long totalElements;
        private int totalPages;
        private int page;
        private int size;

        public static <T> PageResult<T> from(Page<T> page) {
            PageResult<T> result = new PageResult<>();
            result.content = page.getContent();
            result.totalElements = page.getTotalElements();
            result.totalPages = page.getTotalPages();
            result.page = page.getNumber();
            result.size = page.getSize();
            return result;
        }
    }
}
