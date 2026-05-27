package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.service.ai.AiAgentService;
import com.flowablecollab.approval_system.service.ai.LlmClient;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiChatController {

    private final AiAgentService aiAgentService;

    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        AiAgentService.AgentChatRequest agentRequest = new AiAgentService.AgentChatRequest();
        agentRequest.setMessage(request.getMessage());
        agentRequest.setHistory(request.getHistory());
        AiAgentService.AgentChatResult result = aiAgentService.chat(agentRequest);

        ChatResponse response = new ChatResponse();
        response.setReply(result.getReply());
        response.setModel(result.getModel());
        response.setPendingAction(result.getPendingAction());
        return ResponseEntity.ok(response);
    }

    @Data
    public static class ChatRequest {
        private String message;
        private List<LlmClient.ConversationTurn> history;
    }

    @Data
    public static class ChatResponse {
        private String reply;
        private String model;
        private AiAgentService.PendingAction pendingAction;
    }
}
