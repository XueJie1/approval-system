# 审批系统部署指南（MariaDB + Spring Boot + Vue）

本指南基于当前仓库与当前数据库快照编写，目标是：**在新机器上可一次性部署后端、前端与基础数据**。

## 1. 部署目标与组成

- 后端：Spring Boot 3（Java 17）
- 前端：Vue3 + Vite（Node.js 20+）
- 数据库：MariaDB 10.6+（或 MySQL 8+）
- 流程引擎：Flowable（由后端启动时自动建表 `ACT_*` / `FLW_*`）

---

## 2. 前置环境

建议版本：

- JDK：17
- Maven：3.9+
- Node.js：20+
- npm：10+
- MariaDB：10.6+

检查命令：

```bash
java -version
mvn -version
node -v
npm -v
mysql --version
```

---

## 3. 数据库部署（新机）

### 3.1 创建/导入核心业务表与基础数据

执行以下脚本（已包含建库、建表、基础主数据与流程配置数据）：

```bash
mysql -h <DB_HOST> -P <DB_PORT> -u <DB_USER> -p \
  < docs/sql/2026-04-22-deploy-master-snapshot.sql
```

> 脚本说明：
>
> - 文件：`docs/sql/2026-04-22-deploy-master-snapshot.sql`
> - 包含：`sys_*`、`form_*`、`request_template`、`workflow_*` 等核心表及当前基线数据
> - 不包含：Flowable 运行表（`ACT_*`、`FLW_*`），这些由后端自动创建
> - 不包含：业务运行历史（`biz_request*`、`ai_suggestion_record`）

### 3.2 验证导入结果

```sql
USE approval_system;
SELECT COUNT(*) AS dept_count FROM sys_dept;
SELECT COUNT(*) AS user_count FROM sys_user;
SELECT COUNT(*) AS workflow_version_count FROM workflow_definition_version;
```

当前基线应为：

- `sys_dept` = 17
- `sys_user` = 28
- `workflow_definition_version` = 12

---

## 4. 后端部署

## 4.1 构建

```bash
./mvnw clean package -DskipTests
```

生成产物：`target/approval-system-0.0.1-SNAPSHOT.jar`

### 4.2 关键环境变量

建议在生产环境显式配置：

```bash
export SPRING_DATASOURCE_URL='jdbc:mariadb://<DB_HOST>:3306/approval_system?useSSL=false&serverTimezone=UTC'
export SPRING_DATASOURCE_USERNAME='<DB_USER>'
export SPRING_DATASOURCE_PASSWORD='<DB_PASSWORD>'

# 必改（示例值仅演示）
export SECURITY_JWT_SECRET='replace-with-strong-random-secret-at-least-32-bytes'
export SETTINGS_CRYPTO_KEY='replace-with-strong-settings-crypto-key'

# 如需 OpenAI
export OPENAI_API_KEY='<YOUR_OPENAI_API_KEY>'
```

### 4.3 启动

```bash
java -jar target/approval-system-0.0.1-SNAPSHOT.jar
```

默认监听：`http://0.0.0.0:8080`

> 首次启动会自动补齐 Flowable 相关表。

---

## 5. 前端部署

在 `frontend/` 目录执行：

```bash
npm install
npm run build
```

构建产物：`frontend/dist/`

推荐用 Nginx 托管静态文件，并把 `/api/` 反向代理到后端 `:8080`。

Nginx 示例：

```nginx
server {
  listen 80;
  server_name _;

  root /opt/approval-system/frontend/dist;
  index index.html;

  location / {
    try_files $uri $uri/ /index.html;
  }

  location /api/ {
    proxy_pass http://127.0.0.1:8080/api/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

---

## 6. 上线后校验

- 打开前端登录页，确认可访问。
- 使用 `admin` 用户登录后台管理页。
- 在“用户管理/部门管理”中检查：直属主管、部门负责人已存在。
- 发起一条请假单，验证审批链可解析出：直属主管 / 部门负责人 / 上级部门负责人。

---

## 7. 备份与回滚建议

- 上线前备份数据库：

```bash
mysqldump -h <DB_HOST> -P <DB_PORT> -u <DB_USER> -p approval_system > approval_system_backup.sql
```

- 若需回滚，可恢复备份或重新执行基线脚本后再导入业务数据备份。

---

## 8. 安全注意事项（必须）

- 修改默认 JWT 密钥、配置加密密钥。
- 数据库账号不要使用 root，改为最小权限业务账号。
- 生产环境启用 HTTPS。
- 定期轮换 OpenAI/API 密钥并设置访问控制。
