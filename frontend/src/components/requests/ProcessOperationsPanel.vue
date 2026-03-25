<template>
  <el-card shadow="never" class="panel">
    <template #header>流程记录</template>

    <el-alert
      title="仅存在流程实例的记录支持挂起或恢复；终态记录不会显示操作入口。"
      type="info"
      show-icon
      :closable="false"
      class="hint"
    />

    <el-empty v-if="!loading && processes.length === 0" description="当前筛选条件下没有流程记录" />
    <el-table v-else :data="processes" border v-loading="loading">
      <el-table-column prop="processInstanceId" label="流程实例" min-width="220" show-overflow-tooltip />
      <el-table-column prop="processDefinitionId" label="流程定义" min-width="180" show-overflow-tooltip />
      <el-table-column label="业务单号" min-width="160">
        <template #default="{ row }">
          <div>{{ requestByProcessId.get(row.processInstanceId)?.businessKey || row.businessKey }}</div>
          <div class="subtle">{{ requestByProcessId.get(row.processInstanceId)?.title || "未关联到申请标题" }}</div>
        </template>
      </el-table-column>
      <el-table-column label="状态" min-width="120">
        <template #default="{ row }">
          <el-tag :type="requestStatusType(row.processInstanceId)">{{ requestStatusLabel(row.processInstanceId) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" min-width="170">
        <template #default="{ row }">
          <div class="actions">
            <el-button
              size="small"
              type="warning"
              plain
              :disabled="!canOperate(row.processInstanceId)"
              @click="openAction(row.processInstanceId)"
            >
              {{ requestStatusCode(row.processInstanceId) === 7 ? "恢复" : "挂起" }}
            </el-button>
          </div>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="520px">
      <el-form label-position="top">
        <el-form-item label="备注">
          <el-input
            v-model="comment"
            type="textarea"
            :rows="4"
            :placeholder="dialogPlaceholder"
            maxlength="200"
            show-word-limit
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitAction">确认</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { ElMessage } from "element-plus";
import type { BizRequest, ProcessInfo } from "../../types";
import { activateProcess, suspendProcess } from "../../api/workflow";

const props = defineProps<{
  requests: BizRequest[];
  processes: ProcessInfo[];
  loading: boolean;
  statusLabel: (status: number) => string;
}>();

const emit = defineEmits<{
  (event: "refresh"): void;
}>();

const dialogVisible = ref(false);
const submitting = ref(false);
const comment = ref("");
const activeProcessId = ref("");

const requestByProcessId = computed(() => {
  const map = new Map<string, BizRequest>();
  for (const request of props.requests) {
    if (request.processInstanceId) {
      map.set(request.processInstanceId, request);
    }
  }
  return map;
});

const currentRequest = computed(() => requestByProcessId.value.get(activeProcessId.value));

const dialogTitle = computed(() => {
  const statusCode = requestStatusCode(activeProcessId.value);
  return statusCode === 7 ? "恢复流程" : "挂起流程";
});

const dialogPlaceholder = computed(() => {
  const statusCode = requestStatusCode(activeProcessId.value);
  return statusCode === 7 ? "请输入恢复原因" : "请输入挂起原因";
});

function requestStatusCode(processInstanceId: string) {
  return requestByProcessId.value.get(processInstanceId)?.status ?? -1;
}

function requestStatusLabel(processInstanceId: string) {
  const status = requestStatusCode(processInstanceId);
  return status >= 0 ? props.statusLabel(status) : "未关联申请";
}

function requestStatusType(processInstanceId: string) {
  const status = requestStatusCode(processInstanceId);
  if (status === 7) {
    return "warning";
  }
  if (status === 3) {
    return "success";
  }
  if (status === 4 || status === 6) {
    return "danger";
  }
  return "info";
}

function canOperate(processInstanceId: string) {
  const request = requestByProcessId.value.get(processInstanceId);
  if (!request || !request.processInstanceId) {
    return false;
  }
  return ![3, 4, 5, 6].includes(request.status);
}

function openAction(processInstanceId: string) {
  activeProcessId.value = processInstanceId;
  comment.value = "";
  dialogVisible.value = true;
}

async function submitAction() {
  if (!activeProcessId.value || !comment.value.trim()) {
    ElMessage.warning("请输入备注");
    return;
  }

  const request = currentRequest.value;
  if (!request) {
    ElMessage.error("未找到对应申请");
    return;
  }

  submitting.value = true;
  try {
    if (request.status === 7) {
      await activateProcess(activeProcessId.value, { comment: comment.value.trim() });
      ElMessage.success("流程已恢复");
    } else {
      await suspendProcess(activeProcessId.value, { comment: comment.value.trim() });
      ElMessage.success("流程已挂起");
    }
    dialogVisible.value = false;
    emit("refresh");
  } finally {
    submitting.value = false;
  }
}
</script>

<style scoped>
.panel {
  border-radius: 14px;
  border-color: #d8e4ed;
}

.hint {
  margin-bottom: 12px;
}

.subtle {
  margin-top: 4px;
  color: #64748b;
  font-size: 12px;
}

.actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
</style>
