package com.flowablecollab.approval_system.service;

import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.flowable.engine.RuntimeService;
import org.flowable.engine.TaskService;
import org.flowable.engine.runtime.ProcessInstance;
import org.flowable.task.api.Task;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class WorkflowService {

    private final RuntimeService runtimeService;
    private final TaskService taskService;

    public String startApprovalProcess(String requestId, String requester, BigDecimal amount) {
        Map<String, Object> variables = new HashMap<>();
        variables.put("requestId", requestId);
        variables.put("requester", requester);
        variables.put("amount", amount);

        ProcessInstance processInstance = runtimeService
                .startProcessInstanceByKey("approvalWorkflow", variables);

        log.info("Started approval process: {} for request: {}",
                processInstance.getId(), requestId);

        return processInstance.getId();
    }

    public List<TaskInfo> getTasksForAssignee(String assignee) {
        List<Task> tasks = taskService.createTaskQuery()
                .taskAssignee(assignee)
                .list();

        return tasks.stream()
                .map(this::convertToTaskInfo)
                .collect(Collectors.toList());
    }

    public void completeTask(String taskId, boolean approved, String comments) {
        Map<String, Object> variables = new HashMap<>();
        variables.put("approved", approved);
        variables.put("comments", comments);

        taskService.complete(taskId, variables);

        log.info("Completed task: {} with approval: {}", taskId, approved);
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

    @Data
    public static class TaskInfo {
        private String taskId;
        private String taskName;
        private String processInstanceId;
        private String assignee;
        private Date createTime;
    }
}
