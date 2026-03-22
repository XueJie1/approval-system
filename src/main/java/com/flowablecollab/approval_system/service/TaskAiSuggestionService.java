package com.flowablecollab.approval_system.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flowablecollab.approval_system.entity.AiSuggestionRecord;
import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.exception.ForbiddenOperationException;
import com.flowablecollab.approval_system.repository.AiSuggestionRecordRepository;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.service.ai.ApprovalSuggestionService;
import com.flowablecollab.approval_system.service.ai.LlmClient;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.flowable.engine.TaskService;
import org.flowable.task.api.Task;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class TaskAiSuggestionService {

    private final TaskService taskService;
    private final BizRequestRepository bizRequestRepository;
    private final AiSuggestionRecordRepository aiSuggestionRecordRepository;
    private final ApprovalSuggestionService approvalSuggestionService;
    private final ObjectMapper objectMapper;

    @Transactional
    public SuggestionRecordView generateSuggestion(
            String taskId,
            Long requesterId,
            String requesterUsername,
            boolean isAdmin) {
        Task task = requireAccessibleTask(taskId, requesterId, requesterUsername, isAdmin);
        BizRequest request = getRequest(task.getProcessInstanceId());
        ApprovalSuggestionService.SuggestionContext context = buildContext(task, request, List.of());
        ApprovalSuggestionService.SuggestionResult result = approvalSuggestionService.suggest(context);

        AiSuggestionRecord record = new AiSuggestionRecord();
        record.setBusinessKey(request.getBusinessKey());
        record.setProcessInstanceId(task.getProcessInstanceId());
        record.setTaskId(task.getId());
        record.setRequesterId(requesterId);
        record.setModel(result.getModel());
        record.setSuggestionJson(writeJson(result));
        record.setConversationJson(writeJson(List.of()));
        AiSuggestionRecord saved = aiSuggestionRecordRepository.save(record);
        return toView(saved);
    }

    @Transactional
    public SuggestionRecordView followUp(
            String taskId,
            Long recordId,
            String question,
            Long requesterId,
            String requesterUsername,
            boolean isAdmin) {
        Task task = requireAccessibleTask(taskId, requesterId, requesterUsername, isAdmin);
        AiSuggestionRecord record = aiSuggestionRecordRepository.findById(recordId)
                .orElseThrow(() -> new IllegalArgumentException("ai suggestion record not found"));
        if (!Objects.equals(record.getTaskId(), task.getId())) {
            throw new IllegalArgumentException("ai suggestion record does not belong to task");
        }

        BizRequest request = getRequest(task.getProcessInstanceId());
        ApprovalSuggestionService.SuggestionResult suggestion = readSuggestion(record);
        List<ConversationTurnView> conversationTurns = readConversation(record);
        ApprovalSuggestionService.SuggestionContext context = buildContext(task, request, toLlmTurns(conversationTurns));
        ApprovalSuggestionService.FollowUpResult followUpResult = approvalSuggestionService.followUp(context, suggestion, question);

        ConversationTurnView turn = new ConversationTurnView();
        turn.setQuestion(question);
        turn.setAnswer(followUpResult.getAnswer());
        turn.setAskedAt(LocalDateTime.now());
        turn.setAnsweredAt(followUpResult.getAnsweredAt());
        turn.setModel(followUpResult.getModel());
        conversationTurns.add(turn);

        record.setConversationJson(writeJson(conversationTurns));
        if (followUpResult.getModel() != null && !followUpResult.getModel().isBlank()) {
            record.setModel(followUpResult.getModel());
        }
        AiSuggestionRecord saved = aiSuggestionRecordRepository.save(record);
        return toView(saved);
    }

    @Transactional
    public SuggestionRecordView markAdopted(
            String taskId,
            Long recordId,
            Long requesterId,
            String requesterUsername,
            boolean isAdmin) {
        requireAccessibleTask(taskId, requesterId, requesterUsername, isAdmin);
        AiSuggestionRecord record = aiSuggestionRecordRepository.findById(recordId)
                .orElseThrow(() -> new IllegalArgumentException("ai suggestion record not found"));
        if (!Objects.equals(record.getTaskId(), taskId)) {
            throw new IllegalArgumentException("ai suggestion record does not belong to task");
        }
        record.setAdopted(true);
        if (record.getAdoptedAt() == null) {
            record.setAdoptedAt(LocalDateTime.now());
        }
        AiSuggestionRecord saved = aiSuggestionRecordRepository.save(record);
        return toView(saved);
    }

    public List<SuggestionRecordView> getTaskHistory(
            String taskId,
            Long requesterId,
            String requesterUsername,
            boolean isAdmin) {
        requireAccessibleTask(taskId, requesterId, requesterUsername, isAdmin);
        return aiSuggestionRecordRepository.findByTaskIdOrderByCreatedAtDesc(taskId).stream()
                .map(this::toView)
                .toList();
    }

    public List<SuggestionRecordView> getHistoryForBusinessKeys(List<String> businessKeys) {
        if (businessKeys == null || businessKeys.isEmpty()) {
            return List.of();
        }
        return aiSuggestionRecordRepository.findByBusinessKeyInOrderByCreatedAtDesc(businessKeys).stream()
                .map(this::toView)
                .toList();
    }

    @Transactional
    public void markFinalResultForProcess(String processInstanceId, String finalApprovalResult) {
        if (processInstanceId == null || processInstanceId.isBlank() || finalApprovalResult == null || finalApprovalResult.isBlank()) {
            return;
        }
        List<AiSuggestionRecord> records = aiSuggestionRecordRepository.findByProcessInstanceId(processInstanceId);
        if (records.isEmpty()) {
            return;
        }
        for (AiSuggestionRecord record : records) {
            record.setFinalApprovalResult(finalApprovalResult);
        }
        aiSuggestionRecordRepository.saveAll(records);
    }

    private Task requireAccessibleTask(String taskId, Long requesterId, String requesterUsername, boolean isAdmin) {
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        if (task == null) {
            throw new IllegalArgumentException("task not found");
        }
        ensureTaskSuggestionAccess(task, requesterId, requesterUsername, isAdmin);
        return task;
    }

    private BizRequest getRequest(String processInstanceId) {
        return bizRequestRepository.findByProcessInstanceId(processInstanceId)
                .orElseThrow(() -> new IllegalArgumentException("request not found"));
    }

    private ApprovalSuggestionService.SuggestionContext buildContext(
            Task task,
            BizRequest request,
            List<LlmClient.ConversationTurn> conversationTurns) {
        Map<String, Object> variables = new LinkedHashMap<>(taskService.getVariables(task.getId()));
        if (request.getSubmitTime() != null) {
            variables.put("requestSubmitTime", request.getSubmitTime().toString());
        }

        ApprovalSuggestionService.SuggestionContext context = new ApprovalSuggestionService.SuggestionContext();
        context.setTaskId(task.getId());
        context.setTaskName(task.getName());
        context.setProcessInstanceId(task.getProcessInstanceId());
        context.setBusinessKey(request.getBusinessKey());
        context.setTitle(request.getTitle());
        context.setApplicantId(request.getApplicantId());
        context.setVariables(variables);
        context.setApplicantStats(buildApplicantStats(request, variables));
        context.setSimilarCaseStats(buildSimilarCaseStats(request));
        context.setPolicyReferences(buildPolicyReferences(variables));
        context.setHeuristicRiskWarnings(buildRiskWarnings(request, variables));
        context.setHeuristicAnomalies(buildAnomalies(variables));
        context.setConversationTurns(conversationTurns);
        return context;
    }

    private LlmClient.ApplicantStats buildApplicantStats(BizRequest request, Map<String, Object> variables) {
        List<BizRequest> applicantRequests = bizRequestRepository.findByApplicantId(request.getApplicantId());
        YearMonth currentMonth = YearMonth.from(LocalDate.now());
        Double totalAmount = 0D;
        int monthlyCount = 0;
        int monthlySameTypeCount = 0;
        int amountSampleCount = 0;
        Double currentAmount = extractNumber(variables, "amount", "totalAmount", "cost", "fee", "reimbursementAmount");

        for (BizRequest item : applicantRequests) {
            LocalDateTime submitTime = item.getSubmitTime() == null ? item.getCreatedAt() : item.getSubmitTime();
            if (submitTime == null || !YearMonth.from(submitTime.toLocalDate()).equals(currentMonth)) {
                continue;
            }
            monthlyCount++;
            Map<String, Object> itemVariables = readVariables(item.getCurrentTaskId(), item.getProcessInstanceId());
            Double amount = extractNumber(itemVariables, "amount", "totalAmount", "cost", "fee", "reimbursementAmount");
            if (amount != null) {
                totalAmount += amount;
                amountSampleCount++;
            }
            if (isSimilarRequest(request, item)) {
                monthlySameTypeCount++;
            }
        }

        LlmClient.ApplicantStats stats = new LlmClient.ApplicantStats();
        stats.setMonthlyRequestCount(monthlyCount);
        stats.setMonthlySameTypeCount(monthlySameTypeCount);
        stats.setMonthlyTotalAmount(totalAmount);
        if (amountSampleCount > 0) {
            stats.setAverageAmount(totalAmount / amountSampleCount);
        } else {
            stats.setAverageAmount(currentAmount);
        }
        return stats;
    }

    private LlmClient.SimilarCaseStats buildSimilarCaseStats(BizRequest currentRequest) {
        List<BizRequest> allRequests = bizRequestRepository.findAll();
        List<BizRequest> similarRequests = allRequests.stream()
                .filter(item -> !Objects.equals(item.getBusinessKey(), currentRequest.getBusinessKey()))
                .filter(item -> isSimilarRequest(currentRequest, item))
                .toList();

        int approvedCount = 0;
        int rejectedCount = 0;
        double totalAmount = 0D;
        int amountCount = 0;
        long totalProcessingMinutes = 0L;
        int durationCount = 0;

        for (BizRequest item : similarRequests) {
            if (Objects.equals(item.getStatus(), 3)) {
                approvedCount++;
            } else if (Objects.equals(item.getStatus(), 4)) {
                rejectedCount++;
            }
            Map<String, Object> itemVariables = readVariables(item.getCurrentTaskId(), item.getProcessInstanceId());
            Double amount = extractNumber(itemVariables, "amount", "totalAmount", "cost", "fee", "reimbursementAmount");
            if (amount != null) {
                totalAmount += amount;
                amountCount++;
            }
            if (item.getSubmitTime() != null && item.getFinishTime() != null) {
                totalProcessingMinutes += Duration.between(item.getSubmitTime(), item.getFinishTime()).toMinutes();
                durationCount++;
            }
        }

        LlmClient.SimilarCaseStats stats = new LlmClient.SimilarCaseStats();
        stats.setSampleCount(similarRequests.size());
        stats.setApprovedCount(approvedCount);
        stats.setRejectedCount(rejectedCount);
        if (amountCount > 0) {
            stats.setAverageAmount(totalAmount / amountCount);
        }
        if (durationCount > 0) {
            stats.setAverageProcessingTime(formatDurationMinutes(totalProcessingMinutes / durationCount));
        } else {
            stats.setAverageProcessingTime("暂无历史数据");
        }
        return stats;
    }

    private List<String> buildPolicyReferences(Map<String, Object> variables) {
        List<String> references = new ArrayList<>();
        references.add("通用审批实践：审批前应核对申请说明、预算归属、附件单据与金额一致性。");
        Double amount = extractNumber(variables, "amount", "totalAmount", "cost", "fee", "reimbursementAmount");
        if (amount != null && amount >= 10000) {
            references.add("大额申请常规要求：建议补充预算审批依据，并复核发票、合同或报价单。");
        }
        if (Boolean.TRUE.equals(extractBoolean(variables, "urgent", "isUrgent", "emergency"))) {
            references.add("紧急申请常规要求：需说明紧急原因、影响范围和补救方案。");
        }
        if (hasDatePairMismatch(variables)) {
            references.add("票据校验常规要求：发票日期、出差日期与报销期间应保持一致。");
        }
        return references;
    }

    private List<String> buildRiskWarnings(BizRequest request, Map<String, Object> variables) {
        List<String> warnings = new ArrayList<>();
        Double amount = extractNumber(variables, "amount", "totalAmount", "cost", "fee", "reimbursementAmount");
        String description = extractString(variables, "description", "reason", "content", "remark", "comment");

        LlmClient.ApplicantStats applicantStats = buildApplicantStats(request, variables);
        if (amount != null && applicantStats.getAverageAmount() != null
                && applicantStats.getAverageAmount() > 0
                && amount >= applicantStats.getAverageAmount() * 2) {
            warnings.add("金额异常：当前金额高于申请人历史平均水平。");
        }
        if (applicantStats.getMonthlySameTypeCount() != null && applicantStats.getMonthlySameTypeCount() >= 3) {
            warnings.add("频率异常：申请人本月同类申请次数偏高。");
        }
        LocalDateTime submitTime = request.getSubmitTime();
        if (submitTime != null && isOutsideWorkingHours(submitTime)) {
            warnings.add("时间异常：申请在非工作时间提交，请核实紧急性和业务合理性。");
        }
        if (Boolean.TRUE.equals(extractBoolean(variables, "urgent", "isUrgent", "emergency"))) {
            warnings.add("时间异常：申请被标记为紧急，请复核紧急原因。");
        }
        if (description != null && description.length() < 8) {
            warnings.add("内容可疑：申请说明过短，信息完整性不足。");
        }
        return warnings;
    }

    private List<String> buildAnomalies(Map<String, Object> variables) {
        List<String> anomalies = new ArrayList<>();
        Double amount = extractNumber(variables, "amount", "totalAmount", "cost", "fee", "reimbursementAmount");
        if (amount != null && amount < 0) {
            anomalies.add("金额为负数，数据不合法。");
        }

        String description = extractString(variables, "description", "reason", "content", "remark", "comment");
        if (description == null || description.isBlank()) {
            anomalies.add("缺少申请说明。");
        }

        if (hasDatePairMismatch(variables)) {
            anomalies.add("日期信息存在不一致，需核对发票日期与业务日期。");
        }
        return anomalies;
    }

    private boolean hasDatePairMismatch(Map<String, Object> variables) {
        LocalDate invoiceDate = extractDate(variables, "invoiceDate");
        LocalDate tripDate = extractDate(variables, "tripDate", "travelDate", "startDate");
        if (invoiceDate != null && tripDate != null && invoiceDate.isBefore(tripDate.minusDays(30))) {
            return true;
        }
        LocalDate endDate = extractDate(variables, "endDate");
        return tripDate != null && endDate != null && endDate.isBefore(tripDate);
    }

    private LocalDate extractDate(Map<String, Object> variables, String... keys) {
        for (String key : keys) {
            Object value = variables.get(key);
            if (value instanceof String str && !str.isBlank()) {
                try {
                    return LocalDate.parse(str.trim());
                } catch (Exception ignored) {
                    // ignore malformed date values and continue
                }
            }
        }
        return null;
    }

    private boolean isOutsideWorkingHours(LocalDateTime submitTime) {
        DayOfWeek dayOfWeek = submitTime.getDayOfWeek();
        LocalTime time = submitTime.toLocalTime();
        boolean weekend = dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY;
        boolean afterHours = time.isBefore(LocalTime.of(8, 0)) || time.isAfter(LocalTime.of(19, 0));
        return weekend || afterHours;
    }

    private boolean isSimilarRequest(BizRequest left, BizRequest right) {
        if (left == null || right == null) {
            return false;
        }
        if (left.getProcessDefinitionId() != null && left.getProcessDefinitionId().equals(right.getProcessDefinitionId())) {
            return true;
        }
        if (left.getTitle() == null || right.getTitle() == null) {
            return false;
        }
        return left.getTitle().trim().equalsIgnoreCase(right.getTitle().trim());
    }

    private Map<String, Object> readVariables(String currentTaskId, String processInstanceId) {
        if (currentTaskId != null && !currentTaskId.isBlank()) {
            Task activeTask = taskService.createTaskQuery().taskId(currentTaskId).singleResult();
            if (activeTask != null) {
                return taskService.getVariables(activeTask.getId());
            }
        }
        Task anyTask = taskService.createTaskQuery()
                .processInstanceId(processInstanceId)
                .orderByTaskCreateTime()
                .desc()
                .listPage(0, 1)
                .stream()
                .findFirst()
                .orElse(null);
        if (anyTask != null) {
            return taskService.getVariables(anyTask.getId());
        }
        return Map.of();
    }

    private void ensureTaskSuggestionAccess(Task task, Long requesterId, String requesterUsername, boolean isAdmin) {
        if (isAdmin) {
            return;
        }
        String requesterIdText = requesterId == null ? null : String.valueOf(requesterId);
        boolean isAssignee = isSameIdentity(task.getAssignee(), requesterUsername)
                || isSameIdentity(task.getAssignee(), requesterIdText);
        if (isAssignee) {
            return;
        }
        boolean isCandidate = false;
        if (requesterUsername != null && !requesterUsername.isBlank()) {
            isCandidate = taskService.createTaskQuery()
                    .taskId(task.getId())
                    .taskCandidateUser(requesterUsername)
                    .count() > 0;
        }
        if (!isCandidate && requesterIdText != null) {
            isCandidate = taskService.createTaskQuery()
                    .taskId(task.getId())
                    .taskCandidateUser(requesterIdText)
                    .count() > 0;
        }
        if (!isCandidate) {
            throw new ForbiddenOperationException("only assignee/candidate/admin can access ai suggestion");
        }
    }

    private boolean isSameIdentity(String left, String right) {
        return left != null && right != null && left.equals(right);
    }

    private String formatDurationMinutes(long minutes) {
        if (minutes <= 0) {
            return "不足 1 分钟";
        }
        long days = minutes / (60 * 24);
        long hours = (minutes % (60 * 24)) / 60;
        long mins = minutes % 60;
        List<String> parts = new ArrayList<>();
        if (days > 0) {
            parts.add(days + " 天");
        }
        if (hours > 0) {
            parts.add(hours + " 小时");
        }
        if (mins > 0) {
            parts.add(mins + " 分钟");
        }
        return String.join("", parts);
    }

    private Double extractNumber(Map<String, Object> variables, String... keys) {
        for (String key : keys) {
            Object value = variables.get(key);
            if (value instanceof Number number) {
                return number.doubleValue();
            }
            if (value instanceof String str && !str.isBlank()) {
                try {
                    return Double.parseDouble(str.trim());
                } catch (NumberFormatException ignored) {
                    // ignore non-numeric values and continue
                }
            }
        }
        return null;
    }

    private Boolean extractBoolean(Map<String, Object> variables, String... keys) {
        for (String key : keys) {
            Object value = variables.get(key);
            if (value instanceof Boolean b) {
                return b;
            }
            if (value instanceof String str && !str.isBlank()) {
                if ("true".equalsIgnoreCase(str)) {
                    return true;
                }
                if ("false".equalsIgnoreCase(str)) {
                    return false;
                }
            }
        }
        return null;
    }

    private String extractString(Map<String, Object> variables, String... keys) {
        for (String key : keys) {
            Object value = variables.get(key);
            if (value instanceof String str && !str.isBlank()) {
                return str.trim();
            }
        }
        return null;
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("failed to serialize ai suggestion record", ex);
        }
    }

    private ApprovalSuggestionService.SuggestionResult readSuggestion(AiSuggestionRecord record) {
        try {
            return objectMapper.readValue(record.getSuggestionJson(), ApprovalSuggestionService.SuggestionResult.class);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("failed to read ai suggestion record", ex);
        }
    }

    private List<ConversationTurnView> readConversation(AiSuggestionRecord record) {
        if (record.getConversationJson() == null || record.getConversationJson().isBlank()) {
            return new ArrayList<>();
        }
        try {
            List<ConversationTurnView> turns = objectMapper.readValue(
                    record.getConversationJson(),
                    new TypeReference<List<ConversationTurnView>>() {
                    });
            return new ArrayList<>(turns);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("failed to read ai suggestion conversation", ex);
        }
    }

    private List<LlmClient.ConversationTurn> toLlmTurns(List<ConversationTurnView> conversationTurns) {
        return conversationTurns.stream()
                .sorted(Comparator.comparing(ConversationTurnView::getAskedAt, Comparator.nullsLast(Comparator.naturalOrder())))
                .map(turn -> {
                    LlmClient.ConversationTurn llmTurn = new LlmClient.ConversationTurn();
                    llmTurn.setQuestion(turn.getQuestion());
                    llmTurn.setAnswer(turn.getAnswer());
                    return llmTurn;
                })
                .toList();
    }

    private SuggestionRecordView toView(AiSuggestionRecord record) {
        ApprovalSuggestionService.SuggestionResult suggestion = readSuggestion(record);
        List<ConversationTurnView> conversationTurns = readConversation(record);

        SuggestionRecordView view = new SuggestionRecordView();
        view.setRecordId(record.getId());
        view.setBusinessKey(record.getBusinessKey());
        view.setProcessInstanceId(record.getProcessInstanceId());
        view.setTaskId(record.getTaskId());
        view.setDecision(suggestion.getDecision());
        view.setRecommendation(suggestion.getRecommendation());
        view.setSummary(suggestion.getSummary());
        view.setRiskWarnings(suggestion.getRiskWarnings());
        view.setAnomalies(suggestion.getAnomalies());
        view.setSupplementaryInfo(suggestion.getSupplementaryInfo());
        view.setApprovalComment(suggestion.getApprovalComment());
        view.setSuggestedFormUpdates(suggestion.getSuggestedFormUpdates());
        view.setConversation(conversationTurns);
        view.setAdopted(Boolean.TRUE.equals(record.getAdopted()));
        view.setAdoptedAt(record.getAdoptedAt());
        view.setFinalApprovalResult(record.getFinalApprovalResult());
        view.setModel(record.getModel());
        view.setGeneratedAt(suggestion.getGeneratedAt() == null ? record.getCreatedAt() : suggestion.getGeneratedAt());
        return view;
    }

    @Data
    public static class SuggestionRecordView {
        private Long recordId;
        private String businessKey;
        private String processInstanceId;
        private String taskId;
        private String decision;
        private String recommendation;
        private String summary;
        private List<String> riskWarnings;
        private List<String> anomalies;
        private List<String> supplementaryInfo;
        private String approvalComment;
        private Map<String, Object> suggestedFormUpdates;
        private List<ConversationTurnView> conversation;
        private boolean adopted;
        private LocalDateTime adoptedAt;
        private String finalApprovalResult;
        private String model;
        private LocalDateTime generatedAt;
    }

    @Data
    public static class ConversationTurnView {
        private String question;
        private String answer;
        private LocalDateTime askedAt;
        private LocalDateTime answeredAt;
        private String model;
    }
}
