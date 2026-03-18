# 工作流闭环与审计补齐实现说明

日期：2026-03-18  
分支：`qwen3.5-35b-vibe`  
关联提交：`377ea7d`  
主题：流程闭环与审计补齐、Draft/Suspended 状态与接口落地、相关测试补充

## 1. 本轮新增能力

### 1.1 流程闭环与审计补齐
- 增加或签提前结束后的业务留痕补齐：将未完成的 `biz_request_task` 统一补写为 `AUTO_COMPLETE`（服务层 `markAutoCompletedTaskRecords`）。
- 强化委派完成约束：
  - 被委派人仅可 `resolve`，不可直接完成任务；
  - 仅任务 owner 且 `delegationState=RESOLVED` 才能最终 `complete`。
- 强制审批意见必填（控制器参数校验 + 服务层兜底校验）。
- `/api/workflow/tasks` 默认按当前登录用户查询，非管理员禁止代查其他 assignee。

### 1.2 Draft/Suspended 生命周期
- 新增状态：
  - `DRAFT = 0`
  - `SUSPENDED = 7`
- 新增接口：
  - `POST /api/workflow/drafts`
  - `POST /api/workflow/drafts/{businessKey}/submit`
  - `POST /api/workflow/process/{processInstanceId}/suspend`
  - `POST /api/workflow/process/{processInstanceId}/activate`
- 权限规则：
  - 草稿提交、挂起、激活仅申请人本人或管理员可操作。
- 数据模型调整：
  - 草稿阶段允许 `BizRequest.processInstanceId/processDefinitionId` 为空；
  - 草稿日志允许 `BizRequestLog.processInstanceId` 为空。

### 1.3 表单版本锁定与请求状态筛选
- 发起流程支持显式 `formVersionId`，不再只能使用最新版本。
- 草稿保存时支持 `formKey + formVersionId + formData` 快照固化。
- 草稿提交时如未显式传变量，可回放草稿快照数据进入流程变量。
- 请求聚合查询增加可选 `status` 过滤：
  - `/api/requests`
  - `/api/requests/tasks`
  - `/api/requests/logs`
  - `/api/requests/processes`

## 2. 测试补充

本轮新增/增强的关键用例包括：
- `completeTask_requiresComments`
- `delegatedAssignee_cannotCompleteBeforeOwnerResolves`
- `orSignCompletion_marksRemainingTasksAsAutoComplete`
- `saveDraft_andSubmitDraft_startsProcessFromDraft`
- `suspendAndActivate_shouldSwitchRequestStatus`
- `saveDraft_withFormVersionLock_usesSnapshotOnSubmit`
- `startProcess_withExplicitFormVersion_usesSpecifiedVersionInsteadOfLatest`
- `suspendProcess_forbiddenForNonApplicantAndNonAdmin`
- `listRequests_canFilterBySuspendedStatus`

## 3. 验证结果

执行命令：

```bash
./mvnw -q test
```

结果：
- 全量测试通过（`0 failures`, `0 errors`）。

