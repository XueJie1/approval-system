<template>
  <div class="request-page">
    <header class="page-header">
      <div>
        <h1>我的申请</h1>
        <p>查看你发起的所有申请，跟踪审批进度和结果</p>
      </div>
      <el-button type="primary" :icon="Plus" @click="$router.push('/user/start')">发起申请</el-button>
    </header>

    <div class="status-tabs">
      <button
        v-for="tab in statusTabs"
        :key="tab.value"
        class="status-tab"
        :class="{ active: statusFilter === tab.value }"
        @click="statusFilter = tab.value"
      >
        <span class="tab-label">{{ tab.label }}</span>
        <span class="tab-count">{{ getCountByStatus(tab.value) }}</span>
      </button>
    </div>

    <div v-loading="loading" class="request-list">
      <el-empty v-if="filteredRequests.length === 0" description="暂无申请记录">
        <el-button type="primary" @click="$router.push('/user/start')">发起第一条申请</el-button>
      </el-empty>

      <div
        v-for="req in filteredRequests"
        :key="req.id"
        class="request-card"
        @click="openDetail(req)"
      >
        <div class="request-header">
          <div class="request-title">{{ req.title || '未命名申请' }}</div>
          <el-tag :type="getStatusTagType(req.status)" size="small">
            {{ getStatusLabel(req.status) }}
          </el-tag>
        </div>
        <div class="request-body">
          <div class="request-info">
            <span class="info-item">
              <el-icon><Document /></el-icon>
              {{ req.businessKey?.slice(0, 12) || '-' }}
            </span>
            <span class="info-item">
              <el-icon><Clock /></el-icon>
              {{ formatTime(req.submitTime || req.createdAt) }}
            </span>
          </div>
          <div v-if="req.currentTaskId" class="current-task">
            当前环节：{{ getCurrentTaskName(req.currentTaskId) }}
          </div>
        </div>
      </div>
    </div>

    <el-drawer
      v-model="detailDrawer.open"
      :title="selectedRequest?.title || '申请详情'"
      direction="rtl"
      size="600px"
    >
      <div v-if="selectedRequest" class="detail-content">
        <section class="detail-section">
          <div class="section-label">基本信息</div>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">业务单号</span>
              <span class="info-value">{{ selectedRequest.businessKey }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">流程实例</span>
              <span class="info-value">{{ selectedRequest.processInstanceId || '-' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">申请状态</span>
              <el-tag :type="getStatusTagType(selectedRequest.status)">
                {{ getStatusLabel(selectedRequest.status) }}
              </el-tag>
            </div>
            <div class="info-item">
              <span class="info-label">提交时间</span>
              <span class="info-value">{{ formatTime(selectedRequest.submitTime) }}</span>
            </div>
            <div v-if="selectedRequest.finishTime" class="info-item">
              <span class="info-label">完成时间</span>
              <span class="info-value">{{ formatTime(selectedRequest.finishTime) }}</span>
            </div>
          </div>
        </section>

        <section v-if="selectedRelatedTasks.length > 0" class="detail-section">
          <div class="section-label">任务列表</div>
          <div class="task-list">
            <div v-for="task in selectedRelatedTasks" :key="task.taskId" class="task-item">
              <div class="task-name">{{ task.taskName }}</div>
              <div class="task-meta">
                <span>办理人：{{ task.assignee || '待分配' }}</span>
              </div>
            </div>
          </div>
        </section>

        <section class="detail-section">
          <div class="section-label">审批日志</div>
          <div v-if="selectedRelatedLogs.length === 0" class="empty-hint">暂无审批日志</div>
          <el-timeline v-else>
            <el-timeline-item
              v-for="log in selectedRelatedLogs"
              :key="log.id"
              :timestamp="formatTime(log.createdAt)"
              placement="top"
            >
              <div class="log-item">
                <div class="log-action">
                  <el-tag size="small" :type="getActionTagType(log.action)">{{ log.action }}</el-tag>
                </div>
                <div v-if="log.comment" class="log-comment">{{ log.comment }}</div>
              </div>
            </el-timeline-item>
          </el-timeline>
        </section>

        <section v-if="selectedRelatedAiSuggestions.length > 0" class="detail-section">
          <div class="section-label">AI 建议记录</div>
          <div class="ai-records">
            <div v-for="ai in selectedRelatedAiSuggestions" :key="ai.recordId" class="ai-record">
              <div class="ai-header">
                <el-tag :type="ai.decision === 'APPROVE' ? 'success' : 'danger'" size="small">
                  {{ ai.decision === 'APPROVE' ? '建议通过' : '建议拒绝' }}
                </el-tag>
                <span class="ai-time">{{ formatTime(ai.generatedAt) }}</span>
              </div>
              <p class="ai-summary">{{ ai.recommendation || ai.summary }}</p>
              <div v-if="ai.adopted" class="ai-adopted">
                <el-icon><Select /></el-icon> 已采纳
              </div>
            </div>
          </div>
        </section>

        <section class="detail-section">
          <div class="section-label">操作</div>
          <div class="action-buttons">
            <el-button
              v-if="selectedRequest.status === 0"
              type="primary"
              @click="continueDraft"
            >
              继续编辑
            </el-button>
            <el-button
              v-if="selectedRequest.status === 2 && selectedRequest.processInstanceId"
              type="danger"
              plain
              @click="cancelProcess"
            >
              撤销申请
            </el-button>
            <el-button
              v-if="selectedRequest.status === 5"
              type="warning"
              @click="$router.push('/user/start')"
            >
              修改并重提
            </el-button>
          </div>
        </section>
      </div>

      <template #footer>
        <el-button @click="detailDrawer.open = false">关闭</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Document, Clock, Plus, Select } from '@element-plus/icons-vue';
import { useRouter } from 'vue-router';
import type { AiSuggestion, BizRequest, RequestLog, TaskInfo } from '../types';
import { listAiSuggestions, listRequestLogs, listRequestTasks, listRequests } from '../api/requests';
import { cancelProcess as cancelProcessApi } from '../api/workflow';
import { useAuthStore } from '../stores/auth';

const router = useRouter();
const auth = useAuthStore();

const loading = ref(false);
const allRequests = ref<BizRequest[]>([]);
const relatedTasks = ref<TaskInfo[]>([]);
const relatedLogs = ref<RequestLog[]>([]);
const relatedAiSuggestions = ref<AiSuggestion[]>([]);
const selectedRequest = ref<BizRequest | null>(null);

const statusFilter = ref<number | undefined>(undefined);

const detailDrawer = reactive({
  open: false
});

const statusTabs = [
  { label: '全部', value: undefined },
  { label: '草稿', value: 0 },
  { label: '审批中', value: 2 },
  { label: '已通过', value: 3 },
  { label: '已拒绝', value: 4 },
  { label: '已退回', value: 5 },
  { label: '已撤销', value: 6 }
];

const filteredRequests = computed(() => {
  if (statusFilter.value === undefined) {
    return allRequests.value;
  }
  return allRequests.value.filter(r => r.status === statusFilter.value);
});

const selectedRelatedTasks = computed(() => {
  const processInstanceId = selectedRequest.value?.processInstanceId;
  if (!processInstanceId) {
    return [] as TaskInfo[];
  }
  return relatedTasks.value.filter(task => task.processInstanceId === processInstanceId);
});

const selectedRelatedLogs = computed(() => {
  const request = selectedRequest.value;
  if (!request) {
    return [] as RequestLog[];
  }
  return relatedLogs.value
    .filter((log) => {
      if (log.businessKey !== request.businessKey) {
        return false;
      }
      if (!request.processInstanceId) {
        return true;
      }
      return !log.processInstanceId || log.processInstanceId === request.processInstanceId;
    })
    .sort((a, b) => Date.parse(b.createdAt || '') - Date.parse(a.createdAt || ''));
});

const selectedRelatedAiSuggestions = computed(() => {
  const request = selectedRequest.value;
  if (!request) {
    return [] as AiSuggestion[];
  }
  return relatedAiSuggestions.value
    .filter((item) => {
      if (item.businessKey !== request.businessKey) {
        return false;
      }
      if (!request.processInstanceId) {
        return true;
      }
      return !item.processInstanceId || item.processInstanceId === request.processInstanceId;
    })
    .sort((a, b) => Date.parse(b.generatedAt || '') - Date.parse(a.generatedAt || ''));
});

onMounted(() => {
  reload();
});

watch(statusFilter, () => {
  // 筛选是前端过滤，无需重新请求
});

function getCountByStatus(status: number | undefined) {
  if (status === undefined) {
    return allRequests.value.length;
  }
  return allRequests.value.filter(r => r.status === status).length;
}

function getStatusLabel(status: number) {
  const map: Record<number, string> = {
    0: '草稿',
    1: '待提交',
    2: '审批中',
    3: '已通过',
    4: '已拒绝',
    5: '已退回',
    6: '已撤销',
    7: '已挂起'
  };
  return map[status] ?? `状态${status}`;
}

function getStatusTagType(status: number): '' | 'success' | 'warning' | 'danger' | 'info' {
  if (status === 3) return 'success';
  if (status === 4) return 'danger';
  if (status === 5) return 'warning';
  if (status === 2) return 'info';
  if (status === 0) return '';
  return 'info';
}

function getActionTagType(action: string): '' | 'success' | 'warning' | 'danger' | 'info' {
  if (action === 'APPROVE' || action === 'SUBMIT') return 'success';
  if (action === 'REJECT') return 'danger';
  if (action === 'RETURN' || action === 'DELEGATE') return 'warning';
  return 'info';
}

function formatTime(time?: string) {
  if (!time) return '-';
  const d = new Date(time);
  return d.toLocaleString('zh-CN', { hour12: false });
}

function getCurrentTaskName(taskId: string) {
  const task = relatedTasks.value.find(t => t.taskId === taskId);
  return task?.taskName || '审批中';
}

async function reload() {
  loading.value = true;
  try {
    allRequests.value = await listRequests({});
    const tasks = await listRequestTasks({});
    relatedTasks.value = tasks;
    const logs = await listRequestLogs({});
    relatedLogs.value = logs;
    const ais = await listAiSuggestions({});
    relatedAiSuggestions.value = ais;
  } catch (e) {
    console.error(e);
    ElMessage.error('加载失败');
  } finally {
    loading.value = false;
  }
}

async function openDetail(req: BizRequest) {
  selectedRequest.value = req;
  detailDrawer.open = true;
}

function continueDraft() {
  if (!selectedRequest.value) return;
  router.push({
    path: '/user/start',
    query: { businessKey: selectedRequest.value.businessKey }
  });
}

async function cancelProcess() {
  if (!selectedRequest.value?.processInstanceId) return;

  try {
    const { value } = await ElMessageBox.prompt('请输入撤销原因', '撤销申请', {
      confirmButtonText: '确认撤销',
      cancelButtonText: '取消',
      inputPattern: /.+/,
      inputErrorMessage: '请输入撤销原因'
    });

    await cancelProcessApi(selectedRequest.value.processInstanceId, {
      userId: String(auth.currentUser?.userId ?? ''),
      comment: value
    });

    ElMessage.success('申请已撤销');
    detailDrawer.open = false;
    await reload();
  } catch (e) {
    if (e !== 'cancel') {
      console.error(e);
      ElMessage.error('撤销失败');
    }
  }
}
</script>

<style scoped>
.request-page {
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

.status-tabs {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.status-tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 14px;
}

.status-tab:hover {
  border-color: #3b82f6;
}

.status-tab.active {
  background: #3b82f6;
  border-color: #3b82f6;
  color: #fff;
}

.tab-count {
  padding: 2px 8px;
  background: rgba(0, 0, 0, 0.06);
  border-radius: 10px;
  font-size: 12px;
}

.status-tab.active .tab-count {
  background: rgba(255, 255, 255, 0.2);
}

.request-list {
  display: grid;
  gap: 12px;
}

.request-card {
  padding: 16px 20px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.request-card:hover {
  border-color: #3b82f6;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.1);
}

.request-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.request-title {
  font-size: 16px;
  font-weight: 500;
}

.request-body {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.request-info {
  display: flex;
  gap: 16px;
  color: #64748b;
  font-size: 13px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.current-task {
  color: #3b82f6;
  font-size: 13px;
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

.task-list {
  display: grid;
  gap: 8px;
}

.task-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: #f8fafc;
  border-radius: 8px;
}

.task-name {
  font-weight: 500;
}

.task-meta {
  font-size: 13px;
  color: #64748b;
}

.empty-hint {
  color: #94a3b8;
  font-size: 14px;
}

.log-item {
  display: grid;
  gap: 4px;
}

.log-comment {
  color: #64748b;
  font-size: 13px;
}

.ai-records {
  display: grid;
  gap: 12px;
}

.ai-record {
  padding: 12px;
  background: #f8fafc;
  border-radius: 8px;
}

.ai-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.ai-time {
  font-size: 12px;
  color: #94a3b8;
}

.ai-summary {
  margin: 0;
  font-size: 13px;
  line-height: 1.5;
}

.ai-adopted {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-top: 8px;
  font-size: 13px;
  color: #16a34a;
}

.action-buttons {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
  }

  .status-tabs {
    overflow-x: auto;
    flex-wrap: nowrap;
    padding-bottom: 8px;
  }

  .status-tab {
    flex-shrink: 0;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .request-body {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
