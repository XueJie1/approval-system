# OpenAI Provider 与 AI 建议能力实现说明

日期：2026-03-18  
分支：`qwen3.5-35b-vibe`

## 1. 目标

在既有 AI 建议最小闭环基础上，补齐真实 LLM provider（HTTP/OpenAI）并支持配置切换，同时补充可回归测试。

## 2. 本轮实现内容

### 2.1 LLM 抽象与 Provider 落地

新增统一抽象：

- `src/main/java/com/flowablecollab/approval_system/service/ai/LlmClient.java`

保留并支持 mock provider：

- `src/main/java/com/flowablecollab/approval_system/service/ai/MockLlmClient.java`

新增 OpenAI provider：

- `src/main/java/com/flowablecollab/approval_system/service/ai/OpenAiLlmClient.java`

实现要点：

- 使用 `RestTemplate` 调用 `POST {base-url}/chat/completions`
- Header 使用 `Authorization: Bearer <api-key>`
- 通过系统提示词要求模型返回严格 JSON：`decision/summary/riskFlags/followUpChecks`
- 解析模型输出时支持：
  - 纯 JSON 文本
  - Markdown fenced JSON（```json ... ```）
- `decision` 仅允许 `APPROVE|REJECT|REVIEW`，否则降级为 `REVIEW`
- 调用失败或解析失败时抛出可定位异常

### 2.2 Provider 配置切换

配置文件：

- `src/main/resources/application.yml`

新增配置项：

```yaml
ai:
  llm:
    provider: mock
    mock-model: mock-approval-advisor-v1
    openai:
      base-url: https://api.openai.com/v1
      api-key: ${OPENAI_API_KEY:}
      model: gpt-5.4-mini
      temperature: 0.2
      connect-timeout-seconds: 10
      read-timeout-seconds: 30
```

切换规则：

- `provider=mock` -> 启用 `MockLlmClient`
- `provider=openai` -> 启用 `OpenAiLlmClient`

### 2.3 审批建议接口与权限（已接入）

接口：

- `GET /api/workflow/tasks/{taskId}/ai-suggestion`

服务接入：

- `src/main/java/com/flowablecollab/approval_system/service/WorkflowService.java`
- `src/main/java/com/flowablecollab/approval_system/controller/WorkflowController.java`
- `src/main/java/com/flowablecollab/approval_system/service/ai/ApprovalSuggestionService.java`

权限约束：

- 仅 `assignee/candidate/admin` 可读 AI 建议

前端展示：

- `src/main/resources/static/index.html`
- 新增「获取AI建议」按钮和只读展示区（建议结论、风险提示、复核建议、模型与生成时间）

## 3. 测试补充

新增测试文件：

- `src/test/java/com/flowablecollab/approval_system/service/ai/OpenAiLlmClientTests.java`
- `src/test/java/com/flowablecollab/approval_system/service/ai/LlmProviderConfigurationTests.java`

已有集成测试增强：

- `src/test/java/com/flowablecollab/approval_system/WorkflowControllerIntegrationTests.java`

覆盖点：

1. OpenAI provider 请求与返回解析
2. Markdown fenced JSON 解析兼容
3. OpenAI API key 缺失时失败
4. `provider=mock/openai` 条件装配切换
5. AI 建议接口：
   - assignee 可访问
   - 无关用户被拒绝（403）

## 4. 验证结果

执行：

```bash
./mvnw -q -Dtest=OpenAiLlmClientTests,LlmProviderConfigurationTests test
./mvnw -q test
```

结果：

- 全部通过，`0 failures`, `0 errors`
- 当前总测试数：`45`

## 5. 使用说明

### 使用 mock（默认）

```yaml
ai.llm.provider: mock
```

### 使用 OpenAI

```yaml
ai.llm.provider: openai
ai.llm.openai.model: gpt-5.4-mini
```

并设置环境变量：

```bash
export OPENAI_API_KEY=<your_key>
```

## 6. 后续建议

1. 在 `OpenAiLlmClient` 增加重试与幂等请求 ID（降低外部网络抖动影响）
2. 为 AI 建议增加请求/响应审计脱敏落库
3. 支持不同流程类型的专用提示词模板
