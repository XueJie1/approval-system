# 认证鉴权体系实现文档

## 一、概述

本系统实现了完整的认证鉴权体系，包括：
- JWT 无状态认证
- 双因素认证 (2FA/TOTP)
- 恢复码机制
- 账户锁定保护
- 登录日志审计
- 基于角色的访问控制 (RBAC)

## 二、核心组件

### 2.1 JWT 认证服务 (`JwtService`)

**功能：**
- 生成访问令牌（有效期 120 分钟）
- 生成 2FA 挑战令牌（有效期 5 分钟）
- 解析和验证令牌
- 提取用户 ID 和角色信息

**令牌结构：**
```json
{
  "iss": "approval-system",
  "sub": "username",
  "uid": 1,
  "roles": ["EMPLOYEE"],
  "type": "ACCESS",
  "iat": 1709123456,
  "exp": 1709130656
}
```

### 2.2 TOTP 服务 (`TotpService`)

**功能：**
- 生成 TOTP 密钥（Base32 编码）
- 验证 TOTP 码（支持±1 时间窗口）
- 生成恢复码（10 个 8 位随机码）
- 验证恢复码（使用后立即失效）

**OTPAuth URI 格式：**
```
otpauth://totp/ApprovalSystem:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=ApprovalSystem&digits=6&period=30
```

### 2.3 认证服务 (`AuthService`)

**核心方法：**

| 方法 | 描述 | 返回 |
|------|------|------|
| `bootstrapAdmin` | 创建管理员账户 | `LoginResult` |
| `login` | 用户登录 | `LoginResult`（可能需要 2FA） |
| `verifyTwoFactor` | 验证 2FA 码 | `LoginResult` |
| `setupTwoFactor` | 获取 2FA 设置 | `TwoFactorSetup` |
| `enableTwoFactor` | 启用 2FA | - |
| `disableTwoFactor` | 禁用 2FA | - |
| `enableTwoFactorWithRecovery` | 启用 2FA 并生成恢复码 | `TwoFactorSetup` |
| `validateRecoveryCode` | 验证恢复码 | `boolean` |
| `getProfile` | 获取用户信息 | `Profile` |

**账户锁定机制：**
- 连续 5 次登录失败后锁定账户
- 锁定时间：30 分钟
- 锁定期间无法登录

### 2.4 认证过滤器 (`JwtAuthenticationFilter`)

**功能：**
- 拦截所有请求，提取 Bearer Token
- 验证 Token 有效性
- 设置 Spring Security 上下文
- 检查账户锁定状态
- 返回 423 状态码表示账户被锁定

## 三、API 接口

### 3.1 认证接口

#### 1. 初始化管理员
```http
POST /api/auth/bootstrap
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

**响应：**
```json
{
  "accessToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresIn": 7200,
  "userId": 1,
  "username": "admin",
  "roles": ["ADMIN", "SYS_ADMIN"],
  "twoFactorRequired": false
}
```

#### 2. 用户登录
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "user@example.com",
  "password": "password123"
}
```

**响应 1（无 2FA）：**
```json
{
  "accessToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresIn": 7200,
  "userId": 2,
  "username": "user@example.com",
  "roles": ["EMPLOYEE"],
  "twoFactorRequired": false
}
```

**响应 2（需要 2FA）：**
```json
{
  "twoFactorRequired": true,
  "challengeToken": "eyJ...",
  "expiresIn": 300
}
```

#### 3. 2FA 验证
```http
POST /api/auth/login/2fa
Content-Type: application/json

{
  "challengeToken": "eyJ...",
  "code": "123456"
}
```

#### 4. 使用恢复码
```http
POST /api/auth/2fa/recovery/validate
Content-Type: application/json

{
  "code": "1234-5678"
}
```

### 3.2 用户信息接口（需要认证）

#### 1. 获取当前用户信息
```http
GET /api/auth/me
Authorization: Bearer <token>
```

**响应：**
```json
{
  "userId": 2,
  "username": "user@example.com",
  "roles": ["EMPLOYEE"],
  "twoFactorEnabled": true,
  "hasRecoveryCodes": false
}
```

#### 2. 获取 2FA 设置
```http
GET /api/auth/2fa/setup
Authorization: Bearer <token>
```

**响应：**
```json
{
  "secret": "JBSWY3DPEHPK3PXP",
  "otpAuthUri": "otpauth://totp/...",
  "recoveryCodes": "1234-5678,ABCD-EFGH,..."
}
```

**注意：** 恢复码只显示一次，请妥善保管！

#### 3. 启用 2FA
```http
POST /api/auth/2fa/enable
Authorization: Bearer <token>
Content-Type: application/json

{
  "code": "123456"
}
```

#### 4. 禁用 2FA
```http
POST /api/auth/2fa/disable
Authorization: Bearer <token>
Content-Type: application/json

{
  "code": "123456"
}
```

### 3.3 登录日志接口（需要 ADMIN 权限）

#### 1. 查询登录日志
```http
GET /api/admin/login-logs?page=0&size=20&userId=1&loginStatus=0
```

**参数：**
- `page`: 页码（默认 0）
- `size`: 每页数量（默认 20）
- `userId`: 用户 ID（可选）
- `username`: 用户名（可选）
- `loginStatus`: 登录状态 0=成功 1=失败（可选）
- `startDate`: 开始日期（格式：YYYY-MM-DD，可选）
- `endDate`: 结束日期（格式：YYYY-MM-DD，可选）

**响应：**
```json
{
  "content": [
    {
      "id": 1,
      "userId": 2,
      "username": "user@example.com",
      "loginStatus": 0,
      "message": "login successful",
      "ipAddress": "192.168.1.100",
      "userAgent": "Mozilla/5.0...",
      "loginTime": "2026-03-06T21:30:00"
    }
  ],
  "total": 150,
  "page": 0,
  "size": 20,
  "totalPages": 8
}
```

#### 2. 查询单个日志
```http
GET /api/admin/login-logs/1
Authorization: Bearer <token>
```

## 四、数据库表结构

### 4.1 sys_user 扩展字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `two_factor_enabled` | TINYINT | 2FA 是否启用（0=否，1=是） |
| `two_factor_secret` | VARCHAR(128) | TOTP 密钥 |
| `recovery_codes` | VARCHAR(512) | 恢复码（逗号分隔） |
| `last_login_at` | DATETIME | 最后登录时间 |
| `login_failures` | INT | 登录失败次数 |
| `locked_until` | DATETIME | 账户锁定截止时间 |

### 4.2 sys_login_log（新增表）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `id` | BIGINT | 主键 |
| `user_id` | BIGINT | 用户 ID |
| `username` | VARCHAR(64) | 用户名 |
| `login_status` | TINYINT | 登录状态（0=成功，1=失败） |
| `message` | VARCHAR(512) | 消息 |
| `ip_address` | VARCHAR(64) | IP 地址 |
| `user_agent` | VARCHAR(512) | User-Agent |
| `login_time` | DATETIME | 登录时间 |

## 五、安全特性

### 5.1 密码安全
- 使用 BCrypt 加密存储
- 不支持明文密码
- 密码长度建议 8-128 字符

### 5.2 Token 安全
- 使用 HMAC-SHA256 签名
- 访问令牌有效期 120 分钟
- 2FA 挑战令牌有效期 5 分钟
- Token 类型校验（ACCESS/2FA_CHALLENGE）

### 5.3 账户保护
- 连续 5 次失败后锁定 30 分钟
- 登录失败记录 IP 和 User-Agent
- 支持恢复码应急登录

### 5.4 审计日志
- 记录所有登录尝试
- 记录 IP 地址和 User-Agent
- 支持按用户、状态、时间范围查询

## 六、使用流程

### 6.1 新用户注册和 2FA 启用流程

```
1. 管理员创建用户账号
   ↓
2. 用户首次登录
   ↓
3. 系统返回 2FA 设置（或引导启用）
   ↓
4. 用户获取 TOTP 设置（扫描二维码）
   ↓
5. 系统生成 10 个恢复码（只显示一次）
   ↓
6. 用户验证 TOTP 码启用 2FA
   ↓
7. 后续登录需要输入 2FA 码
```

### 6.2 2FA 失效应急流程

```
1. 用户无法访问 TOTP 应用
   ↓
2. 使用恢复码登录
   ↓
3. 系统验证恢复码成功
   ↓
4. 恢复码失效（一次性使用）
   ↓
5. 用户重新启用 2FA 并生成新恢复码
```

## 七、测试指南

### 7.1 测试页面
- 认证指南：`/auth-guide.html`
- 认证测试：`/test-auth.html`

### 7.2 测试步骤

1. **启动应用**
   ```bash
   ./mvnw spring-boot:run
   ```

2. **初始化管理员**
   ```bash
   curl -X POST http://localhost:8080/api/auth/bootstrap \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"admin123"}'
   ```

3. **创建测试用户**
   ```bash
   curl -X POST http://localhost:8080/api/rbac/users \
     -H "Authorization: Bearer <admin_token>" \
     -H "Content-Type: application/json" \
     -d '{"username":"test@example.com","password":"test123","roleCodes":["EMPLOYEE"]}'
   ```

4. **测试登录**
   ```bash
   curl -X POST http://localhost:8080/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username":"test@example.com","password":"test123"}'
   ```

5. **启用 2FA**
   ```bash
   # 获取设置
   curl -X GET http://localhost:8080/api/auth/2fa/setup \
     -H "Authorization: Bearer <token>"
   
   # 启用（需要输入当前 6 位 TOTP 码）
   curl -X POST http://localhost:8080/api/auth/2fa/enable \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{"code":"123456"}'
   ```

## 八、注意事项

1. **生产环境配置**
   - 修改 JWT 密钥（`security.jwt.secret`）
   - 配置 HTTPS
   - 设置合适的 Token 过期时间

2. **恢复码管理**
   - 恢复码只显示一次
   - 使用后立即失效
   - 建议打印或保存在安全位置

3. **账户锁定**
   - 锁定期间无法登录
   - 30 分钟后自动解锁
   - 管理员需关注异常登录尝试

4. **日志保留**
   - 建议定期清理旧日志
   - 生产环境考虑日志归档
