package com.flowablecollab.approval_system.service.ai;

import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ApprovalSuggestionService {

    private final LlmClient llmClient;

    public SuggestionResult suggest(SuggestionContext context) {
        LlmClient.SuggestionRequest request = new LlmClient.SuggestionRequest();
        request.setTaskId(context.getTaskId());
        request.setTaskName(context.getTaskName());
        request.setProcessInstanceId(context.getProcessInstanceId());
        request.setBusinessKey(context.getBusinessKey());
        request.setTitle(context.getTitle());
        request.setVariables(context.getVariables());

        LlmClient.Suggestion llmSuggestion = llmClient.suggestApproval(request);

        SuggestionResult result = new SuggestionResult();
        result.setTaskId(context.getTaskId());
        result.setDecision(llmSuggestion.getDecision());
        result.setSummary(llmSuggestion.getSummary());
        result.setRiskFlags(llmSuggestion.getRiskFlags() == null ? List.of() : llmSuggestion.getRiskFlags());
        result.setFollowUpChecks(llmSuggestion.getFollowUpChecks() == null ? List.of() : llmSuggestion.getFollowUpChecks());
        result.setModel(llmSuggestion.getModel());
        result.setGeneratedAt(LocalDateTime.now());
        return result;
    }

    @Data
    public static class SuggestionContext {
        private String taskId;
        private String taskName;
        private String processInstanceId;
        private String businessKey;
        private String title;
        private Map<String, Object> variables;
    }

    @Data
    public static class SuggestionResult {
        private String taskId;
        private String decision;
        private String summary;
        private List<String> riskFlags;
        private List<String> followUpChecks;
        private String model;
        private LocalDateTime generatedAt;
    }
}
