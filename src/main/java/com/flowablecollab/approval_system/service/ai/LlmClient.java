package com.flowablecollab.approval_system.service.ai;

import lombok.Data;

import java.util.List;
import java.util.Map;

public interface LlmClient {

    Suggestion suggestApproval(SuggestionRequest request);

    FollowUpAnswer answerFollowUp(FollowUpRequest request);

    FormCommandResult parseFormCommand(FormCommandParseRequest request);

    ChatResult chat(ChatRequest request);

    /**
     * Low-level multi-message chat with optional function-calling tools.
     * Returns either a final assistant reply (content non-null) or a list of tool calls
     * that the caller must execute and feed back as new tool messages.
     * Implementations that do not support tools may always return a content-only result.
     */
    default ChatWithToolsResult chatWithTools(ChatWithToolsRequest request) {
        ChatResult basic = chat(new ChatRequest());
        ChatWithToolsResult result = new ChatWithToolsResult();
        result.setContent(basic.getReply());
        result.setModel(basic.getModel());
        return result;
    }

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

    @Data
    class ChatMessage {
        /** "system" | "user" | "assistant" | "tool" */
        private String role;
        /** May be null when the assistant turn only carries tool calls. */
        private String content;
        /** Populated when role=assistant and the model emitted tool_calls. */
        private List<ToolCall> toolCalls;
        /** Populated when role=tool, identifying which assistant tool_call this response answers. */
        private String toolCallId;
        /** Populated when role=tool, the function name that was executed. */
        private String name;
    }

    @Data
    class ToolDefinition {
        private String name;
        private String description;
        /** OpenAI JSONSchema for the function parameters (object). */
        private Map<String, Object> parametersSchema;
    }

    @Data
    class ToolCall {
        private String id;
        private String name;
        /** Raw JSON string of arguments as emitted by the model. */
        private String argumentsJson;
    }

    @Data
    class ChatWithToolsRequest {
        private List<ChatMessage> messages;
        private List<ToolDefinition> tools;
    }

    @Data
    class ChatWithToolsResult {
        /** Final assistant text, present when the model decided to answer the user directly. */
        private String content;
        /** Tool calls the caller must execute. When non-empty, content is typically null. */
        private List<ToolCall> toolCalls;
        private String model;
    }
}
