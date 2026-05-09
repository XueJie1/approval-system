# 核心模块设计与时序图

> 基于实际代码实现，对核心功能模块进行详细设计说明。

## 1. 审批流程发起模块

### 1.1 流程发起时序

```mermaid
sequenceDiagram
    actor U as 用户
    participant FE as Vue 前端
    participant WC as WorkflowController
    participant WS as WorkflowService
    participant RAS as RequestTemplateApprovalResolver
    participant RS as RuntimeService (Flowable)
    participant DB as 数据库

    U->>FE: 填写表单 + 选择模板
    FE->>WC: POST /api/workflow/requests
    WC->>WC: 校验发起权限 (requireLaunchPermission)
    WC->>WC: 解析表单数据 (formService.createFormInstance)
    WC->>WS: startApprovalProcess(startRequest)
    WS->>RAS: 自动解析审批人 (resolve)
    RAS-->>WS: 返回审批人列表 + 策略
    WS->>WS: 设置流程变量 (countersignUsers, mode, passRatio)
    WS->>RS: startProcessInstanceByKey(processKey, businessKey, variables)
    RS-->>WS: ProcessInstance
    WS->>DB: 插入 biz_request (status=Submitted)
    WS->>DB: 插入 biz_request_task (每个审批人)
    WS->>DB: 插入 biz_request_log (SUBMIT)
    WS-->>WC: processInstanceId
    WC-->>FE: { processInstanceId, message }
    FE-->>U: 提示发起成功
```

### 1.2 审批人自动解析

```mermaid
flowchart TD
    A[发起申请] --> B{有模板?}
    B -->|是| C[读取模板审批规则 approval_config_json]
    B -->|否| D[使用请求中的 countersignUsers]
    C --> E{规则类型?}
    E -->|MANAGER| F[查询发起人直属主管]
    E -->|DEPT_LEADER| G[查询发起人部门负责人]
    E -->|SPECIFIC_USER| H[使用指定用户]
    E -->|PARENT_DEPT_LEADER| I[查询上级部门负责人]
    F --> J{审批人数 > 1?}
    G --> J
    H --> J
    I --> J
    J -->|是| K[使用 approvalSequential 流程]
    J -->|否| L[使用 approvalSingle 流程]
```

## 2. 审批执行模块

### 2.1 会签审批时序（并行多实例）

```mermaid
sequenceDiagram
    actor A1 as 审批人A
    actor A2 as 审批人B
    participant WC as WorkflowController
    participant WS as WorkflowService
    participant TS as TaskService (Flowable)
    participant CTL as CountersignTaskListener
    participant DB as 数据库

    Note over A1,A2: 会签任务已并行分配给 A 和 B

    A1->>WC: POST /tasks/{taskId}/complete (APPROVE)
    WC->>WS: completeTask(taskId, userId, "APPROVE", comment)
    WS->>TS: complete(taskId, {approvalResult: APPROVE})
    TS->>CTL: 触发 TaskListener (complete 事件)
    CTL->>CTL: 更新 approveCount/rejectCount
    CTL->>CTL: 计算 countersignResult
    WS->>DB: 更新 biz_request_task (APPROVE, Completed)
    WS->>DB: 插入 biz_request_log (APPROVE)
    WS->>DB: 更新 biz_request (currentTask)

    Note over A2: A2 尚未审批，任务继续等待

    A2->>WC: POST /tasks/{taskId}/complete (APPROVE)
    WC->>WS: completeTask(taskId, userId, "APPROVE", comment)
    WS->>TS: complete(taskId, {approvalResult: APPROVE})
    TS->>CTL: 触发 TaskListener
    CTL->>CTL: approveCount = 2 >= requiredApprove
    CTL->>CTL: countersignResult = "APPROVE"

    Note over TS: completionCondition 满足，多实例结束
    TS-->>TS: 自动取消未完成任务

    WS->>DB: 更新 biz_request_task (AUTO_COMPLETE)
    WS->>DB: 更新 biz_request (status=Approved, finishTime)
    WS->>DB: 标记 AI 建议最终结果
```

### 2.2 委派与时序

```mermaid
sequenceDiagram
    actor O as 原负责人
    actor D as 被委派人
    participant WS as WorkflowService
    participant TS as TaskService

    Note over O: 任务状态 Claimed

    O->>WS: delegateTask(taskId, userId, delegateUserId)
    WS->>TS: taskService.delegateTask(taskId, delegateUserId)
    Note over TS: owner=原负责人, assignee=被委派人, delegationState=PENDING
    WS->>DB: 更新 biz_request_task (status=Delegated, action=DELEGATE)

    D->>WS: resolveTask(taskId, userId, approvalResult, comment)
    WS->>WS: 校验 delegationState == PENDING
    WS->>TS: taskService.resolveTask(taskId, variables)
    Note over TS: assignee=原负责人, delegationState=RESOLVED
    WS->>DB: 更新 biz_request_task (status=Claimed, action=RESOLVE)

    O->>WS: completeTask(taskId, userId, approvalResult, comment)
    WS->>WS: 校验 delegationState == RESOLVED
    WS->>WS: 校验 userId == owner
    WS->>TS: taskService.complete(taskId, variables)
    WS->>DB: 更新 biz_request_task (status=Completed)
```

### 2.3 回退流程

```mermaid
sequenceDiagram
    actor U as 审批人
    participant WC as WorkflowController
    participant WS as WorkflowService
    participant RS as RuntimeService
    participant DB as 数据库

    U->>WC: POST /tasks/{taskId}/return/previous
    WC->>WS: returnToPrevious(taskId, userId, comment)

    WS->>WS: 从历史活动查询上一个 UserTask activityId
    WS->>RS: setVariable(approveCount=0, rejectCount=0, countersignResult=PENDING)
    WS->>RS: createChangeActivityStateBuilder()
             .moveExecutionToActivityId(executionId, previousActivityId)
             .changeState()

    WS->>DB: 更新 biz_request_task (status=Returned, action=RETURN)
    WS->>DB: 插入 biz_request_log (RETURN)
    WS->>DB: 更新 biz_request (status=Returned)
    WS->>WS: refreshCurrentTask (创建新的待办任务)

    WC-->>U: 回退成功
```

## 3. AI 审批建议模块

### 3.1 建议生成流程

```mermaid
sequenceDiagram
    actor U as 审批人
    participant WC as WorkflowController
    participant TAS as TaskAiSuggestionService
    participant AS as ApprovalSuggestionService
    participant LC as LlmClient (OpenAI)
    participant DB as 数据库

    U->>WC: GET /tasks/{taskId}/ai-suggestion
    WC->>TAS: generateSuggestion(taskId, requesterId)
    TAS->>TAS: 从 Flowable 获取任务上下文
    TAS->>TAS: 收集申请人统计 (月度申请数、同类申请审批率)
    TAS->>TAS: 收集相似案例统计
    TAS->>TAS: 生成启发式风险警告
    TAS->>AS: suggest(SuggestionContext)
    AS->>LC: suggestApproval(SuggestionRequest)
    Note over LC: 发送至 LLM API:
    Note over LC: taskName, title, variables,
    Note over LC: applicantStats, similarCaseStats,
    Note over LC: policyReferences, riskWarnings
    LC-->>AS: Suggestion { decision, recommendation, riskWarnings, ... }
    AS->>AS: normalizeDecision (规范化输出)
    AS-->>TAS: SuggestionResult
    TAS->>DB: 插入 ai_suggestion_record (suggestion_json)
    TAS-->>WC: SuggestionRecordView
    WC-->>U: { decision, recommendation, riskWarnings, anomalies, summary }
```

### 3.2 AI 建议输入数据结构

LLM 收到的每条审批建议请求包含以下维度的数据：

| 数据维度 | 内容 | 来源 |
|------|------|------|
| 任务上下文 | 任务名称、申请标题、表单变量 | Flowable 流程变量 |
| 申请人画像 | 月度申请总数、同类申请数、月度总金额、平均金额 | 历史数据统计 |
| 历史参考 | 相似案例样本数、通过率、拒绝率、平均处理时间 | 历史数据统计 |
| 规则参考 | 策略引用列表 | 系统配置 |
| 风险提示 | 启发式风险警告列表、异常检测列表 | 规则引擎 |

### 3.3 AI 建议输出结构

```json
{
  "decision": "APPROVE",
  "recommendation": "该申请金额在预算范围内，申请人在过去3个月有良好记录...",
  "summary": "建议通过，本次差旅申请合规",
  "riskWarnings": ["预算使用率已达 85%"],
  "anomalies": [],
  "supplementaryInfo": ["同类申请平均审批时间 2.3 小时"],
  "approvalComment": "同意该差旅申请，预算充足，行程合理。",
  "suggestedFormUpdates": {}
}
```

## 4. 自然语言表单解析模块

### 4.1 解析流程

```mermaid
flowchart TD
    A[用户输入自然语言] --> B{LLM 可用?}
    B -->|是| C[调用 LLM parseFormCommand]
    B -->|否| D[启发式正则解析]
    C -->|成功| E[使用 LLM 结果]
    C -->|失败| D
    D --> E
    E --> F[合并默认值]
    F --> G[识别缺失必填字段]
    G --> H{置信度足够?}
    H -->|高| I[自动填充表单]
    H -->|低| J[提示用户补充缺失字段]
    I --> K[用户确认/修改]
    J --> K
    K --> L[发起审批流程]
```

### 4.2 启发式解析策略

| 字段类型 | 解析方法 |
|------|------|
| number | 正则匹配数字 `-?\d+(\.\d+)?`，排除日期中的数字 |
| 金额字段 | 关键词匹配（金额/预算/费用/报销）+ 货币符号（¥/$）+ 单位（元/块） |
| 日期字段 | ISO 日期 `YYYY-MM-DD`、中文日期 `YYYY年M月D日`、DateTime `YYYY-MM-DD HH:mm:ss` |
| 天数/时长 | 中文数字（一/二/.../十）+ "天"、日期区间差值 |
| select | 选项 label/value 关键词匹配 |
| 字符串 | 字段别名（label/key）后紧跟的值 |

## 5. 安全模块

### 5.1 JWT 认证流程

```mermaid
sequenceDiagram
    actor U as 用户
    participant AC as AuthController
    participant AS as AuthService
    participant JS as JwtService
    participant DB as 数据库

    U->>AC: POST /api/auth/login { username, password }
    AC->>AS: login(username, password)
    AS->>DB: 查询 sys_user
    AS->>AS: BCrypt 密码校验
    AS->>AS: 检查账号锁定状态
    AS->>DB: 记录登录日志 (sys_login_log)

    alt 2FA 未启用
        AS->>JS: generateAccessToken(userId, username, roles)
        JS-->>AS: JWT Access Token (120min)
        AS-->>AC: { accessToken, profile }
        AC-->>U: 登录成功
    else 2FA 已启用
        AS->>JS: generateTwoFactorChallengeToken(userId, username)
        JS-->>AS: JWT Challenge Token (5min)
        AS-->>AC: { challengeToken, requiresTwoFactor: true }
        AC-->>U: 需要二次验证

        U->>AC: POST /api/auth/login/2fa { challengeToken, code }
        AC->>AS: verifyTwoFactor(challengeToken, code)
        AS->>AS: TOTP 验证 (HmacSHA1)
        AS->>JS: generateAccessToken(userId, username, roles)
        JS-->>AS: JWT Access Token
        AS-->>AC: { accessToken, profile }
        AC-->>U: 登录成功
    end
```

### 5.2 请求认证过滤器

```
HTTP Request
    ↓
JwtAuthenticationFilter.doFilterInternal()
    ↓
提取 Authorization: Bearer <token>
    ↓
JwtService.parseAccessToken(token) → Claims
    ↓
提取 userId, username, roles from Claims
    ↓
创建 AuthUserPrincipal → UsernamePasswordAuthenticationToken
    ↓
存入 SecurityContextHolder
    ↓
SecurityFilterChain 继续 → Controller
```

## 6. 系统初始化引导模块

```mermaid
flowchart TD
    A[系统启动] --> B{数据库有用户?}
    B -->|无| C[引导模式激活]
    B -->|有| D[正常模式]
    C --> E[前端显示 /bootstrap 页面]
    E --> F[用户创建管理员账号]
    F --> G[POST /api/auth/bootstrap]
    G --> H[创建 SYS_ADMIN 角色]
    H --> I[创建 SYS_ADMIN 用户]
    I --> J[创建默认部门]
    J --> K[引导完成, 可正常登录]
    D --> L[正常登录流程]
```

## 7. 设计模式总结

| 设计模式 | 应用位置 | 说明 |
|------|------|------|
| 策略模式 | `LlmClient` 接口 + `OpenAiLlmClient`/`MockLlmClient` | LLM 提供商可切换 |
| 模板方法 | `WorkflowService` 中统一的审批操作流程 | claim→complete→log |
| 监听器模式 | `CountersignTaskListener` / `SingleApprovalTaskListener` | Flowable TaskListener 回调 |
| 仓储模式 | Spring Data JPA `Repository` 接口 | 数据访问抽象 |
| 过滤器链 | Spring Security Filter Chain + `JwtAuthenticationFilter` | 请求认证 |
| DTO 模式 | Controller 中定义的 `StartProcessRequest`/`TaskInfo` 等静态内部类 | 数据传输 |
| 工厂模式 | `FormCatalogBootstrapService` / `WorkflowCatalogBootstrapService` | 系统初始化 |
