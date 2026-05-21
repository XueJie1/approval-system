package com.flowablecollab.approval_system.controller;

import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.ai.FormCommandAiService;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@ConditionalOnBean(FormCommandAiService.class)
public class FormCommandAiController {

    private final FormCommandAiService formCommandAiService;

    @PostMapping("/form-commands/parse")
    public ResponseEntity<FormCommandAiService.ParseResult> parse(
            @RequestBody FormCommandAiService.ParseRequest request) {
        return ResponseEntity.ok(formCommandAiService.parse(request));
    }

    @PostMapping("/form-commands/parse-and-start")
    public ResponseEntity<FormCommandAiService.StartFromCommandResult> parseAndStart(
            @RequestBody FormCommandAiService.StartFromCommandRequest request) {
        return ResponseEntity.ok(formCommandAiService.parseAndStart(request, SecurityUtils.currentUserId()));
    }

}
