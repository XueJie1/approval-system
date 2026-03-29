# 管理员界面与普通用户主页分离 - 实现文档

## 实现日期
2025-03-29

## 实现概述

根据导师建议和项目需求，将原单一布局拆分为独立的管理员控制台和普通用户界面，实现更清晰的用户角色分离。

---

## 变更文件清单

### 新建文件
| 文件路径 | 说明 |
|----------|------|
| `frontend/src/layouts/UserLayout.vue` | 普通用户专用布局组件 |
| `frontend/src/layouts/AdminLayout.vue` | 管理员专用布局组件 |
| `frontend/src/views/AdminWorkflowsView.vue` | 流程管理页面（占位） |
| `frontend/src/views/AdminSettingsView.vue` | 系统设置页面（占位） |

### 修改文件
| 文件路径 | 修改内容 |
|----------|----------|
| `frontend/src/router/index.ts` | 重构路由结构，分离 `/user/*` 和 `/admin/*` 路径 |
| `frontend/src/views/LoginView.vue` | 登录成功后根据角色跳转到对应入口 |
| `frontend/src/views/BootstrapView.vue` | 初始化后跳转到 `/admin` |

### 删除文件
| 文件路径 | 说明 |
|----------|------|
| `frontend/src/layouts/AppShell.vue` | 原统一布局，被两个新布局替代 |

---

## 路由结构

### 普通用户界面 (`/user/*`)
| 路径 | 名称 | 组件 | 功能 |
|------|------|------|------|
| `/user` | - | UserLayout | 重定向到 `/user/start` |
| `/user/start` | user-start | StartRequestView | 发起申请 |
| `/user/tasks` | user-tasks | MyTasksView | 我的待办 |
| `/user/requests` | user-requests | MyRequestsView | 我的申请 |
| `/user/profile` | user-profile | ProfileView | 个人中心 |

### 管理员界面 (`/admin/*`)
| 路径 | 名称 | 组件 | 功能 |
|------|------|------|------|
| `/admin` | - | AdminLayout | 重定向到 `/admin/users` |
| `/admin/users` | admin-users | AdminUsersView | 用户管理 |
| `/admin/workflows` | admin-workflows | AdminWorkflowsView | 流程管理（预留） |
| `/admin/settings` | admin-settings | AdminSettingsView | 系统设置（预留） |

---

## 权限控制逻辑

### 路由守卫
```typescript
// 1. 未登录访问需认证页面 → 跳转 /login
// 2. 已登录访问登录页 → 根据角色跳转 /admin 或 /user
// 3. 访问管理员页面但无权限 → 跳转 /user/start
```

### 角色判断
```typescript
const isAdmin = roles.some(role => role === "ADMIN" || role === "SYS_ADMIN");
```

---

## 布局差异

| 特性 | UserLayout | AdminLayout |
|------|------------|-------------|
| 品牌标题 | Flowable 审批台 | 管理员控制台 |
| 侧边栏样式 | 浅绿色渐变 | 深蓝色渐变 |
| 角色标签颜色 | 绿色 | 橙色 |
| 菜单项 | 发起申请、我的待办、我的申请、个人中心 | 用户管理、流程管理、系统设置 |

---

## 验证结果

### 编译测试
```bash
npm run build
# ✓ built in 3.57s
```

### 功能验证清单
- [x] 路由结构正确分离
- [x] 登录页面根据角色跳转
- [x] 管理员初始化后跳转至 `/admin`
- [x] TypeScript 编译通过
- [x] Vite 打包成功

### 待验证场景（需运行时测试）
- [ ] 普通用户登录后进入 `/user/start`
- [ ] 管理员登录后进入 `/admin/users`
- [ ] 普通用户直接访问 `/admin/*` 被重定向
- [ ] 未登录访问受保护路由跳转 `/login`

---

## 后续优化建议

1. **流程管理页面实现** - 集成 bpmn-js 实现工作流可视化编辑
2. **系统设置页面实现** - 系统参数配置、日志审计等功能
3. **管理员可访问用户功能** - 当前管理员只能访问 `/admin/*`，可考虑增加管理员访问用户功能的入口
4. **布局动态切换** - 可根据用户偏好或屏幕尺寸动态调整布局样式

---

## 技术备注

- 使用 Vue 3 + TypeScript + Element Plus
- 路由使用 Vue Router 4
- 状态管理使用 Pinia
- 权限控制在路由守卫层实现，不依赖视图层条件渲染
