# 流程管理详细设计（初版）

> 2026-04-07 更新说明：本文为高级流程管理层的详细设计文档。当前产品落地不建议把这些能力直接暴露给普通用户；用户侧入口应以内置流程模板和业务化表单为主，详见 `docs/2026-04-07-product-scope-and-built-in-workflow-plan.md`。

## 1. 文档目的

本文档在《流程管理需求分析（初版）》《流程管理概要设计（初版）》和《流程管理数据库表设计与接口设计（初版）》基础上，进一步给出流程管理模块的详细设计初稿，明确实体对象、DTO 结构、服务分层、关键方法、时序流程、校验规则、异常处理与落地策略，作为后续开发实现的直接依据。

本文档重点回答以下问题：

- 后端新增哪些实体、仓储、服务与控制器
- 各层对象如何组织与交互
- 版本发布、停用、启用、发起流程的详细处理流程是什么
- 节点配置、表单绑定与实例追溯如何具体落库
- 异常与校验如何统一处理

## 2. 设计前提

### 2.1 继承现有项目约束

- 继续使用 Spring Boot + JPA + Flowable
- 继续保留现有 `WorkflowController` 与 `WorkflowService` 的运行时职责
- 继续使用现有动态表单模型：`form_definition / form_version / form_instance`
- 继续使用现有业务台账：`biz_request / biz_request_task / biz_request_log`

### 2.2 本轮落地策略

- 流程管理接口与运行期接口分离
- 节点配置本轮先以管理态元数据为主
- 发起流程逻辑最小侵入改造
- 版本生命周期由数据库状态驱动
- 发布时通过专门服务封装 Flowable 部署逻辑
- 用户侧发起入口由“申请类型/内置模板”驱动，而不是直接暴露流程定义与 BPMN 技术参数

## 3. 包结构建议

建议在现有项目结构下新增以下包：

```text
src/main/java/com/flowablecollab/approval_system/
  controller/admin/workflow/
  service/workflow/manage/
  repository/workflow/
  entity/workflow/
  dto/workflow/admin/
  dto/workflow/internal/
  exception/
```

建议职责如下：

- `entity/workflow/`
  - 流程定义、版本、节点配置、发布日志实体

- `repository/workflow/`
  - 对应 JPA Repository

- `service/workflow/manage/`
  - 管理态服务实现

- `dto/workflow/admin/`
  - 管理端请求与响应对象

- `dto/workflow/internal/`
  - 内部服务之间传递的解析结果对象

- `controller/admin/workflow/`
  - 管理端控制器

## 4. 实体设计

### 4.1 WorkflowDefinition

建议类名：`WorkflowDefinition`

建议字段：

- `Long id`
- `String processKey`
- `String processName`
- `String category`
- `String description`
- `String status`
- `Long currentVersionId`
- `Integer latestVersionNo`
- `Long createdBy`
- `Long updatedBy`
- `LocalDateTime createdAt`
- `LocalDateTime updatedAt`
- `Integer isDeleted`

建议行为：

- `prePersist` 自动填充创建时间与默认删除标记
- `preUpdate` 自动更新时间

### 4.2 WorkflowDefinitionVersion

建议类名：`WorkflowDefinitionVersion`

建议字段：

- `Long id`
- `Long definitionId`
- `Integer versionNo`
- `String versionLabel`
- `String status`
- `String bpmnXml`
- `String bpmnChecksum`
- `String flowableDeploymentId`
- `String flowableProcessDefinitionId`
- `String formKey`
- `Long formVersionId`
- `String changeSummary`
- `Long publishedBy`
- `LocalDateTime publishedAt`
- `Long createdBy`
- `Long updatedBy`
- `LocalDateTime createdAt`
- `LocalDateTime updatedAt`
- `Integer isDeleted`

建议说明：

- `bpmnXml` 使用 `@Lob`
- `changeSummary` 建议保留较大长度

### 4.3 WorkflowNodeConfig

建议类名：`WorkflowNodeConfig`

建议字段：

- `Long id`
- `Long definitionVersionId`
- `String nodeId`
- `String nodeName`
- `String nodeType`
- `String approvalType`
- `String assigneeStrategy`
- `String assigneeConfigJson`
- `Integer commentRequired`
- `Integer allowDelegate`
- `Integer allowReassign`
- `Integer allowReturnPrevious`
- `Integer allowReturnApplicant`
- `Integer aiEnabled`
- `String timeoutRuleJson`
- `String extraConfigJson`
- `Integer sortOrder`
- `LocalDateTime createdAt`
- `LocalDateTime updatedAt`

建议说明：

- JSON 字段本轮使用 `String` 存储，交由应用层做 JSON 序列化反序列化，减少 JPA 方言差异风险

### 4.4 WorkflowPublishLog

建议类名：`WorkflowPublishLog`

建议字段：

- `Long id`
- `Long definitionId`
- `Long definitionVersionId`
- `String action`
- `String result`
- `String message`
- `String flowableDeploymentId`
- `String flowableProcessDefinitionId`
- `Long operatorId`
- `LocalDateTime operatedAt`

### 4.5 BizRequest 扩展

建议在现有 `BizRequest` 实体新增：

- `Long workflowDefinitionId`
- `Long workflowDefinitionVersionId`
- `Long formVersionId`

## 5. Repository 设计

### 5.1 WorkflowDefinitionRepository

建议方法：

- `Optional<WorkflowDefinition> findByProcessKeyAndIsDeleted(String processKey, Integer isDeleted)`
- `boolean existsByProcessKeyAndIsDeleted(String processKey, Integer isDeleted)`
- `Page<WorkflowDefinition> findAll(Specification<WorkflowDefinition> spec, Pageable pageable)`

### 5.2 WorkflowDefinitionVersionRepository

建议方法：

- `List<WorkflowDefinitionVersion> findByDefinitionIdAndIsDeletedOrderByVersionNoDesc(Long definitionId, Integer isDeleted)`
- `Optional<WorkflowDefinitionVersion> findByIdAndIsDeleted(Long id, Integer isDeleted)`
- `Optional<WorkflowDefinitionVersion> findByDefinitionIdAndStatusAndIsDeleted(Long definitionId, String status, Integer isDeleted)`
- `boolean existsByDefinitionIdAndVersionNoAndIsDeleted(Long definitionId, Integer versionNo, Integer isDeleted)`
- `long countByDefinitionIdAndIsDeleted(Long definitionId, Integer isDeleted)`

### 5.3 WorkflowNodeConfigRepository

建议方法：

- `List<WorkflowNodeConfig> findByDefinitionVersionIdOrderBySortOrderAscIdAsc(Long definitionVersionId)`
- `Optional<WorkflowNodeConfig> findByDefinitionVersionIdAndNodeId(Long definitionVersionId, String nodeId)`
- `void deleteByDefinitionVersionId(Long definitionVersionId)`

### 5.4 WorkflowPublishLogRepository

建议方法：

- `Page<WorkflowPublishLog> findAll(Specification<WorkflowPublishLog> spec, Pageable pageable)`
- `List<WorkflowPublishLog> findByDefinitionVersionIdOrderByOperatedAtDesc(Long definitionVersionId)`

## 6. DTO 设计

### 6.1 流程定义请求 DTO

#### CreateWorkflowDefinitionRequest

字段：

- `String processKey`
- `String processName`
- `String category`
- `String description`

校验：

- `processKey`：必填、长度 1-64、建议正则 `[A-Za-z][A-Za-z0-9_]*`
- `processName`：必填、长度 1-128

#### UpdateWorkflowDefinitionRequest

字段：

- `String processName`
- `String category`
- `String description`

### 6.2 流程版本请求 DTO

#### CreateWorkflowVersionRequest

字段：

- `Long copyFromVersionId`
- `String versionLabel`
- `String changeSummary`

#### UpdateWorkflowVersionRequest

字段：

- `String versionLabel`
- `String bpmnXml`
- `String formKey`
- `Long formVersionId`
- `String changeSummary`

规则：

- 仅草稿版可修改
- `bpmnXml` 本轮建议必填
- `formVersionId` 本轮建议必填

### 6.3 节点配置 DTO

#### WorkflowNodeConfigItemRequest

字段：

- `String nodeId`
- `String nodeName`
- `String nodeType`
- `String approvalType`
- `String assigneeStrategy`
- `Map<String, Object> assigneeConfig`
- `Boolean commentRequired`
- `Boolean allowDelegate`
- `Boolean allowReassign`
- `Boolean allowReturnPrevious`
- `Boolean allowReturnApplicant`
- `Boolean aiEnabled`
- `Map<String, Object> timeoutRule`
- `Map<String, Object> extraConfig`
- `Integer sortOrder`

#### BatchSaveWorkflowNodeConfigRequest

字段：

- `List<WorkflowNodeConfigItemRequest> nodes`

### 6.4 发布动作 DTO

#### PublishWorkflowVersionRequest

字段：

- `String comment`

#### ChangeVersionStatusRequest

字段：

- `String comment`

用于：

- 停用
- 启用
- 退休

### 6.5 响应 DTO

建议统一提供以下视图对象：

- `WorkflowDefinitionView`
- `WorkflowDefinitionVersionView`
- `WorkflowNodeConfigView`
- `WorkflowPublishLogView`
- `WorkflowVersionUsageView`

## 7. 服务设计

### 7.1 WorkflowDefinitionService

职责：

- 创建流程定义
- 查询定义列表和详情
- 更新定义基础信息
- 停用/归档定义

建议方法：

- `WorkflowDefinitionView createDefinition(CreateWorkflowDefinitionRequest request, Long operatorId)`
- `PageResult<WorkflowDefinitionView> listDefinitions(QueryWorkflowDefinitionRequest request)`
- `WorkflowDefinitionView getDefinition(Long definitionId)`
- `WorkflowDefinitionView updateDefinition(Long definitionId, UpdateWorkflowDefinitionRequest request, Long operatorId)`
- `void inactivateDefinition(Long definitionId, Long operatorId, String comment)`
- `void archiveDefinition(Long definitionId, Long operatorId, String comment)`

关键规则：

- `processKey` 唯一
- 已归档定义不允许创建新版本
- 归档前应无当前发布版本

### 7.2 WorkflowDefinitionVersionService

职责：

- 创建版本草稿
- 更新草稿
- 查询版本列表和详情
- 删除草稿

建议方法：

- `WorkflowDefinitionVersionView createDraft(Long definitionId, CreateWorkflowVersionRequest request, Long operatorId)`
- `List<WorkflowDefinitionVersionView> listVersions(Long definitionId)`
- `WorkflowDefinitionVersionView getVersion(Long versionId)`
- `WorkflowDefinitionVersionView updateDraft(Long versionId, UpdateWorkflowVersionRequest request, Long operatorId)`
- `void deleteDraft(Long versionId, Long operatorId)`

关键规则：

- 新版本号 = `definition.latestVersionNo + 1`
- 支持空白创建和复制创建
- 仅 `DRAFT` 可更新或删除

### 7.3 WorkflowNodeConfigService

职责：

- 解析版本中的 BPMN 节点
- 查询节点配置
- 保存节点配置
- 校验节点配置与 BPMN 一致性

建议方法：

- `List<WorkflowNodeConfigView> listNodeConfigs(Long versionId)`
- `List<WorkflowNodeConfigView> saveNodeConfigs(Long versionId, BatchSaveWorkflowNodeConfigRequest request, Long operatorId)`
- `List<BpmnNodeSnapshot> parseBpmnNodes(String bpmnXml)`
- `void validateNodeConfigs(Long versionId)`

关键规则：

- 仅草稿版本允许保存节点配置
- `nodeId` 必须存在于 BPMN 中

### 7.4 FlowableDeploymentService

职责：

- 封装 Flowable 部署操作
- 返回部署结果

建议内部对象：

#### FlowableDeploymentResult

字段：

- `String deploymentId`
- `String processDefinitionId`
- `String processDefinitionKey`
- `Integer version`

建议方法：

- `FlowableDeploymentResult deploy(String processKey, String bpmnXml)`

关键规则：

- 部署失败抛出业务异常
- 仅返回执行结果，不直接改业务表

### 7.5 WorkflowPublishService

职责：

- 发布草稿版本
- 停用版本
- 启用已停用版本
- 退休版本
- 写入发布日志

建议方法：

- `WorkflowDefinitionVersionView publish(Long versionId, Long operatorId, String comment)`
- `void inactivateVersion(Long versionId, Long operatorId, String comment)`
- `WorkflowDefinitionVersionView activateVersion(Long versionId, Long operatorId, String comment)`
- `void retireVersion(Long versionId, Long operatorId, String comment)`

关键职责拆分：

1. 发布前校验
2. Flowable 部署
3. 数据事务切换
4. 发布日志记录

### 7.6 WorkflowLaunchResolverService

职责：

- 发起流程前按 `processKey` 解析当前版本
- 返回版本绑定信息

建议内部对象：

#### WorkflowLaunchDefinition

字段：

- `Long definitionId`
- `Long versionId`
- `Integer versionNo`
- `String processKey`
- `String flowableProcessDefinitionId`
- `String formKey`
- `Long formVersionId`

建议方法：

- `WorkflowLaunchDefinition resolveCurrentLaunchDefinition(String processKey)`

关键规则：

- 定义必须存在且非归档
- 当前版本必须存在且状态为 `PUBLISHED`
- 版本必须具备表单绑定和部署信息

### 7.7 WorkflowInstanceBindingService

职责：

- 在业务实例创建时补齐定义、版本、表单版本信息
- 查询实例时补充版本展示信息

建议方法：

- `void bindVersionInfo(BizRequest request, WorkflowLaunchDefinition launchDefinition)`
- `WorkflowInstanceVersionView buildInstanceVersionView(BizRequest request)`

## 8. 控制器设计

### 8.1 WorkflowDefinitionAdminController

建议接口：

- `POST /api/admin/workflow-definitions`
- `GET /api/admin/workflow-definitions`
- `GET /api/admin/workflow-definitions/{definitionId}`
- `PUT /api/admin/workflow-definitions/{definitionId}`
- `POST /api/admin/workflow-definitions/{definitionId}/inactivate`
- `POST /api/admin/workflow-definitions/{definitionId}/archive`

### 8.2 WorkflowDefinitionVersionAdminController

建议接口：

- `POST /api/admin/workflow-definitions/{definitionId}/versions`
- `GET /api/admin/workflow-definitions/{definitionId}/versions`
- `GET /api/admin/workflow-definition-versions/{versionId}`
- `PUT /api/admin/workflow-definition-versions/{versionId}`
- `DELETE /api/admin/workflow-definition-versions/{versionId}`

### 8.3 WorkflowNodeConfigAdminController

建议接口：

- `GET /api/admin/workflow-definition-versions/{versionId}/nodes`
- `PUT /api/admin/workflow-definition-versions/{versionId}/nodes`

### 8.4 WorkflowPublishAdminController

建议接口：

- `POST /api/admin/workflow-definition-versions/{versionId}/publish`
- `POST /api/admin/workflow-definition-versions/{versionId}/inactivate`
- `POST /api/admin/workflow-definition-versions/{versionId}/activate`
- `POST /api/admin/workflow-definition-versions/{versionId}/retire`
- `GET /api/admin/workflow-definition-versions/{versionId}/publish-logs`
- `GET /api/admin/workflow-definition-versions/{versionId}/usage`

## 9. BPMN 节点解析设计

### 9.1 目标

从版本中的 `bpmnXml` 解析出节点列表，作为节点配置的基础数据来源。

### 9.2 本轮解析范围

建议至少识别：

- `startEvent`
- `userTask`
- `serviceTask`
- `exclusiveGateway`
- `parallelGateway`
- `endEvent`

### 9.3 解析结果对象

#### BpmnNodeSnapshot

字段：

- `String nodeId`
- `String nodeName`
- `String nodeType`
- `Integer sortOrder`

### 9.4 设计决策

- 节点解析仅作为管理用途，不改变 Flowable 执行模型
- 发布前校验使用相同解析器，保证配置节点均来自 BPMN 真正存在的节点

## 10. 关键流程详细设计

### 10.1 创建流程定义

处理流程：

1. Controller 接收请求并校验基础字段
2. Service 校验 `processKey` 唯一性
3. 创建 `WorkflowDefinition`
4. 设置初始状态 `DRAFT`
5. 保存并返回视图对象

失败场景：

- `processKey` 已存在
- 参数格式非法

### 10.2 创建版本草稿

处理流程：

1. 检查定义存在且未归档
2. 读取 `latestVersionNo`
3. 计算新版本号
4. 如果指定 `copyFromVersionId`：
   - 校验来源版本存在
   - 复制 `bpmnXml / formKey / formVersionId / changeSummary`
   - 复制节点配置
5. 如果未指定：
   - 生成空白草稿版本
6. 定义 `latestVersionNo` 更新
7. 返回新草稿版本

设计决策：

- 允许同一流程定义存在多个草稿版本
- 默认推荐从最近版本复制

### 10.3 更新草稿版本

处理流程：

1. 校验版本存在且状态为 `DRAFT`
2. 校验绑定表单版本存在
3. 更新 BPMN、表单绑定、说明
4. 重新计算 `bpmnChecksum`
5. 保存版本

失败场景：

- 非草稿版本修改
- 表单版本不存在

### 10.4 保存节点配置

处理流程：

1. 校验版本状态为 `DRAFT`
2. 解析 BPMN 节点列表
3. 校验传入节点都存在于 BPMN
4. 将请求中的 JSON 结构序列化为字符串
5. 删除该版本旧节点配置
6. 批量保存新节点配置
7. 返回节点配置列表

设计决策：

- 本轮采用“整版覆盖保存”简化逻辑
- 后续可改成按节点增量更新

### 10.5 发布版本

处理流程分为“部署前校验”和“部署后切换”两段。

#### 10.5.1 部署前校验

1. 校验版本存在且为 `DRAFT`
2. 校验所属定义存在且非归档
3. 校验 `bpmnXml` 非空
4. 调用 BPMN 解析器校验模型可解析
5. 校验 `formVersionId` 存在
6. 校验节点配置与 BPMN 一致

#### 10.5.2 部署调用

1. 从版本中读取 `bpmnXml`
2. 调用 `FlowableDeploymentService.deploy`
3. 拿到 `deploymentId / processDefinitionId`

#### 10.5.3 数据切换事务

1. 查询同定义下当前 `PUBLISHED` 版本
2. 若存在，则将其状态改为 `INACTIVE`
3. 目标版本写入部署结果
4. 目标版本状态改为 `PUBLISHED`
5. 写入 `publishedBy / publishedAt`
6. 更新定义 `currentVersionId`
7. 定义状态改为 `ACTIVE`
8. 写入成功发布日志

#### 10.5.4 失败处理

若部署前校验失败：

- 直接返回错误
- 版本保持 `DRAFT`

若 Flowable 部署失败：

- 版本保持 `DRAFT`
- 写入失败发布日志

### 10.6 停用版本

处理流程：

1. 校验版本状态为 `PUBLISHED`
2. 版本改为 `INACTIVE`
3. 若该版本为定义当前版本，则清空定义 `currentVersionId`
4. 将定义状态改为 `INACTIVE`
5. 写入发布日志

设计决策：

- 停用版本不影响运行中的流程实例

### 10.7 启用已停用版本

处理流程：

1. 校验版本状态为 `INACTIVE`
2. 校验该版本具备可用部署信息
3. 查询当前 `PUBLISHED` 版本，若存在则改为 `INACTIVE`
4. 当前目标版本改为 `PUBLISHED`
5. 更新定义 `currentVersionId`
6. 定义状态置为 `ACTIVE`
7. 写入发布日志

### 10.8 退休版本

处理流程：

1. 校验版本状态为 `PUBLISHED` 或 `INACTIVE`
2. 若版本为当前发布版本，则先禁止直接退休，要求先停用或切换当前版本
3. 将目标版本状态改为 `RETIRED`
4. 写入发布日志

设计决策：

- 当前发布版本不允许直接退休，避免定义失去当前版本却未显式停用

### 10.9 发起流程选版

这是与现有 `WorkflowService` 集成的关键。

建议改造点如下：

#### 当前方式

- 直接根据入参 `processKey` 调用 `runtimeService.startProcessInstanceByKey`

#### 改造后方式

1. Controller 接收原有发起请求
2. `WorkflowService` 调用 `WorkflowLaunchResolverService.resolveCurrentLaunchDefinition(processKey)`
3. 取回当前版本信息
4. 使用当前版本的 `formVersionId` 处理表单绑定
5. 使用解析出的 `processKey` 或 `flowableProcessDefinitionId` 调用 Flowable 启动
6. 创建 `BizRequest` 时写入：
   - `workflowDefinitionId`
   - `workflowDefinitionVersionId`
   - `formVersionId`

设计决策：

- 本轮继续保留前端按 `processKey` 发起的习惯
- 不要求前端显式传 `versionId`

## 11. 运行时改造点

### 11.1 WorkflowService 改造建议

建议在现有 `WorkflowService.startApprovalProcessInternal()` 中加入以下能力：

1. 若传入 `processKey`，先走版本解析器
2. 获取当前版本信息
3. 将版本信息写入 `BizRequest`
4. 表单版本优先以当前版本绑定结果为准

### 11.2 兼容策略

对于尚未初始化到定义管理中的历史 `processKey`，建议短期兼容：

- 若无法解析到 `workflow_definition`，则按旧逻辑直接启动
- 但在管理模块正式上线后，应逐步移除该兜底逻辑

设计取舍：

- 如果更强调规范性，可不保留兜底，直接要求所有流程先完成初始化导入
- 本项目建议保留短期兜底，降低迁移风险

## 12. 校验设计

### 12.1 统一校验分层

建议分三层校验：

1. Controller 参数校验
2. Service 业务规则校验
3. 发布前完整性校验

### 12.2 Controller 校验

适合放在 DTO 注解中的校验：

- 非空
- 长度
- 格式
- 枚举值

### 12.3 Service 业务校验

适合放在 Service 的校验：

- 状态是否允许当前操作
- 流程定义或版本是否存在
- 关联表单版本是否存在
- 草稿是否可修改

### 12.4 发布前校验

建议封装到 `WorkflowPublishService` 内部：

- BPMN 可解析
- 节点配置与 BPMN 一致
- 表单版本存在
- 关键字段完整

## 13. 异常设计

### 13.1 异常类型建议

建议复用现有异常风格并补充细分业务异常：

- `ResourceNotFoundException`
- `ResourceConflictException`
- `ForbiddenOperationException`
- `IllegalArgumentException`
- `WorkflowPublishException`

### 13.2 典型异常场景

#### 流程定义相关

- `processKey already exists`
- `workflow definition not found`
- `workflow definition is archived`

#### 流程版本相关

- `workflow version not found`
- `only draft version can be edited`
- `only draft version can be published`
- `published version cannot be deleted`

#### 节点配置相关

- `nodeId does not exist in BPMN`
- `invalid node configuration`

#### 发布相关

- `form version is required before publish`
- `flowable deployment failed`
- `current published version conflict`

#### 发起流程相关

- `workflow definition not found by processKey`
- `no published workflow version available`
- `workflow version deployment info is missing`

### 13.3 错误响应建议

建议继续沿用现有统一异常响应结构，至少包含：

- `error`
- `timestamp`
- `path`

## 14. 权限控制设计

### 14.1 方法级权限建议

建议在 Controller 层使用注解或统一拦截控制：

- 创建定义：`DESIGNER` 或 `ADMIN`
- 编辑草稿：`DESIGNER` 或 `ADMIN`
- 保存节点配置：`DESIGNER` 或 `ADMIN`
- 发布/停用/启用/退休/归档：`ADMIN`

### 14.2 资源级限制

本轮建议先不引入“仅创建人可编辑”的复杂资源级授权。

原因：

- 当前项目已有 RBAC 能力，但未形成资源归属控制模型
- 本轮优先完成基础流程管理能力

## 15. 日志与审计设计

### 15.1 操作日志

所有以下动作都应写 `workflow_publish_log` 或对应管理日志：

- 创建定义
- 创建版本
- 发布版本
- 停用版本
- 启用版本
- 退休版本
- 归档定义

### 15.2 应用日志

建议在 Service 内对关键动作打应用日志：

- 定义创建成功
- 版本复制成功
- 发布开始与完成
- Flowable 部署结果
- 发起流程选版结果

## 16. 迁移与初始化设计

### 16.1 初始化任务

建议实现一个初始化或迁移组件，将现有 BPMN 文件导入定义管理体系。

建议初始化内容：

- 创建默认流程定义
- 创建默认初始版本
- 标记为 `PUBLISHED`
- 回填定义 `currentVersionId`

### 16.2 历史数据补齐

建议通过批处理补齐 `biz_request` 中的：

- `workflowDefinitionId`
- `workflowDefinitionVersionId`
- `formVersionId`

若无法精确推断，可允许为空并在页面提示“历史实例未绑定版本”。

## 17. 单元测试与集成测试建议

### 17.1 建议覆盖的核心用例

- 创建流程定义成功
- 创建重复 `processKey` 失败
- 创建版本草稿成功
- 复制旧版本生成新草稿成功
- 非草稿版本修改失败
- 节点配置中包含 BPMN 不存在节点时失败
- 草稿发布成功
- 发布失败时状态不切换
- 发布新版本后旧版本自动 `INACTIVE`
- 停用当前版本成功
- 启用已停用版本成功
- 退休当前发布版本失败
- 发起流程时成功选中当前版本
- 发起流程时无可用版本失败
- 新实例写入版本追溯字段

### 17.2 测试分层建议

- Repository 基础持久化测试
- Service 业务规则测试
- Controller 集成测试
- Flowable 部署集成测试

## 18. 本轮详细设计结论

本次详细设计初稿明确了流程管理模块的可开发结构，核心包括：

1. 新增四类管理实体：定义、版本、节点配置、发布日志
2. 扩展 `BizRequest` 以承载版本追溯字段
3. 将管理态服务拆分为定义、版本、节点配置、发布、选版解析等职责明确的服务
4. 发布流程采用“校验 -> 部署 -> 切换状态 -> 写日志”的明确时序
5. 发起流程继续兼容 `processKey`，由后端自动选择当前版本
6. 节点配置本轮先以元数据方式落地，不强制一次性替代现有运行逻辑
7. 保留初始化导入和历史数据补齐方案，降低对现有系统的迁移风险

该设计已可以作为下一步建表、编码、测试和接口实现的直接基础。
