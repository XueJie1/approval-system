package com.flowablecollab.approval_system.service;

import com.flowablecollab.approval_system.entity.BizRequest;
import com.flowablecollab.approval_system.entity.BizRequestLog;
import com.flowablecollab.approval_system.entity.BizRequestTask;
import com.flowablecollab.approval_system.entity.rbac.SysUser;
import com.flowablecollab.approval_system.repository.BizRequestLogRepository;
import com.flowablecollab.approval_system.repository.BizRequestRepository;
import com.flowablecollab.approval_system.repository.BizRequestTaskRepository;
import com.flowablecollab.approval_system.repository.rbac.SysUserRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.flowable.engine.HistoryService;
import org.flowable.engine.RuntimeService;
import org.flowable.engine.TaskService;
import org.flowable.engine.runtime.ProcessInstance;
import org.flowable.task.api.Task;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class WorkflowService {

    private static final int REQUEST_STATUS_SUBMITTED = 1;
    private static final int REQUEST_STATUS_IN_APPROVAL = 2;
    private static final int REQUEST_STATUS_APPROVED = 3;
    private static final int REQUEST_STATUS_REJECTED = 4;
    private static final int REQUEST_STATUS_RETURNED = 5;
    private static final int REQUEST_STATUS_CANCELLED = 6;

    private static final int TASK_STATUS_READY = 0;
    private static final int TASK_STATUS_CLAIMED = 1;
    private static final int TASK_STATUS_DELEGATED = 2;
    private static final int TASK_STATUS_COMPLETED = 3;
    private static final int TASK_STATUS_RETURNED = 4;

    private final RuntimeService runtimeService;
    private final TaskService taskService;
    private final HistoryService historyService;
    private final BizRequestRepository bizRequestRepository;
    private final BizRequestTaskRepository bizRequestTaskRepository;
    private final BizRequestLogRepository bizRequestLogRepository;
    private final SysUserRepository sysUserRepository;

    @Transactional
    public String startApprovalProcess(StartRequest request) {
        String processKey = request.getProcessKey() == null || request.getProcessKey().isBlank()
                ? "approvalWorkflow"
                : request.getProcessKey();
        String businessKey = request.getBusinessKey();
        if (businessKey == null || businessKey.isBlank()) {
            businessKey = UUID.randomUUID().toString();
        }

        Map<String, Object> variables = new HashMap<>();
        if (request.getVariables() != null) {
            variables.putAll(request.getVariables());
        }
        variables.put("businessKey", businessKey);
        variables.put("applicantId", request.getApplicantId());
        variables.put("title", request.getTitle());
        if (request.getFormInstanceId() != null) {
            variables.put("formInstanceId", request.getFormInstanceId());
        }

        List<String> countersignUsers = request.getCountersignUsers();
        if (countersignUsers == null || countersignUsers.isEmpty()) {
            countersignUsers = List.of(String.valueOf(request.getApplicantId()));
        }
        variables.put("countersignUsers", countersignUsers);
        String countersignMode = request.getCountersignMode() == null ? "ALL" : request.getCountersignMode();
        if ("approvalOrSign".equals(processKey)) {
            countersignMode = "OR";
        } else if ("approvalSequential".equals(processKey)) {
            countersignMode = "ALL";
        }
        variables.put("countersignMode", countersignMode);

        int instanceCount = countersignUsers.size();
        BigDecimal passRatio = request.getPassRatio() == null ? BigDecimal.ONE : request.getPassRatio();
        int requiredApprove = passRatio.multiply(BigDecimal.valueOf(instanceCount))
                .setScale(0, RoundingMode.CEILING)
                .intValue();
        if ("ALL".equalsIgnoreCase(countersignMode)) {
            requiredApprove = instanceCount;
        }
        variables.put("requiredApprove", requiredApprove);
        variables.put("approveCount", 0);
        variables.put("rejectCount", 0);
        variables.put("countersignResult", "PENDING");

        ProcessInstance processInstance = runtimeService
                .startProcessInstanceByKey(processKey, businessKey, variables);

        BizRequest bizRequest = new BizRequest();
        bizRequest.setBusinessKey(businessKey);
        bizRequest.setProcessInstanceId(processInstance.getId());
        bizRequest.setProcessDefinitionId(processInstance.getProcessDefinitionId());
        bizRequest.setFormInstanceId(request.getFormInstanceId());
        bizRequest.setApplicantId(request.getApplicantId());
        bizRequest.setApplicantDeptId(request.getApplicantDeptId());
        bizRequest.setApplicantPostId(request.getApplicantPostId());
        bizRequest.setTitle(request.getTitle());
        bizRequest.setStatus(REQUEST_STATUS_SUBMITTED);
        bizRequest.setSubmitTime(LocalDateTime.now());
        bizRequestRepository.save(bizRequest);

        List<Task> tasks = taskService.createTaskQuery()
                .processInstanceId(processInstance.getId())
                .list();
        for (Task task : tasks) {
            upsertTaskRecord(task, TASK_STATUS_READY, "CREATE", null);
        }
        updateRequestCurrentTask(bizRequest, tasks);
        appendLog(processInstance.getId(), null, request.getApplicantId(), "SUBMIT", "提交申请");

        log.info("Started approval process {} for businessKey {}", processInstance.getId(), businessKey);
        return processInstance.getId();
    }

    public List<TaskInfo> getTasksForAssignee(String assignee, boolean includeCandidate) {
        List<Task> tasks = taskService.createTaskQuery()
                .taskAssignee(assignee)
                .list();
        if (includeCandidate) {
            List<Task> candidateTasks = taskService.createTaskQuery()
                    .taskCandidateUser(assignee)
                    .list();
            tasks = new ArrayList<>(tasks);
            tasks.addAll(candidateTasks);
        }
        return tasks.stream().map(this::convertToTaskInfo).collect(Collectors.toList());
    }

    public List<TaskInfo> getTasksByProcessInstanceIds(List<String> processInstanceIds) {
        if (processInstanceIds == null || processInstanceIds.isEmpty()) {
            return List.of();
        }
        List<Task> tasks = taskService.createTaskQuery()
                .processInstanceIdIn(processInstanceIds)
                .list();
        return tasks.stream().map(this::convertToTaskInfo).collect(Collectors.toList());
    }

    public List<ProcessInfo> getProcessesByIds(List<String> processInstanceIds) {
        if (processInstanceIds == null || processInstanceIds.isEmpty()) {
            return List.of();
        }
        List<ProcessInstance> instances = runtimeService.createProcessInstanceQuery()
                .processInstanceIds(new HashSet<>(processInstanceIds))
                .list();
        return instances.stream().map(this::convertToProcessInfo).collect(Collectors.toList());
    }

    @Transactional
    public void claimTask(String taskId, String userId) {
        taskService.claim(taskId, userId);
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        upsertTaskRecord(task, TASK_STATUS_CLAIMED, "CLAIM", null);
        appendLog(task.getProcessInstanceId(), taskId, parseLongSafe(userId), "CLAIM", "认领任务");
    }

    @Transactional
    public void completeTask(String taskId, String userId, String approvalResult, String comments) {
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        Map<String, Object> variables = new HashMap<>();
        variables.put("approvalResult", approvalResult);
        variables.put("comments", comments);
        taskService.complete(taskId, variables);

        upsertTaskRecord(task, TASK_STATUS_COMPLETED, approvalResult, comments);
        appendLog(task.getProcessInstanceId(), taskId, parseLongSafe(userId), approvalResult, comments);
        refreshCurrentTask(task.getProcessInstanceId());
    }

    @Transactional
    public void delegateTask(String taskId, String userId, String delegateUserId, String comment) {
        taskService.delegateTask(taskId, delegateUserId);
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        BizRequestTask record = upsertTaskRecord(task, TASK_STATUS_DELEGATED, "DELEGATE", comment);
        record.setOwnerId(parseLongSafe(userId));
        record.setAssigneeId(parseLongSafe(delegateUserId));
        bizRequestTaskRepository.save(record);
        appendLog(task.getProcessInstanceId(), taskId, parseLongSafe(userId), "DELEGATE", comment);
    }

    @Transactional
    public void resolveTask(String taskId, String userId, String approvalResult, String comment) {
        Map<String, Object> variables = new HashMap<>();
        variables.put("approvalResult", approvalResult);
        variables.put("comments", comment);
        taskService.resolveTask(taskId, variables);
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        BizRequestTask record = upsertTaskRecord(task, TASK_STATUS_CLAIMED, "RESOLVE", comment);
        record.setAssigneeId(parseLongSafe(task.getAssignee()));
        bizRequestTaskRepository.save(record);
        appendLog(task.getProcessInstanceId(), taskId, parseLongSafe(userId), "RESOLVE", comment);
    }

    @Transactional
    public void reassignTask(String taskId, String userId, String newAssigneeId, String comment) {
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        if (task.getAssignee() == null || task.getAssignee().isBlank()) {
            taskService.claim(taskId, newAssigneeId);
        } else {
            taskService.setAssignee(taskId, newAssigneeId);
        }
        Task updated = taskService.createTaskQuery().taskId(taskId).singleResult();
        BizRequestTask record = upsertTaskRecord(updated, TASK_STATUS_CLAIMED, "REASSIGN", comment);
        record.setAssigneeId(parseLongSafe(newAssigneeId));
        bizRequestTaskRepository.save(record);
        appendLog(updated.getProcessInstanceId(), taskId, parseLongSafe(userId), "REASSIGN", comment);
    }

    @Transactional
    public void returnToCountersign(String taskId, String userId, String comment) {
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        if (task == null) {
            return;
        }
        runtimeService.setVariable(task.getProcessInstanceId(), "approveCount", 0);
        runtimeService.setVariable(task.getProcessInstanceId(), "rejectCount", 0);
        runtimeService.setVariable(task.getProcessInstanceId(), "countersignResult", "PENDING");

        runtimeService.createChangeActivityStateBuilder()
                .processInstanceId(task.getProcessInstanceId())
                .moveExecutionToActivityId(task.getExecutionId(), "countersignTask")
                .changeState();

        BizRequestTask record = upsertTaskRecord(task, TASK_STATUS_RETURNED, "RETURN", comment);
        bizRequestTaskRepository.save(record);
        appendLog(task.getProcessInstanceId(), taskId, parseLongSafe(userId), "RETURN", comment);

        Optional<BizRequest> optional = bizRequestRepository.findByProcessInstanceId(task.getProcessInstanceId());
        if (optional.isPresent()) {
            BizRequest request = optional.get();
            request.setStatus(REQUEST_STATUS_RETURNED);
            bizRequestRepository.save(request);
        }
        refreshCurrentTask(task.getProcessInstanceId());
    }

    @Transactional
    public void returnToPrevious(String taskId, String userId, String comment) {
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        if (task == null) {
            return;
        }
        String previousActivityId = findPreviousUserTaskActivity(task.getProcessInstanceId(),
                task.getTaskDefinitionKey());
        if (previousActivityId == null) {
            previousActivityId = "countersignTask";
        }
        returnToActivity(task, previousActivityId, userId, comment);
    }

    @Transactional
    public void returnToActivityId(String taskId, String userId, String targetActivityId, String comment) {
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        if (task == null) {
            return;
        }
        returnToActivity(task, targetActivityId, userId, comment);
    }

    @Transactional
    public void returnToApplicant(String taskId, String userId, String comment) {
        Task task = taskService.createTaskQuery().taskId(taskId).singleResult();
        if (task == null) {
            return;
        }
        returnToActivity(task, "applicantRework", userId, comment);
    }

    @Transactional
    public void cancelProcess(String processInstanceId, String userId, String comment) {
        List<Task> tasks = taskService.createTaskQuery().processInstanceId(processInstanceId).list();
        for (Task task : tasks) {
            upsertTaskRecord(task, TASK_STATUS_COMPLETED, "CANCEL", comment);
            appendLog(processInstanceId, task.getId(), parseLongSafe(userId), "CANCEL_TASK", comment);
        }
        runtimeService.deleteProcessInstance(processInstanceId, "CANCELLED");
        Optional<BizRequest> optional = bizRequestRepository.findByProcessInstanceId(processInstanceId);
        if (optional.isPresent()) {
            BizRequest request = optional.get();
            request.setStatus(REQUEST_STATUS_CANCELLED);
            request.setFinishTime(LocalDateTime.now());
            request.setCurrentTaskId(null);
            request.setCurrentAssigneeId(null);
            bizRequestRepository.save(request);
        }
        appendLog(processInstanceId, null, parseLongSafe(userId), "CANCEL_PROCESS", comment);
    }

    private void returnToActivity(Task task, String targetActivityId, String userId, String comment) {
        runtimeService.setVariable(task.getProcessInstanceId(), "approveCount", 0);
        runtimeService.setVariable(task.getProcessInstanceId(), "rejectCount", 0);
        runtimeService.setVariable(task.getProcessInstanceId(), "countersignResult", "PENDING");

        runtimeService.createChangeActivityStateBuilder()
                .processInstanceId(task.getProcessInstanceId())
                .moveExecutionToActivityId(task.getExecutionId(), targetActivityId)
                .changeState();

        BizRequestTask record = upsertTaskRecord(task, TASK_STATUS_RETURNED, "RETURN", comment);
        bizRequestTaskRepository.save(record);
        appendLog(task.getProcessInstanceId(), task.getId(), parseLongSafe(userId), "RETURN", comment);

        Optional<BizRequest> optional = bizRequestRepository.findByProcessInstanceId(task.getProcessInstanceId());
        if (optional.isPresent()) {
            BizRequest request = optional.get();
            request.setStatus(REQUEST_STATUS_RETURNED);
            bizRequestRepository.save(request);
        }
        refreshCurrentTask(task.getProcessInstanceId());
    }

    private String findPreviousUserTaskActivity(String processInstanceId, String currentTaskDefinitionKey) {
        return historyService.createHistoricActivityInstanceQuery()
                .processInstanceId(processInstanceId)
                .activityType("userTask")
                .finished()
                .orderByHistoricActivityInstanceEndTime()
                .desc()
                .list()
                .stream()
                .filter(activity -> !currentTaskDefinitionKey.equals(activity.getActivityId()))
                .map(activity -> activity.getActivityId())
                .findFirst()
                .orElse(null);
    }

    private void refreshCurrentTask(String processInstanceId) {
        Optional<BizRequest> optional = bizRequestRepository.findByProcessInstanceId(processInstanceId);
        if (optional.isEmpty()) {
            return;
        }
        BizRequest bizRequest = optional.get();
        List<Task> tasks = taskService.createTaskQuery().processInstanceId(processInstanceId).list();
        if (tasks.isEmpty()) {
            // Process may have ended; try to read countersignResult safely
            String countersignResult = null;
            ProcessInstance pi = runtimeService.createProcessInstanceQuery()
                    .processInstanceId(processInstanceId).singleResult();
            if (pi != null) {
                // Process still running (maybe waiting at another node)
                Object resultVar = runtimeService.getVariable(processInstanceId, "countersignResult");
                countersignResult = resultVar != null ? String.valueOf(resultVar) : null;
            } else {
                // Process has ended; check historic variables
                var historicVariableInstance = historyService.createHistoricVariableInstanceQuery()
                        .processInstanceId(processInstanceId)
                        .variableName("countersignResult")
                        .singleResult();
                if (historicVariableInstance != null && historicVariableInstance.getValue() != null) {
                    countersignResult = String.valueOf(historicVariableInstance.getValue());
                }
            }

            if ("APPROVE".equalsIgnoreCase(countersignResult)) {
                bizRequest.setStatus(REQUEST_STATUS_APPROVED);
            } else if ("REJECT".equalsIgnoreCase(countersignResult)) {
                bizRequest.setStatus(REQUEST_STATUS_REJECTED);
            } else {
                bizRequest.setStatus(REQUEST_STATUS_IN_APPROVAL);
            }
            bizRequest.setCurrentTaskId(null);
            bizRequest.setCurrentAssigneeId(null);
            bizRequest.setFinishTime(LocalDateTime.now());
        } else {
            bizRequest.setStatus(REQUEST_STATUS_IN_APPROVAL);
            Task task = tasks.get(0);
            bizRequest.setCurrentTaskId(task.getId());
            bizRequest.setCurrentAssigneeId(parseLongSafe(task.getAssignee()));
        }
        bizRequestRepository.save(bizRequest);
    }

    private void updateRequestCurrentTask(BizRequest request, List<Task> tasks) {
        request.setStatus(REQUEST_STATUS_IN_APPROVAL);
        if (!tasks.isEmpty()) {
            Task task = tasks.get(0);
            request.setCurrentTaskId(task.getId());
            request.setCurrentAssigneeId(parseLongSafe(task.getAssignee()));
        }
        bizRequestRepository.save(request);
    }

    private BizRequestTask upsertTaskRecord(Task task, int status, String action, String comment) {
        if (task == null) {
            return null;
        }
        BizRequestTask record = bizRequestTaskRepository.findByTaskId(task.getId())
                .orElseGet(BizRequestTask::new);
        record.setBusinessKey(getBusinessKey(task.getProcessInstanceId()));
        record.setProcessInstanceId(task.getProcessInstanceId());
        record.setTaskId(task.getId());
        record.setTaskName(task.getName());
        record.setAssigneeId(parseLongSafe(task.getAssignee()));
        record.setStatus(status);
        record.setAction(action);
        record.setComment(comment);
        if (record.getStartTime() == null && task.getCreateTime() != null) {
            record.setStartTime(
                    LocalDateTime.ofInstant(task.getCreateTime().toInstant(), java.time.ZoneId.systemDefault()));
        } else if (record.getStartTime() == null) {
            record.setStartTime(LocalDateTime.now());
        }
        if (status == TASK_STATUS_COMPLETED) {
            record.setEndTime(LocalDateTime.now());
        }
        return bizRequestTaskRepository.save(record);
    }

    private void appendLog(String processInstanceId, String taskId, Long operatorId, String action, String comment) {
        BizRequestLog logEntry = new BizRequestLog();
        logEntry.setBusinessKey(getBusinessKey(processInstanceId));
        logEntry.setProcessInstanceId(processInstanceId);
        logEntry.setTaskId(taskId);
        logEntry.setOperatorId(operatorId);
        logEntry.setAction(action);
        logEntry.setComment(comment);
        bizRequestLogRepository.save(logEntry);
    }

    private String getBusinessKey(String processInstanceId) {
        ProcessInstance instance = runtimeService.createProcessInstanceQuery()
                .processInstanceId(processInstanceId)
                .singleResult();
        if (instance != null) {
            return instance.getBusinessKey();
        }
        return bizRequestRepository.findByProcessInstanceId(processInstanceId)
                .map(BizRequest::getBusinessKey)
                .orElse(null);
    }

    private Long parseLongSafe(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException ex) {
            // Try to resolve as username
            return sysUserRepository.findByUsername(value).map(SysUser::getId).orElse(null);
        }
    }

    private TaskInfo convertToTaskInfo(Task task) {
        TaskInfo info = new TaskInfo();
        info.setTaskId(task.getId());
        info.setTaskName(task.getName());
        info.setProcessInstanceId(task.getProcessInstanceId());
        info.setAssignee(task.getAssignee());
        info.setCreateTime(task.getCreateTime());
        return info;
    }

    private ProcessInfo convertToProcessInfo(ProcessInstance instance) {
        ProcessInfo info = new ProcessInfo();
        info.setProcessInstanceId(instance.getId());
        info.setProcessDefinitionId(instance.getProcessDefinitionId());
        info.setBusinessKey(instance.getBusinessKey());
        return info;
    }

    @Data
    public static class TaskInfo {
        private String taskId;
        private String taskName;
        private String processInstanceId;
        private String assignee;
        private Date createTime;
    }

    @Data
    public static class ProcessInfo {
        private String processInstanceId;
        private String processDefinitionId;
        private String businessKey;
    }

    @Data
    public static class StartRequest {
        private String businessKey;
        private String title;
        private Long applicantId;
        private Long applicantDeptId;
        private Long applicantPostId;
        private Long formInstanceId;
        private String processKey;
        private Map<String, Object> variables;
        private List<String> countersignUsers;
        private String countersignMode;
        private BigDecimal passRatio;
    }
}
