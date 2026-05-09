# 数据库表结构设计（论文三线表格格式）

> 表头格式：字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值

---

## 表 4.1 申请单主表 (biz_request)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| business_key | VARCHAR | 64 | 业务主键，唯一标识申请单 | 否 | 无 |
| process_instance_id | VARCHAR | 64 | Flowable 流程实例 ID | 否 | NULL |
| process_definition_id | VARCHAR | 64 | Flowable 流程定义 ID | 否 | NULL |
| form_instance_id | BIGINT | 20 | 关联表单实例 ID | 否 | NULL |
| workflow_definition_id | BIGINT | 20 | 关联工作流定义 ID | 否 | NULL |
| workflow_definition_version_id | BIGINT | 20 | 关联工作流定义版本 ID | 否 | NULL |
| form_version_id | BIGINT | 20 | 关联表单版本 ID | 否 | NULL |
| request_template_key | VARCHAR | 64 | 申请模板键 | 否 | NULL |
| applicant_id | BIGINT | 20 | 发起人用户 ID | 否 | 无 |
| applicant_dept_id | BIGINT | 20 | 发起人部门 ID | 否 | NULL |
| applicant_post_id | BIGINT | 20 | 发起人岗位 ID | 否 | NULL |
| title | VARCHAR | 128 | 申请标题 | 否 | 无 |
| status | TINYINT | 4 | 申请状态：0草稿/1已提交/2审批中/3通过/4拒绝/5退回/6撤销/7挂起 | 否 | 0 |
| current_task_id | VARCHAR | 64 | 当前待办任务 ID | 否 | NULL |
| current_assignee_id | BIGINT | 20 | 当前处理人用户 ID | 否 | NULL |
| submit_time | DATETIME | — | 提交时间 | 否 | NULL |
| finish_time | DATETIME | — | 结束时间 | 否 | NULL |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| updated_at | DATETIME | — | 更新时间 | 否 | CURRENT_TIMESTAMP |
| is_deleted | TINYINT | 4 | 逻辑删除标记，0未删除/1已删除 | 否 | 0 |

## 表 4.2 审批任务表 (biz_request_task)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| business_key | VARCHAR | 64 | 关联申请单业务主键 | 否 | 无 |
| process_instance_id | VARCHAR | 64 | Flowable 流程实例 ID | 否 | 无 |
| task_id | VARCHAR | 64 | Flowable 任务 ID | 否 | 无 |
| task_name | VARCHAR | 128 | 任务名称 | 否 | NULL |
| assignee_id | BIGINT | 20 | 任务办理人用户 ID | 否 | NULL |
| owner_id | BIGINT | 20 | 任务委派时的原负责人用户 ID | 否 | NULL |
| status | TINYINT | 4 | 任务状态：0待认领/1已认领/2委派中/3已完成/4已回退 | 否 | 0 |
| action | VARCHAR | 32 | 操作动作：CREATE/CLAIM/APPROVE/REJECT/DELEGATE/RESOLVE/REASSIGN/RETURN/AUTO_COMPLETE/CANCEL | 否 | NULL |
| comment | VARCHAR | 512 | 审批意见或操作说明 | 否 | NULL |
| start_time | DATETIME | — | 任务开始时间 | 否 | NULL |
| end_time | DATETIME | — | 任务完成时间 | 否 | NULL |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| updated_at | DATETIME | — | 更新时间 | 否 | CURRENT_TIMESTAMP |

## 表 4.3 审批操作日志表 (biz_request_log)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| business_key | VARCHAR | 64 | 关联申请单业务主键 | 否 | 无 |
| process_instance_id | VARCHAR | 64 | Flowable 流程实例 ID | 否 | NULL |
| task_id | VARCHAR | 64 | 关联 Flowable 任务 ID | 否 | NULL |
| operator_id | BIGINT | 20 | 操作人用户 ID | 否 | 无 |
| action | VARCHAR | 32 | 操作类型：SUBMIT/CLAIM/APPROVE/REJECT/DELEGATE/RESOLVE/REASSIGN/RETURN/CANCEL/SUSPEND/ACTIVATE/SAVE_DRAFT | 否 | 无 |
| comment | VARCHAR | 512 | 操作意见或备注 | 否 | NULL |
| created_at | DATETIME | — | 操作时间 | 否 | CURRENT_TIMESTAMP |

## 表 4.4 AI 建议记录表 (ai_suggestion_record)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| business_key | VARCHAR | 64 | 关联申请单业务主键 | 否 | 无 |
| process_instance_id | VARCHAR | 64 | Flowable 流程实例 ID | 否 | 无 |
| task_id | VARCHAR | 64 | Flowable 任务 ID | 否 | 无 |
| requester_id | BIGINT | 20 | 请求 AI 建议的用户 ID | 否 | 无 |
| model | VARCHAR | 128 | 使用的 LLM 模型名称 | 否 | NULL |
| suggestion_json | TEXT | — | AI 建议内容（JSON 格式） | 否 | 无 |
| conversation_json | TEXT | — | 多轮对话历史（JSON 格式） | 否 | NULL |
| adopted | TINYINT | 1 | 建议是否被采纳 | 否 | 0 |
| adopted_at | DATETIME | — | 采纳时间 | 否 | NULL |
| final_approval_result | VARCHAR | 32 | 申请最终审批结果 | 否 | NULL |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| updated_at | DATETIME | — | 更新时间 | 否 | CURRENT_TIMESTAMP |

---

## 表 4.5 表单定义表 (form_definition)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| form_name | VARCHAR | 128 | 表单名称 | 否 | 无 |
| form_key | VARCHAR | 64 | 表单唯一标识 | 否 | 无 |
| status | INTEGER | 11 | 状态：0禁用/1启用 | 否 | 1 |

## 表 4.6 表单版本表 (form_version)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| form_id | BIGINT | 20 | 关联表单定义 ID | 否 | 无 |
| version | INTEGER | 11 | 版本号 | 否 | 无 |
| schema_json | TEXT | — | 表单结构描述（JSON 格式） | 否 | 无 |
| status | VARCHAR | 32 | 版本状态：DRAFT/PUBLISHED/ARCHIVED | 否 | DRAFT |
| published_by | BIGINT | 20 | 发布人用户 ID | 否 | NULL |
| published_at | DATETIME | — | 发布时间 | 否 | NULL |

## 表 4.7 表单字段表 (form_field)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| form_version_id | BIGINT | 20 | 关联表单版本 ID | 否 | 无 |
| field_key | VARCHAR | 64 | 字段唯一标识 | 否 | 无 |
| variable_key | VARCHAR | 64 | 关联流程变量键名 | 否 | NULL |
| field_type | VARCHAR | 32 | 字段类型：string/number/date/datetime/select/table | 否 | 无 |
| label | VARCHAR | 128 | 字段显示标签 | 否 | NULL |
| required | INTEGER | 11 | 是否必填，0否/1是 | 否 | 0 |
| visible_rule | TEXT | — | 可见条件规则（JSON 格式） | 否 | NULL |
| validate_rule | TEXT | — | 校验规则（JSON 格式） | 否 | NULL |
| options_json | TEXT | — | 下拉选项列表（JSON 格式） | 否 | NULL |
| default_value | TEXT | — | 默认值 | 否 | NULL |
| sort_order | INTEGER | 11 | 排序序号 | 否 | 0 |

## 表 4.8 表单实例表 (form_instance)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| form_version_id | BIGINT | 20 | 关联表单版本 ID | 否 | 无 |
| business_key | VARCHAR | 64 | 关联申请单业务主键 | 否 | 无 |
| data_json | TEXT | — | 表单填写数据（JSON 格式） | 否 | 无 |

## 表 4.9 表单附件表 (form_attachment)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| form_instance_id | BIGINT | 20 | 关联表单实例 ID | 否 | NULL |
| field_key | VARCHAR | 64 | 所属表单字段标识 | 否 | 无 |
| file_name | VARCHAR | 255 | 存储文件名（UUID 命名） | 否 | 无 |
| original_name | VARCHAR | 255 | 原始文件名 | 否 | 无 |
| file_path | VARCHAR | 512 | 文件存储路径 | 否 | 无 |
| file_size | BIGINT | 20 | 文件大小（字节） | 否 | 无 |
| content_type | VARCHAR | 128 | 文件 MIME 类型 | 否 | 无 |
| created_at | DATETIME | — | 上传时间 | 否 | CURRENT_TIMESTAMP |

---

## 表 4.10 工作流定义表 (workflow_definition)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| process_key | VARCHAR | 64 | 流程唯一标识，对应 BPMN process id | 否 | 无 |
| process_name | VARCHAR | 128 | 流程名称 | 否 | 无 |
| category | VARCHAR | 64 | 流程分类 | 否 | NULL |
| description | VARCHAR | 512 | 流程描述 | 否 | NULL |
| status | VARCHAR | 32 | 流程状态：DRAFT/ACTIVE/INACTIVE/ARCHIVED | 否 | DRAFT |
| current_version_id | BIGINT | 20 | 当前生效版本 ID | 否 | NULL |
| latest_version_no | INTEGER | 11 | 最新版本号 | 否 | 0 |
| created_by | BIGINT | 20 | 创建人用户 ID | 否 | 无 |
| updated_by | BIGINT | 20 | 更新人用户 ID | 否 | NULL |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| updated_at | DATETIME | — | 更新时间 | 否 | CURRENT_TIMESTAMP |
| is_deleted | INTEGER | 11 | 逻辑删除标记，0未删除/1已删除 | 否 | 0 |

## 表 4.11 工作流定义版本表 (workflow_definition_version)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| definition_id | BIGINT | 20 | 关联工作流定义 ID | 否 | 无 |
| version_no | INTEGER | 11 | 版本号 | 否 | 无 |
| version_label | VARCHAR | 64 | 版本标签说明 | 否 | NULL |
| status | VARCHAR | 32 | 版本状态：DRAFT/PUBLISHED/INACTIVE/RETIRED | 否 | DRAFT |
| bpmn_xml | LONGTEXT | — | BPMN 2.0 XML 内容 | 否 | 空串 |
| bpmn_checksum | VARCHAR | 64 | BPMN XML 内容校验和 | 否 | NULL |
| flowable_deployment_id | VARCHAR | 64 | Flowable 引擎部署 ID | 否 | NULL |
| flowable_process_definition_id | VARCHAR | 128 | Flowable 引擎流程定义 ID | 否 | NULL |
| form_key | VARCHAR | 64 | 绑定的表单标识 | 否 | NULL |
| form_version_id | BIGINT | 20 | 绑定的表单版本 ID | 否 | NULL |
| change_summary | VARCHAR | 1000 | 变更说明 | 否 | NULL |
| published_by | BIGINT | 20 | 发布人用户 ID | 否 | NULL |
| published_at | DATETIME | — | 发布时间 | 否 | NULL |
| created_by | BIGINT | 20 | 创建人用户 ID | 否 | 无 |
| updated_by | BIGINT | 20 | 更新人用户 ID | 否 | NULL |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| updated_at | DATETIME | — | 更新时间 | 否 | CURRENT_TIMESTAMP |
| is_deleted | INTEGER | 11 | 逻辑删除标记，0未删除/1已删除 | 否 | 0 |

## 表 4.12 工作流节点配置表 (workflow_node_config)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| definition_version_id | BIGINT | 20 | 关联工作流版本 ID | 否 | 无 |
| node_id | VARCHAR | 64 | BPMN 节点 ID | 否 | 无 |
| node_name | VARCHAR | 128 | 节点名称 | 否 | 无 |
| node_type | VARCHAR | 32 | 节点类型：userTask/gateway/startEvent/endEvent | 否 | 无 |
| approval_type | VARCHAR | 32 | 审批类型：single/countersign/orsign/sequential | 否 | NULL |
| assignee_strategy | VARCHAR | 32 | 审批人分配策略 | 否 | NULL |
| assignee_config_json | TEXT | — | 分配策略配置（JSON 格式） | 否 | NULL |
| comment_required | INTEGER | 11 | 审批意见是否必填，0否/1是 | 否 | 1 |
| allow_delegate | INTEGER | 11 | 是否允许委派，0否/1是 | 否 | 1 |
| allow_reassign | INTEGER | 11 | 是否允许转办，0否/1是 | 否 | 1 |
| allow_return_previous | INTEGER | 11 | 是否允许回退上一步，0否/1是 | 否 | 1 |
| allow_return_applicant | INTEGER | 11 | 是否允许退回发起人，0否/1是 | 否 | 1 |
| ai_enabled | INTEGER | 11 | 是否启用 AI 建议，0否/1是 | 否 | 0 |
| timeout_rule_json | TEXT | — | 超时处理规则（JSON 格式） | 否 | NULL |
| extra_config_json | TEXT | — | 扩展配置（JSON 格式） | 否 | NULL |
| sort_order | INTEGER | 11 | 排序序号 | 否 | 0 |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| updated_at | DATETIME | — | 更新时间 | 否 | CURRENT_TIMESTAMP |

## 表 4.13 工作流发布日志表 (workflow_publish_log)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| definition_id | BIGINT | 20 | 关联工作流定义 ID | 否 | 无 |
| definition_version_id | BIGINT | 20 | 关联工作流版本 ID | 否 | 无 |
| action | VARCHAR | 32 | 操作类型：PUBLISH/INACTIVATE/ACTIVATE/RETIRE/ARCHIVE | 否 | 无 |
| result | VARCHAR | 32 | 执行结果：SUCCESS/FAIL | 否 | 无 |
| message | VARCHAR | 1000 | 操作消息或失败原因 | 否 | NULL |
| flowable_deployment_id | VARCHAR | 64 | Flowable 引擎部署 ID | 否 | NULL |
| flowable_process_definition_id | VARCHAR | 128 | Flowable 引擎流程定义 ID | 否 | NULL |
| operator_id | BIGINT | 20 | 操作人用户 ID | 否 | 无 |
| operated_at | DATETIME | — | 操作时间 | 否 | CURRENT_TIMESTAMP |

## 表 4.14 申请模板表 (request_template)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| template_key | VARCHAR | 64 | 模板唯一标识 | 否 | 无 |
| template_name | VARCHAR | 128 | 模板名称 | 否 | 无 |
| category | VARCHAR | 64 | 模板分类 | 否 | NULL |
| description | VARCHAR | 512 | 模板描述 | 否 | NULL |
| form_key | VARCHAR | 64 | 绑定的表单标识 | 否 | NULL |
| form_name | VARCHAR | 128 | 绑定的表单名称 | 否 | NULL |
| process_key | VARCHAR | 64 | 绑定的流程标识 | 否 | 无 |
| countersign_mode | VARCHAR | 32 | 会签模式：ALL全票通过/MAJORITY多数通过 | 否 | ALL |
| pass_ratio | VARCHAR | 16 | 多数通过比例，如 0.5 表示半数以上 | 否 | 1.0 |
| flow_summary | VARCHAR | 512 | 流程流转总览说明 | 否 | NULL |
| approval_config_json | TEXT | — | 审批规则配置（JSON 格式） | 否 | NULL |
| launch_role_codes_json | TEXT | — | 允许发起的角色编码列表（JSON 格式） | 否 | NULL |
| allow_manual_approver_select | INTEGER | 11 | 是否允许手动指定审批人，0否/1是 | 否 | 0 |
| sort_order | INTEGER | 11 | 排序序号 | 否 | 0 |
| status | VARCHAR | 32 | 模板状态：ACTIVE/INACTIVE | 否 | ACTIVE |
| created_by | BIGINT | 20 | 创建人用户 ID | 否 | 无 |
| updated_by | BIGINT | 20 | 更新人用户 ID | 否 | NULL |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| updated_at | DATETIME | — | 更新时间 | 否 | CURRENT_TIMESTAMP |

---

## 表 4.15 用户表 (sys_user)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| username | VARCHAR | 64 | 用户名，全局唯一 | 否 | 无 |
| password | VARCHAR | 128 | 密码（BCrypt 加密存储） | 否 | NULL |
| dept_id | BIGINT | 20 | 所属部门 ID | 否 | NULL |
| manager_user_id | BIGINT | 20 | 直属主管用户 ID | 否 | NULL |
| status | INTEGER | 11 | 用户状态：0禁用/1启用 | 否 | 1 |
| two_factor_enabled | INTEGER | 11 | 双因素认证是否启用，0否/1是 | 否 | 0 |
| two_factor_secret | VARCHAR | 128 | TOTP 共享密钥 | 否 | NULL |
| recovery_codes | VARCHAR | 512 | 2FA 恢复码列表（JSON 格式） | 否 | NULL |
| last_login_at | DATETIME | — | 最后登录时间 | 否 | NULL |
| login_failures | INTEGER | 11 | 连续登录失败次数 | 否 | 0 |
| locked_until | DATETIME | — | 账号锁定截止时间 | 否 | NULL |

## 表 4.16 角色表 (sys_role)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| role_code | VARCHAR | 64 | 角色编码，如 EMPLOYEE/MANAGER/DESIGNER/ADMIN/SYS_ADMIN | 否 | 无 |
| role_name | VARCHAR | 64 | 角色名称 | 否 | 无 |
| status | INTEGER | 11 | 角色状态：0禁用/1启用 | 否 | 1 |

## 表 4.17 部门表 (sys_dept)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| parent_id | BIGINT | 20 | 上级部门 ID，NULL 表示顶级部门 | 否 | NULL |
| dept_code | VARCHAR | 64 | 部门编码，全局唯一 | 否 | NULL |
| dept_name | VARCHAR | 64 | 部门名称 | 否 | 无 |
| leader_user_id | BIGINT | 20 | 部门负责人用户 ID | 否 | NULL |

## 表 4.18 岗位表 (sys_post)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| post_code | VARCHAR | 64 | 岗位编码，全局唯一 | 否 | 无 |
| post_name | VARCHAR | 64 | 岗位名称 | 否 | 无 |

## 表 4.19 用户-角色关联表 (sys_user_role)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| user_id | BIGINT | 20 | 用户 ID | 否 | 无 |
| role_id | BIGINT | 20 | 角色 ID | 否 | 无 |

> 唯一约束：UNIQUE(user_id, role_id)

## 表 4.20 用户-岗位关联表 (sys_user_post)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| user_id | BIGINT | 20 | 用户 ID | 否 | 无 |
| post_id | BIGINT | 20 | 岗位 ID | 否 | 无 |

> 唯一约束：UNIQUE(user_id, post_id)

## 表 4.21 角色数据权限表 (sys_role_data_scope)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| role_id | BIGINT | 20 | 角色 ID | 否 | 无 |
| dept_id | BIGINT | 20 | 部门 ID | 否 | NULL |
| scope_type | VARCHAR | 32 | 数据范围类型 | 否 | 无 |

## 表 4.22 登录日志表 (sys_login_log)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| user_id | BIGINT | 20 | 用户 ID | 否 | NULL |
| username | VARCHAR | 64 | 登录时使用的用户名 | 否 | NULL |
| login_status | INTEGER | 11 | 登录状态：0成功/1失败 | 否 | 无 |
| message | VARCHAR | 512 | 登录结果描述信息 | 否 | NULL |
| ip_address | VARCHAR | 64 | 客户端 IP 地址 | 否 | NULL |
| user_agent | VARCHAR | 512 | 客户端浏览器标识 | 否 | NULL |
| login_time | DATETIME | — | 登录时间 | 否 | CURRENT_TIMESTAMP |

## 表 4.23 用户批量导入任务表 (sys_user_import_job)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| file_name | VARCHAR | 255 | 导入文件名 | 否 | 无 |
| file_type | VARCHAR | 16 | 文件类型，如 CSV/EXCEL | 否 | 无 |
| file_checksum | VARCHAR | 128 | 文件校验和（SHA256） | 否 | 无 |
| strategy | VARCHAR | 32 | 导入策略：CREATE_ONLY/UPSERT | 否 | 无 |
| status | VARCHAR | 32 | 任务状态 | 否 | 无 |
| total_rows | INTEGER | 11 | 总行数 | 否 | 0 |
| success_rows | INTEGER | 11 | 成功行数 | 否 | 0 |
| failed_rows | INTEGER | 11 | 失败行数 | 否 | 0 |
| operator_id | BIGINT | 20 | 操作人用户 ID | 否 | 无 |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| finished_at | DATETIME | — | 完成时间 | 否 | NULL |

## 表 4.24 系统设置表 (sys_setting)

| 字段名称 | 类型 | 长度 | 字段说明 | 主键 | 默认值 |
|:---|:---|:---|:---|:---|:---|
| id | BIGINT | 20 | 主键 | 是 | AUTO_INCREMENT |
| setting_key | VARCHAR | 128 | 设置键名，全局唯一 | 否 | 无 |
| setting_value | TEXT | — | 设置值 | 否 | NULL |
| encrypted | INTEGER | 11 | 是否加密存储，0否/1是 | 否 | 0 |
| updated_by | BIGINT | 20 | 更新人用户 ID | 否 | NULL |
| created_at | DATETIME | — | 创建时间 | 否 | CURRENT_TIMESTAMP |
| updated_at | DATETIME | — | 更新时间 | 否 | CURRENT_TIMESTAMP |
