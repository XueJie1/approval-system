<template>
  <div class="stack">
    <div>
      <h2 class="page-title">我的申请</h2>
      <p class="page-subtitle">按状态筛选申请，并查看流程实例与操作日志</p>
    </div>

    <el-card shadow="never" class="panel">
      <div class="toolbar">
        <el-select v-model="statusFilter" clearable placeholder="按状态筛选" style="width: 220px">
          <el-option v-for="item in statuses" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
        <el-button type="primary" :loading="loading" @click="reload">刷新</el-button>
      </div>

      <el-table :data="requests" border>
        <el-table-column prop="businessKey" label="业务单号" min-width="180" />
        <el-table-column prop="title" label="标题" min-width="220" />
        <el-table-column label="状态" min-width="120">
          <template #default="scope">
            <el-tag>{{ statusLabel(scope.row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="processInstanceId" label="流程实例ID" min-width="220" show-overflow-tooltip />
        <el-table-column prop="submitTime" label="提交时间" min-width="170" />
      </el-table>
    </el-card>

    <el-row :gutter="14">
      <el-col :xs="24" :lg="12">
        <related-tasks-panel :tasks="requestTasks" :loading="loading" />
      </el-col>
      <el-col :xs="24" :lg="12">
        <process-operations-panel
          :requests="requests"
          :processes="processes"
          :loading="loading"
          :status-label="statusLabel"
          @refresh="reload"
        />
      </el-col>
    </el-row>

    <el-row :gutter="14">
      <el-col :xs="24" :md="12">
        <el-card shadow="never" class="panel">
          <template #header>操作日志</template>
          <el-timeline>
            <el-timeline-item v-for="log in logs" :key="log.id" :timestamp="log.createdAt">
              <strong>{{ log.action }}</strong>
              <div>{{ log.comment || "无备注" }}</div>
            </el-timeline-item>
          </el-timeline>
        </el-card>
      </el-col>
      <el-col :xs="24" :md="12">
        <el-card shadow="never" class="panel">
          <template #header>AI 建议记录</template>
          <el-empty v-if="aiSuggestions.length === 0" description="暂无 AI 建议记录" />
          <el-timeline v-else>
            <el-timeline-item v-for="item in aiSuggestions" :key="item.recordId" :timestamp="item.generatedAt">
              <strong>{{ item.decision === "APPROVE" ? "建议通过" : "建议拒绝" }}</strong>
              <div>{{ item.recommendation || item.summary }}</div>
              <div class="timeline-meta">
                采纳：{{ item.adopted ? "是" : "否" }} | 最终结果：{{ item.finalApprovalResult || "待定" }}
              </div>
            </el-timeline-item>
          </el-timeline>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from "vue";
import type { AiSuggestion, BizRequest, ProcessInfo, RequestLog, TaskInfo } from "../types";
import { listAiSuggestions, listProcesses, listRequestTasks, listRequestLogs, listRequests } from "../api/requests";
import RelatedTasksPanel from "../components/requests/RelatedTasksPanel.vue";
import ProcessOperationsPanel from "../components/requests/ProcessOperationsPanel.vue";

const loading = ref(false);
const statusFilter = ref<number | undefined>(undefined);
const requests = ref<BizRequest[]>([]);
const requestTasks = ref<TaskInfo[]>([]);
const processes = ref<ProcessInfo[]>([]);
const logs = ref<RequestLog[]>([]);
const aiSuggestions = ref<AiSuggestion[]>([]);

const statuses = [
  { label: "草稿", value: 0 },
  { label: "已提交", value: 1 },
  { label: "审批中", value: 2 },
  { label: "已通过", value: 3 },
  { label: "已拒绝", value: 4 },
  { label: "已退回", value: 5 },
  { label: "已撤销", value: 6 },
  { label: "已挂起", value: 7 }
];

onMounted(() => {
  reload();
});

watch(statusFilter, () => {
  reload();
});

function statusLabel(status: number) {
  return statuses.find((item) => item.value === status)?.label ?? `未知(${status})`;
}

async function reload() {
  loading.value = true;
  try {
    const params = { status: statusFilter.value };
    requests.value = await listRequests(params);
    requestTasks.value = await listRequestTasks(params);
    processes.value = await listProcesses(params);
    logs.value = await listRequestLogs(params);
    aiSuggestions.value = await listAiSuggestions(params);
  } finally {
    loading.value = false;
  }
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

.timeline-meta {
  color: #64748b;
  font-size: 12px;
  margin-top: 4px;
}
</style>
