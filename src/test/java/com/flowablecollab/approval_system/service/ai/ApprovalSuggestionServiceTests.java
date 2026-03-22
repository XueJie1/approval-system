package com.flowablecollab.approval_system.service.ai;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ApprovalSuggestionServiceTests {

    @Mock
    private LlmClient llmClient;

    @InjectMocks
    private ApprovalSuggestionService approvalSuggestionService;

    @Test
    void suggest_normalizesDecisionAndBuildsDefaultComment() {
        ApprovalSuggestionService.SuggestionContext context = new ApprovalSuggestionService.SuggestionContext();
        context.setTaskId("task-1");

        LlmClient.Suggestion suggestion = new LlmClient.Suggestion();
        suggestion.setDecision("REVIEW");
        suggestion.setRecommendation("申请金额偏高，需要人工复核。");
        suggestion.setRiskWarnings(List.of("金额异常"));
        when(llmClient.suggestApproval(org.mockito.ArgumentMatchers.any())).thenReturn(suggestion);

        ApprovalSuggestionService.SuggestionResult result = approvalSuggestionService.suggest(context);

        assertThat(result.getTaskId()).isEqualTo("task-1");
        assertThat(result.getDecision()).isEqualTo("REJECT");
        assertThat(result.getRecommendation()).isEqualTo("申请金额偏高，需要人工复核。");
        assertThat(result.getSummary()).isEqualTo("申请金额偏高，需要人工复核。");
        assertThat(result.getRiskWarnings()).containsExactly("金额异常");
        assertThat(result.getAnomalies()).isEmpty();
        assertThat(result.getSupplementaryInfo()).isEmpty();
        assertThat(result.getSuggestedFormUpdates()).isEmpty();
        assertThat(result.getApprovalComment()).isEqualTo("建议拒绝：申请金额偏高，需要人工复核。");
        assertThat(result.getGeneratedAt()).isNotNull();
    }

    @Test
    void followUp_passesCurrentSuggestionAndFallsBackForBlankAnswer() {
        ApprovalSuggestionService.SuggestionContext context = new ApprovalSuggestionService.SuggestionContext();
        context.setTaskId("task-2");
        context.setTaskName("经理审批");
        context.setProcessInstanceId("proc-2");
        context.setBusinessKey("biz-2");
        context.setTitle("差旅报销");
        context.setVariables(Map.of("amount", 12888));

        LlmClient.ConversationTurn previousTurn = new LlmClient.ConversationTurn();
        previousTurn.setQuestion("之前有什么风险？");
        previousTurn.setAnswer("金额高于均值。");
        context.setConversationTurns(List.of(previousTurn));

        ApprovalSuggestionService.SuggestionResult currentSuggestion = new ApprovalSuggestionService.SuggestionResult();
        currentSuggestion.setDecision("REJECT");
        currentSuggestion.setRecommendation("缺少票据，建议驳回。");
        currentSuggestion.setSummary("缺少票据，建议驳回。");
        currentSuggestion.setRiskWarnings(List.of("金额异常"));
        currentSuggestion.setAnomalies(List.of("缺少票据"));
        currentSuggestion.setSupplementaryInfo(List.of("同类申请平均 2 天"));
        currentSuggestion.setApprovalComment("建议拒绝：缺少票据，建议驳回。");
        currentSuggestion.setSuggestedFormUpdates(Map.of("receiptRequired", true));

        LlmClient.FollowUpAnswer answer = new LlmClient.FollowUpAnswer();
        answer.setAnswer(" ");
        answer.setModel("mock-model");
        when(llmClient.answerFollowUp(org.mockito.ArgumentMatchers.any())).thenReturn(answer);

        ApprovalSuggestionService.FollowUpResult result =
                approvalSuggestionService.followUp(context, currentSuggestion, "为什么要拒绝？");

        ArgumentCaptor<LlmClient.FollowUpRequest> requestCaptor = ArgumentCaptor.forClass(LlmClient.FollowUpRequest.class);
        verify(llmClient).answerFollowUp(requestCaptor.capture());
        LlmClient.FollowUpRequest request = requestCaptor.getValue();
        assertThat(request.getQuestion()).isEqualTo("为什么要拒绝？");
        assertThat(request.getConversationTurns()).hasSize(1);
        assertThat(request.getConversationTurns().get(0).getQuestion()).isEqualTo("之前有什么风险？");
        assertThat(request.getCurrentSuggestion().getDecision()).isEqualTo("REJECT");
        assertThat(request.getCurrentSuggestion().getSuggestedFormUpdates()).containsEntry("receiptRequired", true);

        assertThat(result.getAnswer()).isEqualTo("暂无补充说明。");
        assertThat(result.getModel()).isEqualTo("mock-model");
        assertThat(result.getAnsweredAt()).isNotNull();
    }
}
