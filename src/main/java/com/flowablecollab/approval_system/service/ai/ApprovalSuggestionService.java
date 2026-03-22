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
        request.setApplicantId(context.getApplicantId());
        request.setVariables(context.getVariables());
        request.setApplicantStats(context.getApplicantStats());
        request.setSimilarCaseStats(context.getSimilarCaseStats());
        request.setPolicyReferences(context.getPolicyReferences());
        request.setHeuristicRiskWarnings(context.getHeuristicRiskWarnings());
        request.setHeuristicAnomalies(context.getHeuristicAnomalies());

        LlmClient.Suggestion llmSuggestion = llmClient.suggestApproval(request);

        List<String> riskWarnings = defaultList(llmSuggestion.getRiskWarnings());
        List<String> anomalies = defaultList(llmSuggestion.getAnomalies());
        SuggestionResult result = new SuggestionResult();
        result.setTaskId(context.getTaskId());
        result.setDecision(normalizeDecision(llmSuggestion.getDecision(), riskWarnings, anomalies));
        result.setRecommendation(defaultText(llmSuggestion.getRecommendation(), llmSuggestion.getSummary()));
        result.setSummary(defaultText(llmSuggestion.getSummary(), llmSuggestion.getRecommendation()));
        result.setRiskWarnings(riskWarnings);
        result.setAnomalies(anomalies);
        result.setSupplementaryInfo(defaultList(llmSuggestion.getSupplementaryInfo()));
        result.setApprovalComment(defaultApprovalComment(result, llmSuggestion.getApprovalComment()));
        result.setSuggestedFormUpdates(defaultMap(llmSuggestion.getSuggestedFormUpdates()));
        result.setModel(llmSuggestion.getModel());
        result.setGeneratedAt(LocalDateTime.now());
        return result;
    }

    public FollowUpResult followUp(SuggestionContext context, SuggestionResult currentSuggestion, String question) {
        LlmClient.FollowUpRequest request = new LlmClient.FollowUpRequest();
        request.setTaskId(context.getTaskId());
        request.setTaskName(context.getTaskName());
        request.setProcessInstanceId(context.getProcessInstanceId());
        request.setBusinessKey(context.getBusinessKey());
        request.setTitle(context.getTitle());
        request.setVariables(context.getVariables());
        request.setQuestion(question);
        request.setConversationTurns(defaultTurns(context.getConversationTurns()));

        LlmClient.Suggestion suggestion = new LlmClient.Suggestion();
        suggestion.setDecision(currentSuggestion.getDecision());
        suggestion.setRecommendation(currentSuggestion.getRecommendation());
        suggestion.setSummary(currentSuggestion.getSummary());
        suggestion.setRiskWarnings(currentSuggestion.getRiskWarnings());
        suggestion.setAnomalies(currentSuggestion.getAnomalies());
        suggestion.setSupplementaryInfo(currentSuggestion.getSupplementaryInfo());
        suggestion.setApprovalComment(currentSuggestion.getApprovalComment());
        suggestion.setSuggestedFormUpdates(currentSuggestion.getSuggestedFormUpdates());
        request.setCurrentSuggestion(suggestion);

        LlmClient.FollowUpAnswer followUpAnswer = llmClient.answerFollowUp(request);
        FollowUpResult result = new FollowUpResult();
        result.setAnswer(defaultText(followUpAnswer.getAnswer(), "暂无补充说明。"));
        result.setModel(followUpAnswer.getModel());
        result.setAnsweredAt(LocalDateTime.now());
        return result;
    }

    private List<String> defaultList(List<String> values) {
        return values == null ? List.of() : values;
    }

    private List<LlmClient.ConversationTurn> defaultTurns(List<LlmClient.ConversationTurn> values) {
        return values == null ? List.of() : values;
    }

    private Map<String, Object> defaultMap(Map<String, Object> values) {
        return values == null ? Map.of() : values;
    }

    private String defaultText(String primary, String fallback) {
        if (primary != null && !primary.isBlank()) {
            return primary;
        }
        if (fallback != null && !fallback.isBlank()) {
            return fallback;
        }
        return "";
    }

    private String normalizeDecision(String rawDecision, List<String> riskWarnings, List<String> anomalies) {
        if ("APPROVE".equalsIgnoreCase(rawDecision)) {
            return "APPROVE";
        }
        if ("REJECT".equalsIgnoreCase(rawDecision)) {
            return "REJECT";
        }
        return (!riskWarnings.isEmpty() || !anomalies.isEmpty()) ? "REJECT" : "APPROVE";
    }

    private String defaultApprovalComment(SuggestionResult result, String approvalComment) {
        if (approvalComment != null && !approvalComment.isBlank()) {
            return approvalComment;
        }
        String prefix = "APPROVE".equals(result.getDecision()) ? "建议通过" : "建议拒绝";
        if (result.getRecommendation() == null || result.getRecommendation().isBlank()) {
            return prefix;
        }
        return prefix + "：" + result.getRecommendation();
    }

    @Data
    public static class SuggestionContext {
        private String taskId;
        private String taskName;
        private String processInstanceId;
        private String businessKey;
        private String title;
        private Long applicantId;
        private Map<String, Object> variables;
        private LlmClient.ApplicantStats applicantStats;
        private LlmClient.SimilarCaseStats similarCaseStats;
        private List<String> policyReferences;
        private List<String> heuristicRiskWarnings;
        private List<String> heuristicAnomalies;
        private List<LlmClient.ConversationTurn> conversationTurns;
    }

    @Data
    public static class SuggestionResult {
        private String taskId;
        private String decision;
        private String recommendation;
        private String summary;
        private List<String> riskWarnings;
        private List<String> anomalies;
        private List<String> supplementaryInfo;
        private String approvalComment;
        private Map<String, Object> suggestedFormUpdates;
        private String model;
        private LocalDateTime generatedAt;
    }

    @Data
    public static class FollowUpResult {
        private String answer;
        private String model;
        private LocalDateTime answeredAt;
    }
}
