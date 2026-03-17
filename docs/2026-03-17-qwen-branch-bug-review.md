# Qwen3.5 分支 Bug 审查

日期：2026-03-17
分支：`qwen3.5-35b-vibe`
审查方式：静态代码审查 + `./mvnw -q test`

## 结论

当前分支存在 3 个明确问题，其中 2 个会导致审批流程运行结果错误或回退失败，建议优先处理。

## 问题 1：单人审批结束后，业务单状态不会进入“已通过/已拒绝”

严重级别：高

### 位置

- [WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L342)
- [CountersignTaskListener.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/listener/CountersignTaskListener.java#L17)
- [approval-single.bpmn20.xml](/home/cao/workspace/graduation_project/approval-system/src/main/resources/processes/approval-single.bpmn20.xml#L11)

### 分析

`approvalSingle` 复用了 `countersignTaskListener`，但这个监听器的结果计算依赖多实例变量 `nrOfInstances`。

单人审批流程不是多实例流程，[approval-single.bpmn20.xml](/home/cao/workspace/graduation_project/approval-system/src/main/resources/processes/approval-single.bpmn20.xml#L11) 中只有普通 `userTask`，因此 `nrOfInstances` 不存在。监听器在这种情况下会把它当成 `0` 处理，[CountersignTaskListener.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/listener/CountersignTaskListener.java#L29) 到 [CountersignTaskListener.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/listener/CountersignTaskListener.java#L62) 的逻辑会让 `countersignResult` 在“同意”场景下仍停留在 `PENDING`。

流程网关本身是按 `approvalResult` 结束的，所以流程实例会结束；但业务单状态刷新时，[WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L349) 到 [WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L375) 又只看 `countersignResult`。结果是流程结束后，`biz_request.status` 会被写回“审批中”而不是“已通过/已拒绝”。

### 影响

- 单人审批完成后，业务状态与实际流程状态不一致。
- 列表查询、统计、后续业务联动都会出现误判。

## 问题 2：回退到会签/上一步在非会签流程里会跳到不存在的节点

严重级别：高

### 位置

- [WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L225)
- [WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L253)
- [approval-single.bpmn20.xml](/home/cao/workspace/graduation_project/approval-system/src/main/resources/processes/approval-single.bpmn20.xml#L11)
- [approval-orsign.bpmn20.xml](/home/cao/workspace/graduation_project/approval-system/src/main/resources/processes/approval-orsign.bpmn20.xml#L11)
- [approval-sequential.bpmn20.xml](/home/cao/workspace/graduation_project/approval-system/src/main/resources/processes/approval-sequential.bpmn20.xml#L11)

### 分析

[WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L234) 到 [WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L237) 把“回退到会签”固定写死为 `countersignTask`。  
[WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L258) 到 [WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java#L263) 在找不到上一个用户任务时，也回落到 `countersignTask`。

但当前分支并不只有这个节点名：

- 单人审批节点是 `singleApprovalTask`
- 或签节点是 `orSignTask`
- 顺序审批节点是 `sequentialTask`

因此在这些流程里调用 `/tasks/{taskId}/return` 或部分场景下调用 `/tasks/{taskId}/return/previous`，Flowable 会尝试跳转到不存在的活动节点，回退直接失败。

### 影响

- 非会签流程无法复用通用回退接口。
- 接口行为和前端按钮文案不一致，容易在运行时暴露 500 错误。

## 问题 3：单人审批已加入后端流程定义，但 UI 和 OpenAPI 仍未暴露该能力

严重级别：中

### 位置

- [approval-single.bpmn20.xml](/home/cao/workspace/graduation_project/approval-system/src/main/resources/processes/approval-single.bpmn20.xml#L7)
- [index.html](/home/cao/workspace/graduation_project/approval-system/src/main/resources/static/index.html#L52)
- [openapi.yaml](/home/cao/workspace/graduation_project/approval-system/docs/openapi.yaml#L987)

### 分析

后端已经新增了 `approvalSingle` 流程定义，但前端流程类型下拉框只提供“并行会签 / 或签 / 顺序审批”，没有“单人审批”入口。OpenAPI 中 `processKey` 的说明也仍然只列出 `approvalWorkflow/approvalCountersign/approvalOrSign/approvalSequential`，没有 `approvalSingle`。

这会导致新能力虽然已部署，但默认界面无法选择，接口文档也不会告诉调用方它需要使用哪个 `processKey`，更不会提示单人审批依赖 `variables.approverId`。

### 影响

- 单人审批功能对现有前端和按文档接入的调用方实际上不可发现。
- 容易被误判为“流程已实现但接口不可用”。

## 验证记录

- 执行了 `./mvnw -q test`，结果通过。
- 当前测试只覆盖 Spring 上下文启动，未覆盖上述流程场景，因此这些问题不会在现有测试中暴露。

## 新增测试用例

已新增以下 JUnit 5 回归测试，用于直接覆盖本次审查发现的问题：

测试环境补充：
- 新增了 H2 测试依赖，见 [pom.xml](/home/cao/workspace/graduation_project/approval-system/pom.xml)
- 新增了测试配置文件 [application-test.yml](/home/cao/workspace/graduation_project/approval-system/src/test/resources/application-test.yml)
- Spring Boot 测试类已切换到 `test` profile，以避免依赖本地 MariaDB

### 1. 单人审批状态回归测试

文件：
- [WorkflowBugRegressionTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/WorkflowBugRegressionTests.java)

用例：
- `singleApprovalCompletion_shouldMarkRequestApproved`

覆盖目标：
- 启动 `approvalSingle`
- 传入 `variables.approverId`
- 完成审批任务
- 断言 `biz_request.status == 3`

该用例用于拦截“流程结束了，但业务单仍停留在审批中”的问题。

### 2. 非会签流程回退回归测试

文件：
- [WorkflowBugRegressionTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/WorkflowBugRegressionTests.java)

用例：
- `returnToCountersign_shouldWorkForSingleApprovalProcess`

覆盖目标：
- 启动 `approvalSingle`
- 获取当前任务
- 调用 `workflowService.returnToCountersign(...)`
- 断言整个调用不抛异常

该用例用于拦截“回退接口把目标节点写死成 `countersignTask`，导致单人审批跳转到不存在节点”的问题。

### 3. 单人审批契约暴露测试

文件：
- [WorkflowContractRegressionTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/WorkflowContractRegressionTests.java)

用例：
- `singleApprovalShouldBeExposedInUiAndApiContract`

覆盖目标：
- 断言首页 `index.html` 包含 `approvalSingle`
- 断言 `docs/openapi.yaml` 包含 `approvalSingle`
- 断言 `docs/openapi.yaml` 说明了 `approverId`

该用例用于拦截“后端已支持单人审批，但前端入口和接口文档没有同步”的问题。

## 测试执行结果

执行命令：
- `./mvnw -q -Dtest=WorkflowBugRegressionTests,WorkflowContractRegressionTests,ApprovalSystemApplicationTests test`

执行结果：
- `ApprovalSystemApplicationTests.contextLoads` 通过
- `WorkflowBugRegressionTests.singleApprovalCompletion_shouldMarkRequestApproved` 失败，实际状态为 `2`，期望为 `3`
- `WorkflowBugRegressionTests.returnToCountersign_shouldWorkForSingleApprovalProcess` 失败，抛出 `FlowableException: Cannot find activity 'countersignTask' in process definition with id 'approvalSingle'`
- `WorkflowContractRegressionTests.singleApprovalShouldBeExposedInUiAndApiContract` 失败，首页未包含 `approvalSingle`

这说明新增测试已经能够稳定复现本次审查中的 3 个问题，而不是停留在静态分析层面。
