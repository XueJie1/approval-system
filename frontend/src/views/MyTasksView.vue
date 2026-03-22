<template>
  <div class="stack">
    <div>
      <h2 class="page-title">我的待办</h2>
      <p class="page-subtitle">支持认领、审批、委派、转办、回退、撤销，以及带追问和历史记录的 AI 建议</p>
    </div>

    <el-card shadow="never" class="panel">
      <div class="toolbar">
        <el-switch v-model="includeCandidate" active-text="包含候选任务" />
        <el-button type="primary" :loading="loading" @click="reload">刷新任务</el-button>
      </div>

      <el-table :data="tasks" border>
        <el-table-column prop="taskId" label="任务ID" min-width="240" show-overflow-tooltip />
        <el-table-column prop="taskName" label="任务名称" min-width="160" />
        <el-table-column prop="processInstanceId" label="流程实例" min-width="220" show-overflow-tooltip />
        <el-table-column prop="assignee" label="办理人" min-width="120" />
        <el-table-column label="操作" min-width="360">
          <template #default="scope">
            <div class="table-actions">
              <el-button size="small" @click="selectTask(scope.row.taskId)">选择</el-button>
              <el-button size="small" @click="claim(scope.row.taskId)">认领</el-button>
              <el-button
                size="small"
                type="primary"
                :loading="aiPanel.loading && aiPanel.taskId === scope.row.taskId"
                @click="openAi(scope.row.taskId)"
              >
                获取 AI 建议
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="never" class="panel">
      <template #header>任务操作面板</template>
      <div class="form-grid">
        <el-form-item label="任务ID">
          <el-input v-model="action.taskId" placeholder="先在列表点击“选择”" />
        </el-form-item>
        <el-form-item label="审批结果">
          <el-select v-model="action.approvalResult">
            <el-option label="同意" value="APPROVE" />
            <el-option label="拒绝" value="REJECT" />
          </el-select>
        </el-form-item>
        <el-form-item label="意见/原因">
          <el-input v-model="action.comment" type="textarea" :rows="3" placeholder="可手动编辑，也可由 AI 回填" />
        </el-form-item>
        <el-form-item label="委派人ID">
          <el-input v-model="action.delegateUserId" />
        </el-form-item>
        <el-form-item label="转办人ID">
          <el-input v-model="action.newAssigneeId" />
        </el-form-item>
        <el-form-item label="回退目标节点ID">
          <el-input v-model="action.targetActivityId" placeholder="如 countersignTask" />
        </el-form-item>
        <el-form-item label="撤销流程实例ID">
          <el-input v-model="action.processInstanceId" />
        </el-form-item>
      </div>

      <div class="ops">
        <el-button type="success" @click="complete">提交审批</el-button>
        <el-button type="warning" @click="delegate">委派</el-button>
        <el-button @click="resolve">委派处理完成</el-button>
        <el-button type="danger" plain @click="reassign">转办</el-button>
        <el-button plain @click="returnPrevious">回退上一步</el-button>
        <el-button plain @click="returnTarget">回退指定节点</el-button>
        <el-button plain @click="returnApplicant">回退发起人</el-button>
        <el-button type="danger" @click="cancel">撤销流程</el-button>
      </div>
    </el-card>

    <el-drawer
      v-model="aiPanel.open"
      title="AI 审批建议"
      direction="rtl"
      :size="'min(760px, 100vw)'"
      class="ai-drawer"
    >
      <div v-loading="aiPanel.loading" class="ai-shell">
        <div v-if="currentSuggestion" class="ai-content">
          <section class="hero-card">
            <div class="hero-head">
              <div>
                <div class="eyebrow">任务 {{ currentSuggestion.taskId }}</div>
                <h3>{{ decisionLabel(currentSuggestion.decision) }}</h3>
              </div>
              <div class="hero-tags">
                <el-tag type="success" v-if="currentSuggestion.decision === 'APPROVE'">建议通过</el-tag>
                <el-tag type="danger" v-else>建议拒绝</el-tag>
                <el-tag v-if="currentSuggestion.adopted" type="warning">已采纳</el-tag>
              </div>
            </div>
            <p class="hero-copy">{{ currentSuggestion.recommendation || currentSuggestion.summary }}</p>
            <div class="hero-meta">
              <span>model={{ currentSuggestion.model }}</span>
              <span>生成时间={{ currentSuggestion.generatedAt }}</span>
            </div>
          </section>

          <section class="ai-section">
            <div class="section-title">风险预警</div>
            <ul v-if="currentSuggestion.riskWarnings.length" class="bullet-list">
              <li v-for="item in currentSuggestion.riskWarnings" :key="item">{{ item }}</li>
            </ul>
            <p v-else class="empty-copy">未发现明显风险预警。</p>
          </section>

          <section class="ai-section">
            <div class="section-title">异常检测</div>
            <ul v-if="currentSuggestion.anomalies.length" class="bullet-list">
              <li v-for="item in currentSuggestion.anomalies" :key="item">{{ item }}</li>
            </ul>
            <p v-else class="empty-copy">未识别到明确异常。</p>
          </section>

          <section class="ai-section">
            <div class="section-title">补充信息</div>
            <ul v-if="currentSuggestion.supplementaryInfo.length" class="bullet-list">
              <li v-for="item in currentSuggestion.supplementaryInfo" :key="item">{{ item }}</li>
            </ul>
            <p v-else class="empty-copy">暂无补充信息。</p>
          </section>

          <section class="ai-section">
            <div class="section-title">建议填入</div>
            <div class="comment-box">{{ currentSuggestion.approvalComment }}</div>
            <div v-if="suggestedFieldEntries.length" class="suggested-fields">
              <div class="section-subtitle">建议补充字段</div>
              <div v-for="[key, value] in suggestedFieldEntries" :key="key" class="suggested-row">
                <span>{{ key }}</span>
                <code>{{ stringifyValue(value) }}</code>
              </div>
            </div>
          </section>

          <section class="ai-section">
            <div class="section-title">追问 AI</div>
            <div class="chat-list">
              <div v-if="currentSuggestion.conversation.length === 0" class="empty-copy">还没有追问记录。</div>
              <div v-for="item in currentSuggestion.conversation" :key="`${item.askedAt}-${item.question}`" class="chat-turn">
                <div class="chat-question">问：{{ item.question }}</div>
                <div class="chat-answer">答：{{ item.answer }}</div>
              </div>
            </div>
            <el-input
              v-model="aiPanel.question"
              type="textarea"
              :rows="3"
              resize="none"
              placeholder="例如：为什么你觉得这个申请有风险？"
            />
            <div class="drawer-actions">
              <el-button :loading="aiPanel.asking" type="primary" @click="askAi">追问 AI</el-button>
              <el-button :loading="aiPanel.adopting" @click="fillIntoForm">填入表单</el-button>
              <el-button @click="aiPanel.open = false">关闭</el-button>
            </div>
          </section>
        </div>

        <el-empty v-else description="请选择任务后获取 AI 建议" />

        <aside class="history-panel">
          <div class="history-head">
            <span>历史记录</span>
            <el-button text @click="reloadAiHistory">刷新</el-button>
          </div>
          <div v-if="suggestionHistory.length === 0" class="empty-copy">暂无历史记录。</div>
          <button
            v-for="item in suggestionHistory"
            :key="item.recordId"
            type="button"
            class="history-item"
            :class="{ active: currentSuggestion?.recordId === item.recordId }"
            @click="currentSuggestion = item"
          >
            <div class="history-top">
              <strong>{{ decisionLabel(item.decision) }}</strong>
              <span>{{ item.generatedAt }}</span>
            </div>
            <div class="history-summary">{{ item.recommendation || item.summary }}</div>
            <div class="history-meta">
              <span>采纳：{{ item.adopted ? "是" : "否" }}</span>
              <span>结果：{{ item.finalApprovalResult || "待定" }}</span>
            </div>
          </button>
        </aside>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from "vue";
import { ElMessage } from "element-plus";
import type { AiSuggestion, TaskInfo } from "../types";
import { useAuthStore } from "../stores/auth";
import {
  adoptAiSuggestion,
  aiSuggestion,
  aiSuggestionFollowUp,
  aiSuggestionHistory,
  cancelProcess,
  claimTask,
  completeTask,
  delegateTask,
  fetchTasks,
  reassignTask,
  resolveTask,
  returnToApplicant,
  returnToPrevious,
  returnToTarget
} from "../api/workflow";

const auth = useAuthStore();

const loading = ref(false);
const includeCandidate = ref(false);
const tasks = ref<TaskInfo[]>([]);
const suggestionHistory = ref<AiSuggestion[]>([]);
const currentSuggestion = ref<AiSuggestion | null>(null);

const action = reactive({
  taskId: "",
  approvalResult: "APPROVE",
  comment: "",
  delegateUserId: "",
  newAssigneeId: "",
  targetActivityId: "",
  processInstanceId: ""
});

const aiPanel = reactive({
  open: false,
  taskId: "",
  loading: false,
  asking: false,
  adopting: false,
  question: ""
});

const suggestedFieldEntries = computed(() => Object.entries(currentSuggestion.value?.suggestedFormUpdates ?? {}));

const currentUserId = () => String(auth.currentUser?.userId ?? "");

onMounted(() => {
  reload();
});

async function reload() {
  loading.value = true;
  try {
    tasks.value = await fetchTasks("", includeCandidate.value);
  } finally {
    loading.value = false;
  }
}

function selectTask(taskId: string) {
  action.taskId = taskId;
}

function decisionLabel(decision: string) {
  return decision === "APPROVE" ? "建议通过" : "建议拒绝";
}

function stringifyValue(value: unknown) {
  if (typeof value === "string") {
    return value;
  }
  return JSON.stringify(value);
}

function mergeHistory(primary: AiSuggestion, history: AiSuggestion[]) {
  const dedup = new Map<number, AiSuggestion>();
  [primary, ...history].forEach((item) => {
    dedup.set(item.recordId, item);
  });
  return Array.from(dedup.values()).sort((left, right) => (left.recordId < right.recordId ? 1 : -1));
}

async function loadAiHistory(taskId: string, primary?: AiSuggestion) {
  const history = await aiSuggestionHistory(taskId);
  suggestionHistory.value = primary ? mergeHistory(primary, history) : history;
}

async function openAi(taskId: string) {
  aiPanel.open = true;
  aiPanel.taskId = taskId;
  aiPanel.question = "";
  action.taskId = taskId;
  aiPanel.loading = true;
  currentSuggestion.value = null;
  try {
    const suggestion = await aiSuggestion(taskId);
    currentSuggestion.value = suggestion;
    await loadAiHistory(taskId, suggestion);
  } finally {
    aiPanel.loading = false;
  }
}

async function reloadAiHistory() {
  if (!aiPanel.taskId) {
    return;
  }
  aiPanel.loading = true;
  try {
    await loadAiHistory(aiPanel.taskId, currentSuggestion.value ?? undefined);
  } finally {
    aiPanel.loading = false;
  }
}

async function fillIntoForm() {
  if (!currentSuggestion.value) {
    return;
  }
  aiPanel.adopting = true;
  try {
    const adopted = await adoptAiSuggestion(currentSuggestion.value.taskId, currentSuggestion.value.recordId);
    currentSuggestion.value = adopted;
    action.taskId = adopted.taskId;
    action.approvalResult = adopted.decision === "APPROVE" ? "APPROVE" : "REJECT";
    action.comment = adopted.approvalComment;
    await loadAiHistory(adopted.taskId, adopted);
    ElMessage.success("AI 建议已填入审批意见框");
  } finally {
    aiPanel.adopting = false;
  }
}

async function askAi() {
  if (!currentSuggestion.value || !aiPanel.question.trim()) {
    ElMessage.warning("请输入追问内容");
    return;
  }
  aiPanel.asking = true;
  try {
    const updated = await aiSuggestionFollowUp(
      currentSuggestion.value.taskId,
      currentSuggestion.value.recordId,
      aiPanel.question.trim()
    );
    currentSuggestion.value = updated;
    aiPanel.question = "";
    await loadAiHistory(updated.taskId, updated);
  } finally {
    aiPanel.asking = false;
  }
}

async function claim(taskId: string) {
  await claimTask(taskId, currentUserId());
  ElMessage.success("已认领");
  await reload();
}

async function complete() {
  if (!action.taskId || !action.comment.trim()) {
    ElMessage.warning("任务ID和审批意见必填");
    return;
  }
  await completeTask(action.taskId, {
    userId: currentUserId(),
    approvalResult: action.approvalResult,
    comments: action.comment
  });
  ElMessage.success("审批已提交");
  await reload();
}

async function delegate() {
  if (!action.taskId || !action.delegateUserId.trim() || !action.comment.trim()) {
    ElMessage.warning("任务ID、委派人、意见必填");
    return;
  }
  await delegateTask(action.taskId, {
    userId: currentUserId(),
    delegateUserId: action.delegateUserId.trim(),
    comment: action.comment
  });
  ElMessage.success("任务已委派");
  await reload();
}

async function resolve() {
  if (!action.taskId || !action.comment.trim()) {
    ElMessage.warning("任务ID和意见必填");
    return;
  }
  await resolveTask(action.taskId, {
    userId: currentUserId(),
    approvalResult: action.approvalResult,
    comment: action.comment
  });
  ElMessage.success("委派处理完成");
  await reload();
}

async function reassign() {
  if (!action.taskId || !action.newAssigneeId.trim() || !action.comment.trim()) {
    ElMessage.warning("任务ID、转办人、意见必填");
    return;
  }
  await reassignTask(action.taskId, {
    userId: currentUserId(),
    newAssigneeId: action.newAssigneeId.trim(),
    comment: action.comment
  });
  ElMessage.success("任务已转办");
  await reload();
}

async function returnPrevious() {
  if (!action.taskId || !action.comment.trim()) {
    ElMessage.warning("任务ID和意见必填");
    return;
  }
  await returnToPrevious(action.taskId, { userId: currentUserId(), comment: action.comment });
  ElMessage.success("已回退到上一步");
  await reload();
}

async function returnTarget() {
  if (!action.taskId || !action.targetActivityId.trim() || !action.comment.trim()) {
    ElMessage.warning("任务ID、目标节点ID、意见必填");
    return;
  }
  await returnToTarget(action.taskId, {
    userId: currentUserId(),
    targetActivityId: action.targetActivityId.trim(),
    comment: action.comment
  });
  ElMessage.success("已回退到指定节点");
  await reload();
}

async function returnApplicant() {
  if (!action.taskId || !action.comment.trim()) {
    ElMessage.warning("任务ID和意见必填");
    return;
  }
  await returnToApplicant(action.taskId, { userId: currentUserId(), comment: action.comment });
  ElMessage.success("已回退到发起人");
  await reload();
}

async function cancel() {
  if (!action.processInstanceId.trim() || !action.comment.trim()) {
    ElMessage.warning("流程实例ID和撤销原因必填");
    return;
  }
  await cancelProcess(action.processInstanceId.trim(), {
    userId: currentUserId(),
    comment: action.comment
  });
  ElMessage.success("流程已撤销");
  await reload();
}
</script>

<style scoped>
.stack {
  display: grid;
  gap: 14px;
}

.panel {
  border-radius: 14px;
  border-color: #d8e4ed;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.table-actions {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.ops {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.ai-shell {
  display: grid;
  gap: 16px;
}

.ai-content {
  display: grid;
  gap: 14px;
}

.hero-card {
  background: linear-gradient(135deg, #fff3e8, #fffaf1);
  border: 1px solid #f1dcc3;
  border-radius: 18px;
  padding: 18px;
}

.hero-head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: flex-start;
}

.hero-head h3 {
  margin: 4px 0 0;
  font-size: 24px;
}

.hero-tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.eyebrow {
  color: #9a5f29;
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.hero-copy {
  margin: 12px 0 0;
  color: #4b3621;
  line-height: 1.7;
}

.hero-meta {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 12px;
  color: #7c6a58;
  font-size: 12px;
}

.ai-section {
  border: 1px solid #d8e4ed;
  border-radius: 14px;
  padding: 14px;
  background: #fff;
}

.section-title {
  font-size: 15px;
  font-weight: 700;
  margin-bottom: 10px;
}

.section-subtitle {
  font-size: 13px;
  font-weight: 700;
  margin-bottom: 8px;
}

.bullet-list {
  margin: 0;
  padding-left: 18px;
  display: grid;
  gap: 6px;
}

.empty-copy {
  margin: 0;
  color: #64748b;
}

.comment-box {
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 12px;
  padding: 12px;
  white-space: pre-wrap;
  line-height: 1.7;
}

.suggested-fields {
  margin-top: 12px;
}

.suggested-row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 0;
  border-top: 1px solid #e5edf5;
}

.chat-list {
  display: grid;
  gap: 10px;
  margin-bottom: 12px;
}

.chat-turn {
  border-left: 3px solid #d6b48d;
  background: #fcfaf6;
  padding: 10px 12px;
  border-radius: 0 10px 10px 0;
}

.chat-question {
  font-weight: 700;
  margin-bottom: 6px;
}

.chat-answer {
  color: #3f3f46;
  line-height: 1.7;
}

.drawer-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 12px;
}

.history-panel {
  border-top: 1px solid #e2e8f0;
  padding-top: 12px;
  display: grid;
  gap: 10px;
}

.history-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.history-item {
  border: 1px solid #d9e2ec;
  background: #fff;
  border-radius: 12px;
  padding: 12px;
  text-align: left;
  cursor: pointer;
}

.history-item.active {
  border-color: #c57b37;
  background: #fff7ef;
}

.history-top,
.history-meta {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 12px;
}

.history-summary {
  margin: 8px 0;
  color: #334155;
  line-height: 1.6;
}

@media (max-width: 768px) {
  .toolbar {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .hero-head,
  .suggested-row,
  .history-top,
  .history-meta {
    flex-direction: column;
  }
}
</style>
