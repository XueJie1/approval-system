# 单人审批功能缺失分析

## 📊 现状概览

当前项目已实现的审批类型：
| 审批类型 | BPMN 文件 | 状态 |
|---------|----------|------|
| 会签 | approval-countersign.bpmn20.xml | ✅ 已实现 |
| 或签 | approval-orsign.bpmn20.xml | ✅ 已实现 |
| 顺序审批 | approval-sequential.bpmn20.xml | ✅ 已实现 |
| **单人审批** | ❌ **缺失** | ⚠️ **未实现** |

---

## 🔍 核心缺失功能

### 1. BPMN 流程定义缺失

**问题：** 没有单人审批的 BPMN 流程文件

**需要创建：** `approval-single.bpmn20.xml`

**建议流程结构：**
```xml
<process id="approvalSingle" name="Single Approval">
    <startEvent id="start"/>
    <userTask id="approvalTask" name="单人审批">
        <!-- assignee 动态分配 -->
    </userTask>
    <exclusiveGateway id="decision"/>
    <endEvent id="approvedEnd"/>
    <endEvent id="rejectedEnd"/>
</process>
```

---

### 2. 审批人动态分配机制缺失

**问题：** 当前没有根据发起人自动确定审批人的逻辑

**需要实现：**

#### 2.1 审批人规则配置表

```sql
CREATE TABLE workflow_approver_rule (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    process_key VARCHAR(64) NOT NULL,  -- 流程类型
    rule_type VARCHAR(32) NOT NULL,    -- 规则类型
    rule_config JSON,                  -- 规则配置
    status TINYINT DEFAULT 1
);
```

#### 2.2 审批人分配策略

| 策略 | 说明 | 示例 |
|------|------|------|
| **直属主管** | 发起人的直接上级 | 部门经理 |
| **指定角色** | 固定角色审批 | 财务专员 |
| **指定岗位** | 固定岗位 | 报销审核岗 |
| **部门负责人** | 发起人所在部门负责人 | 部门经理 |
| **自定义列表** | 配置多个审批人 | 主管 1、主管 2 |

---

### 3. 表单字段动态绑定缺失

**问题：** 当前表单是静态的，不支持动态表单配置

**需要实现：**

#### 3.1 动态表单字段映射

```sql
CREATE TABLE form_field_mapping (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    form_key VARCHAR(64),
    field_key VARCHAR(64),
    process_variable VARCHAR(64),
    field_type VARCHAR(32),
    required TINYINT DEFAULT 0
);
```

#### 3.2 表单数据到流程变量转换

```java
// 需要将表单字段值转换为流程变量
Map<String, Object> formVariables = new HashMap<>();
for (FormFieldMapping mapping : mappings) {
    formVariables.put(mapping.getProcessVariable(), formData.get(mapping.getFieldKey()));
}
```

---

### 4. 审批意见记录不完整

**问题：** 缺少审批意见的完整存储和查询

**需要实现：**

#### 4.1 审批意见表

```sql
CREATE TABLE approval_comment (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id VARCHAR(64),
    process_instance_id VARCHAR(64),
    business_key VARCHAR(64),
    operator_id BIGINT,
    operator_name VARCHAR(128),
    comment TEXT,
    approval_result VARCHAR(32),  -- APPROVE/REJECT
    created_at DATETIME,
   附件 VARCHAR(512)
);
```

#### 4.2 意见查询 API

```java
@GetMapping("/tasks/{taskId}/comments")
public ResponseEntity<List<ApprovalComment>> getComments(@PathVariable String taskId) {
    // 返回该任务的所有审批意见
}
```

---

### 5. 审批通知机制缺失

**问题：** 没有审批消息通知

**需要实现：**

#### 5.1 通知方式

| 通知方式 | 说明 |
|---------|------|
| 站内消息 | 系统内通知 |
| 邮件通知 | 发送到邮箱 |
| 短信通知 | 发送到手机 |
| WebSocket | 实时推送 |

#### 5.2 通知场景

```java
// 待办通知 - 审批任务分配给某人
void notifyTaskAssigned(String userId, String taskId, String taskName);

// 进度通知 - 申请状态变更
void notifyStatusChanged(String applicantId, String businessKey, String newStatus);

// 催办通知 - 审批超时提醒
void notifyUrgentReminder(String taskId, String assigneeId);
```

---

### 6. 审批超时处理缺失

**问题：** 没有审批超时自动提醒或转办

**需要实现：**

#### 6.1 超时策略配置

```java
@Data
public class TimeoutStrategy {
    private String processKey;
    private int timeoutHours;  // 超时时长（小时）
    private TimeoutAction action;  // 超时动作
    private String reminderTemplate;
}

public enum TimeoutAction {
    REMIND,      // 发送提醒
    DELEGATE,    // 自动转办给上级
    AUTO_APPROVE, // 自动通过
    AUTO_REJECT  // 自动拒绝
}
```

#### 6.2 超时检查任务

```java
@Component
public class TimeoutCheckScheduler {
    @Scheduled(fixedRate = 3600000)  // 每小时检查一次
    public void checkTimeoutTasks() {
        // 检查逾期未处理的审批任务
    }
}
```

---

### 7. 审批历史记录不完整

**问题：** 缺少完整的审批流程历史记录

**需要实现：**

#### 7.1 流程历史快照

```sql
CREATE TABLE approval_history_snapshot (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    process_instance_id VARCHAR(64),
    business_key VARCHAR(64),
    snapshot_time DATETIME,
    current_activity VARCHAR(128),
    current_assignee_id BIGINT,
    snapshot_data JSON  -- 完整流程状态快照
);
```

#### 7.2 历史查询 API

```java
@GetMapping("/process/{processInstanceId}/history")
public ResponseEntity<List<ApprovalHistoryNode>> getProcessHistory(
        @PathVariable String processInstanceId) {
    // 返回完整的审批流程历史
}
```

---

### 8. 批量审批功能缺失

**问题：** 只能单个审批，不支持批量处理

**需要实现：**

```java
@PostMapping("/tasks/batch/complete")
public ResponseEntity<BatchActionResponse> batchCompleteTasks(
        @RequestBody BatchCompleteRequest request) {
    // request: {
    //   "taskIds": ["task1", "task2", "task3"],
    //   "approvalResult": "APPROVE",
    //   "comment": "统一审批意见"
    // }
}
```

---

### 9. 审批撤回功能缺失

**问题：** 发起人无法撤回已提交的申请

**需要实现：**

```java
@PostMapping("/requests/{businessKey}/cancel")
public ResponseEntity<ActionResponse> cancelRequest(
        @PathVariable String businessKey,
        @RequestParam String comment) {
    // 只有在审批开始之前才能撤回
}
```

---

### 10. 审批统计报表缺失

**问题：** 没有审批数据分析

**需要实现：**

#### 10.1 统计指标

| 指标 | 说明 |
|------|------|
| 待审批数量 | 当前待处理的审批单 |
| 平均审批时长 | 从提交到审批完成的时间 |
| 审批通过率 | 通过数量 / 总数量 |
| 超期审批数量 | 超过规定时长的审批 |

#### 10.2 统计 API

```java
@GetMapping("/stats/approval")
public ResponseEntity<ApprovalStatistics> getApprovalStats(
        @RequestParam Long userId,
        @RequestParam String startDate,
        @RequestParam String endDate) {
    // 返回审批统计报表
}
```

---

## 📋 实现优先级建议

### 高优先级（必须实现）
1. ✅ BPMN 流程定义 - `approval-single.bpmn20.xml`
2. ✅ 审批人动态分配 - 根据发起人自动确定审批人
3. ✅ 审批意见记录 - 完整的意见存储和查询
4. ✅ 表单字段动态绑定 - 支持动态表单配置

### 中优先级（强烈建议）
5. ✅ 审批通知机制 - 待办消息通知
6. ✅ 审批历史记录 - 完整的流程历史
7. ✅ 审批超时处理 - 超时提醒和转办

### 低优先级（可选）
8. ⭐ 批量审批 - 提升效率
9. ⭐ 审批撤回 - 发起人撤销申请
10. ⭐ 统计报表 - 数据分析

---

## 💡 实现建议

### 方案一：使用现有流程引擎扩展

```java
// 在启动流程时，动态设置审批人
public String startSingleApprovalProcess(StartRequest request) {
    // 1. 查询审批人规则
    String approverId = approverRuleService.getApproverByRule(
        request.getProcessKey(), 
        request.getApplicantId()
    );
    
    // 2. 设置流程变量
    Map<String, Object> variables = new HashMap<>();
    variables.put("approverId", approverId);
    
    // 3. 启动流程
    ProcessInstance instance = runtimeService.startProcessInstanceByKey(
        "approvalSingle", 
        request.getBusinessKey(), 
        variables
    );
    
    return instance.getId();
}
```

### 方案二：使用 Flowable 的候选人类机制

```xml
<!-- 使用候选人类分配 -->
<userTask id="approvalTask" name="单人审批">
    <candidateUsers>${getApproverForApplicant(applicantId)}</candidateUsers>
</userTask>
```

---

## 📝 测试场景

### 正常流程测试
1. 用户 A 提交申请
2. 系统自动分配审批人 B
3. B 审批通过
4. 流程结束

### 异常流程测试
1. 用户 A 提交申请
2. 审批人 B 拒绝
3. 流程结束（拒绝）

### 边界场景测试
1. 审批人离职/调岗 - 自动转办上级
2. 审批超时 - 发送提醒
3. 多人审批冲突 - 第一人处理有效

---

**文档版本：** v1.0  
**最后更新：** 2026-03-14  
**作者：** AI Assistant
