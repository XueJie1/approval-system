# 测试覆盖补充说明

日期：2026-03-17  
分支：`qwen3.5-35b-vibe`  
提交：`7895e30`  
主题：为当前已实现功能补齐集成测试与基础安全/运行环境测试

## 1. 本次完成内容

本次工作的目标不是新增业务功能，而是为仓库中已经存在的接口与核心能力补充可执行测试，覆盖当前真正落地的实现范围。

本次新增了以下测试文件：

- [AbstractIntegrationTestSupport.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/AbstractIntegrationTestSupport.java)
- [BootstrapAuthIntegrationTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/BootstrapAuthIntegrationTests.java)
- [AuthControllerIntegrationTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/AuthControllerIntegrationTests.java)
- [RbacControllerIntegrationTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/RbacControllerIntegrationTests.java)
- [FormControllerIntegrationTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/FormControllerIntegrationTests.java)
- [WorkflowControllerIntegrationTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/WorkflowControllerIntegrationTests.java)
- [RequestControllerIntegrationTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/RequestControllerIntegrationTests.java)
- [LoginLogControllerIntegrationTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/LoginLogControllerIntegrationTests.java)
- [SecurityServiceTests.java](/home/cao/workspace/graduation_project/approval-system/src/test/java/com/flowablecollab/approval_system/SecurityServiceTests.java)

同时补充了测试运行所需配置：

- [application-test.yml](/home/cao/workspace/graduation_project/approval-system/src/test/resources/application-test.yml)
- [org.mockito.plugins.MockMaker](/home/cao/workspace/graduation_project/approval-system/src/test/resources/mockito-extensions/org.mockito.plugins.MockMaker)

## 2. 覆盖范围

### 2.1 认证与安全

覆盖内容：

- 管理员 bootstrap 初始化
- 用户名密码登录
- 2FA challenge 登录流转
- 2FA setup / enable / disable
- recovery code 生成与校验
- `/api/auth/me`
- JWT access token / challenge token 解析
- TOTP secret / URI / recovery code 生成
- 登录日志请求头提取逻辑

对应文件：

- [AuthController.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/controller/AuthController.java)
- [AuthService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/AuthService.java)
- [JwtService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/security/JwtService.java)
- [TotpService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/security/TotpService.java)
- [LoginLogService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/LoginLogService.java)

### 2.2 RBAC

覆盖内容：

- 创建用户
- 创建角色
- 创建部门
- 创建岗位
- 分配角色
- 分配岗位
- 添加角色数据范围
- 非管理员访问受限
- DTO 参数校验

对应文件：

- [RbacController.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/controller/RbacController.java)
- [RbacService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/RbacService.java)

### 2.3 动态表单

覆盖内容：

- 创建表单定义
- 创建表单版本
- 替换字段定义
- 查询最新版本
- 查询字段列表
- 表单校验成功场景
- 表单校验失败场景
- 创建表单实例

对应文件：

- [FormController.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/controller/FormController.java)
- [FormService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/FormService.java)

### 2.4 工作流接口

覆盖内容：

- 发起单人审批流程
- 查询任务
- 认领任务
- 完成任务
- 委派
- resolve
- 转办
- 回退到当前审批节点
- 回退到申请人
- 回退到指定节点
- 回退到上一步
- 撤销流程

对应文件：

- [WorkflowController.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/controller/WorkflowController.java)
- [WorkflowService.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java)

### 2.5 请求视图与日志视图

覆盖内容：

- 按 SELF 数据范围查看申请单
- 查看可见任务/流程/日志聚合接口
- 管理员代查指定用户数据
- 登录日志分页与详情
- 非管理员访问登录日志被拒绝

对应文件：

- [RequestController.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/controller/RequestController.java)
- [LoginLogController.java](/home/cao/workspace/graduation_project/approval-system/src/main/java/com/flowablecollab/approval_system/controller/LoginLogController.java)

## 3. 处理中遇到的问题

### 3.1 H2 测试上下文重复启动冲突

问题现象：

- 某些测试类在重建 Spring 上下文后，Hibernate/Flowable 对同一个内存库再次初始化时会报元数据相关错误。

处理方式：

- 将 [application-test.yml](/home/cao/workspace/graduation_project/approval-system/src/test/resources/application-test.yml) 中的 H2 URL 改为带 `${random.uuid}` 的唯一数据库名。

效果：

- 每个测试上下文使用独立内存库，避免不同测试类之间相互污染。

### 3.2 Mockito inline mock maker 在当前 JVM 无法自附加

问题现象：

- Spring Test 的 `ResetMocksTestExecutionListener` 在当前环境下触发 Mockito 初始化时失败，报错为 Byte Buddy agent 无法 attach 到当前 JVM。

处理方式：

- 增加 [org.mockito.plugins.MockMaker](/home/cao/workspace/graduation_project/approval-system/src/test/resources/mockito-extensions/org.mockito.plugins.MockMaker)，强制使用 `mock-maker-subclass`。

效果：

- 测试环境不再依赖 inline instrumentation，Spring Boot 测试监听器可正常执行。

### 3.3 测试断言需要与现有实现语义对齐

在补测试过程中，还修正了两类“测试假设”和“现有代码真实语义”不一致的问题：

- `schemaJson` 是字符串字段，因此测试请求体必须做正确 JSON 转义
- `RequestController` 的可见范围是基于“被查询用户”的数据范围计算，而不是基于调用者的数据范围

这两处最终通过调整测试输入修复，而不是改动现有业务代码。

## 4. 最终执行结果

执行命令：

```bash
./mvnw -q -Dtest=BootstrapAuthIntegrationTests,AuthControllerIntegrationTests,RbacControllerIntegrationTests,FormControllerIntegrationTests,WorkflowControllerIntegrationTests,RequestControllerIntegrationTests,LoginLogControllerIntegrationTests,SecurityServiceTests,WorkflowBugRegressionTests,WorkflowContractRegressionTests,ApprovalSystemApplicationTests test
```

结果：

- 共 `25` 个测试
- `0 failures`
- `0 errors`
- `0 skipped`

Surefire 报告见：

- [target/surefire-reports](/home/cao/workspace/graduation_project/approval-system/target/surefire-reports)

## 5. 结果说明

本次补充后，项目不再只有上下文启动和少量回归测试，而是已经具备一套覆盖主要已实现接口的集成测试基线。  
这套基线更适合继续迭代认证、RBAC、表单和工作流逻辑，也能更早暴露控制器参数约束、权限拦截、流程状态和测试环境配置问题。

需要说明的是，本次测试覆盖仍然只针对“当前已实现能力”。以下范围仍未覆盖或尚未实现：

- AI 能力
- 可视化流程设计器
- 更完整的前端交互测试
- 更细粒度的会签自动结束留痕验证
- 更深的异常/边界/性能测试

## 6. 提交记录

本次修改已提交：

- 提交号：`7895e30`
- 提交信息：`Add integration coverage for implemented APIs`
