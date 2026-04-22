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

            </el-row>
          </el-form>
        </el-card>

        <el-card shadow="never" class="form-section">
          <template #header>
            <div class="section-header">
              <span class="section-title">申请类型</span>
            </div>
          </template>

          <el-form label-position="top">
            <el-row :gutter="16">
              <el-col :span="24">
                <el-form-item label="申请类型" required>
                  <el-select v-model="form.templateKey" style="width: 100%" @change="handleTemplateChange">
                    <el-option
                      v-for="template in requestTemplates"
                      :key="template.templateKey"
                      :label="template.templateName"
                      :value="template.templateKey"
                    />
                  </el-select>
                </el-form-item>
              </el-col>

              <el-col :span="24">
                <div class="template-summary">
                  <div class="template-summary__title">{{ currentTemplate?.templateName ?? '暂无申请模板' }}</div>
                  <p class="template-summary__desc">{{ currentTemplate?.description ?? '当前角色暂无可发起模板，请联系管理员在“申请模板管理”中配置可发起角色。' }}</p>
                  <div class="template-summary__meta">
                    <span>默认流程：{{ currentTemplate?.flowSummary ?? '未配置' }}</span>
                    <span>表单模板：{{ currentTemplate?.formName ?? '未配置' }}</span>
                  </div>
                </div>
              </el-col>

              <el-col v-if="allowManualApproverSelect" :span="24">
                <el-form-item label="审批人">
                  <CountersignUserPickerDialog v-model="form.countersignUsers" />
                  <div class="field-hint">选择本次申请的主要审批人，系统会按申请类型套用默认审批模式</div>
                </el-form-item>
              </el-col>

              <el-col v-else :span="24">
                <el-alert
                  type="info"
                  :closable="false"
                  show-icon
                  title="该申请类型按公司规则自动确定审批人，无需手动指定。"
                />
              </el-col>

              <el-col :span="24">
                <div class="approval-preview-card">
                  <div class="approval-preview-card__title">预计审批链</div>
                  <div v-if="approvalPreviewLoading" class="field-hint">正在计算审批链...</div>
                  <div v-else-if="approvalPreviewError" class="field-hint approval-preview-error">{{ approvalPreviewError }}</div>
                  <div v-else-if="approvalPreviewSteps.length" class="approval-preview-list">
                    <div v-for="step in approvalPreviewSteps" :key="`${step.orderNo}-${step.approverId}`" class="approval-preview-item">
                      <span class="approval-preview-order">{{ step.orderNo }}</span>
                      <div>
                        <div class="approval-preview-label">{{ step.approverName || `用户 ${step.approverId}` }}</div>
                        <div class="approval-preview-meta">{{ step.sourceDescription || step.resolverLabel || step.label || '自动审批' }}</div>
                      </div>
                    </div>
                  </div>
                  <div v-else class="field-hint">系统会根据当前模板、组织关系和表单数据自动计算审批链。</div>
                </div>
              </el-col>
            </el-row>
          </el-form>
        </el-card>

        <el-card shadow="never" class="form-section">
          <template #header>
            <div class="section-header">
              <span class="section-title">表单内容</span>
              <span class="section-subtitle">{{ currentTemplate?.formName ?? '未配置表单' }}</span>
            </div>
          </template>

          <div v-if="!form.formKey" class="empty-form">
            <el-empty description="当前申请类型暂未配置表单模板" :image-size="80" />
          </div>

          <RequestDynamicFields
            v-else
            v-model="dynamicData"
            :fields="dynamicFields"
            :loaded-version-id="loadedVersionId"
          />

          <el-alert
            v-if="form.formKey"
            type="info"
            :closable="false"
            show-icon
            title="表单已按申请类型自动加载，无需填写技术参数"
          />
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
            <span class="section-title">AI 填表助手</span>
          </template>
          <div class="help-content">
            <el-input
              v-model="aiCommand"
              type="textarea"
              :rows="4"
              placeholder="例如：我要请假，类型年假，开始时间2026-06-01 09:00，结束时间2026-06-03 18:00，请假天数3天，原因陪伴家人"
            />
            <div class="action-buttons">
              <el-button :loading="aiParsing" @click="handleAiParse">解析并预填</el-button>
              <el-button type="primary" :loading="aiStarting" @click="handleAiParseAndStart">解析并发起</el-button>
            </div>
            <div v-if="aiParseHint" class="field-hint">{{ aiParseHint }}</div>
          </div>
        </el-card>

        <el-card shadow="never" class="help-card">
          <template #header>
            <span class="section-title">填写说明</span>
          </template>
          <div class="help-content">
            <div class="help-item">
              <strong>{{ currentTemplate?.templateName ?? '暂无申请模板' }}</strong>
              <p>{{ currentTemplate?.description ?? '当前角色暂无可发起模板，请联系管理员在“申请模板管理”中配置可发起角色。' }}</p>
            </div>
            <div class="help-item">
              <strong>默认审批方式</strong>
              <p>{{ currentTemplate?.flowSummary ?? '请先由管理员配置审批流程说明。' }}</p>
            </div>
            <div class="help-item">
              <strong>提交建议</strong>
              <p>先完整填写业务表单，再选择本次需要参与审批的人员</p>
            </div>
            <div class="help-item">
              <strong>草稿能力</strong>
              <p>未准备好时可先保存草稿，之后再继续补充并提交</p>
            </div>
          </div>
        </el-card>
      </aside>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { AxiosError } from 'axios';
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { ElMessage } from 'element-plus';
import { InfoFilled } from '@element-plus/icons-vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import type { FormField, RequestTemplateApprovalPreviewStep, RequestTemplateSummary, SaveDraftPayload, StartRequestPayload, SubmitDraftPayload } from '../types';
import { parseAndStartByFormCommand, parseFormCommand } from '../api/ai-form-commands';
import { fetchFormFields, latestFormVersion, validateForm } from '../api/forms';
import { listRequestTemplates, previewRequestTemplateApproval } from '../api/request-templates';
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
const requestTemplates = ref<RequestTemplateSummary[]>([]);
const approvalPreviewSteps = ref<RequestTemplateApprovalPreviewStep[]>([]);
const approvalPreviewLoading = ref(false);
const approvalPreviewError = ref('');
const aiCommand = ref('');
const aiParsing = ref(false);
const aiStarting = ref(false);
const aiParseHint = ref('');

const form = reactive({
  businessKey: '',
  title: '',
  templateKey: '',
  processKey: 'approvalSequential',
  countersignUsers: [] as string[],
  countersignMode: 'ALL',
  passRatio: '1.0',
  formKey: '',
  variablesText: ''
});

const currentTemplate = computed(() => {
  return requestTemplates.value.find(template => template.templateKey === form.templateKey) ?? null;
});

const allowManualApproverSelect = computed(() => currentTemplate.value?.allowManualApproverSelect === true);

function currentUserId() {
  return auth.currentUser?.userId ?? null;
}

function parseVariables() {
  return {
    requestTemplateKey: form.templateKey,
    requestTemplateLabel: currentTemplate.value?.templateName ?? ''
  } as Record<string, unknown>;
}

function parseCountersignUsers() {
  if (!allowManualApproverSelect.value) {
    return [] as string[];
  }
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
  const boundFormVersionId = currentTemplate.value?.formVersionId ?? null;
  const normalizedFormKey = form.formKey.trim();
  if (!boundFormVersionId && !normalizedFormKey) {
    loadedVersionId.value = null;
    dynamicFields.value = [];
    dynamicData.value = {};
    return;
  }

  loadingForm.value = true;
  try {
    loadedVersionId.value = null;
    dynamicFields.value = [];
    dynamicData.value = {};
    if (boundFormVersionId) {
      loadedVersionId.value = boundFormVersionId;
      dynamicFields.value = await fetchFormFields(boundFormVersionId);
    } else {
      const version = await latestFormVersion(normalizedFormKey);
      loadedVersionId.value = version.id;
      dynamicFields.value = await fetchFormFields(version.id);
    }
    ElMessage.success('表单模板已加载');
  } catch (e) {
    console.error(e);
    loadedVersionId.value = null;
    dynamicFields.value = [];
    dynamicData.value = {};
    const error = e as AxiosError<{ error?: string }>;
    if (error.response?.status === 404) {
      ElMessage.warning(boundFormVersionId ? '流程当前发布版本未绑定可用表单' : '该申请类型暂未配置可用表单');
      return;
    }
    ElMessage.error('加载表单模板失败');
  } finally {
    loadingForm.value = false;
  }
}

async function applyTemplate() {
  if (!currentTemplate.value) {
    form.processKey = 'approvalSequential';
    form.countersignMode = 'ALL';
    form.passRatio = '1.0';
    form.formKey = '';
    dynamicFields.value = [];
    loadedVersionId.value = null;
    approvalPreviewSteps.value = [];
    approvalPreviewError.value = '';
    return;
  }

  form.processKey = currentTemplate.value.processKey;
  form.countersignMode = currentTemplate.value.countersignMode;
  form.passRatio = currentTemplate.value.passRatio;
  form.formKey = currentTemplate.value.formKey ?? '';

  if (!form.title.trim()) {
    form.title = currentTemplate.value.templateName;
  }

  await loadDynamicForm();
  await loadApprovalPreview();
}

async function handleTemplateChange() {
  dynamicData.value = {};
  await applyTemplate();
}

async function loadApprovalPreview() {
  if (!form.templateKey) {
    approvalPreviewSteps.value = [];
    approvalPreviewError.value = '';
    return;
  }
  const applicantId = currentUserId();
  if (!applicantId) {
    approvalPreviewSteps.value = [];
    approvalPreviewError.value = '登录信息已失效';
    return;
  }
  approvalPreviewLoading.value = true;
  approvalPreviewError.value = '';
  try {
    approvalPreviewSteps.value = await previewRequestTemplateApproval(form.templateKey, {
      applicantId,
      variables: {
        ...parseVariables(),
        ...(buildFormData() ?? {})
      }
    });
  } catch (e) {
    approvalPreviewSteps.value = [];
    const error = e as AxiosError<{ error?: string }>;
    approvalPreviewError.value = error.response?.data?.error || '暂时无法预览审批链';
  } finally {
    approvalPreviewLoading.value = false;
  }
}

async function loadRequestTemplates() {
  try {
    const templates = await listRequestTemplates();
    requestTemplates.value = templates;
    if (!templates.length) {
      ElMessage.warning('当前角色暂无可发起模板，请联系管理员配置模板可发起角色');
      return;
    }
    if (!form.templateKey || !templates.some(template => template.templateKey === form.templateKey)) {
      form.templateKey = templates[0].templateKey;
    }
    await applyTemplate();
  } catch (e) {
    console.error(e);
    ElMessage.error('加载申请模板失败');
  }
}

async function handleAiParse() {
  if (!aiCommand.value.trim()) {
    ElMessage.warning('请输入表单指令');
    return;
  }
  aiParsing.value = true;
  aiParseHint.value = '';
  try {
    const parsed = await parseFormCommand({
      command: aiCommand.value.trim(),
      requestTemplateKey: form.templateKey || undefined,
      formKey: form.formKey || undefined,
      formVersionId: loadedVersionId.value ?? undefined
    });
    if (parsed.templateKey && parsed.templateKey !== form.templateKey && requestTemplates.value.some(item => item.templateKey === parsed.templateKey)) {
      form.templateKey = parsed.templateKey;
      await applyTemplate();
    }
    dynamicData.value = {
      ...dynamicData.value,
      ...parsed.formData
    };
    await loadApprovalPreview();
    aiParseHint.value = parsed.missingRequiredFields.length
      ? `已预填，仍缺少必填字段：${parsed.missingRequiredFields.join('、')}`
      : '已完成预填，可直接提交或继续补充。';
    ElMessage.success('AI 解析完成');
  } catch (e) {
    console.error(e);
    aiParseHint.value = 'AI 解析失败，请补充后重试';
    ElMessage.error('AI 解析失败');
  } finally {
    aiParsing.value = false;
  }
}

async function handleAiParseAndStart() {
  if (!aiCommand.value.trim()) {
    ElMessage.warning('请输入表单指令');
    return;
  }
  aiStarting.value = true;
  aiParseHint.value = '';
  try {
    const result = await parseAndStartByFormCommand({
      command: aiCommand.value.trim(),
      title: form.title.trim() || undefined,
      requestTemplateKey: form.templateKey || undefined,
      formKey: form.formKey || undefined,
      formVersionId: loadedVersionId.value ?? undefined,
      requireAllRequiredFields: true
    });
    lastProcessId.value = result.processInstanceId;
    form.businessKey = result.businessKey;
    aiParseHint.value = 'AI 已直接发起流程';
    ElMessage.success('AI 已发起申请');
  } catch (e) {
    console.error(e);
    const error = e as AxiosError<{ error?: string }>;
    const message = error.response?.data?.error;
    aiParseHint.value = 'AI 发起失败，请先执行解析预填并手工补充';
    ElMessage.error(message || 'AI 发起失败');
  } finally {
    aiStarting.value = false;
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
      requestTemplateKey: form.templateKey,
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
    const error = e as AxiosError<{ error?: string }>;
    ElMessage.error(error.response?.data?.error || '提交失败');
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
      requestTemplateKey: form.templateKey,
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
    const error = e as AxiosError<{ error?: string }>;
    ElMessage.error(error.response?.data?.error || '提交失败');
  } finally {
    submitting.value = false;
  }
}

function resetForm() {
  form.businessKey = '';
  form.title = '';
  form.templateKey = requestTemplates.value[0]?.templateKey ?? '';
  form.processKey = 'approvalSequential';
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
  aiCommand.value = '';
  aiParseHint.value = '';
}

function goRequests() {
  router.push('/user/requests');
}

onMounted(() => {
  loadRequestTemplates();
  // 可从 query 读取草稿 businessKey 进行恢复
});

watch(dynamicData, () => {
  if (currentTemplate.value && !allowManualApproverSelect.value) {
    loadApprovalPreview();
  }
}, { deep: true });
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

.section-subtitle {
  font-size: 13px;
  color: #64748b;
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

.template-summary {
  padding: 14px 16px;
  border-radius: 12px;
  background: linear-gradient(135deg, #f8fafc, #eef6ff);
  border: 1px solid #dbeafe;
}

.template-summary__title {
  font-size: 16px;
  font-weight: 600;
  color: #0f172a;
}

.template-summary__desc {
  margin: 6px 0 0;
  color: #475569;
  line-height: 1.6;
}

.template-summary__meta {
  display: grid;
  gap: 4px;
  margin-top: 10px;
  font-size: 13px;
  color: #1d4ed8;
}

.approval-preview-card {
  padding: 14px 16px;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  background: #fff;
}

.approval-preview-card__title {
  margin-bottom: 10px;
  font-size: 14px;
  font-weight: 600;
}

.approval-preview-list {
  display: grid;
  gap: 10px;
}

.approval-preview-item {
  display: flex;
  gap: 10px;
  align-items: flex-start;
}

.approval-preview-order {
  display: inline-flex;
  width: 22px;
  height: 22px;
  border-radius: 999px;
  align-items: center;
  justify-content: center;
  background: #dbeafe;
  color: #1d4ed8;
  font-size: 12px;
  font-weight: 600;
}

.approval-preview-label {
  font-size: 14px;
  color: #0f172a;
}

.approval-preview-meta {
  margin-top: 2px;
  font-size: 12px;
  color: #64748b;
}

.approval-preview-error {
  color: #dc2626;
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
