<template>
  <div class="task-page">
    <header class="page-header">
      <div>
        <h1>我的待办</h1>
        <p>处理需要你审批或办理的任务，支持同意、拒绝、委派、转办、回退等操作</p>
      </div>
      <div class="header-actions">
        <el-switch v-model="includeCandidate" active-text="显示候选任务" />
        <el-button type="primary" :icon="Refresh" :loading="loading" @click="reload">刷新</el-button>
      </div>
    </header>

    <el-empty v-if="!loading && tasks.length === 0" description="暂无待办任务">
      <el-button type="primary" @click="$router.push('/user/start')">发起申请</el-button>
    </el-empty>

    <div v-else class="task-list">
      <div
        v-for="task in tasks"
        :key="task.taskId"
        class="task-card"
        :class="{ selected: selectedTaskId === task.taskId }"
        @click="selectTask(task)"
      >
        <div class="task-main">
          <div class="task-title">{{ task.requestTitle || task.taskName || '审批任务' }}</div>
          <div class="task-meta">
            <span class="meta-item">
              <el-icon><Document /></el-icon>
              {{ task.processInstanceId?.slice(0, 8) || '-' }}
            </span>
            <span class="meta-item">
              <el-icon><User /></el-icon>
              {{ task.assignee || '待认领' }}
            </span>
            <span class="meta-item">
              <el-icon><Clock /></el-icon>
              {{ formatTime(task.createTime) }}
            </span>
          </div>
        </div>
        <div class="task-status">
          <el-tag v-if="!task.assignee" type="warning" size="small">待认领</el-tag>
          <el-tag v-else-if="task.delegationState === 'PENDING' && isCurrentIdentity(task.assignee)" type="warning" size="small">待委派处理</el-tag>
          <el-tag v-else-if="task.delegationState === 'RESOLVED' && isCurrentIdentity(task.owner)" type="success" size="small">待最终确认</el-tag>
          <el-tag v-else type="info" size="small">待处理</el-tag>
        </div>
      </div>
    </div>

    <el-drawer
      v-model="detailDrawer.open"
      :title="selectedTask?.requestTitle || selectedTask?.taskName || '任务详情'"
      direction="rtl"
      size="560px"
      :close-on-click-modal="false"
    >
      <div v-if="selectedTask" class="detail-content">
        <section class="detail-section">
          <div class="section-label">任务信息</div>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">任务编号</span>
              <span class="info-value">{{ selectedTask.taskId }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">流程实例</span>
              <span class="info-value">{{ selectedTask.processInstanceId }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">当前办理人</span>
              <span class="info-value">{{ selectedTask.assignee || '待认领' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">任务所有者</span>
              <span class="info-value">{{ selectedTask.owner || '-' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">创建时间</span>
              <span class="info-value">{{ formatTime(selectedTask.createTime) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">委派状态</span>
              <span class="info-value">{{ delegationStateLabel(selectedTask.delegationState) }}</span>
            </div>
          </div>
        </section>

        <section class="detail-section">
          <div class="section-label">审批操作</div>
          
          <div v-if="!selectedTask.assignee" class="action-hint">
            <el-alert type="info" :closable="false" show-icon>
              此任务需要先认领才能处理
            </el-alert>
            <el-button type="primary" size="large" :loading="actionLoading" @click="claimTask">
              认领任务
            </el-button>
          </div>

          <div v-else-if="canResolveDelegatedTask(selectedTask)" class="action-form">
            <el-alert type="warning" :closable="false" show-icon title="该任务已委派给你，请先执行“委派处理”，任务会返回原委派人做最终确认。" />
            <el-form label-position="top">
              <el-form-item label="处理结论" required>
                <el-radio-group v-model="action.approvalResult" size="large">
                  <el-radio-button label="APPROVE">
                    <el-icon><Select /></el-icon> 同意
                  </el-radio-button>
                  <el-radio-button label="REJECT">
                    <el-icon><CloseBold /></el-icon> 拒绝
                  </el-radio-button>
                </el-radio-group>
              </el-form-item>

              <el-form-item label="处理意见" required>
                <el-input
                  v-model="action.comment"
                  type="textarea"
                  :rows="3"
                  placeholder="请输入委派处理意见"
                />
              </el-form-item>

              <el-button
                type="warning"
                size="large"
                :loading="actionLoading"
                :disabled="!action.comment.trim()"
                @click="handleResolveTask"
              >
                委派处理
              </el-button>
            </el-form>
          </div>

          <div v-else class="action-form">
            <el-alert
              v-if="canCompleteDelegatedTask(selectedTask)"
              type="success"
              :closable="false"
              show-icon
              title="被委派人已处理完成，请你提交最终审批结果。"
            />
            <el-form label-position="top">
              <el-form-item label="审批决定" required>
                <el-radio-group v-model="action.approvalResult" size="large">
                  <el-radio-button label="APPROVE">
                    <el-icon><Select /></el-icon> 同意
                  </el-radio-button>
                  <el-radio-button label="REJECT">
                    <el-icon><CloseBold /></el-icon> 拒绝
                  </el-radio-button>
                </el-radio-group>
              </el-form-item>

              <el-form-item label="审批意见" required>
                <el-input
                  v-model="action.comment"
                  type="textarea"
                  :rows="3"
                  placeholder="请输入审批意见，说明同意或拒绝的原因"
                />
              </el-form-item>

              <el-button
                type="primary"
                size="large"
                :loading="actionLoading"
                :disabled="!action.comment.trim()"
                @click="completeTask"
              >
                {{ canCompleteDelegatedTask(selectedTask) ? '提交最终审批' : '提交审批' }}
              </el-button>
            </el-form>
          </div>
        </section>

        <section v-if="selectedTask.assignee && !canResolveDelegatedTask(selectedTask)" class="detail-section">
          <div class="section-label">更多操作</div>
          <div class="more-actions">
            <el-collapse>
              <el-collapse-item title="委派给他人" name="delegate">
                <div class="collapse-form">
                  <p class="collapse-hint">将任务临时委派给他人处理，处理后返回给你确认</p>
                  <el-input v-model="action.delegateUserId" placeholder="输入被委派人ID" />
                  <el-button
                    type="warning"
                    :loading="actionLoading"
                    :disabled="!action.delegateUserId.trim() || !action.comment.trim()"
                    @click="handleDelegateTask"
                  >
                    确认委派
                  </el-button>
                </div>
              </el-collapse-item>

              <el-collapse-item title="转办给他人" name="reassign">
                <div class="collapse-form">
                  <p class="collapse-hint">将任务永久转给他人处理，责任转移</p>
                  <el-input v-model="action.newAssigneeId" placeholder="输入转办人ID" />
                  <el-button
                    type="danger"
                    plain
                    :loading="actionLoading"
                    :disabled="!action.newAssigneeId.trim() || !action.comment.trim()"
                    @click="handleReassignTask"
                  >
                    确认转办
                  </el-button>
                </div>
              </el-collapse-item>

              <el-collapse-item title="回退" name="return">
                <div class="collapse-form">
                  <p class="collapse-hint">将任务退回到指定环节重新处理</p>
                  <div class="return-buttons">
                    <el-button :loading="actionLoading" :disabled="!action.comment.trim()" @click="returnPrevious">
                      回退上一步
                    </el-button>
                    <el-button :loading="actionLoading" :disabled="!action.comment.trim()" @click="returnApplicant">
                      回退发起人
                    </el-button>
                  </div>
                  <el-input
                    v-model="action.targetActivityId"
                    placeholder="指定节点ID（如 countersignTask）"
                    style="margin-top: 12px"
                  />
                  <el-button
                    :loading="actionLoading"
                    :disabled="!action.targetActivityId.trim() || !action.comment.trim()"
                    style="margin-top: 8px"
                    @click="returnTarget"
                  >
                    回退指定节点
                  </el-button>
                </div>
              </el-collapse-item>
            </el-collapse>
          </div>
        </section>

        <section class="detail-section">
          <div class="section-label">
            <span>AI 审批建议</span>
            <el-button
              type="primary"
              size="small"
              :loading="aiPanel.loading"
              @click="loadAiSuggestion"
            >
              获取建议
            </el-button>
          </div>

          <div v-if="aiPanel.loading" class="ai-loading">
            <el-icon class="is-loading"><Loading /></el-icon>
            正在生成建议...
          </div>

          <div v-else-if="currentSuggestion" class="ai-suggestion">
            <div class="ai-decision" :class="{ approve: currentSuggestion.decision === 'APPROVE' }">
              <el-icon v-if="currentSuggestion.decision === 'APPROVE'"><CircleCheck /></el-icon>
              <el-icon v-else><CircleClose /></el-icon>
              <span>{{ currentSuggestion.decision === 'APPROVE' ? '建议通过' : '建议拒绝' }}</span>
            </div>

            <div class="ai-content">
              <p class="ai-summary">{{ currentSuggestion.recommendation || currentSuggestion.summary }}</p>

              <div v-if="currentSuggestion.riskWarnings?.length" class="ai-warnings">
                <div class="warning-label">风险提示</div>
                <ul>
                  <li v-for="(w, i) in currentSuggestion.riskWarnings" :key="i">{{ w }}</li>
                </ul>
              </div>

              <div v-if="currentSuggestion.approvalComment" class="ai-comment">
                <div class="comment-label">建议审批意见</div>
                <div class="comment-text">{{ currentSuggestion.approvalComment }}</div>
                <el-button size="small" @click="adoptAiComment">采用此意见</el-button>
              </div>

              <div v-if="currentSuggestion.conversation?.length" class="ai-history">
                <div class="history-label">追问记录</div>
                <div v-for="(turn, i) in currentSuggestion.conversation" :key="i" class="conversation-turn">
                  <div class="question">问：{{ turn.question }}</div>
                  <div class="answer">答：{{ turn.answer }}</div>
                </div>
              </div>

              <div class="ai-follow-up">
                <el-input
                  v-model="aiPanel.question"
                  placeholder="追问 AI..."
                  @keyup.enter="askAi"
                />
                <el-button type="primary" :loading="aiPanel.asking" @click="askAi">追问</el-button>
              </div>
            </div>
          </div>

          <el-empty v-else description="点击上方按钮获取 AI 审批建议" :image-size="64" />
        </section>
      </div>

      <template #footer>
        <el-button @click="detailDrawer.open = false">关闭</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue';
import { ElMessage } from 'element-plus';
import {
  Clock,
  Document,
  User,
  Refresh,
  Select,
  CloseBold,
  CircleCheck,
  CircleClose,
  Loading
} from '@element-plus/icons-vue';
import type { AiSuggestion, TaskInfo } from '../types';
import { useAuthStore } from '../stores/auth';
import {
  fetchTasks,
  claimTask as claimTaskApi,
  completeTask as completeTaskApi,
  delegateTask as delegateTaskApi,
  resolveTask as resolveTaskApi,
  reassignTask as reassignTaskApi,
  returnToPrevious,
  returnToTarget,
  returnToApplicant,
  aiSuggestion,
  aiSuggestionFollowUp
} from '../api/workflow';

const auth = useAuthStore();

const loading = ref(false);
const actionLoading = ref(false);
const includeCandidate = ref(false);
const tasks = ref<TaskInfo[]>([]);
const selectedTaskId = ref<string>('');
const selectedTask = ref<TaskInfo | null>(null);
const currentSuggestion = ref<AiSuggestion | null>(null);

const detailDrawer = reactive({
  open: false
});

const action = reactive({
  approvalResult: 'APPROVE',
  comment: '',
  delegateUserId: '',
  newAssigneeId: '',
  targetActivityId: ''
});

const aiPanel = reactive({
  loading: false,
  asking: false,
  question: ''
});

onMounted(() => {
  reload();
});

async function reload() {
  loading.value = true;
  try {
    tasks.value = await fetchTasks('', includeCandidate.value);
  } catch (e) {
    console.error(e);
    ElMessage.error('加载任务失败');
  } finally {
    loading.value = false;
  }
}

function selectTask(task: TaskInfo) {
  selectedTaskId.value = task.taskId;
  selectedTask.value = task;
  action.approvalResult = 'APPROVE';
  action.comment = '';
  action.delegateUserId = '';
  action.newAssigneeId = '';
  action.targetActivityId = '';
  currentSuggestion.value = null;
  detailDrawer.open = true;
}

function formatTime(time?: string | Date) {
  if (!time) return '-';
  const d = typeof time === 'string' ? new Date(time) : time;
  return d.toLocaleString('zh-CN', { hour12: false });
}

function currentUserId() {
  return String(auth.currentUser?.userId ?? '');
}

function currentUsername() {
  return auth.currentUser?.username ?? '';
}

function isCurrentIdentity(identity?: string) {
  if (!identity || !identity.trim()) {
    return false;
  }
  const normalized = identity.trim();
  return normalized === currentUserId() || normalized === currentUsername();
}

function canResolveDelegatedTask(task: TaskInfo) {
  return task.delegationState === 'PENDING' && isCurrentIdentity(task.assignee);
}

function canCompleteDelegatedTask(task: TaskInfo) {
  return task.delegationState === 'RESOLVED' && isCurrentIdentity(task.owner);
}

function delegationStateLabel(state?: string) {
  if (!state) {
    return '无';
  }
  if (state === 'PENDING') {
    return '委派处理中';
  }
  if (state === 'RESOLVED') {
    return '已委派处理';
  }
  return state;
}

async function claimTask() {
  if (!selectedTask.value) return;
  actionLoading.value = true;
  try {
    await claimTaskApi(selectedTask.value.taskId, currentUserId());
    ElMessage.success('认领成功');
    await reload();
    const updated = tasks.value.find(t => t.taskId === selectedTaskId.value);
    if (updated) {
      selectedTask.value = updated;
    }
  } catch (e) {
    console.error(e);
    ElMessage.error('认领失败');
  } finally {
    actionLoading.value = false;
  }
}

async function completeTask() {
  if (!selectedTask.value || !action.comment.trim()) return;
  actionLoading.value = true;
  try {
    await completeTaskApi(selectedTask.value.taskId, {
      userId: currentUserId(),
      approvalResult: action.approvalResult,
      comments: action.comment.trim()
    });
    ElMessage.success('审批已提交');
    detailDrawer.open = false;
    await reload();
  } catch (e) {
    console.error(e);
    ElMessage.error('审批提交失败');
  } finally {
    actionLoading.value = false;
  }
}

async function handleResolveTask() {
  if (!selectedTask.value || !action.comment.trim()) return;
  actionLoading.value = true;
  try {
    await resolveTaskApi(selectedTask.value.taskId, {
      userId: currentUserId(),
      approvalResult: action.approvalResult,
      comment: action.comment.trim()
    });
    ElMessage.success('委派处理已提交，任务已返回委派人');
    detailDrawer.open = false;
    await reload();
  } catch (e) {
    console.error(e);
    ElMessage.error('委派处理失败');
  } finally {
    actionLoading.value = false;
  }
}

async function handleDelegateTask() {
  if (!selectedTask.value || !action.delegateUserId.trim() || !action.comment.trim()) return;
  actionLoading.value = true;
  try {
    await delegateTaskApi(selectedTask.value.taskId, {
      userId: currentUserId(),
      delegateUserId: action.delegateUserId.trim(),
      comment: action.comment.trim()
    });
    ElMessage.success('委派成功');
    detailDrawer.open = false;
    await reload();
  } catch (e) {
    console.error(e);
    ElMessage.error('委派失败');
  } finally {
    actionLoading.value = false;
  }
}

async function handleReassignTask() {
  if (!selectedTask.value || !action.newAssigneeId.trim() || !action.comment.trim()) return;
  actionLoading.value = true;
  try {
    await reassignTaskApi(selectedTask.value.taskId, {
      userId: currentUserId(),
      newAssigneeId: action.newAssigneeId.trim(),
      comment: action.comment.trim()
    });
    ElMessage.success('转办成功');
    detailDrawer.open = false;
    await reload();
  } catch (e) {
    console.error(e);
    ElMessage.error('转办失败');
  } finally {
    actionLoading.value = false;
  }
}

async function returnPrevious() {
  if (!selectedTask.value || !action.comment.trim()) return;
  actionLoading.value = true;
  try {
    await returnToPrevious(selectedTask.value.taskId, {
      userId: currentUserId(),
      comment: action.comment.trim()
    });
    ElMessage.success('已回退到上一步');
    detailDrawer.open = false;
    await reload();
  } catch (e) {
    console.error(e);
    ElMessage.error('回退失败');
  } finally {
    actionLoading.value = false;
  }
}

async function returnTarget() {
  if (!selectedTask.value || !action.targetActivityId.trim() || !action.comment.trim()) return;
  actionLoading.value = true;
  try {
    await returnToTarget(selectedTask.value.taskId, {
      userId: currentUserId(),
      targetActivityId: action.targetActivityId.trim(),
      comment: action.comment.trim()
    });
    ElMessage.success('已回退到指定节点');
    detailDrawer.open = false;
    await reload();
  } catch (e) {
    console.error(e);
    ElMessage.error('回退失败');
  } finally {
    actionLoading.value = false;
  }
}

async function returnApplicant() {
  if (!selectedTask.value || !action.comment.trim()) return;
  actionLoading.value = true;
  try {
    await returnToApplicant(selectedTask.value.taskId, {
      userId: currentUserId(),
      comment: action.comment.trim()
    });
    ElMessage.success('已回退到发起人');
    detailDrawer.open = false;
    await reload();
  } catch (e) {
    console.error(e);
    ElMessage.error('回退失败');
  } finally {
    actionLoading.value = false;
  }
}

async function loadAiSuggestion() {
  if (!selectedTask.value) return;
  aiPanel.loading = true;
  try {
    currentSuggestion.value = await aiSuggestion(selectedTask.value.taskId);
  } catch (e) {
    console.error(e);
    ElMessage.error('获取 AI 建议失败');
  } finally {
    aiPanel.loading = false;
  }
}

function adoptAiComment() {
  if (!currentSuggestion.value?.approvalComment) return;
  action.comment = currentSuggestion.value.approvalComment;
  if (currentSuggestion.value.decision) {
    action.approvalResult = currentSuggestion.value.decision;
  }
  ElMessage.success('已填入 AI 建议意见');
}

async function askAi() {
  if (!selectedTask.value || !currentSuggestion.value || !aiPanel.question.trim()) return;
  aiPanel.asking = true;
  try {
    currentSuggestion.value = await aiSuggestionFollowUp(
      selectedTask.value.taskId,
      currentSuggestion.value.recordId,
      aiPanel.question.trim()
    );
    aiPanel.question = '';
    ElMessage.success('追问成功');
  } catch (e) {
    console.error(e);
    ElMessage.error('追问失败');
  } finally {
    aiPanel.asking = false;
  }
}
</script>

<style scoped>
.task-page {
  display: grid;
  gap: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.page-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.page-header p {
  margin: 4px 0 0;
  color: #64748b;
  font-size: 14px;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.task-list {
  display: grid;
  gap: 12px;
}

.task-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.task-card:hover {
  border-color: #3b82f6;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.1);
}

.task-card.selected {
  border-color: #3b82f6;
  background: #eff6ff;
}

.task-main {
  display: grid;
  gap: 8px;
}

.task-title {
  font-size: 16px;
  font-weight: 500;
}

.task-meta {
  display: flex;
  gap: 16px;
  color: #64748b;
  font-size: 13px;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.task-status {
  flex-shrink: 0;
}

.detail-content {
  display: grid;
  gap: 24px;
}

.detail-section {
  display: grid;
  gap: 12px;
}

.section-label {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 15px;
  font-weight: 600;
  color: #1e293b;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.info-item {
  display: grid;
  gap: 4px;
}

.info-label {
  font-size: 12px;
  color: #64748b;
}

.info-value {
  font-size: 14px;
  word-break: break-all;
}

.action-hint {
  display: grid;
  gap: 16px;
}

.action-form {
  display: grid;
  gap: 16px;
}

.more-actions {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.collapse-form {
  display: grid;
  gap: 12px;
}

.collapse-hint {
  margin: 0;
  font-size: 13px;
  color: #64748b;
}

.return-buttons {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.ai-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 32px;
  color: #64748b;
}

.ai-suggestion {
  display: grid;
  gap: 16px;
}

.ai-decision {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  background: #fef2f2;
  border-radius: 8px;
  font-weight: 600;
  color: #dc2626;
}

.ai-decision.approve {
  background: #f0fdf4;
  color: #16a34a;
}

.ai-content {
  display: grid;
  gap: 12px;
}

.ai-summary {
  margin: 0;
  line-height: 1.6;
}

.ai-warnings,
.ai-comment,
.ai-history {
  padding: 12px;
  background: #f8fafc;
  border-radius: 8px;
}

.warning-label,
.comment-label,
.history-label {
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 8px;
}

.ai-warnings ul {
  margin: 0;
  padding-left: 20px;
}

.ai-warnings li {
  color: #dc2626;
  margin: 4px 0;
}

.comment-text {
  white-space: pre-wrap;
  margin-bottom: 12px;
  padding: 8px;
  background: #fff;
  border-radius: 6px;
  border: 1px dashed #cbd5e1;
}

.conversation-turn {
  padding: 8px 0;
  border-bottom: 1px solid #e2e8f0;
}

.conversation-turn:last-child {
  border-bottom: none;
}

.question {
  font-weight: 500;
  margin-bottom: 4px;
}

.answer {
  color: #64748b;
  font-size: 13px;
}

.ai-follow-up {
  display: flex;
  gap: 8px;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .task-card {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
}
</style>
