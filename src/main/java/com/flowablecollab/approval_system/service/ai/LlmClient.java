package com.flowablecollab.approval_system.service.ai;

import lombok.Data;

import java.util.List;
import java.util.Map;

public interface LlmClient {

    Suggestion suggestApproval(SuggestionRequest request);

    @Data
    class SuggestionRequest {
        private String taskId;
        private String taskName;
        private String processInstanceId;
        private String businessKey;
        private String title;
        private Map<String, Object> variables;
    }

    @Data
    class Suggestion {
        private String decision;
        private String summary;
        private List<String> riskFlags;
        private List<String> followUpChecks;
        private String model;
    }
}
