# 流程管理数据库表设计与接口设计（初版）

## 1. 文档目的

本文档在《流程管理需求分析（初版）》和《流程管理概要设计（初版）》基础上，进一步给出流程管理模块的数据库表设计和接口设计初稿，用于指导后续详细设计、数据库迁移、后端接口开发与前端管理页面对接。

本文档重点覆盖：

- 流程定义与版本管理相关数据表设计
- 实例追溯相关字段扩展设计
- 流程管理后台接口设计
- 运行期发起流程接口的选版改造方案

## 2. 设计范围

### 2.1 包含内容

- `workflow_definition` 表设计
- `workflow_definition_version` 表设计
- `workflow_node_config` 表设计
- `workflow_publish_log` 表设计
- `biz_request` 表扩展设计
- 管理端定义、版本、节点配置、发布接口
- 发起流程选版逻辑涉及的接口调整建议

### 2.2 不包含内容

- 完整 DDL 执行脚本
- Controller / Service / DTO 代码实现
- 前端页面实现细节
- Flowable 部署工具类详细实现
- 审批人解析器详细实现

## 3. 数据库设计原则

### 3.1 业务主档与版本分离

- 流程定义主表仅存流程主档信息。
- 流程版本表存储可编辑和可发布的版本实体。

### 3.2 已发布版本不可覆盖修改

- 已发布、已停用、已退休版本在数据库层面保留原始内容。
- 流程变更通过新版本草稿实现。

### 3.3 实例侧强关联版本

- 每条新流程实例必须落库流程定义 ID、版本 ID 与表单版本 ID。

### 3.4 优先兼容当前项目结构

- 保持与现有 `form_definition / form_version / form_instance` 结构兼容。
- 保持与现有 `biz_request` 流程台账结构兼容。

### 3.5 先满足管理态，再逐步驱动运行态

- 节点配置先满足管理、展示、发布校验和追溯。
- 后续可逐步接管运行期能力。

## 4. 数据表设计

### 4.1 流程定义主表 `workflow_definition`

#### 4.1.1 表用途

用于描述系统中的流程定义主档，例如“差旅申请流程”“报销审批流程”。

#### 4.1.2 建议字段

| 字段名 | 类型 | 非空 | 默认值 | 索引/约束 | 说明 |
| --- | --- | --- | --- | --- | --- |
| id | BIGINT | Y | 自增 | PK | 主键 |
| process_key | VARCHAR(64) | Y | - | UK | 流程唯一标识 |
| process_name | VARCHAR(128) | Y | - |  | 流程名称 |
| category | VARCHAR(64) | N | NULL | IDX | 流程分类 |
| description | VARCHAR(512) | N | NULL |  | 流程描述 |
| status | VARCHAR(32) | Y | `DRAFT` | IDX | 定义状态 |
| current_version_id | BIGINT | N | NULL | IDX | 当前发布版本 ID |
| latest_version_no | INT | Y | `0` |  | 最新版本号 |
| created_by | BIGINT | Y | - | IDX | 创建人 |
| updated_by | BIGINT | N | NULL |  | 更新人 |
| created_at | DATETIME | Y | CURRENT_TIMESTAMP |  | 创建时间 |
| updated_at | DATETIME | Y | CURRENT_TIMESTAMP |  | 更新时间 |
| is_deleted | TINYINT | Y | `0` | IDX | 逻辑删除 |

#### 4.1.3 状态枚举

- `DRAFT`
- `ACTIVE`
- `INACTIVE`
- `ARCHIVED`

#### 4.1.4 约束建议

- `process_key` 全局唯一
- `current_version_id` 指向 `workflow_definition_version.id`
- 已归档流程定义不允许新增新版本

#### 4.1.5 索引建议

- 唯一索引：`uk_workflow_definition_process_key(process_key)`
- 普通索引：`idx_workflow_definition_status(status)`
- 普通索引：`idx_workflow_definition_category(category)`
- 普通索引：`idx_workflow_definition_current_version(current_version_id)`

### 4.2 流程定义版本表 `workflow_definition_version`

#### 4.2.1 表用途

用于描述某流程定义的具体版本，是平台级版本管理的核心表。

#### 4.2.2 建议字段

| 字段名 | 类型 | 非空 | 默认值 | 索引/约束 | 说明 |
| --- | --- | --- | --- | --- | --- |
| id | BIGINT | Y | 自增 | PK | 主键 |
| definition_id | BIGINT | Y | - | IDX | 流程定义 ID |
| version_no | INT | Y | - | UK(definition_id, version_no) | 版本号 |
| version_label | VARCHAR(64) | N | NULL |  | 版本标签 |
| status | VARCHAR(32) | Y | `DRAFT` | IDX | 版本状态 |
| bpmn_xml | LONGTEXT | Y | - |  | BPMN XML 内容 |
| bpmn_checksum | VARCHAR(64) | N | NULL | IDX | BPMN 内容摘要 |
| flowable_deployment_id | VARCHAR(64) | N | NULL | IDX | Flowable 部署 ID |
| flowable_process_definition_id | VARCHAR(128) | N | NULL | IDX | Flowable 流程定义 ID |
| form_key | VARCHAR(64) | N | NULL | IDX | 绑定表单 Key |
| form_version_id | BIGINT | N | NULL | IDX | 绑定表单版本 ID |
| change_summary | VARCHAR(1000) | N | NULL |  | 版本说明 |
| published_by | BIGINT | N | NULL | IDX | 发布人 |
| published_at | DATETIME | N | NULL | IDX | 发布时间 |
| created_by | BIGINT | Y | - | IDX | 创建人 |
| updated_by | BIGINT | N | NULL |  | 更新人 |
| created_at | DATETIME | Y | CURRENT_TIMESTAMP |  | 创建时间 |
| updated_at | DATETIME | Y | CURRENT_TIMESTAMP |  | 更新时间 |
| is_deleted | TINYINT | Y | `0` | IDX | 逻辑删除 |

#### 4.2.3 状态枚举

- `DRAFT`
- `PUBLISHED`
- `INACTIVE`
- `RETIRED`

#### 4.2.4 约束建议

- 同一 `definition_id` 下 `version_no` 唯一
- 同一 `definition_id` 任一时刻只允许一个 `PUBLISHED` 版本
- 已发布版本必须存在 `flowable_process_definition_id` 或部署成功记录

#### 4.2.5 索引建议

- 唯一索引：`uk_wf_definition_version(definition_id, version_no)`
- 普通索引：`idx_wf_version_status(status)`
- 普通索引：`idx_wf_version_definition(definition_id)`
- 普通索引：`idx_wf_version_form_version(form_version_id)`
- 普通索引：`idx_wf_version_flowable_pd(flowable_process_definition_id)`
- 普通索引：`idx_wf_version_published_at(published_at)`

#### 4.2.6 设计说明

- `bpmn_xml` 是平台级版本事实来源，必须保存。
- `flowable_process_definition_id` 是执行侧映射字段，用于实例启动与运行追踪。
- `form_version_id` 直接记录当前版本绑定的表单版本，避免运行期重复推导。

### 4.3 节点配置表 `workflow_node_config`

#### 4.3.1 表用途

用于描述某个流程版本下的节点业务配置。

#### 4.3.2 建议字段

| 字段名 | 类型 | 非空 | 默认值 | 索引/约束 | 说明 |
| --- | --- | --- | --- | --- | --- |
| id | BIGINT | Y | 自增 | PK | 主键 |
| definition_version_id | BIGINT | Y | - | IDX | 流程版本 ID |
| node_id | VARCHAR(64) | Y | - | UK(definition_version_id, node_id) | BPMN 节点 ID |
| node_name | VARCHAR(128) | Y | - |  | 节点名称 |
| node_type | VARCHAR(32) | Y | - | IDX | 节点类型 |
| approval_type | VARCHAR(32) | N | NULL | IDX | 审批类型 |
| assignee_strategy | VARCHAR(32) | N | NULL | IDX | 审批人策略 |
| assignee_config_json | JSON | N | NULL |  | 审批人配置 |
| comment_required | TINYINT | Y | `1` |  | 审批意见是否必填 |
| allow_delegate | TINYINT | Y | `1` |  | 是否允许委派 |
| allow_reassign | TINYINT | Y | `1` |  | 是否允许转办 |
| allow_return_previous | TINYINT | Y | `1` |  | 是否允许退回上一步 |
| allow_return_applicant | TINYINT | Y | `1` |  | 是否允许退回申请人 |
| ai_enabled | TINYINT | Y | `0` |  | 是否启用 AI 建议 |
| timeout_rule_json | JSON | N | NULL |  | 超时规则配置 |
| extra_config_json | JSON | N | NULL |  | 扩展配置 |
| sort_order | INT | Y | `0` |  | 显示顺序 |
| created_at | DATETIME | Y | CURRENT_TIMESTAMP |  | 创建时间 |
| updated_at | DATETIME | Y | CURRENT_TIMESTAMP |  | 更新时间 |

#### 4.3.3 关键枚举建议

`node_type`：

- `START`
- `USER_TASK`
- `SERVICE_TASK`
- `GATEWAY`
- `END`

`approval_type`：

- `SINGLE`
- `COUNTERSIGN`
- `ORSIGN`
- `SEQUENTIAL`

`assignee_strategy`：

- `USER`
- `ROLE`
- `POST`
- `DEPT_MANAGER`
- `INITIATOR_SUPERVISOR`
- `FORM_FIELD`

#### 4.3.4 索引建议

- 唯一索引：`uk_wf_node_config(definition_version_id, node_id)`
- 普通索引：`idx_wf_node_config_version(definition_version_id)`
- 普通索引：`idx_wf_node_config_node_type(node_type)`
- 普通索引：`idx_wf_node_config_approval_type(approval_type)`

#### 4.3.5 JSON 字段说明

`assignee_config_json` 示例：

```json
{"userIds":[1001,1002]}
```

```json
{"roleCodes":["FINANCE_REVIEWER"]}
```

```json
{"fieldKey":"approverId"}
```

`timeout_rule_json` 示例：

```json
{"timeoutHours":24,"action":"REMIND"}
```

### 4.4 发布日志表 `workflow_publish_log`

#### 4.4.1 表用途

用于记录流程管理中的发布、停用、启用、退休等关键生命周期操作。

#### 4.4.2 建议字段

| 字段名 | 类型 | 非空 | 默认值 | 索引/约束 | 说明 |
| --- | --- | --- | --- | --- | --- |
| id | BIGINT | Y | 自增 | PK | 主键 |
| definition_id | BIGINT | Y | - | IDX | 流程定义 ID |
| definition_version_id | BIGINT | Y | - | IDX | 流程版本 ID |
| action | VARCHAR(32) | Y | - | IDX | 动作类型 |
| result | VARCHAR(32) | Y | - | IDX | 执行结果 |
| message | VARCHAR(1000) | N | NULL |  | 结果说明 |
| flowable_deployment_id | VARCHAR(64) | N | NULL | IDX | Flowable 部署 ID |
| flowable_process_definition_id | VARCHAR(128) | N | NULL | IDX | Flowable 流程定义 ID |
| operator_id | BIGINT | Y | - | IDX | 操作人 |
| operated_at | DATETIME | Y | CURRENT_TIMESTAMP | IDX | 操作时间 |

#### 4.4.3 枚举建议

`action`：

- `PUBLISH`
- `INACTIVATE`
- `ACTIVATE`
- `RETIRE`
- `ARCHIVE`

`result`：

- `SUCCESS`
- `FAIL`

### 4.5 业务申请表扩展 `biz_request`

#### 4.5.1 扩展目的

用于建立业务实例与流程版本、表单版本之间的可追溯关系。

#### 4.5.2 建议新增字段

| 字段名 | 类型 | 非空 | 默认值 | 索引/约束 | 说明 |
| --- | --- | --- | --- | --- | --- |
| workflow_definition_id | BIGINT | N | NULL | IDX | 流程定义 ID |
| workflow_definition_version_id | BIGINT | N | NULL | IDX | 流程定义版本 ID |
| form_version_id | BIGINT | N | NULL | IDX | 表单版本 ID |

#### 4.5.3 设计说明

- 新实例创建时，这三个字段必须写入。
- 历史数据允许为空，通过补齐任务逐步迁移。

## 5. 表关系与运行规则

### 5.1 表关系

- `workflow_definition (1) -> (N) workflow_definition_version`
- `workflow_definition_version (1) -> (N) workflow_node_config`
- `workflow_definition_version (1) -> (N) workflow_publish_log`
- `workflow_definition_version (1) -> (N) biz_request`
- `form_version (1) -> (N) workflow_definition_version`

### 5.2 当前版本规则

- 当前版本通过 `workflow_definition.current_version_id` 标识
- 当前版本对应的版本记录状态必须为 `PUBLISHED`
- 发布新版本成功后，原 `PUBLISHED` 版本自动变更为 `INACTIVE`

### 5.3 实例选版规则

- 发起流程时默认按 `processKey` 查找流程定义
- 后端读取 `current_version_id`
- 再读取对应流程版本记录
- 再通过该版本的 `flowable_process_definition_id` 或 `processKey` 启动 Flowable 流程实例
- 启动成功后，将版本信息写入 `biz_request`

## 6. 接口设计原则

### 6.1 管理接口与运行接口分离

- 管理端接口专注流程定义、版本、节点配置和发布操作
- 运行期接口继续保留在现有工作流控制器中

### 6.2 资源路径清晰

建议按资源对象进行分层，例如：

- `/api/admin/workflow-definitions`
- `/api/admin/workflow-definition-versions`
- `/api/admin/workflow-publish-logs`

### 6.3 统一操作语义

- 创建使用 `POST`
- 查询使用 `GET`
- 编辑使用 `PUT`
- 状态流转使用专门动作接口，如 `publish`、`inactivate`

### 6.4 权限建议

- `DESIGNER`：定义创建、草稿维护、节点配置
- `ADMIN`：发布、停用、启用、退休、归档、审计
- `EMPLOYEE`：无管理接口权限

## 7. 管理端接口设计

### 7.1 流程定义管理接口

#### 7.1.1 创建流程定义

`POST /api/admin/workflow-definitions`

请求体示例：

```json
{
  "processKey": "travelRequest",
  "processName": "差旅申请流程",
  "category": "OA",
  "description": "用于员工差旅申请与审批"
}
```

返回示例：

```json
{
  "id": 1001,
  "processKey": "travelRequest",
  "status": "DRAFT",
  "message": "Workflow definition created"
}
```

校验规则：

- `processKey` 必填，长度不超过 64
- `processKey` 必须唯一
- `processName` 必填

#### 7.1.2 查询流程定义列表

`GET /api/admin/workflow-definitions`

查询参数建议：

- `keyword`
- `category`
- `status`
- `page`
- `size`

返回内容建议包括：

- 流程定义基础信息
- 当前版本号
- 当前状态
- 更新时间

#### 7.1.3 查询流程定义详情

`GET /api/admin/workflow-definitions/{definitionId}`

返回内容建议包括：

- 主档信息
- 当前版本信息
- 最新版本号
- 版本统计信息

#### 7.1.4 更新流程定义基础信息

`PUT /api/admin/workflow-definitions/{definitionId}`

说明：

- 仅允许更新名称、分类、描述等基础信息
- 不允许修改 `processKey`

#### 7.1.5 停用流程定义

`POST /api/admin/workflow-definitions/{definitionId}/inactivate`

作用：

- 将定义状态置为 `INACTIVE`
- 阻止新实例发起

#### 7.1.6 归档流程定义

`POST /api/admin/workflow-definitions/{definitionId}/archive`

建议前置规则：

- 当前无 `PUBLISHED` 版本

### 7.2 流程版本管理接口

#### 7.2.1 创建新版本草稿

`POST /api/admin/workflow-definitions/{definitionId}/versions`

请求体示例：

```json
{
  "copyFromVersionId": 2001,
  "versionLabel": "v2",
  "changeSummary": "新增财务复核节点"
}
```

说明：

- `copyFromVersionId` 可选
- 不传时表示空白创建

返回示例：

```json
{
  "id": 2002,
  "definitionId": 1001,
  "versionNo": 2,
  "status": "DRAFT"
}
```

#### 7.2.2 查询版本列表

`GET /api/admin/workflow-definitions/{definitionId}/versions`

返回建议包含：

- 版本号
- 状态
- 版本说明
- 发布时间
- 发布人

#### 7.2.3 查询版本详情

`GET /api/admin/workflow-definition-versions/{versionId}`

返回内容建议包括：

- 版本基础信息
- BPMN XML
- 绑定表单版本
- 节点配置摘要
- Flowable 部署信息

#### 7.2.4 更新草稿版本

`PUT /api/admin/workflow-definition-versions/{versionId}`

请求体示例：

```json
{
  "versionLabel": "v2",
  "bpmnXml": "<?xml version=...>",
  "formKey": "travel-form",
  "formVersionId": 12,
  "changeSummary": "新增财务复核节点"
}
```

规则：

- 仅 `DRAFT` 状态允许修改

#### 7.2.5 删除草稿版本

`DELETE /api/admin/workflow-definition-versions/{versionId}`

规则：

- 仅 `DRAFT` 状态允许删除
- 已发布历史版本不允许删除

### 7.3 节点配置接口

#### 7.3.1 查询版本节点列表

`GET /api/admin/workflow-definition-versions/{versionId}/nodes`

返回内容建议包括：

- 节点 ID
- 节点名称
- 节点类型
- 已配置元数据

说明：

- 节点列表可以来源于 BPMN XML 解析结果与节点配置合并后的视图

#### 7.3.2 批量保存节点配置

`PUT /api/admin/workflow-definition-versions/{versionId}/nodes`

请求体示例：

```json
{
  "nodes": [
    {
      "nodeId": "managerApproveTask",
      "nodeName": "部门主管审批",
      "nodeType": "USER_TASK",
      "approvalType": "SINGLE",
      "assigneeStrategy": "DEPT_MANAGER",
      "assigneeConfig": {"deptSource": "applicantDept"},
      "commentRequired": true,
      "allowDelegate": true,
      "allowReassign": true,
      "allowReturnPrevious": true,
      "allowReturnApplicant": true,
      "aiEnabled": false
    }
  ]
}
```

规则：

- 仅 `DRAFT` 状态允许修改节点配置
- `nodeId` 必须存在于 BPMN 中

### 7.4 发布管理接口

#### 7.4.1 发布流程版本

`POST /api/admin/workflow-definition-versions/{versionId}/publish`

请求体示例：

```json
{
  "comment": "发布差旅流程 v2"
}
```

返回示例：

```json
{
  "success": true,
  "message": "Workflow version published",
  "definitionId": 1001,
  "versionId": 2002,
  "versionNo": 2,
  "status": "PUBLISHED",
  "flowableDeploymentId": "7501",
  "flowableProcessDefinitionId": "travelRequest:2:9001"
}
```

处理规则：

1. 仅 `DRAFT` 版本允许发布
2. 发布前执行 BPMN、表单、节点配置校验
3. 发布成功后更新当前版本
4. 原当前 `PUBLISHED` 版本自动转为 `INACTIVE`

#### 7.4.2 停用流程版本

`POST /api/admin/workflow-definition-versions/{versionId}/inactivate`

规则：

- 仅 `PUBLISHED` 版本允许停用
- 停用后不可再用于新实例发起

#### 7.4.3 启用已停用版本

`POST /api/admin/workflow-definition-versions/{versionId}/activate`

规则：

- 仅 `INACTIVE` 版本允许启用
- 启用成功后成为新的当前 `PUBLISHED` 版本

#### 7.4.4 退休版本

`POST /api/admin/workflow-definition-versions/{versionId}/retire`

规则：

- 允许 `PUBLISHED` 或 `INACTIVE` 版本转为 `RETIRED`
- `RETIRED` 为终态

#### 7.4.5 查询发布日志

`GET /api/admin/workflow-definition-versions/{versionId}/publish-logs`

或：

`GET /api/admin/workflow-publish-logs`

查询参数建议：

- `definitionId`
- `versionId`
- `action`
- `result`
- `page`
- `size`

### 7.5 实例追溯接口

#### 7.5.1 查询某版本关联实例统计

`GET /api/admin/workflow-definition-versions/{versionId}/usage`

返回内容建议包括：

- 实例总数
- 运行中数量
- 已结束数量
- 最近实例列表

#### 7.5.2 查询某定义下当前可发起版本

`GET /api/admin/workflow-definitions/{definitionId}/current-version`

用于管理端快速展示当前版本信息。

## 8. 运行期接口调整建议

### 8.1 现有发起流程接口保留

保留现有：

`POST /api/workflow/requests`

### 8.2 发起请求参数兼容策略

当前建议仍允许前端传：

- `processKey`
- 表单数据
- 业务变量

新增建议：

- 不要求前端显式传 `versionId`
- 后端自动根据 `processKey` 解析当前版本

### 8.3 发起接口内部逻辑调整

原逻辑：

- 直接按 `processKey` 调用 Flowable 启动

改造后逻辑：

1. 根据 `processKey` 查询 `workflow_definition`
2. 获取 `current_version_id`
3. 获取当前版本绑定的 `form_version_id`
4. 获取当前版本 `flowable_process_definition_id` 或 `processKey`
5. 构造业务请求与表单实例
6. 调用 Flowable 启动流程
7. 将定义和版本信息写入 `biz_request`

### 8.4 运行期错误码建议

新增建议错误场景：

- 当前流程定义不存在
- 当前流程无可用版本
- 当前版本未绑定表单版本
- 当前版本部署信息缺失

## 9. 接口返回对象建议

### 9.1 流程定义视图对象

建议包含：

- `id`
- `processKey`
- `processName`
- `category`
- `description`
- `status`
- `currentVersionId`
- `currentVersionNo`
- `latestVersionNo`
- `createdAt`
- `updatedAt`

### 9.2 流程版本视图对象

建议包含：

- `id`
- `definitionId`
- `versionNo`
- `versionLabel`
- `status`
- `formKey`
- `formVersionId`
- `changeSummary`
- `publishedBy`
- `publishedAt`
- `flowableDeploymentId`
- `flowableProcessDefinitionId`

### 9.3 节点配置视图对象

建议包含：

- `nodeId`
- `nodeName`
- `nodeType`
- `approvalType`
- `assigneeStrategy`
- `assigneeConfig`
- `commentRequired`
- `allowDelegate`
- `allowReassign`
- `allowReturnPrevious`
- `allowReturnApplicant`
- `aiEnabled`

## 10. 典型接口时序说明

### 10.1 发布版本时序

1. 前端调用发布接口
2. 后端读取草稿版本
3. 执行 BPMN 校验、表单校验、节点配置校验
4. 调用 Flowable 部署服务
5. 获取部署结果
6. 在事务中切换版本状态和当前版本
7. 写入发布日志
8. 返回发布结果

### 10.2 发起流程时序

1. 前端调用发起流程接口并传 `processKey`
2. 后端查询流程定义和当前版本
3. 查询表单版本与部署信息
4. 创建表单实例
5. 启动 Flowable 流程
6. 创建 `biz_request` 记录并写入版本信息
7. 返回流程实例 ID

## 11. 校验规则建议

### 11.1 创建定义校验

- `processKey` 不可为空
- `processKey` 只能包含字母、数字、下划线，建议与现有 `processKey` 风格一致
- `processName` 不可为空

### 11.2 保存草稿校验

- `bpmnXml` 不可为空
- `formVersionId` 本轮建议必填
- `definitionId` 必须存在且未归档

### 11.3 节点配置校验

- `nodeId` 必须存在于 BPMN 模型中
- `USER_TASK` 节点建议必须配置 `approvalType`
- 若配置了 `assigneeStrategy`，则对应配置 JSON 必须满足最小结构要求

### 11.4 发布校验

- 版本状态必须为 `DRAFT`
- BPMN XML 可被引擎解析
- 已绑定表单版本存在
- 节点配置与 BPMN 一致
- 同一流程定义不存在并发发布冲突

## 12. 兼容与迁移建议

### 12.1 初始数据导入

建议将现有流程文件初始化为以下流程定义与版本：

- `approvalSingle`
- `approvalCountersign`
- `approvalOrSign`
- `approvalSequential`

每个初始流程：

- 创建一条 `workflow_definition`
- 创建一条 `workflow_definition_version`
- 状态置为 `PUBLISHED`
- 与现有 Flowable 流程定义建立映射

### 12.2 历史实例处理

建议：

- 先允许历史数据版本字段为空
- 再通过离线补齐任务补全
- 对无法精确判断版本的历史实例保留空值并在界面标识

### 12.3 旧接口兼容

- 发起流程仍使用原接口地址
- 运行期任务接口不变
- 通过内部选版逻辑接入新管理能力

## 13. 本轮建议的实现优先级

### 第一优先级

1. 新增数据表和实体
2. 流程定义和版本基础 CRUD
3. 发布、停用、启用接口
4. `biz_request` 版本字段写入
5. 发起流程选版逻辑改造

### 第二优先级

1. 节点配置管理接口
2. 发布日志查询接口
3. 版本使用统计接口

### 第三优先级

1. 节点配置与运行期联动
2. 审批人策略运行期解析

## 14. 本轮设计结论

本次数据库表设计和接口设计采用“最小可行流程管理平台”方案，在不推翻现有 Flowable 执行体系的前提下，补充定义主档、版本、节点配置、发布日志和实例版本追溯能力。

核心设计决策如下：

1. 流程定义与版本分表管理
2. 版本以 `DRAFT / PUBLISHED / INACTIVE / RETIRED` 管理生命周期
3. 同一定义仅允许一个当前发布版本
4. 发起流程继续按 `processKey`，由后端自动解析当前版本
5. 实例在 `biz_request` 中记录定义 ID、版本 ID 和表单版本 ID
6. 节点配置本轮先以管理态元数据为主
7. 管理端接口与运行期接口分离，减少对现有工作流能力的冲击

该设计已可作为下一步详细设计、建表迁移和后端开发的基础版本。
