package com.flowablecollab.approval_system.controller;

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

    private final LlmClient llmClient;

    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        LlmClient.ChatRequest llmRequest = new LlmClient.ChatRequest();
        llmRequest.setMessage(request.getMessage());
        llmRequest.setHistory(request.getHistory());
        LlmClient.ChatResult chatResult = llmClient.chat(llmRequest);
        ChatResponse response = new ChatResponse();
        response.setReply(chatResult.getReply());
        response.setModel(chatResult.getModel());
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
    }
}
