<template>
  <div class="approved-page">
    <header class="page-header">
      <div>
        <h1>我的审批</h1>
        <p>查看你审批过的所有申请记录</p>
      </div>
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
      <el-empty v-if="filteredItems.length === 0" description="暂无审批记录" />

      <div
        v-for="item in filteredItems"
        :key="item.id + '-' + item.actionTime"
        class="request-card"
        @click="openDetail(item)"
      >
        <div class="card-top">
          <div class="request-title">{{ item.title || '未命名申请' }}</div>
          <el-tag :type="getStatusTagType(item.status)" size="small">
            {{ getStatusLabel(item.status) }}
          </el-tag>
        </div>
        <div class="card-body">
          <div class="card-info">
            <span class="info-item">
              <el-icon><Document /></el-icon>
              {{ item.businessKey?.slice(0, 12) || '-' }}
            </span>
            <span class="info-item">
              <el-icon><Clock /></el-icon>
              审批时间：{{ formatTime(item.actionTime) }}
            </span>
          </div>
          <el-tag
            :type="item.action === 'APPROVE' ? 'success' : 'danger'"
            size="small"
            effect="plain"
          >
            {{ item.action === 'APPROVE' ? '已通过' : '已拒绝' }}
          </el-tag>
        </div>
        <div v-if="item.comment" class="card-comment">
          <span class="comment-label">审批意见：</span>
          {{ item.comment }}
        </div>
      </div>
    </div>

    <el-drawer
      v-model="detailDrawer.open"
      :title="selectedItem?.title || '申请详情'"
      direction="rtl"
      size="600px"
    >
      <div v-if="selectedItem" class="detail-content">
        <section class="detail-section">
          <div class="section-label">基本信息</div>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">业务单号</span>
              <span class="info-value">{{ selectedItem.businessKey }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">流程实例</span>
              <span class="info-value">{{ selectedItem.processInstanceId || '-' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">申请状态</span>
              <el-tag :type="getStatusTagType(selectedItem.status)">
                {{ getStatusLabel(selectedItem.status) }}
              </el-tag>
            </div>
            <div class="info-item">
              <span class="info-label">提交时间</span>
              <span class="info-value">{{ formatTime(selectedItem.submitTime) }}</span>
            </div>
            <div v-if="selectedItem.finishTime" class="info-item">
              <span class="info-label">完成时间</span>
              <span class="info-value">{{ formatTime(selectedItem.finishTime) }}</span>
            </div>
          </div>
        </section>

        <section class="detail-section">
          <div class="section-label">我的审批</div>
          <div class="my-approval">
            <div class="approval-row">
              <span class="approval-label">审批结果</span>
              <el-tag
                :type="selectedItem.action === 'APPROVE' ? 'success' : 'danger'"
                size="large"
              >
                {{ selectedItem.action === 'APPROVE' ? '通过' : '拒绝' }}
              </el-tag>
            </div>
            <div class="approval-row">
              <span class="approval-label">审批时间</span>
              <span class="info-value">{{ formatTime(selectedItem.actionTime) }}</span>
            </div>
            <div v-if="selectedItem.comment" class="approval-row">
              <span class="approval-label">审批意见</span>
              <div class="comment-box">{{ selectedItem.comment }}</div>
            </div>
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
import { computed, onMounted, reactive, ref } from 'vue';
import { ElMessage } from 'element-plus';
import { Document, Clock } from '@element-plus/icons-vue';
import type { ApprovedRequestItem } from '../api/requests';
import { listApprovedByMe } from '../api/requests';

const loading = ref(false);
const allItems = ref<ApprovedRequestItem[]>([]);
const selectedItem = ref<ApprovedRequestItem | null>(null);

const statusFilter = ref<number | undefined>(undefined);

const detailDrawer = reactive({
  open: false
});

const statusTabs = [
  { label: '全部', value: undefined },
  { label: '审批中', value: 2 },
  { label: '已通过', value: 3 },
  { label: '已拒绝', value: 4 },
  { label: '已退回', value: 5 },
  { label: '已撤销', value: 6 }
];

const filteredItems = computed(() => {
  if (statusFilter.value === undefined) {
    return allItems.value;
  }
  return allItems.value.filter(r => r.status === statusFilter.value);
});

onMounted(() => {
  reload();
});

function getCountByStatus(status: number | undefined) {
  if (status === undefined) {
    return allItems.value.length;
  }
  return allItems.value.filter(r => r.status === status).length;
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
  return 'info';
}

function formatTime(time?: string) {
  if (!time) return '-';
  const d = new Date(time);
  return d.toLocaleString('zh-CN', { hour12: false });
}

async function reload() {
  loading.value = true;
  try {
    allItems.value = await listApprovedByMe();
  } catch (e) {
    console.error(e);
    ElMessage.error('加载失败');
  } finally {
    loading.value = false;
  }
}

function openDetail(item: ApprovedRequestItem) {
  selectedItem.value = item;
  detailDrawer.open = true;
}
</script>

<style scoped>
.approved-page {
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

.card-top {
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

.card-body {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.card-info {
  display: flex;
  gap: 16px;
  color: #64748b;
  font-size: 13px;
}

.card-comment {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid #f1f5f9;
  color: #64748b;
  font-size: 13px;
  line-height: 1.5;
}

.comment-label {
  color: #94a3b8;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 4px;
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

.my-approval {
  display: grid;
  gap: 12px;
  padding: 16px;
  background: #f8fafc;
  border-radius: 8px;
}

.approval-row {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.approval-label {
  font-size: 12px;
  color: #64748b;
}

.comment-box {
  padding: 8px 12px;
  background: #fff;
  border-radius: 6px;
  font-size: 14px;
  line-height: 1.5;
  white-space: pre-wrap;
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

  .card-body {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
