package com.flowablecollab.approval_system.service.ai;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class MockLlmClientTests {

    private final MockLlmClient client = createClient();

    @Test
    void suggestApproval_flagsAnomaliesAndFormUpdates() {
        LlmClient.SuggestionRequest request = new LlmClient.SuggestionRequest();
        request.setVariables(Map.of(
                "amount", -50,
                "urgent", true
        ));
        request.setHeuristicRiskWarnings(List.of("时间异常：申请在非工作时间提交，请核实紧急性和业务合理性。"));
        request.setPolicyReferences(List.of("通用审批实践：审批前应核对申请说明。"));

        LlmClient.ApplicantStats applicantStats = new LlmClient.ApplicantStats();
        applicantStats.setMonthlySameTypeCount(4);
        applicantStats.setAverageAmount(20D);
        request.setApplicantStats(applicantStats);

        LlmClient.Suggestion suggestion = client.suggestApproval(request);

        assertThat(suggestion.getDecision()).isEqualTo("REJECT");
        assertThat(suggestion.getRecommendation()).contains("负数");
        assertThat(suggestion.getAnomalies()).anyMatch(item -> item.contains("负数"));
        assertThat(suggestion.getAnomalies()).anyMatch(item -> item.contains("缺少申请说明"));
        assertThat(suggestion.getRiskWarnings()).anyMatch(item -> item.contains("频率异常"));
        assertThat(suggestion.getRiskWarnings()).anyMatch(item -> item.contains("紧急"));
        assertThat(suggestion.getSupplementaryInfo()).contains("通用审批实践：审批前应核对申请说明。");
        assertThat(suggestion.getSuggestedFormUpdates()).containsEntry("description", "请补充业务背景、用途与费用构成");
        assertThat(suggestion.getApprovalComment()).startsWith("建议拒绝：");
        assertThat(suggestion.getModel()).isEqualTo("mock-approval-advisor-v2");
    }

    @Test
    void answerFollowUp_usesSuggestionListsAndProvidesFallback() {
        LlmClient.FollowUpRequest riskRequest = new LlmClient.FollowUpRequest();
        riskRequest.setQuestion("这次风险是什么？");
        LlmClient.Suggestion currentSuggestion = new LlmClient.Suggestion();
        currentSuggestion.setRiskWarnings(List.of("金额异常", "预算依据不足"));
        riskRequest.setCurrentSuggestion(currentSuggestion);

        LlmClient.FollowUpAnswer riskAnswer = client.answerFollowUp(riskRequest);
        assertThat(riskAnswer.getAnswer()).contains("风险主要来自");
        assertThat(riskAnswer.getAnswer()).contains("金额异常");

        LlmClient.FollowUpRequest genericRequest = new LlmClient.FollowUpRequest();
        genericRequest.setQuestion("还有什么要补充？");
        genericRequest.setCurrentSuggestion(new LlmClient.Suggestion());

        LlmClient.FollowUpAnswer genericAnswer = client.answerFollowUp(genericRequest);
        assertThat(genericAnswer.getAnswer()).contains("继续人工复核");
        assertThat(genericAnswer.getModel()).isEqualTo("mock-approval-advisor-v2");
    }

    private MockLlmClient createClient() {
        MockLlmClient mockLlmClient = new MockLlmClient();
        ReflectionTestUtils.setField(mockLlmClient, "mockModel", "mock-approval-advisor-v2");
        return mockLlmClient;
    }
}
