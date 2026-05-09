# 用例图与流程图 (PlantUML)

## 1. 系统用例图

```plantuml
@startuml 系统用例图
left to right direction
skinparam packageStyle rectangle

actor "普通员工" as EMP
actor "部门主管" as MGR
actor "流程设计员" as DSG
actor "系统管理员" as ADM

rectangle "智能协同审批系统" {
  
  package "审批流程" {
    usecase "发起申请" as UC01
    usecase "保存草稿" as UC02
    usecase "查看申请进度" as UC03
    usecase "撤销申请" as UC04
    usecase "认领任务" as UC05
    usecase "审批通过/拒绝" as UC06
    usecase "委派任务" as UC07
    usecase "转办任务" as UC08
    usecase "回退审批" as UC09
    usecase "查看审批历史" as UC10
  }
  
  package "AI 智能辅助" {
    usecase "查看 AI 审批建议" as UC11
    usecase "追问 AI 建议" as UC12
    usecase "自然语言填写表单" as UC13
    usecase "AI 聊天助手" as UC14
  }
  
  package "动态表单" {
    usecase "填写动态表单" as UC15
    usecase "上传附件" as UC16
    usecase "管理表单定义" as UC17
    usecase "管理表单版本" as UC18
    usecase "配置表单字段" as UC19
  }
  
  package "工作流管理" {
    usecase "管理流程定义" as UC20
    usecase "编辑 BPMN 流程" as UC21
    usecase "发布流程版本" as UC22
    usecase "配置审批节点" as UC23
    usecase "管理申请模板" as UC24
  }
  
  package "权限管理" {
    usecase "管理用户" as UC25
    usecase "管理角色" as UC26
    usecase "管理部门" as UC27
    usecase "管理岗位" as UC28
    usecase "配置数据权限" as UC29
    usecase "CSV 批量导入用户" as UC30
  }
  
  package "个人中心" {
    usecase "修改密码" as UC31
    usecase "设置双因素认证" as UC32
    usecase "查看登录日志" as UC33
  }
}

EMP --> UC01
EMP --> UC02
EMP --> UC03
EMP --> UC04
EMP --> UC05
EMP --> UC06
EMP --> UC10
EMP --> UC11
EMP --> UC12
EMP --> UC13
EMP --> UC14
EMP --> UC15
EMP --> UC16
EMP --> UC31
EMP --> UC32

MGR --> UC01
MGR --> UC03
MGR --> UC05
MGR --> UC06
MGR --> UC07
MGR --> UC08
MGR --> UC09
MGR --> UC10
MGR --> UC11
MGR --> UC12

DSG --> UC17
DSG --> UC18
DSG --> UC19
DSG --> UC20
DSG --> UC21
DSG --> UC22
DSG --> UC23

ADM --> UC20
ADM --> UC21
ADM --> UC22
ADM --> UC23
ADM --> UC24
ADM --> UC25
ADM --> UC26
ADM --> UC27
ADM --> UC28
ADM --> UC29
ADM --> UC30
ADM --> UC33

@enduml
```

## 2. 审批主流程图

```plantuml
@startuml 审批主流程
skinparam ActivityBackgroundColor #E8F5E9
skinparam ActivityBorderColor #4CAF50

start
:用户选择申请模板;
:填写动态表单;
:提交申请;

if (模板配置了审批规则?) then (是)
  :自动解析审批人;
else (否)
  :使用手动指定审批人;
endif

:创建流程实例;
:写入 biz_request;
:生成审批任务;

:Flowable 引擎分配任务;
:任务进入待办队列;

partition "审批执行" {
  repeat
    :审批人打开待办任务;
    if (查看 AI 建议?) then (是)
      :获取 AI 审批建议;
      :可追问 AI 细节;
    endif
    :审批人做出决策;
    if (决定?) then (通过)
      :提交通过;
      :更新 approveCount;
    else (拒绝)
      :提交拒绝;
      :更新 rejectCount;
    endif
    
    if (完成条件满足?) then (是)
      :确定最终结果;
      #LightGreen:流程进入下一节点
      或结束;
      break
    else (否)
      :继续等待其余
      审批人;
    endif
  repeat while (还有未完成任务?)
}

if (最终结果?) then (APPROVE)
  :申请状态 → 已通过;
  :记录 finishTime;
else (REJECT)
  :申请状态 → 已拒绝;
  :记录 finishTime;
endif

:写入操作日志;
:更新 AI 建议采纳记录;

stop
@enduml
```

## 3. AI 审批建议生成流程图

```plantuml
@startuml AI审批建议
skinparam ActivityBackgroundColor #E3F2FD
skinparam ActivityBorderColor #1565C0

start
:审批人打开任务;
:请求 AI 建议;

partition "数据采集" {
  :从 Flowable 获取任务上下文
  (taskName, variables, title);
  :统计申请人月度数据
  (申请数, 同类数, 总金额);
  :统计相似案例数据
  (通过率, 拒绝率, 平均时间);
  :应用启发式规则
  (异常检测, 风险检查);
}

partition "LLM 调用" {
  :组装 SuggestionRequest;
  :调用 LlmClient.suggestApproval();
  if (LLM 调用成功?) then (是)
    :解析 LLM 返回结果;
  else (否)
    :使用降级策略
    (返回基本规则建议);
  endif
}

partition "结果处理" {
  :规范化决策字段
  (APPROVE/REJECT);
  :格式化推荐理由;
  :提取风险警告列表;
  :提取异常检测结果;
  :生成审批意见模板;
}

:持久化到 ai_suggestion_record;
:返回 SuggestionRecordView;

:前端展示建议卡片
(decision, recommendation,
riskWarnings, anomalies);

if (审批人采纳?) then (是)
  :标记 adopted=true;
  :记录 adoptedAt;
else (否)
  :继续等待最终审批结果;
endif

:审批完成后更新
finalApprovalResult;

stop
@enduml
```

## 4. 自然语言表单解析流程图

```plantuml
@startuml 表单解析
skinparam ActivityBackgroundColor #FFF3E0
skinparam ActivityBorderColor #E65100

start
:用户输入自然语言描述;
:选择目标表单/模板;

:获取表单字段定义列表;

if (LLM 服务可用?) then (是)
  :构造 FieldDefinition 列表;
  :调用 LlmClient.parseFormCommand();
  if (LLM 解析成功?) then (是)
    :使用 LLM 解析结果;
    :设置 model = LLM模型名;
  else (否)
    :降级到启发式解析;
    :设置 model = heuristic;
  endif
else (否)
  :直接使用启发式解析;
  :设置 model = heuristic;
endif

partition "启发式解析 (备选)" {
  :遍历表单字段;
  repeat
    if (字段类型?) then (number)
      :正则匹配数值
      排除日期干扰;
    else (date/datetime)
      :匹配 ISO/中文日期;
    else (select)
      :关键词匹配选项;
    else (string)
      :字段别名匹配提取;
    endif
    if (是金额字段?) then (是)
      :货币符号+关键词匹配;
    endif
    if (是天数字段?) then (是)
      :中文数字+日期区间算天数;
    endif
  repeat while (还有字段?) is (是)
}

:合并默认值;
:识别缺失必填字段;

if (置信度 >= 阈值?) then (高)
  :自动填充表单;
else (低)
  :提示用户补充缺失字段;
endif

:用户确认/修改;
:发起审批流程;

stop
@enduml
```

## 5. 用户登录认证流程图

```plantuml
@startuml 登录认证
skinparam ActivityBackgroundColor #FCE4EC
skinparam ActivityBorderColor #C62828

start
:用户访问系统;

if (系统处于引导模式?) then (是)
  :跳转 Bootstrap 页面;
  :创建管理员账号;
  :初始化默认角色/部门;
  :引导完成;
endif

:进入登录页面;
:输入用户名和密码;
:提交登录请求;

:AuthService 验证密码;
if (密码正确?) then (是)
  :更新最后登录时间;
  :重置登录失败次数;
else (否)
  :递增登录失败次数;
  :记录失败日志;
  if (超过最大尝试次数?) then (是)
    :锁定账号 30 分钟;
    :返回账号已锁定;
    stop
  else (否)
    :返回密码错误;
    stop
  endif
endif

:记录登录成功日志;
:写入 sys_login_log;

if (用户启用 2FA?) then (是)
  :生成 Challenge Token (5min);
  :返回 requiresTwoFactor=true;
  :用户输入 6 位 TOTP 验证码;
  :验证 TOTP (HMAC-SHA1);
  if (TOTP 验证通过?) then (是)
    :生成 Access Token (120min);
  else (否)
    :返回验证码错误;
    stop
  endif
else (否)
  :生成 Access Token (120min);
endif

:返回 { accessToken, profile };
:前端存储 Token;
:跳转到用户首页;

stop
@enduml
```

## 6. 会签审批时序图

```plantuml
@startuml 会签审批时序
skinparam ParticipantBackgroundColor #E8F5E9
skinparam ParticipantBorderColor #4CAF50

actor "审批人A" as A
actor "审批人B" as B
participant "WorkflowController" as WC
participant "WorkflowService" as WS
participant "TaskService\n(Flowable)" as TS
participant "CountersignTask\nListener" as CTL
database "MariaDB" as DB

== 会签任务已并行分配给 A 和 B ==

A -> WC: POST /tasks/{id}/complete\n{ APPROVE, "同意该申请" }
WC -> WS: completeTask(taskId, userId, "APPROVE", comment)
WS -> WS: 校验委派状态
WS -> TS: taskService.complete(taskId, variables)
TS -> CTL: 触发 TaskListener (complete 事件)
CTL -> CTL: approveCount += 1
CTL -> CTL: 判断完成条件
note right of CTL: approveCount=1 < requiredApprove=2\n继续等待
WS -> DB: UPDATE biz_request_task\n(status=Completed, action=APPROVE)
WS -> DB: INSERT biz_request_log (APPROVE)
WS -> DB: UPDATE biz_request (currentTask)
WS --> WC: 完成成功
WC --> A: { success: true }

Note over A,B: B 尚未审批，流程继续等待

B -> WC: POST /tasks/{id}/complete\n{ APPROVE, "一致同意" }
WC -> WS: completeTask(...)
WS -> TS: taskService.complete(taskId, variables)
TS -> CTL: 触发 TaskListener
CTL -> CTL: approveCount = 2 >= requiredApprove = 2
CTL -> CTL: countersignResult = "APPROVE"
note right of CTL: completionCondition 满足\n多实例结束
TS -> TS: 取消其余未完成任务
WS -> DB: UPDATE biz_request_task (AUTO_COMPLETE)
WS -> DB: UPDATE biz_request\n(status=Approved, finishTime=now)
WS -> DB: 标记 AI 建议 finalResult
WS --> WC: 流程结束
WC --> B: { success: true }

@enduml
```

## 7. 任务委派与完成时序图

```plantuml
@startuml 任务委派
skinparam ParticipantBackgroundColor #FFF3E0
skinparam ParticipantBorderColor #E65100

actor "原负责人" as O
actor "被委派人" as D
participant "WorkflowController" as WC
participant "WorkflowService" as WS
participant "TaskService\n(Flowable)" as TS
database "MariaDB" as DB

== 阶段1: 委派 ==

O -> WC: POST /tasks/{id}/delegate\n{ delegateUserId, comment }
WC -> WS: delegateTask(taskId, userId, delegateUserId, comment)
WS -> TS: taskService.delegateTask(taskId, delegateUserId)
note right of TS: owner = 原负责人\nassignee = 被委派人\ndelegationState = PENDING
WS -> DB: UPDATE biz_request_task\n(status=Delegated, action=DELEGATE,\nownerId=原负责人, assigneeId=被委派人)
WS -> DB: INSERT biz_request_log (DELEGATE)
WS --> WC: 委派成功
WC --> O: { success: true }

== 阶段2: 被委派人处理 ==

D -> WC: POST /tasks/{id}/resolve\n{ approvalResult, comment }
WC -> WS: resolveTask(taskId, userId, "APPROVE", comment)
WS -> WS: 校验 delegationState == PENDING
WS -> WS: 校验 assignee == userId
WS -> TS: taskService.resolveTask(taskId, variables)
note right of TS: assignee = 原负责人\ndelegationState = RESOLVED
WS -> DB: UPDATE biz_request_task\n(status=Claimed, action=RESOLVE,\nassigneeId=原负责人)
WS -> DB: INSERT biz_request_log (RESOLVE)
WS --> WC: 处理完成
WC --> D: { success: true }

== 阶段3: 原负责人确认 ==

O -> WC: POST /tasks/{id}/complete\n{ APPROVE, "最终确认" }
WC -> WS: completeTask(taskId, userId, "APPROVE", comment)
WS -> WS: 校验 delegationState == RESOLVED
WS -> WS: 校验 userId == owner
WS -> TS: taskService.complete(taskId, variables)
WS -> DB: UPDATE biz_request_task\n(status=Completed, action=APPROVE)
WS -> DB: INSERT biz_request_log (APPROVE)
WS --> WC: 任务完成
WC --> O: { success: true }

@enduml
```

## 8. JWT 认证请求过滤时序图

```plantuml
@startuml JWT认证过滤
skinparam ParticipantBackgroundColor #E3F2FD
skinparam ParticipantBorderColor #1565C0

actor "客户端" as C
participant "JwtAuthentication\nFilter" as JF
participant "JwtService" as JS
participant "SecurityContext\nHolder" as SCH
participant "Controller" as CTRL
participant "SecurityUtils" as SU

C -> JF: HTTP Request\nAuthorization: Bearer <token>
JF -> JF: 提取 "Bearer " 后的 token

alt Token 为空
  JF -> C: 继续过滤器链 (未认证)
else Token 存在
  JF -> JS: parseAccessToken(token)
  JS -> JS: 验证签名和有效期
  
  alt Token 无效或过期
    JS --> JF: 抛出 JwtException
    JF -> C: 401 Unauthorized
  else Token 有效
    JS --> JF: Claims { uid, sub, roles, type }
    JF -> JF: 验证 type == "ACCESS"
    JF -> JF: 构造 AuthUserPrincipal
    JF -> JF: 构造 UsernamePasswordAuthenticationToken
    JF -> SCH: 设置认证信息到上下文
  end
end

JF -> CTRL: 过滤器链继续

CTRL -> SU: SecurityUtils.currentUserId()
SU -> SCH: 获取当前认证信息
SCH --> SU: AuthUserPrincipal
SU --> CTRL: userId

CTRL -> SU: SecurityUtils.hasAnyRole("ADMIN")
SU -> SCH: 获取角色列表
SCH --> SU: roles
SU --> CTRL: true/false

CTRL --> C: 业务响应

@enduml
```
