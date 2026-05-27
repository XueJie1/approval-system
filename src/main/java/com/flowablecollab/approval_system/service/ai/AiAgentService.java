package com.flowablecollab.approval_system.service.ai;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.form.FormField;
import com.flowablecollab.approval_system.security.SecurityUtils;
import com.flowablecollab.approval_system.service.FormService;
import com.flowablecollab.approval_system.service.workflow.manage.RequestTemplateService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Agentic chat orchestrator. Given a user message, runs a tool-calling loop with the LLM
 * so it can list request templates and parse natural-language commands into form data.
 * Write operations (actually starting a process) are intentionally NOT exposed as tools —
 * the agent only produces a pendingAction; the frontend asks the user to confirm before
 * invoking the existing /ai/form-commands/parse-and-start endpoint.
 */
@Service
@RequiredArgsConstructor
public class AiAgentService {

    private static final Logger log = LoggerFactory.getLogger(AiAgentService.class);
    private static final int MAX_TOOL_ITERATIONS = 5;
    private static final String SYSTEM_PROMPT = """
            你是一个智能审批系统的 AI 助手。你可以回答与审批流程、表单填写、系统使用相关的问题，
            并且当用户表达了"想发起某项申请"的意图（例如请假、报销、用车、采购等）时，
            你需要主动使用工具完成以下流程：
            1) 先调用 list_request_templates 工具，了解当前用户可以发起哪些申请模板，以及每个模板的表单字段；
            2) 再调用 parse_form_command 工具，从用户的自然语言中抽取出该表单需要的字段值；
            3) 然后用中文向用户清晰地汇报：识别出的申请类型、已填字段、仍缺少的必填字段、置信度，
               并明确询问"是否需要发起申请？"——你不要自己执行发起，由用户在界面上确认。
            如果用户只是闲聊或问知识性问题，不要调用工具，直接简洁地回答即可。
            所有回复使用中文。
            """;

    private final LlmClient llmClient;
    private final ObjectProvider<RequestTemplateService> templateServiceProvider;
    private final ObjectProvider<FormService> formServiceProvider;
    private final ObjectProvider<FormCommandAiService> formCommandServiceProvider;
    private final ObjectMapper objectMapper;

    public AgentChatResult chat(AgentChatRequest request) {
        List<LlmClient.ChatMessage> messages = new ArrayList<>();
        messages.add(sysMsg(SYSTEM_PROMPT));
        if (request.getHistory() != null) {
            for (LlmClient.ConversationTurn turn : request.getHistory()) {
                if (turn.getQuestion() != null && !turn.getQuestion().isBlank()) {
                    messages.add(userMsg(turn.getQuestion()));
                }
                if (turn.getAnswer() != null && !turn.getAnswer().isBlank()) {
                    messages.add(assistantTextMsg(turn.getAnswer()));
                }
            }
        }
        messages.add(userMsg(request.getMessage()));

        List<LlmClient.ToolDefinition> tools = buildTools();
        PendingAction pendingAction = null;
        String model = null;

        for (int iter = 0; iter < MAX_TOOL_ITERATIONS; iter++) {
            LlmClient.ChatWithToolsRequest llmRequest = new LlmClient.ChatWithToolsRequest();
            llmRequest.setMessages(messages);
            llmRequest.setTools(tools);

            LlmClient.ChatWithToolsResult llmResult;
            try {
                llmResult = llmClient.chatWithTools(llmRequest);
            } catch (Exception ex) {
                log.warn("LLM agent call failed: {}", ex.getMessage());
                AgentChatResult result = new AgentChatResult();
                result.setReply("AI 服务暂时不可用：" + ex.getMessage());
                return result;
            }
            model = llmResult.getModel();

            List<LlmClient.ToolCall> toolCalls = llmResult.getToolCalls();
            if (toolCalls == null || toolCalls.isEmpty()) {
                AgentChatResult result = new AgentChatResult();
                result.setReply(llmResult.getContent() == null ? "" : llmResult.getContent());
                result.setModel(model);
                result.setPendingAction(pendingAction);
                return result;
            }

            // Append the assistant turn carrying the tool_calls, then execute and append tool results.
            LlmClient.ChatMessage assistantTurn = new LlmClient.ChatMessage();
            assistantTurn.setRole("assistant");
            assistantTurn.setContent(llmResult.getContent());
            assistantTurn.setToolCalls(toolCalls);
            messages.add(assistantTurn);

            for (LlmClient.ToolCall call : toolCalls) {
                ToolExecutionOutcome outcome = executeTool(call);
                if (outcome.pendingAction != null) {
                    pendingAction = outcome.pendingAction;
                }
                LlmClient.ChatMessage toolReply = new LlmClient.ChatMessage();
                toolReply.setRole("tool");
                toolReply.setToolCallId(call.getId());
                toolReply.setName(call.getName());
                toolReply.setContent(outcome.contentJson);
                messages.add(toolReply);
            }
        }

        // Loop budget exhausted; return whatever we have.
        AgentChatResult result = new AgentChatResult();
        result.setReply("（AI 推理步骤过多，已停止。请简化你的请求重试。）");
        result.setModel(model);
        result.setPendingAction(pendingAction);
        return result;
    }

    private List<LlmClient.ToolDefinition> buildTools() {
        List<LlmClient.ToolDefinition> tools = new ArrayList<>();

        LlmClient.ToolDefinition listTool = new LlmClient.ToolDefinition();
        listTool.setName("list_request_templates");
        listTool.setDescription("列出当前用户有权限发起的审批申请模板。返回每个模板的 templateKey、名称、描述、所属表单的字段定义（fieldKey/类型/必填/可选项/标签）。当用户表达想发起申请时，先调用此工具确认模板与字段。");
        listTool.setParametersSchema(Map.of(
                "type", "object",
                "properties", Map.of(),
                "additionalProperties", false
        ));
        tools.add(listTool);

        LlmClient.ToolDefinition parseTool = new LlmClient.ToolDefinition();
        parseTool.setName("parse_form_command");
        parseTool.setDescription("根据自然语言指令解析某个申请模板的表单字段值。仅做解析与回显，不会真正发起流程。返回 formData（已识别字段）、missingRequiredFields（仍需补充的必填字段 fieldKey 列表）、confidence（0-1 置信度）以及 templateKey/templateName。");
        Map<String, Object> parseProps = new LinkedHashMap<>();
        parseProps.put("command", Map.of("type", "string", "description", "原始自然语言指令，例如『请假5天 6月1日到6月5日 陪伴家人』。"));
        parseProps.put("requestTemplateKey", Map.of("type", "string", "description", "目标模板的 templateKey。若省略则系统会根据指令自动推断。"));
        parseTool.setParametersSchema(Map.of(
                "type", "object",
                "properties", parseProps,
                "required", List.of("command"),
                "additionalProperties", false
        ));
        tools.add(parseTool);

        return tools;
    }

    private ToolExecutionOutcome executeTool(LlmClient.ToolCall call) {
        try {
            Map<String, Object> args = parseArgs(call.getArgumentsJson());
            return switch (call.getName()) {
                case "list_request_templates" -> doListTemplates();
                case "parse_form_command" -> doParseFormCommand(args);
                default -> ToolExecutionOutcome.text("{\"error\":\"unknown tool: " + call.getName() + "\"}");
            };
        } catch (Exception ex) {
            log.warn("Tool {} execution failed: {}", call.getName(), ex.getMessage());
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("error", ex.getMessage());
            return ToolExecutionOutcome.text(toJson(err));
        }
    }

    private ToolExecutionOutcome doListTemplates() {
        RequestTemplateService templateService = templateServiceProvider.getIfAvailable();
        FormService formService = formServiceProvider.getIfAvailable();
        if (templateService == null || formService == null) {
            return ToolExecutionOutcome.text("{\"templates\":[],\"warning\":\"template/form service unavailable\"}");
        }
        Set<String> roleCodes = safeRoleCodes();
        List<RequestTemplateService.TemplateView> templates = templateService.listActiveTemplatesForRoles(roleCodes);

        List<Map<String, Object>> payload = new ArrayList<>();
        for (RequestTemplateService.TemplateView t : templates) {
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("templateKey", t.getTemplateKey());
            entry.put("templateName", t.getTemplateName());
            if (t.getCategory() != null) entry.put("category", t.getCategory());
            if (t.getDescription() != null) entry.put("description", t.getDescription());
            entry.put("formKey", t.getFormKey());
            entry.put("formName", t.getFormName());

            List<Map<String, Object>> fieldSummaries = new ArrayList<>();
            if (t.getFormVersionId() != null) {
                try {
                    List<FormField> fields = formService.getFields(t.getFormVersionId());
                    for (FormField f : fields) {
                        Map<String, Object> fieldEntry = new LinkedHashMap<>();
                        fieldEntry.put("fieldKey", f.getFieldKey());
                        fieldEntry.put("fieldType", f.getFieldType());
                        fieldEntry.put("label", f.getLabel());
                        fieldEntry.put("required", f.getRequired() != null && f.getRequired() == 1);
                        if (f.getOptionsJson() != null && !f.getOptionsJson().isBlank()) {
                            fieldEntry.put("optionsJson", f.getOptionsJson());
                        }
                        fieldSummaries.add(fieldEntry);
                    }
                } catch (Exception ignored) {
                    // schema lookup may fail for misconfigured templates; skip silently
                }
            }
            entry.put("fields", fieldSummaries);
            payload.add(entry);
        }

        Map<String, Object> wrapper = new LinkedHashMap<>();
        wrapper.put("templates", payload);
        return ToolExecutionOutcome.text(toJson(wrapper));
    }

    private ToolExecutionOutcome doParseFormCommand(Map<String, Object> args) {
        FormCommandAiService formCommandService = formCommandServiceProvider.getIfAvailable();
        if (formCommandService == null) {
            return ToolExecutionOutcome.text("{\"error\":\"form-command service unavailable\"}");
        }
        String command = (String) args.get("command");
        String templateKey = (String) args.get("requestTemplateKey");
        if (command == null || command.isBlank()) {
            return ToolExecutionOutcome.text("{\"error\":\"command is required\"}");
        }

        FormCommandAiService.ParseRequest parseRequest = new FormCommandAiService.ParseRequest();
        parseRequest.setCommand(command);
        parseRequest.setRequestTemplateKey(templateKey);
        FormCommandAiService.ParseResult parseResult = formCommandService.parse(parseRequest);

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("templateKey", parseResult.getTemplateKey());
        payload.put("templateName", parseResult.getTemplateName());
        payload.put("formKey", parseResult.getFormKey());
        payload.put("formVersionId", parseResult.getFormVersionId());
        payload.put("formData", parseResult.getFormData());
        payload.put("missingRequiredFields", parseResult.getMissingRequiredFields());
        payload.put("confidence", parseResult.getConfidence());
        payload.put("model", parseResult.getModel());

        PendingAction pendingAction = new PendingAction();
        pendingAction.setId(UUID.randomUUID().toString());
        pendingAction.setKind("start_process");
        pendingAction.setCommand(command);
        pendingAction.setTemplateKey(parseResult.getTemplateKey());
        pendingAction.setTemplateName(parseResult.getTemplateName());
        pendingAction.setFormKey(parseResult.getFormKey());
        pendingAction.setFormVersionId(parseResult.getFormVersionId());
        pendingAction.setFormData(parseResult.getFormData());
        pendingAction.setMissingRequiredFields(parseResult.getMissingRequiredFields());
        pendingAction.setConfidence(parseResult.getConfidence());

        return new ToolExecutionOutcome(toJson(payload), pendingAction);
    }

    private Map<String, Object> parseArgs(String argumentsJson) {
        if (argumentsJson == null || argumentsJson.isBlank()) {
            return Map.of();
        }
        try {
            JsonNode node = objectMapper.readTree(argumentsJson);
            if (!node.isObject()) {
                return Map.of();
            }
            return objectMapper.convertValue(node, new TypeReference<Map<String, Object>>() {});
        } catch (Exception ex) {
            return Map.of();
        }
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception ex) {
            return "{}";
        }
    }

    private Set<String> safeRoleCodes() {
        try {
            return SecurityUtils.currentRoleCodes();
        } catch (Exception ex) {
            return Set.of();
        }
    }

    private static LlmClient.ChatMessage sysMsg(String content) {
        LlmClient.ChatMessage m = new LlmClient.ChatMessage();
        m.setRole("system");
        m.setContent(content);
        return m;
    }

    private static LlmClient.ChatMessage userMsg(String content) {
        LlmClient.ChatMessage m = new LlmClient.ChatMessage();
        m.setRole("user");
        m.setContent(content);
        return m;
    }

    private static LlmClient.ChatMessage assistantTextMsg(String content) {
        LlmClient.ChatMessage m = new LlmClient.ChatMessage();
        m.setRole("assistant");
        m.setContent(content);
        return m;
    }

    private record ToolExecutionOutcome(String contentJson, PendingAction pendingAction) {
        static ToolExecutionOutcome text(String json) {
            return new ToolExecutionOutcome(json, null);
        }
    }

    @Data
    public static class AgentChatRequest {
        private String message;
        private List<LlmClient.ConversationTurn> history;
    }

    @Data
    public static class AgentChatResult {
        private String reply;
        private String model;
        private PendingAction pendingAction;
    }

    @Data
    public static class PendingAction {
        private String id;
        /** "start_process" for now; reserved for future kinds. */
        private String kind;
        private String command;
        private String templateKey;
        private String templateName;
        private String formKey;
        private Long formVersionId;
        private Map<String, Object> formData;
        private List<String> missingRequiredFields;
        private Double confidence;
    }
}
