# API 接口清单

> 基于实际 Controller 代码反向推导，记录系统所有 REST API 端点。

## 1. 认证相关 (/api/auth)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/auth/bootstrap-status | 无 | 无 | 查询是否为首次引导模式 |
| POST | /api/auth/bootstrap | 无 | 无 | 引导创建系统管理员 |
| POST | /api/auth/login | 无 | 无 | 用户登录，返回 Access Token 或 Challenge Token |
| POST | /api/auth/login/2fa | 无 | 无 | 2FA 二次验证 |
| GET | /api/auth/me | JWT | 已认证 | 获取当前用户信息 |
| POST | /api/auth/2fa/setup | JWT | 已认证 | 初始化 2FA（生成密钥和二维码） |
| POST | /api/auth/2fa/enable | JWT | 已认证 | 启用 2FA |
| POST | /api/auth/2fa/disable | JWT | 已认证 | 禁用 2FA |
| POST | /api/auth/2fa/recovery/generate | JWT | 已认证 | 生成恢复码 |
| POST | /api/auth/2fa/recovery/validate | 无 | 无 | 使用恢复码验证 |
| POST | /api/auth/password/change | JWT | 已认证 | 修改密码 |

## 2. 审批流程 (/api/workflow)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| POST | /api/workflow/requests | JWT | EMPLOYEE+ | 发起审批流程 |
| POST | /api/workflow/drafts | JWT | EMPLOYEE+ | 保存草稿 |
| POST | /api/workflow/drafts/{businessKey}/submit | JWT | EMPLOYEE+ | 提交草稿 |
| GET | /api/workflow/tasks | JWT | 已认证 | 查询待办任务 |
| POST | /api/workflow/tasks/{taskId}/claim | JWT | 已认证 | 认领任务 |
| POST | /api/workflow/tasks/{taskId}/complete | JWT | 已认证 | 完成任务（通过/拒绝） |
| POST | /api/workflow/tasks/{taskId}/delegate | JWT | 已认证 | 委派任务 |
| POST | /api/workflow/tasks/{taskId}/resolve | JWT | 已认证 | 被委派人处理 |
| POST | /api/workflow/tasks/{taskId}/reassign | JWT | 已认证 | 转办任务 |
| POST | /api/workflow/tasks/{taskId}/return | JWT | 已认证 | 回退到会签 |
| POST | /api/workflow/tasks/{taskId}/return/previous | JWT | 已认证 | 回退到上一步 |
| POST | /api/workflow/tasks/{taskId}/return/target | JWT | 已认证 | 回退到指定节点 |
| POST | /api/workflow/tasks/{taskId}/return/applicant | JWT | 已认证 | 退回发起人 |
| POST | /api/workflow/process/{id}/cancel | JWT | 已认证 | 撤销流程 |
| POST | /api/workflow/process/{id}/suspend | JWT | 已认证 | 挂起流程 |
| POST | /api/workflow/process/{id}/activate | JWT | 已认证 | 激活流程 |

## 3. AI 辅助 (/api/workflow/tasks/{taskId}/ai-suggestion)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/workflow/tasks/{taskId}/ai-suggestion | JWT | 已认证 | 获取 AI 审批建议 |
| POST | /api/workflow/tasks/{taskId}/ai-suggestion/{recordId}/follow-up | JWT | 已认证 | 对 AI 建议追问 |
| POST | /api/workflow/tasks/{taskId}/ai-suggestion/{recordId}/adopt | JWT | 已认证 | 采纳 AI 建议 |
| GET | /api/workflow/tasks/{taskId}/ai-suggestion/history | JWT | 已认证 | 查看 AI 建议历史 |

## 4. 申请单查询 (/api/requests)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/requests | JWT | 已认证 | 查询申请单列表（按数据权限过滤） |
| GET | /api/requests/tasks | JWT | 已认证 | 查询关联任务 |
| GET | /api/requests/logs | JWT | 已认证 | 查询操作日志 |
| GET | /api/requests/processes | JWT | 已认证 | 查询关联流程 |
| GET | /api/requests/ai-suggestions | JWT | 已认证 | 查询 AI 建议记录 |
| GET | /api/requests/by-process/{id} | JWT | 已认证 | 按流程实例查申请 |
| GET | /api/requests/approved-by-me | JWT | 已认证 | 我审批过的申请 |

## 5. 动态表单 (/api/forms)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/forms/definitions | JWT | 已认证 | 查询表单定义列表 |
| GET | /api/forms/definitions/{id} | JWT | 已认证 | 查询单个表单定义 |
| POST | /api/forms/definitions | JWT | DESIGNER+ | 创建表单定义 |
| GET | /api/forms/versions | JWT | 已认证 | 查询表单版本列表 |
| POST | /api/forms/versions | JWT | DESIGNER+ | 创建表单版本 |
| GET | /api/forms/versions/{id} | JWT | 已认证 | 查询表单版本 |
| GET | /api/forms/fields | JWT | 已认证 | 查询字段列表 |
| POST | /api/forms/fields | JWT | DESIGNER+ | 创建/更新字段 |
| POST | /api/forms/attachments/upload | JWT | 已认证 | 上传附件 |
| GET | /api/forms/attachments/{id} | JWT | 已认证 | 下载附件 |
| GET | /api/forms/instances | JWT | 已认证 | 查询表单实例 |

## 6. AI 表单指令 (/api/ai/form-commands)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| POST | /api/ai/form-commands/parse | JWT | 已认证 | 自然语言解析表单 |
| POST | /api/ai/form-commands/parse-and-start | JWT | 已认证 | 解析并直接发起流程 |

## 7. AI 聊天 (/api/ai)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| POST | /api/ai/chat | JWT | 已认证 | AI 聊天对话 |

## 8. RBAC 管理 (/api/rbac)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/rbac/users | JWT | ADMIN+ | 查询用户列表 |
| POST | /api/rbac/users | JWT | ADMIN+ | 创建用户 |
| PUT | /api/rbac/users/{id} | JWT | ADMIN+ | 更新用户 |
| GET | /api/rbac/roles | JWT | ADMIN+ | 查询角色列表 |
| POST | /api/rbac/roles | JWT | ADMIN+ | 创建角色 |
| PUT | /api/rbac/roles/{id} | JWT | ADMIN+ | 更新角色 |
| DELETE | /api/rbac/roles/{id} | JWT | ADMIN+ | 删除角色 |
| GET | /api/rbac/role-data-scopes | JWT | ADMIN+ | 查询角色数据范围 |
| POST | /api/rbac/role-data-scopes | JWT | ADMIN+ | 设置角色数据范围 |
| GET | /api/rbac/user-post/{userId} | JWT | ADMIN+ | 查询用户岗位 |
| POST | /api/rbac/user-post/{userId} | JWT | ADMIN+ | 设置用户岗位 |

## 9. 部门管理 (/api/departments)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/departments | JWT | ADMIN+ | 查询部门列表 |
| POST | /api/departments | JWT | ADMIN+ | 创建部门 |
| PUT | /api/departments/{id} | JWT | ADMIN+ | 更新部门 |
| DELETE | /api/departments/{id} | JWT | ADMIN+ | 删除部门 |

## 10. 岗位管理 (/api/positions)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/positions | JWT | ADMIN+ | 查询岗位列表 |
| POST | /api/positions | JWT | ADMIN+ | 创建岗位 |
| PUT | /api/positions/{id} | JWT | ADMIN+ | 更新岗位 |
| DELETE | /api/positions/{id} | JWT | ADMIN+ | 删除岗位 |

## 11. 用户管理 (/api/admin/users)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/admin/users | JWT | ADMIN+ | 管理员查用户列表 |
| POST | /api/admin/users | JWT | ADMIN+ | 管理员创建用户 |
| PUT | /api/admin/users/{id} | JWT | ADMIN+ | 管理员更新用户 |
| POST | /api/admin/users/import/dry-run | JWT | ADMIN+ | CSV 导入预校验 |
| POST | /api/admin/users/import/execute | JWT | ADMIN+ | CSV 导入执行 |
| GET | /api/admin/users/import/{jobId} | JWT | ADMIN+ | 查询导入结果 |

## 12. 登录日志 (/api/admin/login-logs)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/admin/login-logs | JWT | ADMIN+ | 查询登录日志 |

## 13. 流程定义管理 (/api/admin/workflows)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/admin/workflows/definitions | JWT | ADMIN+ | 查询流程定义列表 |
| POST | /api/admin/workflows/definitions | JWT | ADMIN+ | 创建流程定义 |
| GET | /api/admin/workflows/definitions/{id} | JWT | ADMIN+ | 查询流程定义 |
| PUT | /api/admin/workflows/definitions/{id} | JWT | ADMIN+ | 更新流程定义 |
| GET | /api/admin/workflows/versions | JWT | ADMIN+ | 查询流程版本列表 |
| POST | /api/admin/workflows/versions | JWT | ADMIN+ | 创建流程版本 |
| GET | /api/admin/workflows/versions/{id} | JWT | ADMIN+ | 查询流程版本 |
| PUT | /api/admin/workflows/versions/{id} | JWT | ADMIN+ | 更新流程版本 |
| DELETE | /api/admin/workflows/versions/{id} | JWT | ADMIN+ | 删除流程版本 |
| POST | /api/admin/workflows/versions/{id}/publish | JWT | ADMIN+ | 发布流程版本 |
| POST | /api/admin/workflows/versions/{id}/inactivate | JWT | ADMIN+ | 停用流程版本 |
| POST | /api/admin/workflows/versions/{id}/retire | JWT | ADMIN+ | 废弃流程版本 |
| GET | /api/admin/workflows/node-configs | JWT | ADMIN+ | 查询节点配置 |
| POST | /api/admin/workflows/node-configs | JWT | ADMIN+ | 设置节点配置 |
| GET | /api/admin/workflows/publish-logs | JWT | ADMIN+ | 查询发布日志 |
| GET | /api/admin/workflows/launch-definitions | JWT | 已认证 | 查询可发起流程 |

## 14. 表单管理 (/api/admin/forms)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/admin/forms | JWT | DESIGNER+ | 管理员查表单列表 |
| GET | /api/admin/forms/{id} | JWT | DESIGNER+ | 管理员查表单 |
| PUT | /api/admin/forms/{id} | JWT | DESIGNER+ | 管理员更新表单 |

## 15. 申请模板管理 (/api/admin/request-templates)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/admin/request-templates | JWT | ADMIN+ | 查询模板列表 |
| POST | /api/admin/request-templates | JWT | ADMIN+ | 创建模板 |
| PUT | /api/admin/request-templates/{id} | JWT | ADMIN+ | 更新模板 |
| DELETE | /api/admin/request-templates/{id} | JWT | ADMIN+ | 删除模板 |
| GET | /api/request-templates | JWT | 已认证 | 用户查可用模板列表 |

## 16. 系统设置 (/api/admin/settings)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/admin/settings | JWT | ADMIN+ | 查询设置列表 |
| PUT | /api/admin/settings | JWT | ADMIN+ | 更新设置 |

## 17. 用户目录 (/api/user-directory)

| 方法 | 路径 | 认证 | 权限 | 说明 |
|------|------|------|------|------|
| GET | /api/user-directory/search | JWT | 已认证 | 搜索用户（用于选择审批人等） |
