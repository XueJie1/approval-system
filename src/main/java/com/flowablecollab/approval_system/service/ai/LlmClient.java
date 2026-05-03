package com.flowablecollab.approval_system.service.ai;

import lombok.Data;

import java.util.List;
import java.util.Map;

public interface LlmClient {

    Suggestion suggestApproval(SuggestionRequest request);

    FollowUpAnswer answerFollowUp(FollowUpRequest request);

    FormCommandResult parseFormCommand(FormCommandParseRequest request);

    ChatResult chat(ChatRequest request);

    @Data
    class SuggestionRequest {
        private String taskId;
        private String taskName;
        private String processInstanceId;
        private String businessKey;
        private String title;
        private Long applicantId;
        private Map<String, Object> variables;
        private ApplicantStats applicantStats;
        private SimilarCaseStats similarCaseStats;
        private List<String> policyReferences;
        private List<String> heuristicRiskWarnings;
        private List<String> heuristicAnomalies;
    }

    @Data
    class Suggestion {
        private String decision;
        private String recommendation;
        private String summary;
        private List<String> riskWarnings;
        private List<String> anomalies;
        private List<String> supplementaryInfo;
        private String approvalComment;
        private Map<String, Object> suggestedFormUpdates;
        private String model;
    }

    @Data
    class FollowUpRequest {
        private String taskId;
        private String taskName;
        private String processInstanceId;
        private String businessKey;
        private String title;
        private Map<String, Object> variables;
        private Suggestion currentSuggestion;
        private List<ConversationTurn> conversationTurns;
        private String question;
    }

    @Data
    class FollowUpAnswer {
        private String answer;
        private String model;
    }

    @Data
    class ConversationTurn {
        private String question;
        private String answer;
    }

    @Data
    class ApplicantStats {
        private Integer monthlyRequestCount;
        private Integer monthlySameTypeCount;
        private Double monthlyTotalAmount;
        private Double averageAmount;
    }

    @Data
    class SimilarCaseStats {
        private Integer sampleCount;
        private Integer approvedCount;
        private Integer rejectedCount;
        private Double averageAmount;
        private String averageProcessingTime;
    }

    @Data
    class FormCommandParseRequest {
        private String command;
        private List<FieldDefinition> fields;
    }

    @Data
    class FieldDefinition {
        private String fieldKey;
        private String fieldType;
        private String label;
        private boolean required;
        private List<String> options;
    }

    @Data
    class FormCommandResult {
        private Map<String, Object> formData;
        private Double confidence;
        private String reasoning;
        private String model;
    }

    @Data
    class ChatRequest {
        private String message;
        private List<ConversationTurn> history;
    }

    @Data
    class ChatResult {
        private String reply;
        private String model;
    }
}
