package com.flowablecollab.approval_system.listener;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.flowable.engine.RuntimeService;
import org.flowable.task.service.delegate.DelegateTask;
import org.flowable.task.service.delegate.TaskListener;
import org.springframework.stereotype.Component;

/**
 * Task listener for single approval process.
 * Unlike countersignTaskListener, this doesn't depend on multi-instance variables
 * like nrOfInstances. It directly sets countersignResult based on approvalResult.
 */
@Slf4j
@Component("singleApprovalTaskListener")
@RequiredArgsConstructor
public class SingleApprovalTaskListener implements TaskListener {

    private final RuntimeService runtimeService;

    @Override
    public void notify(DelegateTask delegateTask) {
        String processInstanceId = delegateTask.getProcessInstanceId();
        String approvalResult = String.valueOf(delegateTask.getVariable("approvalResult"));

        // For single approval, the countersignResult is simply the approvalResult
        // No need for complex logic involving nrOfInstances, approveCount, etc.
        String countersignResult = "APPROVE".equalsIgnoreCase(approvalResult) ? "APPROVE" : "REJECT";

        runtimeService.setVariable(processInstanceId, "countersignResult", countersignResult);
        log.info("Single approval updated: approvalResult={}, countersignResult={}", approvalResult, countersignResult);
    }
}
