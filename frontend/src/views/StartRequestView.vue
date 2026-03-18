<template>
  <div class="stack">
    <div>
      <h2 class="page-title">发起申请</h2>
      <p class="page-subtitle">首轮交付：流程参数 + 动态表单 + 后端校验一体化</p>
    </div>

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
          <el-input v-model="form.countersignUsers" placeholder="多个用户ID用逗号分隔" />
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
        <el-form-item label="业务单号">
          <el-input v-model="form.businessKey" placeholder="可留空自动生成" />
        </el-form-item>
      </div>

      <el-divider />

      <div class="inline-tools">
        <el-input v-model="form.formKey" placeholder="输入表单Key并加载动态字段" />
        <el-button @click="loadDynamicForm">加载表单</el-button>
      </div>

      <div v-if="dynamicFields.length > 0" class="dynamic-block">
        <h4>动态表单</h4>
        <div class="form-grid">
          <el-form-item v-for="field in dynamicFields" :key="field.fieldKey" :label="field.label || field.fieldKey">
            <el-input
              v-if="field.fieldType === 'string' || field.fieldType === 'date'"
              v-model="dynamicData[field.fieldKey]"
              :placeholder="field.fieldType === 'date' ? 'YYYY-MM-DD' : ''"
            />
            <el-input-number v-else-if="field.fieldType === 'number'" v-model="dynamicData[field.fieldKey]" :min="0" :controls="false" style="width: 100%" />
            <el-select v-else-if="field.fieldType === 'select'" v-model="dynamicData[field.fieldKey]" style="width: 100%">
              <el-option v-for="opt in parseOptions(field.optionsJson)" :key="String(opt.value)" :label="String(opt.label)" :value="opt.value" />
            </el-select>
            <el-input v-else v-model="dynamicData[field.fieldKey]" />
          </el-form-item>
        </div>
      </div>

      <el-form-item label="扩展变量(JSON)">
        <el-input v-model="form.variablesText" type="textarea" :rows="3" placeholder='{"amount": 3000}' />
      </el-form-item>

      <div class="actions">
        <el-button type="primary" :loading="submitting" @click="submit">发起流程</el-button>
      </div>
      <el-alert v-if="lastProcessId" type="success" :closable="false" style="margin-top: 10px" :title="`流程已创建：${lastProcessId}`" />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from "vue";
import { ElMessage } from "element-plus";
import { useAuthStore } from "../stores/auth";
import type { FormField } from "../types";
import { fetchFormFields, latestFormVersion, validateForm } from "../api/forms";
import { startRequest } from "../api/workflow";

const auth = useAuthStore();

const submitting = ref(false);
const lastProcessId = ref("");
const dynamicFields = ref<FormField[]>([]);
const dynamicData = reactive<Record<string, unknown>>({});
const loadedVersionId = ref<number | null>(null);

const form = reactive({
  businessKey: "",
  title: "",
  processKey: "approvalCountersign",
  countersignUsers: "",
  countersignMode: "ALL",
  passRatio: "1.0",
  formKey: "",
  variablesText: ""
});

function parseOptions(optionsJson?: string) {
  if (!optionsJson) {
    return [] as Array<{ label: string; value: string }>;
  }
  try {
    return JSON.parse(optionsJson) as Array<{ label: string; value: string }>;
  } catch {
    return [];
  }
}

async function loadDynamicForm() {
  if (!form.formKey.trim()) {
    ElMessage.warning("请先输入 formKey");
    return;
  }
  const version = await latestFormVersion(form.formKey.trim());
  loadedVersionId.value = version.id;
  dynamicFields.value = await fetchFormFields(version.id);
  for (const key of Object.keys(dynamicData)) {
    delete dynamicData[key];
  }
}

function parseVariables() {
  if (!form.variablesText.trim()) {
    return {};
  }
  return JSON.parse(form.variablesText) as Record<string, unknown>;
}

async function submit() {
  const currentUser = auth.currentUser;
  if (!currentUser) {
    ElMessage.error("登录信息已失效，请重新登录");
    return;
  }
  if (!form.title.trim()) {
    ElMessage.warning("标题不能为空");
    return;
  }

  submitting.value = true;
  try {
    const variables = parseVariables();
    const formData = dynamicFields.value.length > 0 ? { ...dynamicData } : null;

    if (loadedVersionId.value && formData) {
      await validateForm({
        userId: currentUser.userId,
        formVersionId: loadedVersionId.value,
        data: formData
      });
    }

    const result = await startRequest({
      businessKey: form.businessKey.trim() || null,
      title: form.title.trim(),
      applicantId: currentUser.userId,
      formKey: form.formKey.trim() || null,
      formVersionId: loadedVersionId.value,
      formData,
      processKey: form.processKey,
      countersignUsers: form.countersignUsers
        ? form.countersignUsers.split(",").map((item) => item.trim()).filter(Boolean)
        : [],
      countersignMode: form.countersignMode,
      passRatio: Number(form.passRatio),
      variables
    });
    lastProcessId.value = result.processInstanceId;
    ElMessage.success("流程发起成功");
  } catch {
    // unified error interceptor
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

.dynamic-block {
  margin-bottom: 12px;
}

.dynamic-block h4 {
  margin: 0 0 10px;
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
