<template>
  <div class="stack">
    <div>
      <h2 class="page-title">我的待办</h2>
      <p class="page-subtitle">支持认领、审批、委派、转办、回退、撤销与 AI 建议</p>
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
        <el-table-column label="操作" min-width="320">
          <template #default="scope">
            <div class="table-actions">
              <el-button size="small" @click="selectTask(scope.row.taskId)">选择</el-button>
              <el-button size="small" @click="claim(scope.row.taskId)">认领</el-button>
              <el-button size="small" type="primary" @click="openAi(scope.row.taskId)">AI 建议</el-button>
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
          <el-input v-model="action.comment" />
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

    <el-card v-if="suggestion.summary" shadow="never" class="panel">
      <template #header>AI 审批建议</template>
      <p><strong>决策建议：</strong>{{ suggestion.decision }}</p>
      <p>{{ suggestion.summary }}</p>
      <p><strong>风险提示：</strong>{{ suggestion.riskFlags.join("；") || "无" }}</p>
      <p><strong>复核建议：</strong>{{ suggestion.followUpChecks.join("；") || "无" }}</p>
      <p class="meta">model={{ suggestion.model }} | generatedAt={{ suggestion.generatedAt }}</p>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from "vue";
import { ElMessage } from "element-plus";
import type { AiSuggestion, TaskInfo } from "../types";
import { useAuthStore } from "../stores/auth";
import {
  aiSuggestion,
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

const action = reactive({
  taskId: "",
  approvalResult: "APPROVE",
  comment: "",
  delegateUserId: "",
  newAssigneeId: "",
  targetActivityId: "",
  processInstanceId: ""
});

const suggestion = reactive<AiSuggestion>({
  taskId: "",
  decision: "",
  summary: "",
  riskFlags: [],
  followUpChecks: [],
  model: "",
  generatedAt: ""
});

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

async function openAi(taskId: string) {
  const res = await aiSuggestion(taskId);
  suggestion.taskId = res.taskId;
  suggestion.decision = res.decision;
  suggestion.summary = res.summary;
  suggestion.riskFlags = res.riskFlags || [];
  suggestion.followUpChecks = res.followUpChecks || [];
  suggestion.model = res.model;
  suggestion.generatedAt = res.generatedAt;
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

.meta {
  color: #64748b;
  font-size: 12px;
}

@media (max-width: 768px) {
  .toolbar {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
}
</style>
