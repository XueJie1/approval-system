package com.flowablecollab.approval_system.listener;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.flowable.engine.RuntimeService;
import org.flowable.task.service.delegate.DelegateTask;
import org.flowable.task.service.delegate.TaskListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component("countersignTaskListener")
@RequiredArgsConstructor
public class CountersignTaskListener implements TaskListener {

    private final RuntimeService runtimeService;

    @Override
    public void notify(DelegateTask delegateTask) {
        String processInstanceId = delegateTask.getProcessInstanceId();
        String approvalResult = String.valueOf(delegateTask.getVariable("approvalResult"));

        // Read variables from delegateTask which traverses the execution scope
        // hierarchy
        // (nrOfInstances is a multi-instance scoped variable, NOT a root process
        // variable)
        int approveCount = getIntFromTask(delegateTask, "approveCount");
        int rejectCount = getIntFromTask(delegateTask, "rejectCount");
        int requiredApprove = getIntFromTask(delegateTask, "requiredApprove");
        int nrOfInstances = getIntFromTask(delegateTask, "nrOfInstances");
        String mode = String.valueOf(delegateTask.getVariable("countersignMode"));

        if ("APPROVE".equalsIgnoreCase(approvalResult)) {
            approveCount += 1;
        } else {
            rejectCount += 1;
        }

        runtimeService.setVariable(processInstanceId, "approveCount", approveCount);
        runtimeService.setVariable(processInstanceId, "rejectCount", rejectCount);

        String result = "PENDING";
        if ("OR".equalsIgnoreCase(mode)) {
            if (approveCount >= 1) {
                result = "APPROVE";
            } else if (rejectCount >= nrOfInstances && nrOfInstances > 0) {
                result = "REJECT";
            }
        } else if ("ALL".equalsIgnoreCase(mode)) {
            if (rejectCount > 0) {
                result = "REJECT";
            } else if (approveCount >= nrOfInstances && nrOfInstances > 0) {
                result = "APPROVE";
            }
        } else {
            if (approveCount >= requiredApprove && requiredApprove > 0) {
                result = "APPROVE";
            } else if (rejectCount > (nrOfInstances - requiredApprove)) {
                result = "REJECT";
            }
        }

        runtimeService.setVariable(processInstanceId, "countersignResult", result);
        log.info("Countersign updated: approve={}, reject={}, nrOfInstances={}, mode={}, result={}",
                approveCount, rejectCount, nrOfInstances, mode, result);
    }

    private int getIntFromTask(DelegateTask delegateTask, String key) {
        Object value = delegateTask.getVariable(key);
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value == null) {
            return 0;
        }
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (NumberFormatException ex) {
            return 0;
        }
    }
}
