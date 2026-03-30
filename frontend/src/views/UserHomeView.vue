<template>
  <div class="home-page">
    <header class="page-header">
      <div>
        <h1>工作台</h1>
        <p>{{ greeting }}，{{ auth.currentUser?.username || '用户' }}。今天要处理什么？</p>
      </div>
      <div class="quick-actions">
        <el-button type="primary" :icon="Plus" @click="goStart">发起申请</el-button>
        <el-button :icon="List" @click="goTasks">查看待办</el-button>
      </div>
    </header>

    <div class="metric-cards">
      <div class="metric-card" @click="goTasks">
        <div class="metric-icon pending">
          <el-icon><Clock /></el-icon>
        </div>
        <div class="metric-info">
          <div class="metric-value">{{ taskCount }}</div>
          <div class="metric-label">待办任务</div>
        </div>
      </div>

      <div class="metric-card" @click="goRequests(2)">
        <div class="metric-icon processing">
          <el-icon><Loading /></el-icon>
        </div>
        <div class="metric-info">
          <div class="metric-value">{{ processingCount }}</div>
          <div class="metric-label">审批中</div>
        </div>
      </div>

      <div class="metric-card" @click="goRequests(5)">
        <div class="metric-icon returned">
          <el-icon><RefreshLeft /></el-icon>
        </div>
        <div class="metric-info">
          <div class="metric-value">{{ returnedCount }}</div>
          <div class="metric-label">已退回</div>
        </div>
      </div>

      <div class="metric-card" @click="goRequests(3)">
        <div class="metric-icon approved">
          <el-icon><CircleCheck /></el-icon>
        </div>
        <div class="metric-info">
          <div class="metric-value">{{ approvedCount }}</div>
          <div class="metric-label">已通过</div>
        </div>
      </div>
    </div>

    <div class="content-grid">
      <el-card shadow="never" class="recent-card">
        <template #header>
          <div class="card-header">
            <span>最近申请</span>
            <el-button text type="primary" @click="goRequests()">查看全部</el-button>
          </div>
        </template>

        <el-empty v-if="recentRequests.length === 0" description="暂无申请记录" :image-size="64">
          <el-button type="primary" @click="goStart">发起第一条申请</el-button>
        </el-empty>

        <div v-else class="recent-list">
          <div
            v-for="req in recentRequests"
            :key="req.id"
            class="recent-item"
            @click="goRequests(req.status)"
          >
            <div class="recent-main">
              <div class="recent-title">{{ req.title || '未命名申请' }}</div>
              <div class="recent-meta">
                <span>{{ req.businessKey?.slice(0, 10) }}</span>
                <span>{{ formatTime(req.submitTime || req.createdAt) }}</span>
              </div>
            </div>
            <el-tag :type="getStatusTagType(req.status)" size="small">
              {{ getStatusLabel(req.status) }}
            </el-tag>
          </div>
        </div>
      </el-card>

      <el-card shadow="never" class="task-card">
        <template #header>
          <div class="card-header">
            <span>待办任务</span>
            <el-button text type="primary" @click="goTasks">查看全部</el-button>
          </div>
        </template>

        <el-empty v-if="recentTasks.length === 0" description="暂无待办任务" :image-size="64" />

        <div v-else class="task-list">
          <div
            v-for="task in recentTasks"
            :key="task.taskId"
            class="task-item"
            @click="goTasks"
          >
            <div class="task-icon">
              <el-icon><Document /></el-icon>
            </div>
            <div class="task-main">
              <div class="task-name">{{ task.taskName }}</div>
              <div class="task-meta">
                <span>{{ task.assignee || '待认领' }}</span>
                <span>{{ formatTime(task.createTime) }}</span>
              </div>
            </div>
            <el-tag v-if="!task.assignee" type="warning" size="small">待认领</el-tag>
            <el-tag v-else type="info" size="small">待处理</el-tag>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { Plus, List, Clock, Loading, RefreshLeft, CircleCheck, Document } from '@element-plus/icons-vue';
import { useAuthStore } from '../stores/auth';
import type { BizRequest, TaskInfo } from '../types';
import { listRequests } from '../api/requests';
import { fetchTasks } from '../api/workflow';

const router = useRouter();
const auth = useAuthStore();

const allRequests = ref<BizRequest[]>([]);
const allTasks = ref<TaskInfo[]>([]);

const taskCount = computed(() => allTasks.value.length);
const processingCount = computed(() => allRequests.value.filter(r => r.status === 2).length);
const returnedCount = computed(() => allRequests.value.filter(r => r.status === 5).length);
const approvedCount = computed(() => allRequests.value.filter(r => r.status === 3).length);

const recentRequests = computed(() => {
  return [...allRequests.value]
    .sort((a, b) => {
      const timeA = a.updatedAt ? new Date(a.updatedAt).getTime() : 0;
      const timeB = b.updatedAt ? new Date(b.updatedAt).getTime() : 0;
      return timeB - timeA;
    })
    .slice(0, 5);
});

const recentTasks = computed(() => {
  return allTasks.value.slice(0, 5);
});

const greeting = computed(() => {
  const hour = new Date().getHours();
  if (hour < 6) return '夜深了';
  if (hour < 12) return '上午好';
  if (hour < 14) return '中午好';
  if (hour < 18) return '下午好';
  if (hour < 22) return '晚上好';
  return '夜深了';
});

onMounted(async () => {
  await Promise.all([
    loadRequests(),
    loadTasks()
  ]);
});

async function loadRequests() {
  try {
    allRequests.value = await listRequests({});
  } catch (e) {
    console.error('加载申请失败', e);
  }
}

async function loadTasks() {
  try {
    allTasks.value = await fetchTasks('', true);
  } catch (e) {
    console.error('加载任务失败', e);
  }
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

function formatTime(time?: string | Date) {
  if (!time) return '-';
  const d = typeof time === 'string' ? new Date(time) : time;
  const now = new Date();
  const diff = now.getTime() - d.getTime();
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  if (days === 0) {
    const hours = Math.floor(diff / (1000 * 60 * 60));
    if (hours === 0) {
      const minutes = Math.floor(diff / (1000 * 60));
      return minutes <= 1 ? '刚刚' : `${minutes}分钟前`;
    }
    return `${hours}小时前`;
  }
  if (days === 1) return '昨天';
  if (days < 7) return `${days}天前`;
  return d.toLocaleDateString('zh-CN');
}

function goStart() {
  router.push('/user/start');
}

function goTasks() {
  router.push('/user/tasks');
}

function goRequests(status?: number) {
  if (status !== undefined) {
    router.push({ path: '/user/requests', query: { status: String(status) } });
  } else {
    router.push('/user/requests');
  }
}
</script>

<style scoped>
.home-page {
  display: grid;
  gap: 24px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.page-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 700;
}

.page-header p {
  margin: 8px 0 0;
  color: #64748b;
  font-size: 15px;
}

.quick-actions {
  display: flex;
  gap: 8px;
}

.metric-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.metric-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.metric-card:hover {
  border-color: #3b82f6;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.1);
  transform: translateY(-2px);
}

.metric-icon {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  font-size: 24px;
}

.metric-icon.pending {
  background: #fef3c7;
  color: #d97706;
}

.metric-icon.processing {
  background: #dbeafe;
  color: #2563eb;
}

.metric-icon.returned {
  background: #fee2e2;
  color: #dc2626;
}

.metric-icon.approved {
  background: #d1fae5;
  color: #059669;
}

.metric-info {
  display: grid;
  gap: 4px;
}

.metric-value {
  font-size: 28px;
  font-weight: 700;
  line-height: 1;
}

.metric-label {
  font-size: 13px;
  color: #64748b;
}

.content-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.recent-card,
.task-card {
  border-radius: 12px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.recent-list,
.task-list {
  display: grid;
  gap: 8px;
}

.recent-item,
.task-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #f8fafc;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.recent-item:hover,
.task-item:hover {
  background: #f1f5f9;
}

.recent-main,
.task-main {
  display: grid;
  gap: 4px;
  overflow: hidden;
}

.recent-title,
.task-name {
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.recent-meta,
.task-meta {
  display: flex;
  gap: 12px;
  font-size: 12px;
  color: #94a3b8;
}

.task-icon {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #e0e7ff;
  color: #4f46e5;
  border-radius: 8px;
}

@media (max-width: 1024px) {
  .content-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
  }

  .metric-cards {
    grid-template-columns: repeat(2, 1fr);
  }

  .quick-actions {
    width: 100%;
  }

  .quick-actions .el-button {
    flex: 1;
  }
}
</style>
