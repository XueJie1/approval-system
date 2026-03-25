<template>
  <div class="stack">
    <div>
      <h2 class="page-title">发起申请</h2>
      <p class="page-subtitle">流程参数、动态表单、草稿保存和草稿提交都在这里完成</p>
    </div>

    <RequestDraftActions
      v-model:businessKey="form.businessKey"
      :fallback-business-key="lastDraftBusinessKey"
      :saving="savingDraft"
      :submitting="submitting"
      :last-saved-business-key="lastDraftBusinessKey"
      @save="saveDraft"
      @submit="submitDraftRequest"
    />

    <el-card shadow="never" class="panel">
      <template #header>流程参数</template>
      <div class="form-grid">
        <el-form-item label="标题">
          <el-input v-model="form.title" placeholder="例如：差旅申请" />
        </el-form-item>
        <el-form-item label="流程类型">
          <el-select v-model="form.processKey">
            <el-option label="并行会签" value="approvalCountersign" />
            <el-option label="或签" value="approvalOrSign" />
            <el-option label="顺序审批" value="approvalSequential" />
            <el-option label="单人审批" value="approvalSingle" />
          </el-select>
        </el-form-item>
        <el-form-item label="会签用户">
          <CountersignUserPickerDialog v-model="form.countersignUsers" />
        </el-form-item>
        <el-form-item label="会签模式">
          <el-select v-model="form.countersignMode">
            <el-option label="全票通过" value="ALL" />
            <el-option label="多数通过" value="MAJORITY" />
          </el-select>
        </el-form-item>
        <el-form-item label="通过比例">
          <el-input v-model="form.passRatio" placeholder="例如 0.6" />
        </el-form-item>
      </div>

      <el-divider />

      <div class="inline-tools">
        <el-input v-model="form.formKey" placeholder="输入表单Key并加载动态字段" />
        <el-button :loading="loadingForm" @click="loadDynamicForm">加载表单</el-button>
      </div>

      <RequestDynamicFields v-model="dynamicData" :fields="dynamicFields" :loaded-version-id="loadedVersionId" />

      <el-form-item label="扩展变量(JSON)">
        <el-input v-model="form.variablesText" type="textarea" :rows="3" placeholder='{"amount": 3000}' />
      </el-form-item>

      <div class="actions">
        <el-button type="primary" :loading="submitting" @click="submitRequest">发起流程</el-button>
      </div>

      <el-alert
        v-if="lastProcessId"
        type="success"
        :closable="false"
        style="margin-top: 10px"
        :title="`流程已创建：${lastProcessId}`"
      />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from "vue";
import { ElMessage } from "element-plus";
import { useAuthStore } from "../stores/auth";
import type { FormField, SaveDraftPayload, StartRequestPayload, SubmitDraftPayload } from "../types";
import { fetchFormFields, latestFormVersion, validateForm } from "../api/forms";
import { saveDraft as saveDraftRequest, startRequest, submitDraft as submitDraftRequestApi } from "../api/workflow";
import CountersignUserPickerDialog from "../components/requests/CountersignUserPickerDialog.vue";
import RequestDraftActions from "../components/requests/RequestDraftActions.vue";
import RequestDynamicFields from "../components/requests/RequestDynamicFields.vue";

const auth = useAuthStore();

const loadingForm = ref(false);
const savingDraft = ref(false);
const submitting = ref(false);
const lastProcessId = ref("");
const lastDraftBusinessKey = ref("");
const dynamicFields = ref<FormField[]>([]);
const dynamicData = ref<Record<string, unknown>>({});
const loadedVersionId = ref<number | null>(null);

const form = reactive({
  businessKey: "",
  title: "",
  processKey: "approvalCountersign",
  countersignUsers: [] as string[],
  countersignMode: "ALL",
  passRatio: "1.0",
  formKey: "",
  variablesText: ""
});

function currentUserId() {
  return auth.currentUser?.userId ?? null;
}

function parseVariables() {
  if (!form.variablesText.trim()) {
    return {} as Record<string, unknown>;
  }
  try {
    return JSON.parse(form.variablesText) as Record<string, unknown>;
  } catch {
    ElMessage.error("扩展变量 JSON 格式错误");
    return null;
  }
}

function parseCountersignUsers() {
  return form.countersignUsers.filter(Boolean);
}

function buildFormData() {
  return Object.keys(dynamicData.value).length > 0 ? { ...dynamicData.value } : null;
}

function resetDynamicData() {
  dynamicData.value = {};
}

async function loadDynamicForm() {
  if (!form.formKey.trim()) {
    ElMessage.warning("请先输入 formKey");
    return;
  }

  loadingForm.value = true;
  try {
    loadedVersionId.value = null;
    dynamicFields.value = [];
    resetDynamicData();
    const version = await latestFormVersion(form.formKey.trim());
    loadedVersionId.value = version.id;
    dynamicFields.value = await fetchFormFields(version.id);
    ElMessage.success("表单已加载");
  } finally {
    loadingForm.value = false;
  }
}

async function saveDraft() {
  const userId = currentUserId();
  if (!userId) {
    ElMessage.error("登录信息已失效，请重新登录");
    return;
  }
  if (!form.title.trim()) {
    ElMessage.warning("标题不能为空");
    return;
  }

  savingDraft.value = true;
  try {
    const result = await persistDraft(userId);
    form.businessKey = result.businessKey;
    lastDraftBusinessKey.value = result.businessKey;
    ElMessage.success("草稿已保存");
  } finally {
    savingDraft.value = false;
  }
}

async function submitDraftRequest() {
  const userId = currentUserId();
  if (!userId) {
    ElMessage.error("登录信息已失效，请重新登录");
    return;
  }
  if (!form.title.trim()) {
    ElMessage.warning("标题不能为空");
    return;
  }

  const businessKey = form.businessKey.trim() || lastDraftBusinessKey.value.trim();
  if (!businessKey) {
    ElMessage.warning("请先填写并保存业务单号，或使用已保存的草稿编号");
    return;
  }

  const variables = parseVariables();
  if (variables === null) {
    return;
  }

  submitting.value = true;
  try {
    const payload: SubmitDraftPayload = {
      title: form.title.trim(),
      applicantId: userId,
      applicantDeptId: null,
      applicantPostId: null,
      formInstanceId: null,
      processKey: form.processKey,
      variables: {
        ...variables,
        ...(buildFormData() ?? {})
      },
      countersignUsers: parseCountersignUsers(),
      countersignMode: form.countersignMode,
      passRatio: Number(form.passRatio)
    };
    const result = await submitDraftRequestApi(businessKey, payload);
    lastProcessId.value = result.processInstanceId;
    form.businessKey = businessKey;
    ElMessage.success("草稿已提交");
  } finally {
    submitting.value = false;
  }
}

async function persistDraft(userId: number) {
  const formData = buildFormData();
  let persistSnapshot = Boolean(loadedVersionId.value && form.formKey.trim() && formData);
  if (persistSnapshot && formData) {
    try {
      await validateForm({
        userId,
        formVersionId: loadedVersionId.value as number,
        data: formData
      });
    } catch {
      persistSnapshot = false;
      ElMessage.info("当前表单未完整，已先保存业务信息");
    }
  }

  const payload: SaveDraftPayload = {
    businessKey: form.businessKey.trim() || null,
    title: form.title.trim(),
    applicantId: userId,
    applicantDeptId: null,
    applicantPostId: null,
    formInstanceId: null,
    formKey: persistSnapshot ? form.formKey.trim() : null,
    formVersionId: persistSnapshot ? (loadedVersionId.value as number) : null,
    formData: persistSnapshot ? formData : null
  };

  return saveDraftRequest(payload);
}

async function submitRequest() {
  const userId = currentUserId();
  if (!userId) {
    ElMessage.error("登录信息已失效，请重新登录");
    return;
  }
  if (!form.title.trim()) {
    ElMessage.warning("标题不能为空");
    return;
  }

  const variables = parseVariables();
  if (variables === null) {
    return;
  }

  submitting.value = true;
  try {
    const formData = buildFormData();
    if (loadedVersionId.value && formData) {
      await validateForm({
        userId,
        formVersionId: loadedVersionId.value,
        data: formData
      });
    }

    const payload: StartRequestPayload = {
      businessKey: form.businessKey.trim() || null,
      title: form.title.trim(),
      applicantId: userId,
      applicantDeptId: null,
      applicantPostId: null,
      formInstanceId: null,
      formKey: form.formKey.trim() || null,
      formVersionId: loadedVersionId.value,
      formData,
      processKey: form.processKey,
      countersignUsers: parseCountersignUsers(),
      countersignMode: form.countersignMode,
      passRatio: Number(form.passRatio),
      variables
    };
    const result = await startRequest(payload);
    lastProcessId.value = result.processInstanceId;
    ElMessage.success("流程发起成功");
  } finally {
    submitting.value = false;
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

.inline-tools {
  display: flex;
  gap: 10px;
  margin-bottom: 12px;
}

.actions {
  display: flex;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .inline-tools {
    flex-direction: column;
  }
}
</style>
