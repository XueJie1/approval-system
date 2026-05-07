

## WORKING MEMORY
[2026-04-11T08:35:47.171Z] 修复 admin/workflows 两个前端问题：BpmnVisualDesigner 改为优先导入 normalize 后 XML（避免内置流程缺 DI 时失败），移除 import.done 的重复报错触发；新增画布布局等待+fitToViewport 与 ResizeObserver/canvas.resized，CSS 强制 djs svg 宽高 100% 并 display:block。frontend build 通过，vitest 无测试文件。

[2026-04-11T08:53:39.064Z] 修复 BPMN 可视化空白与保存无效：BpmnVisualDesigner 在缺失 BPMNDI 时自动为单流程生成基础 DI（shape/edge/waypoint）并 fit viewport；AdminWorkflowsView 的可视化“保存”改为调用 saveVersionDraft 持久化。frontend build 通过，vitest 仍无测试文件。
[2026-04-15T14:57:56.166Z] 实现“个人设置-修改密码”：新增 /api/auth/password/change（需当前密码，限制非 ADMIN/SYS_ADMIN），AuthService 校验旧密码+长度+不同密码并更新哈希；前端新增 ChangePasswordPanel 并在 ProfileView 显示（管理员改为提示去用户管理重置）。新增 AuthControllerIntegrationTests 两条用例（普通用户改密成功且新旧密码登录校验、管理员受限）。验证：frontend npm run build/test 通过；./mvnw test 全量 160 tests 通过。
[2026-04-15T15:25:21.870Z] 新增管理员 OpenAI Provider 模型选择：后端 settings 持久化 ai.llm.openai.model，OpenAiLlmClient 改为运行时读取模型；新增 POST /api/admin/settings/ai/openai/models（按 baseUrl/apiKey 拉取 [baseUrl]/models 并返回去重排序列表）。前端 AdminSettingsView 新增模型下拉+刷新模型列表按钮并提交 model 字段。新增/更新 AdminSettingsControllerIntegrationTests 和 OpenAiLlmClientTests。验证通过：frontend build+vitest，backend ./mvnw test 全量 161 tests 通过。
[2026-04-15T15:47:28.557Z] 修复管理员模型列表拉取失败：AiProviderSettingsService.listOpenAiModels 现在会在报错信息中包含具体 endpoint 与底层原因；当 baseUrl 为 https://localhost 或 https://127.0.0.1 且失败时，自动回退到 http 同地址重试（用于本地网关实际仅 HTTP 场景）。新增集成测试覆盖 https localhost -> http 回退。验证：./mvnw -Dtest=AdminSettingsControllerIntegrationTests test 与 ./mvnw test 全量 162 tests 通过。