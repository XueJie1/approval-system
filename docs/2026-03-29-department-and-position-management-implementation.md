# 部门和岗位管理功能实现说明

**日期**: 2026-03-29  
**作者**: AI Assistant  
**状态**: 已完成

---

## 一、概述

本次实现完成了审批系统中部门（Department）和岗位（Position）的完整增删改查功能，包括后端 API 和前端管理界面。

---

## 二、后端实现

### 2.1 新增文件

#### Controller 层
- `DepartmentController.java` - 部门管理的 REST 控制器
- `PositionController.java` - 岗位管理的 REST 控制器

#### Service 层
- `DepartmentService.java` - 部门业务逻辑服务
- `PositionService.java` - 岗位业务逻辑服务

#### Repository 层修改
- `SysUserRepository.java` - 新增 `findByDeptId()` 方法
- `SysUserPostRepository.java` - 新增 `findByPostId()` 方法

#### 异常处理
- `GlobalExceptionHandler.java` - 新增 `RuntimeException` 处理器，返回 404 状态

### 2.2 API 接口

#### 部门 API (`/api/departments`)

| HTTP 方法 | 路径 | 描述 | 请求参数 | 响应 |
|-----------|------|------|----------|------|
| GET | `/api/departments` | 获取所有部门列表 | - | `List<SysDept>` |
| GET | `/api/departments/{id}` | 根据 ID 获取部门 | `id` (path) | `SysDept` |
| POST | `/api/departments` | 创建部门 | `deptCode?`, `deptName`, `parentId?` | `SysDept` |
| PUT | `/api/departments/{id}` | 更新部门 | `id` (path), `deptCode?`, `deptName`, `parentId?` | `SysDept` |
| DELETE | `/api/departments/{id}` | 删除部门 | `id` (path) | 204 No Content |

#### 岗位 API (`/api/positions`)

| HTTP 方法 | 路径 | 描述 | 请求参数 | 响应 |
|-----------|------|------|----------|------|
| GET | `/api/positions` | 获取所有岗位列表 | - | `List<SysPost>` |
| GET | `/api/positions/{id}` | 根据 ID 获取岗位 | `id` (path) | `SysPost` |
| POST | `/api/positions` | 创建岗位 | `postCode`, `postName` | `SysPost` |
| PUT | `/api/positions/{id}` | 更新岗位 | `id` (path), `postCode`, `postName` | `SysPost` |
| DELETE | `/api/positions/{id}` | 删除岗位 | `id` (path) | 204 No Content |

### 2.3 业务规则

#### 部门管理
- **唯一性约束**: `deptCode` 必须唯一（可为空）
- **父部门验证**: 创建/更新时，`parentId` 必须存在
- **删除限制**: 
  - 有子部门时无法删除
  - 有用户分配时无法删除

#### 岗位管理
- **唯一性约束**: `postCode` 必须唯一且不能为空
- **删除限制**: 有用户分配时无法删除

#### 权限控制
- 所有增删改操作需要 `ADMIN` 或 `SYS_ADMIN` 角色
- 查询操作需要用户登录

### 2.4 测试覆盖

#### DepartmentControllerIntegrationTests
- ✅ admin_canCreateDepartment - 创建部门
- ✅ admin_canCreateSubDepartment - 创建子部门
- ✅ admin_canListAllDepartments - 列出所有部门
- ✅ admin_canGetDepartmentById - 根据 ID 获取部门
- ✅ admin_canUpdateDepartment - 更新部门
- ✅ admin_canDeleteDepartment - 删除部门
- ✅ cannotDeleteDepartmentWithChildren - 删除有子部门的部门失败
- ✅ cannotDeleteDepartmentWithUsers - 删除有用户的部门失败
- ✅ createDepartment_validatesDeptCodeUniqueness - 部门代码唯一性验证
- ✅ nonAdmin_cannotManageDepartments - 非管理员无法操作
- ✅ getDepartmentNotFound_returns404 - 获取不存在的部门返回 404
- ✅ updateDepartmentNotFound_returns404 - 更新不存在的部门返回 404
- ✅ deleteDepartmentNotFound_returns404 - 删除不存在的部门返回 404

#### PositionControllerIntegrationTests
- ✅ admin_canCreatePosition - 创建岗位
- ✅ admin_canListAllPositions - 列出所有岗位
- ✅ admin_canGetPositionById - 根据 ID 获取岗位
- ✅ admin_canUpdatePosition - 更新岗位
- ✅ admin_canDeletePosition - 删除岗位
- ✅ cannotDeletePositionWithUsers - 删除有用户的岗位失败
- ✅ createPosition_validatesPostCodeUniqueness - 岗位代码唯一性验证
- ✅ nonAdmin_cannotManagePositions - 非管理员无法操作
- ✅ getPositionNotFound_returns404 - 获取不存在的岗位返回 404
- ✅ updatePositionNotFound_returns404 - 更新不存在的岗位返回 404
- ✅ deletePositionNotFound_returns404 - 删除不存在的岗位返回 404
- ✅ createPosition_requiresPostCode - 创建岗位需要岗位代码
- ✅ createPosition_requiresPostName - 创建岗位需要岗位名称

**总计**: 26 个测试用例全部通过

---

## 三、前端实现

### 3.1 新增文件

#### API 接口
- `src/api/departments.ts` - 部门 API 调用封装
- `src/api/positions.ts` - 岗位 API 调用封装

#### 页面组件
- `src/views/AdminDepartmentsView.vue` - 部门管理页面
- `src/views/AdminPositionsView.vue` - 岗位管理页面

### 3.2 修改文件

- `src/router/index.ts` - 添加部门和岗位管理路由
- `src/layouts/AdminLayout.vue` - 添加菜单项

### 3.3 页面功能

#### 部门管理页面
- **列表展示**: 显示所有部门的 ID、部门代码、部门名称、父部门
- **搜索功能**: 支持按部门名称或代码搜索
- **新增部门**: 弹窗表单，支持设置父部门
- **编辑部门**: 修改部门信息
- **删除部门**: 带确认提示，受后端约束保护

#### 岗位管理页面
- **列表展示**: 显示所有岗位的 ID、岗位代码、岗位名称
- **搜索功能**: 支持按岗位名称或代码搜索
- **新增岗位**: 弹窗表单，岗位代码和名称必填
- **编辑岗位**: 修改岗位信息
- **删除岗位**: 带确认提示，受后端约束保护

### 3.4 管理员控制台菜单

| 菜单项 | 路径 | 说明 |
|--------|------|------|
| 用户管理 | `/admin/users` | 用户管理 |
| **部门管理** | `/admin/departments` | **部门增删改查** |
| **岗位管理** | `/admin/positions` | **岗位增删改查** |
| 流程管理 | `/admin/workflows` | 工作流管理 |
| 系统设置 | `/admin/settings` | 系统设置 |

---

## 四、数据库实体

### 4.1 SysDept (部门表)
```java
@Table(name = "sys_dept")
public class SysDept {
    private Long id;              // 主键
    private Long parentId;        // 父部门 ID
    private String deptCode;      // 部门代码（唯一）
    private String deptName;      // 部门名称
}
```

### 4.2 SysPost (岗位表)
```java
@Table(name = "sys_post")
public class SysPost {
    private Long id;              // 主键
    private String postCode;      // 岗位代码（唯一，必填）
    private String postName;      // 岗位名称
}
```

---

## 五、接口示例

### 5.1 创建部门
```bash
POST /api/departments
Content-Type: application/json
Authorization: Bearer <token>

{
  "deptCode": "IT",
  "deptName": "信息技术部",
  "parentId": 1
}
```

响应：
```json
{
  "id": 10,
  "deptCode": "IT",
  "deptName": "信息技术部",
  "parentId": 1
}
```

### 5.2 创建岗位
```bash
POST /api/positions
Content-Type: application/json
Authorization: Bearer <token>

{
  "postCode": "MANAGER",
  "postName": "经理"
}
```

响应：
```json
{
  "id": 5,
  "postCode": "MANAGER",
  "postName": "经理"
}
```

### 5.3 错误响应

#### 冲突错误 (409)
```json
{
  "error": "deptCode already exists: IT"
}
```

#### 权限错误 (403)
```json
{
  "error": "operator has no RBAC management permission"
}
```

#### 业务规则错误 (403)
```json
{
  "error": "Cannot delete department with child departments"
}
```

---

## 六、构建和测试验证

### 6.1 后端验证
```bash
# 编译
./mvnw clean compile

# 运行测试
./mvnw test -Dtest=DepartmentControllerIntegrationTests,PositionControllerIntegrationTests

# 运行全部测试
./mvnw test
```

**结果**: 85 个测试用例全部通过

### 6.2 前端验证
```bash
# 类型检查和构建
npm run build
```

**结果**: TypeScript 编译通过，构建成功

### 6.3 运行项目
```bash
# 后端
./mvnw spring-boot:run

# 前端
npm run dev
```

**运行状态**:
- 后端服务：http://localhost:8080 ✅
- 前端服务：http://localhost:5173 ✅

---

## 七、待优化事项

1. **部门树形结构展示**: 当前为扁平列表，可考虑改为树形表格
2. **批量操作**: 支持批量删除部门/岗位
3. **导入导出**: 支持 Excel 批量导入部门和岗位
4. **数据范围**: 部门管理可结合角色的数据权限范围
5. **岗位与角色关联**: 可考虑岗位与角色的关联关系

---

## 八、总结

本次实现完成了部门和岗位的完整 CRUD 功能，包括：
- ✅ 后端 RESTful API（5 个接口 × 2 = 10 个端点）
- ✅ 业务规则验证（唯一性、外键约束、删除保护）
- ✅ 权限控制（ADMIN/SYS_ADMIN 角色）
- ✅ 前端管理界面（Vue 3 + Element Plus）
- ✅ 完整的集成测试（26 个测试用例）
- ✅ 类型安全的 TypeScript API 封装

所有功能经过充分测试，可以正常使用。

---
