<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <h2 class="page-title">管理员工作台</h2>
        <p class="page-subtitle">{{ greeting }}，{{ auth.currentUser?.username || '管理员' }}。这里是系统运行概览与常用入口。</p>
      </div>
      <div class="heading-actions">
        <el-button :loading="loading" @click="loadDashboard">刷新数据</el-button>
      </div>
    </div>

    <el-row :gutter="14" class="summary-grid">
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">用户总数</div>
          <div class="metric-value">{{ safeValue(overview.users) }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">角色总数</div>
          <div class="metric-value">{{ safeValue(overview.roles) }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">部门总数</div>
          <div class="metric-value">{{ safeValue(overview.depts) }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">岗位总数</div>
          <div class="metric-value">{{ safeValue(overview.posts) }}</div>
        </div>
      </el-col>
    </el-row>

    <div class="content-grid">
      <el-card shadow="never" class="panel-card">
        <template #header>
          <div class="card-header">
            <span>流程与模板</span>
          </div>
        </template>

        <div class="stats-list">
          <div class="stats-item">
            <span>模板总数</span>
            <strong>{{ safeValue(templateTotal) }}</strong>
          </div>
          <div class="stats-item">
            <span>启用模板</span>
            <strong>{{ safeValue(templateActive) }}</strong>
          </div>
          <div class="stats-item">
            <span>流程定义总数</span>
            <strong>{{ safeValue(workflowTotal) }}</strong>
          </div>
        </div>
      </el-card>

      <el-card shadow="never" class="panel-card">
        <template #header>
          <div class="card-header">
            <span>快捷入口</span>
          </div>
        </template>

        <div class="quick-actions">
          <el-button type="primary" plain @click="go('/admin/request-templates')">模板管理</el-button>
          <el-button v-if="isTechAdmin" type="primary" plain @click="go('/admin/users')">用户管理</el-button>
          <el-button v-if="isTechAdmin" type="primary" plain @click="go('/admin/roles')">角色管理</el-button>
          <el-button v-if="isTechAdmin" type="primary" plain @click="go('/admin/departments')">部门管理</el-button>
          <el-button v-if="isTechAdmin" type="primary" plain @click="go('/admin/workflows')">流程管理</el-button>
          <el-button v-if="isTechAdmin" @click="go('/admin/settings')">系统设置</el-button>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import { fetchAdminUserOptions } from '../api/admin-users';
import { listAdminRequestTemplates } from '../api/admin-request-templates';
import { listWorkflowDefinitions } from '../api/admin-workflows';

const router = useRouter();
const auth = useAuthStore();

const loading = ref(false);
const overview = ref<{ users: number | null; roles: number | null; depts: number | null; posts: number | null }>({
  users: null,
  roles: null,
  depts: null,
  posts: null
});
const templateTotal = ref<number | null>(null);
const templateActive = ref<number | null>(null);
const workflowTotal = ref<number | null>(null);

const isTechAdmin = computed(() => (auth.currentUser?.roles ?? []).includes('SYS_ADMIN'));

const greeting = computed(() => {
  const hour = new Date().getHours();
  if (hour < 6) return '夜深了';
  if (hour < 12) return '上午好';
  if (hour < 14) return '中午好';
  if (hour < 18) return '下午好';
  if (hour < 22) return '晚上好';
  return '夜深了';
});

onMounted(() => {
  loadDashboard();
});

async function loadDashboard() {
  loading.value = true;
  const jobs: Array<Promise<unknown>> = [loadTemplateStats()];
  if (isTechAdmin.value) {
    jobs.push(loadOverview(), loadWorkflowStats());
  }
  await Promise.allSettled(jobs);
  loading.value = false;
}

async function loadOverview() {
  const options = await fetchAdminUserOptions();
  overview.value = {
    users: options.users.length,
    roles: options.roles.length,
    depts: options.depts.length,
    posts: options.posts.length
  };
}

async function loadTemplateStats() {
  const templates = await listAdminRequestTemplates();
  templateTotal.value = templates.length;
  templateActive.value = templates.filter((item) => item.status === 'ACTIVE').length;
}

async function loadWorkflowStats() {
  const page = await listWorkflowDefinitions({ page: 0, size: 1 });
  workflowTotal.value = page.total;
}

function safeValue(value: number | null) {
  return value == null ? '--' : value;
}

function go(path: string) {
  router.push(path);
}
</script>

<style scoped>
.admin-page {
  display: grid;
  gap: 18px;
}

.heading {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.heading-actions {
  display: flex;
  gap: 10px;
}

.summary-grid {
  margin-bottom: 0;
}

.metric {
  padding: 16px;
  border-radius: 12px;
}

.metric-label {
  color: #64748b;
  font-size: 13px;
}

.metric-value {
  margin-top: 10px;
  font-size: 28px;
  line-height: 1;
  font-weight: 700;
  color: #0f172a;
}

.content-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.panel-card {
  border-radius: 12px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 600;
}

.stats-list {
  display: grid;
  gap: 12px;
}

.stats-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 12px;
  border-radius: 10px;
  background: #f8fafc;
  color: #334155;
}

.stats-item strong {
  color: #0f172a;
  font-size: 18px;
}

.quick-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

@media (max-width: 960px) {
  .content-grid {
    grid-template-columns: 1fr;
  }
}
</style>
