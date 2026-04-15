<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <h2 class="page-title">表单管理</h2>
        <p class="page-subtitle">维护表单定义、版本发布、字段规则与样例校验</p>
      </div>
      <div class="heading-actions">
        <el-button :loading="loadingDefinitions" @click="loadDefinitions">刷新</el-button>
        <el-button type="primary" @click="openCreateDefinitionDialog">新建表单</el-button>
      </div>
    </div>

    <div class="toolbar">
      <el-input v-model="filters.keyword" clearable placeholder="按表单名称或 Key 搜索" style="max-width: 280px" />
      <el-select v-model="filters.status" clearable placeholder="状态" style="width: 120px">
        <el-option label="启用" :value="1" />
        <el-option label="停用" :value="0" />
      </el-select>
      <el-button @click="loadDefinitions">查询</el-button>
    </div>

    <div class="split-layout">
      <el-card shadow="never" class="panel">
        <template #header>
          <div class="panel-title">表单定义</div>
        </template>
        <el-table
          v-loading="loadingDefinitions"
          :data="definitions"
          row-key="id"
          border
          highlight-current-row
          @current-change="handleDefinitionSelect"
        >
          <el-table-column prop="formName" label="名称" min-width="150" />
          <el-table-column prop="formKey" label="Key" min-width="160" />
          <el-table-column label="最新版本" width="120">
            <template #default="{ row }">v{{ row.latestVersionNo ?? '-' }}</template>
          </el-table-column>
          <el-table-column label="已发布" width="120">
            <template #default="{ row }">v{{ row.publishedVersionNo ?? '-' }}</template>
          </el-table-column>
          <el-table-column label="状态" width="90">
            <template #default="{ row }">
              <el-tag :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="100" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click.stop="openEditDefinitionDialog(row)">编辑</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-card>

      <div class="stack">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-header">
              <span class="panel-title">版本管理</span>
              <div>
                <el-button size="small" :disabled="!selectedDefinition" @click="openCreateVersionDialog">创建版本</el-button>
                <el-button
                  size="small"
                  type="primary"
                  :disabled="!selectedVersion || selectedVersion.status !== 'DRAFT'"
                  @click="publishSelectedVersion"
                >发布版本</el-button>
                <el-button
                  size="small"
                  :disabled="!selectedVersion || selectedVersion.status === 'ARCHIVED'"
                  @click="archiveSelectedVersion"
                >归档版本</el-button>
              </div>
            </div>
          </template>

          <el-empty v-if="!selectedDefinition" description="请先选择左侧表单定义" />
          <el-table
            v-else
            v-loading="loadingVersions"
            :data="versions"
            row-key="id"
            border
            highlight-current-row
            @current-change="handleVersionSelect"
          >
            <el-table-column prop="version" label="版本" width="90">
              <template #default="{ row }">v{{ row.version }}</template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="120">
              <template #default="{ row }">
                <el-tag :type="statusTagType(row.status)">{{ row.status }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="fieldCount" label="字段数" width="90" />
            <el-table-column prop="publishedAt" label="发布时间" min-width="160">
              <template #default="{ row }">{{ formatTime(row.publishedAt) }}</template>
            </el-table-column>
          </el-table>
        </el-card>

        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-header">
              <span class="panel-title">字段设计</span>
              <div>
                <el-button size="small" :disabled="!canEditFields" @click="addFieldRow">新增字段</el-button>
                <el-button size="small" type="primary" :disabled="!canEditFields" @click="saveFields">保存字段</el-button>
              </div>
            </div>
          </template>

          <el-empty v-if="!selectedVersion" description="请先选择版本" />
          <div v-else class="stack">
            <el-alert
              :title="canEditFields ? '当前为草稿版本，可编辑字段。' : '仅草稿版本允许编辑字段，已发布/归档版本只读。'"
              type="info"
              :closable="false"
              show-icon
            />
            <el-table :data="editableFields" border>
              <el-table-column label="字段Key" min-width="140">
                <template #default="{ row }">
                  <el-input v-model="row.fieldKey" :disabled="!canEditFields" />
                </template>
              </el-table-column>
              <el-table-column label="变量Key" min-width="140">
                <template #default="{ row }">
                  <el-input v-model="row.variableKey" :disabled="!canEditFields" placeholder="默认同字段Key" />
                </template>
              </el-table-column>
              <el-table-column label="类型" width="120">
                <template #default="{ row }">
                  <el-select v-model="row.fieldType" :disabled="!canEditFields">
                    <el-option v-for="type in fieldTypeOptions" :key="type" :label="type" :value="type" />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="名称" min-width="120">
                <template #default="{ row }">
                  <el-input v-model="row.label" :disabled="!canEditFields" />
                </template>
              </el-table-column>
              <el-table-column label="必填" width="80">
                <template #default="{ row }">
                  <el-switch v-model="row.required" :disabled="!canEditFields" />
                </template>
              </el-table-column>
              <el-table-column label="默认值" min-width="130">
                <template #default="{ row }">
                  <el-input v-model="row.defaultValue" :disabled="!canEditFields" />
                </template>
              </el-table-column>
              <el-table-column label="校验规则(JSON)" min-width="170">
                <template #default="{ row }">
                  <el-input v-model="row.validateRule" :disabled="!canEditFields" placeholder='如 {"min":1}' />
                </template>
              </el-table-column>
              <el-table-column label="显隐规则(JSON)" min-width="170">
                <template #default="{ row }">
                  <el-input v-model="row.visibleRule" :disabled="!canEditFields" />
                </template>
              </el-table-column>
              <el-table-column label="下拉选项(JSON)" min-width="170">
                <template #default="{ row }">
                  <el-input v-model="row.optionsJson" :disabled="!canEditFields" placeholder='如 ["A","B"]' />
                </template>
              </el-table-column>
              <el-table-column label="排序" width="80">
                <template #default="{ row }">
                  <el-input-number v-model="row.sortOrder" :disabled="!canEditFields" :min="0" :controls="false" />
                </template>
              </el-table-column>
              <el-table-column label="操作" width="80" fixed="right">
                <template #default="{ $index }">
                  <el-button link type="danger" :disabled="!canEditFields" @click="removeFieldRow($index)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-card>

        <el-row :gutter="12">
          <el-col :span="12">
            <el-card shadow="never" class="panel">
              <template #header>
                <span class="panel-title">样例校验</span>
              </template>
              <el-input
                v-model="sampleJson"
                type="textarea"
                :rows="7"
                placeholder='请输入 JSON，例如 {"amount": 1000}'
              />
              <div class="panel-actions">
                <el-button type="primary" :disabled="!selectedVersion" @click="validateSample">校验样例</el-button>
              </div>
              <div v-if="sampleValidationMessage" class="hint">{{ sampleValidationMessage }}</div>
            </el-card>
          </el-col>
          <el-col :span="12">
            <el-card shadow="never" class="panel">
              <template #header>
                <span class="panel-title">影响分析</span>
              </template>
              <div v-if="!versionImpacts" class="hint">选择版本后自动加载</div>
              <div v-else class="stack">
                <div class="impact-line">申请模板引用：{{ versionImpacts.requestTemplateCount }}</div>
                <div class="impact-line">流程版本引用：{{ versionImpacts.workflowVersionCount }}</div>
                <div class="hint">模板：{{ versionImpacts.requestTemplates.map(item => item.templateName).join('、') || '无' }}</div>
                <div class="hint">流程：{{ versionImpacts.workflowVersions.map(item => `${item.definitionName || item.processKey || '-'} v${item.versionNo}`).join('、') || '无' }}</div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>
    </div>

    <el-dialog v-model="definitionDialogVisible" :title="editingDefinitionId ? '编辑表单定义' : '新建表单定义'" width="520px">
      <el-form label-position="top" :model="definitionForm">
        <el-form-item label="表单名称" required>
          <el-input v-model="definitionForm.formName" />
        </el-form-item>
        <el-form-item label="表单Key" required>
          <el-input v-model="definitionForm.formKey" :disabled="Boolean(editingDefinitionId)" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="definitionForm.status" style="width: 100%">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="definitionDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingDefinition" @click="submitDefinition">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="versionDialogVisible" title="创建版本" width="560px">
      <el-form label-position="top" :model="versionForm">
        <el-form-item label="复制来源版本">
          <el-select v-model="versionForm.copyFromVersionId" clearable style="width: 100%" placeholder="可选">
            <el-option
              v-for="item in versions"
              :key="item.id"
              :label="`v${item.version} · ${item.status}`"
              :value="item.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="Schema(JSON)">
          <el-input
            v-model="versionForm.schemaJson"
            type="textarea"
            :rows="5"
            placeholder='默认 {"fields": []}'
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="versionDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingVersion" @click="submitVersion">创建</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue';
import { ElMessage } from 'element-plus';
import type { AdminFormDefinitionSummary, AdminFormVersionSummary, FormField, FormVersionImpact } from '../types';
import {
  archiveAdminFormVersion,
  createAdminFormDefinition,
  createAdminFormVersion,
  getAdminFormVersionImpacts,
  listAdminFormDefinitions,
  listAdminFormVersionFields,
  listAdminFormVersions,
  publishAdminFormVersion,
  saveAdminFormVersionFields,
  updateAdminFormDefinition,
  validateAdminFormVersionSample
} from '../api/admin-forms';
import { normalizeFieldDrafts } from '../utils/form-management';

const loadingDefinitions = ref(false);
const loadingVersions = ref(false);
const savingDefinition = ref(false);
const savingVersion = ref(false);

const definitions = ref<AdminFormDefinitionSummary[]>([]);
const versions = ref<AdminFormVersionSummary[]>([]);
const editableFields = ref<Array<{
  fieldKey: string;
  variableKey?: string;
  fieldType: string;
  label?: string;
  required: boolean;
  visibleRule?: string;
  validateRule?: string;
  optionsJson?: string;
  defaultValue?: string;
  sortOrder: number;
}>>([]);

const versionImpacts = ref<FormVersionImpact | null>(null);
const sampleJson = ref('{\n  \n}');
const sampleValidationMessage = ref('');

const selectedDefinitionId = ref<number | null>(null);
const selectedVersionId = ref<number | null>(null);

const definitionDialogVisible = ref(false);
const versionDialogVisible = ref(false);
const editingDefinitionId = ref<number | null>(null);

const definitionForm = reactive({
  formKey: '',
  formName: '',
  status: 1
});

const versionForm = reactive({
  schemaJson: '{"fields": []}',
  copyFromVersionId: null as number | null
});

const filters = reactive({
  keyword: '',
  status: undefined as number | undefined
});

const fieldTypeOptions = ['string', 'number', 'date', 'datetime', 'select', 'table'];

const selectedDefinition = computed(() => definitions.value.find(item => item.id === selectedDefinitionId.value) ?? null);
const selectedVersion = computed(() => versions.value.find(item => item.id === selectedVersionId.value) ?? null);
const canEditFields = computed(() => selectedVersion.value?.status === 'DRAFT');

onMounted(() => {
  loadDefinitions();
});

async function loadDefinitions() {
  loadingDefinitions.value = true;
  try {
    definitions.value = await listAdminFormDefinitions({
      keyword: filters.keyword.trim() || undefined,
      status: filters.status
    });
  } catch (e) {
    console.error(e);
    ElMessage.error('加载表单定义失败');
  } finally {
    loadingDefinitions.value = false;
  }
}

async function handleDefinitionSelect(row?: AdminFormDefinitionSummary) {
  selectedDefinitionId.value = row?.id ?? null;
  selectedVersionId.value = null;
  versions.value = [];
  editableFields.value = [];
  versionImpacts.value = null;
  if (!row) {
    return;
  }
  await loadVersions(row.id);
}

async function loadVersions(definitionId: number) {
  loadingVersions.value = true;
  try {
    versions.value = await listAdminFormVersions(definitionId);
    if (versions.value.length > 0) {
      selectedVersionId.value = versions.value[0].id;
      await handleVersionSelect(versions.value[0]);
    }
  } catch (e) {
    console.error(e);
    ElMessage.error('加载表单版本失败');
  } finally {
    loadingVersions.value = false;
  }
}

async function handleVersionSelect(row?: AdminFormVersionSummary) {
  selectedVersionId.value = row?.id ?? null;
  editableFields.value = [];
  versionImpacts.value = null;
  sampleValidationMessage.value = '';
  if (!row) {
    return;
  }
  try {
    const fields = await listAdminFormVersionFields(row.id);
    editableFields.value = fields.map(mapFieldRow);
    versionImpacts.value = await getAdminFormVersionImpacts(row.id);
  } catch (e) {
    console.error(e);
    ElMessage.error('加载版本详情失败');
  }
}

function mapFieldRow(field: FormField) {
  return {
    fieldKey: field.fieldKey,
    variableKey: field.variableKey ?? '',
    fieldType: field.fieldType,
    label: field.label ?? '',
    required: field.required === 1,
    visibleRule: field.visibleRule ?? '',
    validateRule: field.validateRule ?? '',
    optionsJson: field.optionsJson ?? '',
    defaultValue: field.defaultValue ?? '',
    sortOrder: field.sortOrder ?? 0
  };
}

function addFieldRow() {
  editableFields.value.push({
    fieldKey: '',
    variableKey: '',
    fieldType: 'string',
    label: '',
    required: false,
    visibleRule: '',
    validateRule: '',
    optionsJson: '',
    defaultValue: '',
    sortOrder: editableFields.value.length
  });
}

function removeFieldRow(index: number) {
  editableFields.value.splice(index, 1);
}

async function saveFields() {
  if (!selectedVersion.value) {
    return;
  }
  try {
    const payload = normalizeFieldDrafts(editableFields.value);

    const saved = await saveAdminFormVersionFields(selectedVersion.value.id, payload);
    editableFields.value = saved.map(mapFieldRow);
    ElMessage.success('字段已保存');
  } catch (e) {
    console.error(e);
    ElMessage.error('保存字段失败');
  }
}

async function publishSelectedVersion() {
  if (!selectedVersion.value) return;
  try {
    await publishAdminFormVersion(selectedVersion.value.id);
    ElMessage.success('版本已发布');
    if (selectedDefinition.value) {
      await loadVersions(selectedDefinition.value.id);
      await loadDefinitions();
    }
  } catch (e) {
    console.error(e);
    ElMessage.error('发布失败');
  }
}

async function archiveSelectedVersion() {
  if (!selectedVersion.value) return;
  try {
    await archiveAdminFormVersion(selectedVersion.value.id);
    ElMessage.success('版本已归档');
    if (selectedDefinition.value) {
      await loadVersions(selectedDefinition.value.id);
    }
  } catch (e) {
    console.error(e);
    ElMessage.error('归档失败');
  }
}

async function validateSample() {
  if (!selectedVersion.value) return;
  try {
    const parsed = JSON.parse(sampleJson.value || '{}') as Record<string, unknown>;
    const result = await validateAdminFormVersionSample(selectedVersion.value.id, parsed);
    sampleValidationMessage.value = result.valid ? `校验通过：${formatTime(result.validatedAt)}` : '校验未通过';
    ElMessage.success('样例校验通过');
  } catch (e) {
    console.error(e);
    sampleValidationMessage.value = '样例校验失败';
  }
}

function openCreateDefinitionDialog() {
  editingDefinitionId.value = null;
  definitionForm.formKey = '';
  definitionForm.formName = '';
  definitionForm.status = 1;
  definitionDialogVisible.value = true;
}

function openEditDefinitionDialog(row: AdminFormDefinitionSummary) {
  editingDefinitionId.value = row.id;
  definitionForm.formKey = row.formKey;
  definitionForm.formName = row.formName;
  definitionForm.status = row.status;
  definitionDialogVisible.value = true;
}

async function submitDefinition() {
  if (!definitionForm.formName.trim() || !definitionForm.formKey.trim()) {
    ElMessage.warning('请填写表单名称和 Key');
    return;
  }
  savingDefinition.value = true;
  try {
    if (editingDefinitionId.value) {
      await updateAdminFormDefinition(editingDefinitionId.value, {
        formName: definitionForm.formName.trim(),
        status: definitionForm.status
      });
      ElMessage.success('表单定义已更新');
    } else {
      await createAdminFormDefinition({
        formKey: definitionForm.formKey.trim(),
        formName: definitionForm.formName.trim()
      });
      ElMessage.success('表单定义已创建');
    }
    definitionDialogVisible.value = false;
    await loadDefinitions();
  } catch (e) {
    console.error(e);
    ElMessage.error('保存表单定义失败');
  } finally {
    savingDefinition.value = false;
  }
}

function openCreateVersionDialog() {
  versionForm.schemaJson = '{"fields": []}';
  versionForm.copyFromVersionId = null;
  versionDialogVisible.value = true;
}

async function submitVersion() {
  if (!selectedDefinition.value) {
    return;
  }
  savingVersion.value = true;
  try {
    await createAdminFormVersion(selectedDefinition.value.id, {
      schemaJson: versionForm.schemaJson?.trim() || undefined,
      copyFromVersionId: versionForm.copyFromVersionId
    });
    versionDialogVisible.value = false;
    ElMessage.success('版本已创建');
    await loadVersions(selectedDefinition.value.id);
    await loadDefinitions();
  } catch (e) {
    console.error(e);
    ElMessage.error('创建版本失败');
  } finally {
    savingVersion.value = false;
  }
}

function statusTagType(status: string) {
  if (status === 'PUBLISHED') return 'success';
  if (status === 'DRAFT') return 'warning';
  return 'info';
}

function formatTime(value?: string | null) {
  if (!value) return '-';
  return new Date(value).toLocaleString('zh-CN', { hour12: false });
}
</script>

<style scoped>
.stack {
  display: grid;
  gap: 14px;
}

.heading {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: flex-start;
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
.toolbar,
.panel-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.split-layout {
  display: grid;
  grid-template-columns: 1.1fr 1.9fr;
  gap: 12px;
}

.panel {
  border-radius: 12px;
}

.panel-title {
  font-size: 15px;
  font-weight: 600;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  align-items: center;
}

.hint {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
}

.impact-line {
  font-size: 13px;
}

@media (max-width: 1280px) {
  .split-layout {
    grid-template-columns: 1fr;
  }
}
</style>
