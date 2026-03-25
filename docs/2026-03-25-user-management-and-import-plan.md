# 管理员新建用户与 CSV/XLSX 批量导入实现方案

日期：2026-03-25

## 1. 目标

围绕“管理员在系统中新建用户”和“管理员以 CSV/XLSX 格式批量导入用户”两项能力，补齐后端接口、导入校验、审计记录和前端管理页面，形成可直接开发的执行方案。

本方案基于当前项目现状制定：

- 已有用户、角色、部门、岗位、RBAC 和管理员鉴权基础
- 已有基础用户创建接口，但能力较弱
- 尚无正式的管理员用户管理页面
- 尚无批量导入、预校验、导入记录和结果回溯能力

## 2. 范围

### 2.1 本次纳入范围

- 管理员单个新建用户
- 管理员查看用户列表与用户详情
- 管理员修改用户状态
- 管理员重置用户密码
- 管理员分配角色、岗位、部门
- 管理员上传 CSV/XLSX 文件
- 导入前预校验（Dry-Run）
- 导入确认执行
- 导入任务结果查询
- 导入失败行导出
- 导入任务审计
- 前端管理员入口与页面

### 2.2 本次不纳入范围

- 邀请码注册链接
- 邮件或短信发送初始密码
- 与外部组织架构系统自动同步
- 细粒度权限点模型
- 大规模异步队列化导入

## 3. 现状与差距

### 3.1 当前已具备能力

- 管理员可通过 RBAC 接口创建用户、角色、部门、岗位
- 系统已支持 JWT、2FA、登录日志和管理员鉴权
- 前端已有登录态、角色信息和基础用户查询能力

### 3.2 当前缺口

- 缺少完整的管理员用户管理入口
- `POST /api/rbac/users` 只能创建基础用户，不能一次性绑定角色和岗位
- 缺少用户详情、更新、启停用、重置密码接口
- 缺少导入任务表、导入行结果表和审计字段
- 缺少 CSV/XLSX 文件解析与 Dry-Run 能力
- 缺少前端批量导入页面和结果展示

## 4. 总体方案

推荐采用“两阶段落地”。

### 4.1 第一阶段

- 管理员页面入口
- 用户列表
- 单个新建用户
- 用户详情
- 启用/禁用
- 重置密码

### 4.2 第二阶段

- CSV/XLSX 批量导入
- Dry-Run
- 执行导入
- 导入记录与失败报告

### 4.3 推荐原因

- 风险可控，先把基础用户管理闭环做稳
- 批量导入可直接复用第一阶段的用户写入逻辑
- 前端页面可以先落下管理骨架，再接入导入流程

## 5. 页面方案

推荐在现有主界面中新增管理员专属菜单“用户管理”，单页内用 Tab 承载不同能力。

### 5.1 页面结构

- 路由：`/admin/users`
- 页面：`UserAdminView.vue`
- 仅 `ADMIN` / `SYS_ADMIN` 可见

### 5.2 Tab 结构

- `用户列表`
- `新建用户`
- `批量导入`
- `导入记录`

### 5.3 采用单页 Tab 的原因

优点：

- 与当前前端结构最一致
- 菜单不膨胀
- 新建和导入都属于同一管理语境

缺点：

- 页面职责更集中

结论：

- 当前项目阶段推荐单页 Tab，而不是拆成多个管理员页面

## 6. 后端接口设计

## 6.1 管理员用户接口

建议新增独立命名空间 `/api/admin/users`，不要把所有能力继续堆在 `/api/rbac/**` 下。

原因：

- `/api/rbac/**` 更适合承载角色、岗位、部门等基础配置
- `/api/admin/users/**` 更适合承载账号管理和导入能力
- 权限边界更清晰

### 6.1.1 创建用户

`POST /api/admin/users`

请求体建议：

```json
{
  "username": "zhangsan",
  "password": "Password@123",
  "deptId": 10,
  "roleIds": [1, 2],
  "postIds": [3],
  "status": 1
}
```

返回体建议：

```json
{
  "id": 1001,
  "username": "zhangsan",
  "deptId": 10,
  "status": 1,
  "roles": [
    { "id": 1, "roleCode": "EMPLOYEE", "roleName": "员工" }
  ],
  "posts": [
    { "id": 3, "postCode": "FINANCE_REVIEWER", "postName": "财务审批岗" }
  ]
}
```

说明：

- 单个创建接口推荐使用 `roleIds` 和 `postIds`
- 前端通常先加载下拉选项，再提交 ID，歧义最少

### 6.1.2 查询用户列表

`GET /api/admin/users`

查询参数建议：

- `keyword`
- `status`
- `deptId`
- `roleId`
- `page`
- `size`

返回内容建议包含：

- 用户基础信息
- 部门信息
- 角色摘要
- 岗位摘要
- 最近登录时间
- 2FA 状态
- 是否锁定

### 6.1.3 查询用户详情

`GET /api/admin/users/{id}`

返回内容建议包含：

- 用户基础信息
- 角色列表
- 岗位列表
- 登录安全状态
- 最近登录信息

### 6.1.4 更新用户资料

`PATCH /api/admin/users/{id}`

请求体建议：

```json
{
  "deptId": 20,
  "roleIds": [2, 5],
  "postIds": [4],
  "status": 1
}
```

说明：

- 第一版只允许修改部门、角色、岗位、状态
- 不建议在第一版开放用户名变更

### 6.1.5 启用或禁用用户

`PATCH /api/admin/users/{id}/status`

请求体建议：

```json
{
  "status": 0
}
```

### 6.1.6 重置密码

`POST /api/admin/users/{id}/reset-password`

请求体建议：

```json
{
  "newPassword": "Password@123"
}
```

说明：

- 第一版先由管理员直接设置初始密码
- 后续如需要可增加“首次登录强制修改密码”

## 6.2 导入相关接口

### 6.2.1 下载模板

`GET /api/admin/users/imports/template`

用途：

- 提供标准 CSV 模板
- 也可提供 XLSX 模板

### 6.2.2 上传并预校验

`POST /api/admin/users/imports/validate`

请求：

- `multipart/form-data`
- 文件字段：`file`
- 表单字段：
  - `strategy`: `CREATE_ONLY` / `UPSERT`

返回体建议：

```json
{
  "jobId": 12,
  "fileName": "users.xlsx",
  "strategy": "CREATE_ONLY",
  "totalRows": 50,
  "successRows": 45,
  "failedRows": 5,
  "errors": [
    {
      "rowNo": 3,
      "username": "lisi",
      "message": "role_codes contains unknown role: MANAGER_X"
    }
  ],
  "preview": [
    {
      "rowNo": 2,
      "username": "zhangsan",
      "deptCode": "FIN",
      "roleCodes": ["EMPLOYEE"],
      "postCodes": ["FINANCE_REVIEWER"],
      "status": 1,
      "valid": true
    }
  ]
}
```

### 6.2.3 执行导入

`POST /api/admin/users/imports/{jobId}/execute`

请求体建议：

```json
{
  "skipErrorRows": true
}
```

返回体建议：

```json
{
  "jobId": 12,
  "status": "COMPLETED",
  "totalRows": 50,
  "successRows": 45,
  "failedRows": 5
}
```

### 6.2.4 查询导入任务列表

`GET /api/admin/users/imports`

查询参数建议：

- `status`
- `operatorId`
- `startDate`
- `endDate`
- `page`
- `size`

### 6.2.5 查询导入任务详情

`GET /api/admin/users/imports/{jobId}`

### 6.2.6 查询导入明细

`GET /api/admin/users/imports/{jobId}/items`

### 6.2.7 导出失败行

`GET /api/admin/users/imports/{jobId}/failed-export`

## 7. 导入文件格式

推荐统一模板字段如下：

- `username`
- `password`
- `dept_code`
- `post_codes`
- `role_codes`
- `status`

### 7.1 字段说明

| 字段 | 是否必填 | 说明 |
| --- | --- | --- |
| `username` | 是 | 用户名，系统内唯一 |
| `password` | 是 | 初始密码 |
| `dept_code` | 否 | 部门编码，不填表示无部门 |
| `post_codes` | 否 | 多个岗位编码，英文逗号分隔 |
| `role_codes` | 是 | 多个角色编码，英文逗号分隔 |
| `status` | 否 | `0` 禁用，`1` 启用，默认 `1` |

### 7.2 CSV 与 XLSX 支持方式

推荐做法：

- 同时支持 CSV 和 XLSX
- 解析层分别实现
- 解析完成后统一转换为同一种“导入行模型”再进入校验和写库逻辑

原因：

- 可以满足用户需求
- 后端校验逻辑只维护一套
- 后续扩展更多模板时成本更低

## 8. 导入策略

支持两种策略：

### 8.1 `CREATE_ONLY`

规则：

- 用户名不存在则创建
- 用户名已存在则报错

优点：

- 安全
- 适合首次导入

缺点：

- 不能修正已有账号

### 8.2 `UPSERT`

规则：

- 用户名不存在则创建
- 用户名存在则更新部门、角色、岗位、状态

优点：

- 适合组织同步或批量修正

缺点：

- 覆盖风险更高

### 8.3 推荐策略

- 第一版同时支持两种策略
- 默认选择 `CREATE_ONLY`

## 9. 数据表设计

现有 `sys_user`、`sys_user_role`、`sys_user_post` 可继续复用。

为支持导入任务和审计，建议新增两张表。

## 9.1 导入任务表

表名建议：`sys_user_import_job`

字段建议：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | BIGINT | 主键 |
| `file_name` | VARCHAR(255) | 原始文件名 |
| `file_type` | VARCHAR(16) | `CSV` / `XLSX` |
| `file_checksum` | VARCHAR(128) | 文件摘要 |
| `strategy` | VARCHAR(32) | `CREATE_ONLY` / `UPSERT` |
| `status` | VARCHAR(32) | `DRAFT` / `VALIDATED` / `RUNNING` / `COMPLETED` / `FAILED` |
| `total_rows` | INT | 总行数 |
| `success_rows` | INT | 成功行数 |
| `failed_rows` | INT | 失败行数 |
| `operator_id` | BIGINT | 操作人 |
| `created_at` | DATETIME | 创建时间 |
| `finished_at` | DATETIME | 完成时间 |

## 9.2 导入行结果表

表名建议：`sys_user_import_job_item`

字段建议：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | BIGINT | 主键 |
| `job_id` | BIGINT | 关联导入任务 |
| `row_no` | INT | 行号 |
| `username` | VARCHAR(64) | 用户名 |
| `raw_payload` | TEXT | 原始行内容 |
| `result` | VARCHAR(32) | `SUCCESS` / `FAILED` / `SKIPPED` |
| `error_message` | VARCHAR(512) | 错误原因 |
| `created_user_id` | BIGINT | 新建出的用户 ID |
| `before_snapshot` | TEXT | 更新前摘要 |
| `after_snapshot` | TEXT | 更新后摘要 |

## 9.3 是否需要单独文件存储

可选方案：

- 方案 A：只存摘要，不保留原文件
  - 优点：实现简单
  - 缺点：审计证据较弱
- 方案 B：保留原文件到本地或对象存储，并在任务表存路径
  - 优点：审计更完整
  - 缺点：存储管理更复杂

推荐：

- 第一版先采用方案 A
- 保存原文件名、摘要、行级原始内容

## 10. 核心校验规则

## 10.1 单个创建校验

- 用户名不能为空
- 用户名长度不超过 64
- 用户名必须唯一
- 密码不能为空
- 密码长度至少 8 位
- 部门存在性校验
- 角色存在性校验
- 岗位存在性校验

## 10.2 导入文件校验

- 文件类型只允许 CSV/XLSX
- 文件大小设置上限
- 行数设置上限
- 表头必须匹配模板
- 编码合法

### 10.2.1 单行校验

- `username` 非空
- `username` 在文件内不重复
- `username` 与库内冲突时根据策略处理
- `password` 满足规则
- `dept_code` 存在
- `role_codes` 都存在
- `post_codes` 都存在
- `status` 只能为 `0` 或 `1`

### 10.2.2 执行前校验

- 任务状态必须为 `VALIDATED`
- 不允许重复执行
- 执行人必须是管理员

## 11. 写库规则

## 11.1 单个创建

- 先创建 `sys_user`
- 再写入 `sys_user_role`
- 再写入 `sys_user_post`

要求：

- 整体事务提交
- 任一步失败整体回滚

## 11.2 批量导入

### 11.2.1 `CREATE_ONLY`

- 用户不存在则创建并绑定关系
- 用户存在则该行失败

### 11.2.2 `UPSERT`

- 用户不存在则创建
- 用户存在则更新：
  - `dept_id`
  - `status`
  - 角色集合
  - 岗位集合

不建议第一版在 `UPSERT` 中更新：

- 用户名
- 最近登录时间
- 2FA 相关字段
- 锁定状态

## 12. 权限与安全要求

- 所有管理员用户管理接口只允许 `ADMIN` / `SYS_ADMIN`
- 前端菜单和路由只对管理员显示
- 批量导入接口必须记录操作者
- 审计记录必须保留导入时间、文件摘要、结果统计

建议同时补强以下现有问题：

- 用户被禁用后，请求链路应尽快失效
- 角色被停用后，发 token 时应过滤无效角色
- 普通选人接口和管理员管理接口分开

推荐边界：

- `/api/users` 保留为业务选人接口，返回最小字段
- `/api/admin/users/**` 作为管理员管理接口

## 13. 前端实现规划

## 13.1 路由与菜单

- 新增管理员路由 `/admin/users`
- 使用现有 `meta.roles`
- 左侧菜单仅管理员显示

## 13.2 用户列表 Tab

功能：

- 用户名搜索
- 状态筛选
- 查看部门、角色、岗位
- 查看 2FA 与锁定状态
- 查看详情
- 启停用
- 重置密码

## 13.3 新建用户 Tab

表单字段：

- 用户名
- 初始密码
- 部门
- 角色多选
- 岗位多选
- 状态

## 13.4 批量导入 Tab

功能：

- 下载模板
- 上传 CSV/XLSX
- 选择导入策略
- 显示 Dry-Run 结果
- 确认导入
- 展示成功数和失败数

## 13.5 导入记录 Tab

功能：

- 查看任务列表
- 查看任务详情
- 查看失败原因
- 导出失败行

## 14. 后端代码落点建议

- 管理员用户接口：新增 `AdminUserController`
- 用户管理服务：新增 `AdminUserService`
- 导入服务：新增 `UserImportService`
- 导入解析：新增独立解析组件
- 复用现有：
  - `RbacService`
  - `SysUserRepository`
  - `SysRoleRepository`
  - `SysUserRoleRepository`
  - `SysUserPostRepository`

推荐原因：

- 避免把导入逻辑塞进 `RbacService`
- 保持基础 RBAC 能力和管理员账号管理能力分层清晰

## 15. 测试标准

以下内容全部通过后，才算该功能完成。

### 15.1 后端测试

- 管理员可新建单个用户并绑定角色、岗位、部门
- 非管理员无法访问管理员接口
- 用户状态修改生效
- 重置密码后可以正常登录
- CSV Dry-Run 能正确返回错误
- XLSX Dry-Run 能正确返回错误
- `CREATE_ONLY` 不覆盖已有用户
- `UPSERT` 正确更新允许更新字段
- 导入任务与导入明细可查询
- 失败行可导出

### 15.2 前端测试

- 非管理员看不到用户管理入口
- 管理员可以打开用户管理页面
- 新建用户表单可成功提交
- 批量导入可显示 Dry-Run 结果
- 导入记录可查询

## 16. 研发拆分建议

## 16.1 后端任务

1. 新增管理员用户接口与服务
2. 补齐用户详情、更新、状态、重置密码接口
3. 新增导入任务表与导入行结果表
4. 实现 CSV/XLSX 解析
5. 实现 Dry-Run
6. 实现执行导入
7. 实现导入记录与失败导出
8. 补齐集成测试

## 16.2 前端任务

1. 新增管理员菜单和路由
2. 新增用户管理页面
3. 接入用户列表和详情
4. 接入新建用户表单
5. 接入导入上传和 Dry-Run
6. 接入导入记录和失败明细

## 17. 完成标准

当以下条件同时满足时，功能可视为完成：

- 管理员可在页面中新建单个用户
- 管理员可通过 CSV/XLSX 导入用户
- 导入前可看到明确的预校验结果
- 导入后可查看成功、失败和原因
- 用户、角色、岗位、部门关系写入正确
- 非管理员无法访问相关页面和接口
- 自动化测试覆盖主路径和关键异常路径

## 18. 最终建议

本功能建议按以下顺序推进：

1. 管理员页面入口和用户管理骨架
2. 单个新建用户闭环
3. 用户详情、状态、密码重置
4. 批量导入表结构
5. CSV/XLSX Dry-Run
6. 执行导入与结果回溯
7. 测试与文档收口

推荐优先交付内容：

- 管理员新建用户
- 管理员用户列表与详情
- CSV/XLSX 批量导入
- Dry-Run
- 导入记录

