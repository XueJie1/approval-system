<template>
  <div class="start-page">
    <header class="page-header">
      <div>
        <h1>发起申请</h1>
        <p>填写申请信息并提交审批流程</p>
      </div>
    </header>

    <div class="form-layout">
      <div class="main-form">
        <el-card shadow="never" class="form-section">
          <template #header>
            <div class="section-header">
              <span class="section-title">基本信息</span>
            </div>
          </template>

          <el-form label-position="top">
            <el-row :gutter="16">
              <el-col :span="24">
                <el-form-item label="申请标题" required>
                  <el-input
                    v-model="form.title"
                    placeholder="例如：差旅申请、采购申请、请假申请"
                  />
                </el-form-item>
              </el-col>

              <el-col :span="24">
                <el-form-item label="业务单号">
                  <el-input
                    v-model="form.businessKey"
                    placeholder="留空系统自动生成"
                  />
                  <div class="field-hint">业务单号用于标识此申请，留空时系统自动生成唯一编号</div>
                </el-form-item>
              </el-col>
            </el-row>
          </el-form>
        </el-card>

        <el-card shadow="never" class="form-section">
          <template #header>
            <div class="section-header">
              <span class="section-title">审批流程</span>
            </div>
          </template>

          <el-form label-position="top">
            <el-row :gutter="16">
              <el-col :xs="24" :sm="12">
                <el-form-item label="流程类型" required>
                  <el-select v-model="form.processKey" style="width: 100%">
                    <el-option label="并行会签（多人同时审批）" value="approvalCountersign" />
                    <el-option label="或签（任意一人通过即可）" value="approvalOrSign" />
                    <el-option label="顺序审批（按顺序依次审批）" value="approvalSequential" />
                    <el-option label="单人审批" value="approvalSingle" />
                  </el-select>
                  <div class="field-hint">选择适合本次申请的审批模式</div>
                </el-form-item>
              </el-col>

              <el-col :xs="24" :sm="12">
                <el-form-item label="会签模式">
                  <el-select v-model="form.countersignMode" style="width: 100%">
                    <el-option label="全票通过（所有人同意）" value="ALL" />
                    <el-option label="多数通过（超过半数同意）" value="MAJORITY" />
                  </el-select>
                </el-form-item>
              </el-col>

              <el-col :xs="24" :sm="12">
                <el-form-item label="审批人">
                  <CountersignUserPickerDialog v-model="form.countersignUsers" />
                  <div class="field-hint">选择需要审批的人员</div>
                </el-form-item>
              </el-col>

              <el-col :xs="24" :sm="12">
                <el-form-item label="通过比例">
                  <el-input
                    v-model="form.passRatio"
                    placeholder="例如：0.6 表示60%同意即通过"
                  />
                </el-form-item>
              </el-col>
            </el-row>
          </el-form>
        </el-card>

        <el-card shadow="never" class="form-section">
          <template #header>
            <div class="section-header">
              <span class="section-title">表单内容</span>
              <div class="section-actions">
                <el-input
                  v-model="form.formKey"
                  placeholder="输入表单模板Key"
                  style="width: 200px"
                  clearable
                />
                <el-button :loading="loadingForm" @click="loadDynamicForm">加载模板</el-button>
              </div>
            </div>
          </template>

          <div v-if="!form.formKey" class="empty-form">
            <el-empty description="输入表单模板Key加载动态表单字段" :image-size="80" />
          </div>

          <RequestDynamicFields
            v-else
            v-model="dynamicData"
            :fields="dynamicFields"
            :loaded-version-id="loadedVersionId"
          />

          <el-divider v-if="form.formKey" />

          <el-form label-position="top">
            <el-form-item label="补充信息（JSON格式）">
              <el-input
                v-model="form.variablesText"
                type="textarea"
                :rows="3"
                placeholder='例如：{"amount": 3000, "reason": "出差"}'
              />
              <div class="field-hint">可填写额外的业务数据，以JSON格式输入</div>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card v-if="lastProcessId" shadow="never" class="form-section success-card">
          <el-result icon="success" title="申请已提交" :sub-title="`流程实例ID: ${lastProcessId}`">
            <template #extra>
              <el-button type="primary" @click="goRequests">查看我的申请</el-button>
              <el-button @click="resetForm">继续发起</el-button>
            </template>
          </el-result>
        </el-card>
      </div>

      <aside class="side-panel">
        <el-card shadow="never" class="action-card">
          <template #header>
            <span class="section-title">操作</span>
          </template>

          <div class="action-buttons">
            <el-button
              type="primary"
              size="large"
              :loading="submitting"
              :disabled="!form.title.trim()"
              style="width: 100%"
              @click="submitRequest"
            >
              提交申请
            </el-button>
            <el-button
              size="large"
              :loading="savingDraft"
              :disabled="!form.title.trim()"
              style="width: 100%"
              @click="saveDraft"
            >
              保存草稿
            </el-button>
            <el-button
              v-if="lastDraftBusinessKey"
              size="large"
              style="width: 100%"
              @click="submitDraftRequest"
            >
              提交草稿
            </el-button>
          </div>

          <div v-if="lastDraftBusinessKey" class="draft-info">
            <el-icon><InfoFilled /></el-icon>
            <span>草稿已保存：{{ lastDraftBusinessKey.slice(0, 12) }}...</span>
          </div>
        </el-card>

        <el-card shadow="never" class="help-card">
          <template #header>
            <span class="section-title">流程说明</span>
          </template>
          <div class="help-content">
            <div class="help-item">
              <strong>并行会签</strong>
              <p>所有审批人同时收到待办，需全部或多数同意后流转</p>
            </div>
            <div class="help-item">
              <strong>或签</strong>
              <p>所有审批人同时收到待办，任意一人同意即流转</p>
            </div>
            <div class="help-item">
              <strong>顺序审批</strong>
              <p>审批人按顺序依次收到待办</p>
            </div>
            <div class="help-item">
              <strong>单人审批</strong>
              <p>仅一人审批即可完成</p>
            </div>
          </div>
        </el-card>
      </aside>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue';
import { ElMessage } from 'element-plus';
import { InfoFilled } from '@element-plus/icons-vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import type { FormField, SaveDraftPayload, StartRequestPayload, SubmitDraftPayload } from '../types';
import { fetchFormFields, latestFormVersion, validateForm } from '../api/forms';
import { saveDraft as saveDraftApi, startRequest, submitDraft as submitDraftApi } from '../api/workflow';
import CountersignUserPickerDialog from '../components/requests/CountersignUserPickerDialog.vue';
import RequestDynamicFields from '../components/requests/RequestDynamicFields.vue';

const router = useRouter();
const auth = useAuthStore();

const loadingForm = ref(false);
const savingDraft = ref(false);
const submitting = ref(false);
const lastProcessId = ref('');
const lastDraftBusinessKey = ref('');
const dynamicFields = ref<FormField[]>([]);
const dynamicData = ref<Record<string, unknown>>({});
const loadedVersionId = ref<number | null>(null);

const form = reactive({
  businessKey: '',
  title: '',
  processKey: 'approvalCountersign',
  countersignUsers: [] as string[],
  countersignMode: 'ALL',
  passRatio: '1.0',
  formKey: '',
  variablesText: ''
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
    ElMessage.error('补充信息 JSON 格式错误');
    return null;
  }
}

function parseCountersignUsers() {
  return form.countersignUsers.filter(Boolean);
}

function buildSubmissionContext() {
  const countersignUsers = parseCountersignUsers();
  const variables = parseVariables();
  if (variables === null) {
    return null;
  }

  const mergedVariables: Record<string, unknown> = {
    ...variables,
    ...(buildFormData() ?? {})
  };

  if (form.processKey === 'approvalSingle') {
    const approverId = typeof mergedVariables.approverId === 'string'
      ? mergedVariables.approverId.trim()
      : '';
    if (approverId) {
      mergedVariables.approverId = approverId;
    } else if (countersignUsers.length === 1) {
      mergedVariables.approverId = countersignUsers[0];
    } else {
      ElMessage.warning('单人审批必须选择 1 位审批人');
      return null;
    }
  }

  return {
    countersignUsers,
    variables: mergedVariables
  };
}

function buildFormData() {
  return Object.keys(dynamicData.value).length > 0 ? { ...dynamicData.value } : null;
}

async function loadDynamicForm() {
  if (!form.formKey.trim()) {
    ElMessage.warning('请输入表单模板Key');
    return;
  }

  loadingForm.value = true;
  try {
    loadedVersionId.value = null;
    dynamicFields.value = [];
    dynamicData.value = {};
    const version = await latestFormVersion(form.formKey.trim());
    loadedVersionId.value = version.id;
    dynamicFields.value = await fetchFormFields(version.id);
    ElMessage.success('表单模板已加载');
  } catch (e) {
    console.error(e);
    ElMessage.error('加载表单模板失败');
  } finally {
    loadingForm.value = false;
  }
}

async function saveDraft() {
  const userId = currentUserId();
  if (!userId) {
    ElMessage.error('登录信息已失效，请重新登录');
    return;
  }
  if (!form.title.trim()) {
    ElMessage.warning('请填写申请标题');
    return;
  }

  savingDraft.value = true;
  try {
    const result = await persistDraft(userId);
    form.businessKey = result.businessKey;
    lastDraftBusinessKey.value = result.businessKey;
    ElMessage.success('草稿已保存');
  } catch (e) {
    console.error(e);
    ElMessage.error('保存草稿失败');
  } finally {
    savingDraft.value = false;
  }
}

async function submitDraftRequest() {
  const userId = currentUserId();
  if (!userId) {
    ElMessage.error('登录信息已失效，请重新登录');
    return;
  }
  if (!form.title.trim()) {
    ElMessage.warning('请填写申请标题');
    return;
  }

  const businessKey = form.businessKey.trim() || lastDraftBusinessKey.value.trim();
  if (!businessKey) {
    ElMessage.warning('请先保存草稿');
    return;
  }

  const submissionContext = buildSubmissionContext();
  if (!submissionContext) return;

  submitting.value = true;
  try {
    const payload: SubmitDraftPayload = {
      title: form.title.trim(),
      applicantId: userId,
      applicantDeptId: null,
      applicantPostId: null,
      formInstanceId: null,
      processKey: form.processKey,
      variables: submissionContext.variables,
      countersignUsers: submissionContext.countersignUsers,
      countersignMode: form.countersignMode,
      passRatio: Number(form.passRatio)
    };
    const result = await submitDraftApi(businessKey, payload);
    lastProcessId.value = result.processInstanceId;
    form.businessKey = businessKey;
    ElMessage.success('草稿已提交');
  } catch (e) {
    console.error(e);
    ElMessage.error('提交失败');
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
      ElMessage.info('表单未完整，已保存基本信息');
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

  return saveDraftApi(payload);
}

async function submitRequest() {
  const userId = currentUserId();
  if (!userId) {
    ElMessage.error('登录信息已失效，请重新登录');
    return;
  }
  if (!form.title.trim()) {
    ElMessage.warning('请填写申请标题');
    return;
  }

  const submissionContext = buildSubmissionContext();
  if (!submissionContext) return;

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
      countersignUsers: submissionContext.countersignUsers,
      countersignMode: form.countersignMode,
      passRatio: Number(form.passRatio),
      variables: submissionContext.variables
    };
    const result = await startRequest(payload);
    lastProcessId.value = result.processInstanceId;
    ElMessage.success('申请已提交');
  } catch (e) {
    console.error(e);
    ElMessage.error('提交失败');
  } finally {
    submitting.value = false;
  }
}

function resetForm() {
  form.businessKey = '';
  form.title = '';
  form.processKey = 'approvalCountersign';
  form.countersignUsers = [];
  form.countersignMode = 'ALL';
  form.passRatio = '1.0';
  form.formKey = '';
  form.variablesText = '';
  dynamicFields.value = [];
  dynamicData.value = {};
  loadedVersionId.value = null;
  lastProcessId.value = '';
  lastDraftBusinessKey.value = '';
}

function goRequests() {
  router.push('/user/requests');
}

onMounted(() => {
  // 可从 query 读取草稿 businessKey 进行恢复
});
</script>

<style scoped>
.start-page {
  display: grid;
  gap: 20px;
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

.form-layout {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: 20px;
}

.main-form {
  display: grid;
  gap: 16px;
}

.form-section {
  border-radius: 12px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
}

.section-actions {
  display: flex;
  gap: 8px;
}

.field-hint {
  margin-top: 4px;
  font-size: 12px;
  color: #94a3b8;
}

.empty-form {
  padding: 20px 0;
}

.success-card {
  border-color: #22c55e;
}

.side-panel {
  display: grid;
  gap: 16px;
  align-self: start;
}

.action-card {
  border-radius: 12px;
}

.action-buttons {
  display: grid;
  gap: 8px;
}

.draft-info {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 12px;
  padding: 8px 12px;
  background: #f0f9ff;
  border-radius: 6px;
  font-size: 13px;
  color: #0369a1;
}

.help-card {
  border-radius: 12px;
}

.help-content {
  display: grid;
  gap: 12px;
}

.help-item strong {
  display: block;
  margin-bottom: 4px;
  font-size: 14px;
}

.help-item p {
  margin: 0;
  font-size: 13px;
  color: #64748b;
  line-height: 1.5;
}

@media (max-width: 1024px) {
  .form-layout {
    grid-template-columns: 1fr;
  }

  .side-panel {
    order: -1;
  }
}
</style>
