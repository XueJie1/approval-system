<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <h2 class="page-title">申请模板管理</h2>
        <p class="page-subtitle">维护申请模板名称、说明、表单绑定、默认流程、状态和排序</p>
      </div>
      <div class="heading-actions">
        <el-button :loading="loading" @click="loadTemplates">刷新</el-button>
        <el-button type="primary" @click="openCreateDialog">新增模板</el-button>
      </div>
    </div>

    <el-row :gutter="14" class="summary-grid">
      <el-col :xs="24" :sm="8">
        <div class="metric page-card">
          <div class="metric-label">模板总数</div>
          <div class="metric-value">{{ templates.length }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="8">
        <div class="metric page-card">
          <div class="metric-label">启用模板</div>
          <div class="metric-value">{{ activeCount }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="8">
        <div class="metric page-card">
          <div class="metric-label">未配置表单</div>
          <div class="metric-value">{{ unboundFormCount }}</div>
        </div>
      </el-col>
    </el-row>

    <div class="panel page-card stack">
      <el-alert
        type="warning"
        :closable="false"
        show-icon
        title="停用模板后，发起页将不再显示该模板，但已发起的申请不会受影响。"
      />

      <div class="toolbar wrap">
        <el-input v-model="keyword" clearable placeholder="按模板名称、标识或表单搜索" style="max-width: 320px" />
        <el-select v-model="statusFilter" clearable placeholder="状态" style="width: 140px">
          <el-option label="启用" value="ACTIVE" />
          <el-option label="停用" value="INACTIVE" />
        </el-select>
      </div>

      <el-table v-loading="loading" :data="filteredTemplates" border stripe row-key="id">
        <el-table-column prop="templateName" label="模板名称" min-width="160" />
        <el-table-column prop="templateKey" label="模板标识" min-width="140" />
        <el-table-column prop="category" label="分类" min-width="110" />
        <el-table-column prop="formName" label="表单名称" min-width="150">
          <template #default="{ row }">{{ row.formName || '-' }}</template>
        </el-table-column>
        <el-table-column prop="formKey" label="表单 Key" min-width="140">
          <template #default="{ row }">{{ row.formKey || '-' }}</template>
        </el-table-column>
        <el-table-column label="默认流程" min-width="180">
          <template #default="{ row }">
            {{ getProcessLabel(row.processKey) }}
          </template>
        </el-table-column>
        <el-table-column prop="sortOrder" label="排序" width="90" />
        <el-table-column label="使用情况" min-width="120">
          <template #default="{ row }">
            <el-tag :type="(row.usageCount ?? 0) > 0 ? 'warning' : 'info'">
              {{ (row.usageCount ?? 0) > 0 ? `使用中 ${row.usageCount}` : '未使用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'ACTIVE' ? 'success' : 'info'">{{ row.status === 'ACTIVE' ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="160" fixed="right">
          <template #default="{ row }">
            <el-space>
              <el-button link type="primary" @click="openEditDialog(row)">编辑</el-button>
              <el-button
                link
                :type="row.status === 'ACTIVE' ? 'warning' : 'success'"
                @click="toggleTemplateStatus(row)"
              >
                {{ row.status === 'ACTIVE' ? '停用' : '启用' }}
              </el-button>
            </el-space>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑模板' : '新增模板'" width="720px">
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top" class="form-grid two-columns">
        <el-form-item label="模板名称" prop="templateName">
          <el-input v-model="form.templateName" maxlength="128" show-word-limit />
        </el-form-item>
        <el-form-item label="模板标识" prop="templateKey">
          <el-input v-model="form.templateKey" maxlength="64" show-word-limit :disabled="Boolean(editingId)" />
        </el-form-item>
        <el-form-item label="分类">
          <el-input v-model="form.category" maxlength="64" show-word-limit />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sortOrder" :min="0" :max="9999" style="width: 100%" />
        </el-form-item>
        <el-form-item label="表单绑定" class="full-span">
          <el-select
            v-model="selectedFormDefinitionId"
            clearable
            filterable
            placeholder="请选择已有表单定义"
            style="width: 100%"
            @change="handleFormBindingChange"
          >
            <el-option
              v-for="item in formDefinitions"
              :key="item.id"
              :label="`${item.formName} · ${item.formKey}`"
              :value="item.id"
            />
          </el-select>
          <div class="field-hint">选择后会自动回填表单名称和表单 Key</div>
        </el-form-item>
        <el-form-item label="表单名称">
          <el-input v-model="form.formName" maxlength="128" show-word-limit readonly />
        </el-form-item>
        <el-form-item label="表单 Key">
          <el-input v-model="form.formKey" maxlength="64" show-word-limit readonly placeholder="请选择表单定义后自动回填" />
        </el-form-item>
        <el-form-item label="默认流程" prop="processKey">
          <el-select v-model="form.processKey" filterable style="width: 100%" placeholder="请选择已有流程定义">
            <el-option
              v-for="item in workflowDefinitions"
              :key="item.id"
              :label="`${item.processName} · ${item.processKey}`"
              :value="item.processKey"
            />
          </el-select>
          <div class="field-hint">从系统已有流程定义中选择默认流程</div>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="form.status" style="width: 100%">
            <el-option label="启用" value="ACTIVE" />
            <el-option label="停用" value="INACTIVE" />
          </el-select>
        </el-form-item>
        <el-form-item label="会签模式">
          <el-select v-model="form.countersignMode" style="width: 100%">
            <el-option label="全票通过" value="ALL" />
            <el-option label="多数通过" value="MAJORITY" />
          </el-select>
        </el-form-item>
        <el-form-item label="通过比例">
          <el-input v-model="form.passRatio" placeholder="例如 1.0 或 0.5" />
        </el-form-item>
        <el-form-item label="允许发起时手动指定审批人">
          <el-switch v-model="form.allowManualApproverSelect" />
          <div class="field-hint">标准模板默认关闭，仅特殊模板建议开启</div>
        </el-form-item>
        <el-form-item label="审批规则" class="full-span">
          <div class="approval-rules stack">
            <div v-for="(rule, ruleIndex) in approvalRules" :key="ruleIndex" class="approval-rule-card">
              <el-input v-model="rule.name" placeholder="规则名称，例如：金额超过 5000" style="max-width: 280px" />
              <div class="approval-step-row">
                <div v-for="(condition, conditionIndex) in rule.conditions ?? []" :key="conditionIndex" class="approval-step-row">
                  <el-select v-model="condition.field" style="width: 140px">
                    <el-option label="请假天数" value="days" />
                    <el-option label="金额" value="amount" />
                    <el-option label="预算" value="budget" />
                  </el-select>
                  <el-select v-model="condition.operator" style="width: 110px">
                    <el-option label=">" value="GT" />
                    <el-option label=">=" value="GTE" />
                    <el-option label="<" value="LT" />
                    <el-option label="<=" value="LTE" />
                    <el-option label="=" value="EQ" />
                  </el-select>
                  <el-input-number v-model="condition.value" :min="0" style="width: 140px" />
                  <el-button link type="danger" @click="removeApprovalCondition(ruleIndex, conditionIndex)">删除条件</el-button>
                </div>
                <el-button plain @click="addApprovalCondition(ruleIndex)">新增条件</el-button>
              </div>
              <div v-for="(step, stepIndex) in rule.steps" :key="stepIndex" class="approval-step-row">
                <el-select v-model="step.type" style="width: 220px">
                  <el-option label="直属主管" value="MANAGER" />
                  <el-option label="部门负责人" value="DEPT_LEADER" />
                  <el-option label="上级部门负责人" value="PARENT_DEPT_LEADER" />
                  <el-option label="指定用户" value="SPECIFIC_USER" />
                </el-select>
                <el-select
                  v-if="step.type === 'SPECIFIC_USER'"
                  v-model="step.userId"
                  filterable
                  clearable
                  placeholder="请选择审批人"
                  style="width: 220px"
                >
                  <el-option
                    v-for="user in approverOptions"
                    :key="user.userId"
                    :label="user.username"
                    :value="user.userId"
                  />
                </el-select>
                <el-button link type="danger" @click="removeApprovalStep(ruleIndex, stepIndex)">删除步骤</el-button>
              </div>
              <div class="approval-step-row">
                <el-button plain @click="addApprovalStep(ruleIndex)">新增审批步骤</el-button>
                <el-button link type="danger" @click="removeApprovalRule(ruleIndex)">删除规则</el-button>
              </div>
            </div>
            <el-button plain @click="addApprovalRule">新增规则</el-button>
            <div class="field-hint">不设置条件表示默认生效；命中条件的规则会继续追加审批步骤。</div>
          </div>
        </el-form-item>
        <el-form-item label="模板说明" class="full-span">
          <el-input v-model="form.description" type="textarea" :rows="3" maxlength="512" show-word-limit />
        </el-form-item>
        <el-form-item label="默认流程说明" class="full-span">
          <el-input v-model="form.flowSummary" type="textarea" :rows="3" maxlength="512" show-word-limit />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="submitForm">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue';
import { ElMessage, type FormInstance, type FormRules } from 'element-plus';
import type { FormDefinitionSummary, RequestTemplateApprovalCondition, RequestTemplateApprovalRule, RequestTemplateApprovalStep, RequestTemplateSummary, RequestTemplateUpsertPayload, UserDirectoryItem, WorkflowDefinitionSummary } from '../types';
import { createRequestTemplate, listAdminRequestTemplates, updateRequestTemplate } from '../api/admin-request-templates';
import { listLaunchableWorkflowDefinitions } from '../api/admin-workflows';
import { listFormDefinitions } from '../api/forms';
import { listUsers } from '../api/users';

const loading = ref(false);
const saving = ref(false);
const dialogVisible = ref(false);
const editingId = ref<number | null>(null);
const keyword = ref('');
const statusFilter = ref<string | undefined>(undefined);
const templates = ref<RequestTemplateSummary[]>([]);
const formDefinitions = ref<FormDefinitionSummary[]>([]);
const workflowDefinitions = ref<WorkflowDefinitionSummary[]>([]);
const approverOptions = ref<UserDirectoryItem[]>([]);
const selectedFormDefinitionId = ref<number | null>(null);
const formRef = ref<FormInstance>();
const approvalRules = ref<RequestTemplateApprovalRule[]>([]);

const form = reactive<RequestTemplateUpsertPayload>({
  templateKey: '',
  templateName: '',
  category: '',
  description: '',
  formKey: '',
  formName: '',
  processKey: 'approvalSequential',
  countersignMode: 'ALL',
  passRatio: '1.0',
  flowSummary: '',
  approvalConfig: { rules: [] },
  allowManualApproverSelect: false,
  sortOrder: 0,
  status: 'ACTIVE'
});

const rules: FormRules = {
  templateName: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
  templateKey: [{ required: true, message: '请输入模板标识', trigger: 'blur' }],
  processKey: [{ required: true, message: '请选择默认流程', trigger: 'change' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
};

const filteredTemplates = computed(() => {
  return templates.value.filter((item) => {
    const hitKeyword = !keyword.value.trim()
      || [item.templateName, item.templateKey, item.formName, item.formKey]
        .filter(Boolean)
        .some((value) => value?.toLowerCase().includes(keyword.value.trim().toLowerCase()));
    const hitStatus = !statusFilter.value || item.status === statusFilter.value;
    return hitKeyword && hitStatus;
  });
});

const activeCount = computed(() => templates.value.filter(item => item.status === 'ACTIVE').length);
const unboundFormCount = computed(() => templates.value.filter(item => !item.formKey).length);

onMounted(() => {
  loadFormDefinitions();
  loadWorkflowDefinitions();
  loadApproverOptions();
  loadTemplates();
});

async function loadApproverOptions() {
  try {
    approverOptions.value = await listUsers({ status: 1 });
  } catch (e) {
    console.error(e);
    ElMessage.error('加载审批人列表失败');
  }
}

async function loadFormDefinitions() {
  try {
    formDefinitions.value = await listFormDefinitions();
  } catch (e) {
    console.error(e);
    ElMessage.error('加载表单定义失败');
  }
}

async function loadTemplates() {
  loading.value = true;
  try {
    templates.value = await listAdminRequestTemplates();
  } catch (e) {
    console.error(e);
    ElMessage.error('加载申请模板失败');
  } finally {
    loading.value = false;
  }
}

async function loadWorkflowDefinitions() {
  try {
    workflowDefinitions.value = await listLaunchableWorkflowDefinitions();
  } catch (e) {
    console.error(e);
    ElMessage.error('加载可发起流程失败');
  }
}

function resetForm() {
  editingId.value = null;
  form.templateKey = '';
  form.templateName = '';
  form.category = '';
  form.description = '';
  form.formKey = '';
  form.formName = '';
  selectedFormDefinitionId.value = null;
  form.processKey = 'approvalSequential';
  form.countersignMode = 'ALL';
  form.passRatio = '1.0';
  form.flowSummary = '';
  form.approvalConfig = { rules: [] };
  form.allowManualApproverSelect = false;
  approvalRules.value = [];
  form.sortOrder = 0;
  form.status = 'ACTIVE';
}

function openCreateDialog() {
  resetForm();
  dialogVisible.value = true;
}

function openEditDialog(row: RequestTemplateSummary) {
  editingId.value = row.id;
  form.templateKey = row.templateKey;
  form.templateName = row.templateName;
  form.category = row.category ?? '';
  form.description = row.description ?? '';
  form.formKey = row.formKey ?? '';
  form.formName = row.formName ?? '';
  selectedFormDefinitionId.value = formDefinitions.value.find(item => item.formKey === row.formKey)?.id ?? null;
  form.processKey = row.processKey;
  form.countersignMode = row.countersignMode;
  form.passRatio = row.passRatio;
  form.flowSummary = row.flowSummary ?? '';
  form.approvalConfig = row.approvalConfig ?? { rules: [] };
  form.allowManualApproverSelect = Boolean(row.allowManualApproverSelect);
  approvalRules.value = [...(row.approvalConfig?.rules ?? [])].map(rule => ({
    name: rule.name ?? '',
    conditions: [...(rule.conditions ?? [])],
    steps: [...(rule.steps ?? [])]
  }));
  form.sortOrder = row.sortOrder;
  form.status = row.status;
  dialogVisible.value = true;
}

function addApprovalRule() {
  approvalRules.value.push({ name: '', conditions: [], steps: [{ type: 'MANAGER', userId: null }] });
}

function removeApprovalRule(index: number) {
  approvalRules.value.splice(index, 1);
}

function addApprovalCondition(ruleIndex: number) {
  approvalRules.value[ruleIndex]?.conditions?.push({ field: 'days', operator: 'GT', value: 1 } as RequestTemplateApprovalCondition);
}

function removeApprovalCondition(ruleIndex: number, conditionIndex: number) {
  approvalRules.value[ruleIndex]?.conditions?.splice(conditionIndex, 1);
}

function addApprovalStep(ruleIndex: number) {
  approvalRules.value[ruleIndex]?.steps.push({ type: 'MANAGER', userId: null } as RequestTemplateApprovalStep);
}

function removeApprovalStep(ruleIndex: number, stepIndex: number) {
  approvalRules.value[ruleIndex]?.steps.splice(stepIndex, 1);
}

function handleFormBindingChange(value: number | null) {
  if (!value) {
    form.formKey = '';
    form.formName = '';
    return;
  }
  const selected = formDefinitions.value.find(item => item.id === value);
  if (!selected) {
    return;
  }
  form.formKey = selected.formKey;
  form.formName = selected.formName;
}

function getProcessLabel(processKey: string) {
  const matched = workflowDefinitions.value.find(item => item.processKey === processKey);
  if (!matched) {
    return processKey;
  }
  return `${matched.processName} · ${matched.processKey}`;
}

async function submitForm() {
  const valid = await formRef.value?.validate().catch(() => false);
  if (!valid) {
    return;
  }

  saving.value = true;
  try {
    const payload: RequestTemplateUpsertPayload = {
      ...form,
      category: form.category?.trim() || null,
      description: form.description?.trim() || null,
      formKey: form.formKey?.trim() || null,
      formName: form.formName?.trim() || null,
      flowSummary: form.flowSummary?.trim() || null,
      approvalConfig: {
        rules: approvalRules.value
          .filter(rule => rule.steps?.length)
          .map(rule => ({
            name: rule.name?.trim() || null,
            conditions: (rule.conditions ?? []).map(condition => ({
              field: condition.field,
              operator: condition.operator,
              value: Number(condition.value)
            })),
            steps: rule.steps
              .filter(step => step.type && (step.type !== 'SPECIFIC_USER' || step.userId))
              .map(step => ({ type: step.type, userId: step.type === 'SPECIFIC_USER' ? step.userId ?? null : null }))
          }))
      },
      allowManualApproverSelect: Boolean(form.allowManualApproverSelect)
    };

    if (editingId.value) {
      await updateRequestTemplate(editingId.value, payload);
      ElMessage.success('模板已更新');
    } else {
      await createRequestTemplate(payload);
      ElMessage.success('模板已创建');
    }

    dialogVisible.value = false;
    await loadTemplates();
  } catch (e) {
    console.error(e);
    ElMessage.error(editingId.value ? '更新模板失败' : '创建模板失败');
  } finally {
    saving.value = false;
  }
}

async function toggleTemplateStatus(row: RequestTemplateSummary) {
  try {
    await updateRequestTemplate(row.id, {
      templateKey: row.templateKey,
      templateName: row.templateName,
      category: row.category ?? null,
      description: row.description ?? null,
      formKey: row.formKey ?? null,
      formName: row.formName ?? null,
      processKey: row.processKey,
      countersignMode: row.countersignMode,
      passRatio: row.passRatio,
       flowSummary: row.flowSummary ?? null,
       approvalConfig: row.approvalConfig ?? { rules: [] },
       allowManualApproverSelect: Boolean(row.allowManualApproverSelect),
       sortOrder: row.sortOrder,
       status: row.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE'
     });
    ElMessage.success(row.status === 'ACTIVE' ? '模板已停用' : '模板已启用');
    await loadTemplates();
  } catch (e) {
    console.error(e);
    ElMessage.error(row.status === 'ACTIVE' ? '停用模板失败' : '启用模板失败');
  }
}
</script>

<style scoped>
.stack {
  display: grid;
  gap: 16px;
}

.heading {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
  flex-wrap: wrap;
}

.page-title {
  margin: 0;
  font-size: 24px;
}

.page-subtitle {
  margin: 6px 0 0;
  color: #64748b;
}

.heading-actions,
.toolbar.wrap {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.summary-grid {
  margin: 0;
}

.metric {
  padding: 18px;
}

.metric-label {
  font-size: 13px;
  color: #64748b;
}

.metric-value {
  margin-top: 8px;
  font-size: 28px;
  font-weight: 700;
}

.panel {
  padding: 18px;
}

.form-grid.two-columns {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px 16px;
}

.full-span {
  grid-column: 1 / -1;
}

.approval-step-row {
  display: flex;
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
}

.approval-rule-card {
  display: grid;
  gap: 10px;
  padding: 12px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #f8fafc;
}

@media (max-width: 900px) {
  .form-grid.two-columns {
    grid-template-columns: 1fr;
  }
}
</style>
