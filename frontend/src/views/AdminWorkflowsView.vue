<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <h2 class="page-title">流程管理</h2>
        <p class="page-subtitle">管理流程定义、版本发布、节点元数据与使用追溯</p>
      </div>
    </div>

    <el-row :gutter="14" class="summary-grid">
      <el-col :xs="24" :sm="12" :lg="8">
        <div class="metric page-card">
          <div class="metric-label">流程总数</div>
          <div class="metric-value">{{ definitionPage.total }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="8">
        <div class="metric page-card">
          <div class="metric-label">已发布版本</div>
          <div class="metric-value">{{ publishedCount }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="8">
        <div class="metric page-card">
          <div class="metric-label">草稿版本</div>
          <div class="metric-value">{{ draftCount }}</div>
        </div>
      </el-col>
    </el-row>

    <div class="workflow-shell">
      <section class="left-column stack">
        <div class="panel page-card">
          <div class="toolbar wrap">
            <el-input v-model="query.keyword" clearable placeholder="按流程标识或名称搜索" @input="debounceSearch">
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-input v-model="query.category" clearable placeholder="分类" @input="debounceSearch" />
            <el-select v-model="query.status" clearable placeholder="状态" style="width: 150px" @change="debounceSearch">
              <el-option v-for="item in definitionStatuses" :key="item" :label="item" :value="item" />
            </el-select>
            <el-button @click="resetQuery">重置</el-button>
            <el-button type="primary" @click="openCreateDefinitionDialog">
              <el-icon><Plus /></el-icon>
              新建流程
            </el-button>
          </div>

          <el-table
            v-loading="definitionLoading"
            :data="definitionPage.content"
            border
            stripe
            highlight-current-row
            row-key="id"
            @current-change="handleDefinitionSelect"
            @row-click="handleDefinitionSelect"
          >
            <el-table-column prop="processName" label="流程名称" min-width="180" />
            <el-table-column prop="processKey" label="标识" min-width="160" />
            <el-table-column prop="category" label="分类" min-width="100" show-overflow-tooltip />
            <el-table-column label="状态" width="120">
              <template #default="{ row }">
                <el-tag :type="definitionStatusType(row.status)">{{ row.status }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="当前版本" width="110">
              <template #default="{ row }">
                {{ row.currentVersionNo ? `v${row.currentVersionNo}` : "-" }}
              </template>
            </el-table-column>
          </el-table>

          <div class="pager">
            <el-pagination
              background
              layout="total, sizes, prev, pager, next"
              :current-page="query.page + 1"
              :page-size="query.size"
              :page-sizes="[10, 20, 50]"
              :total="definitionPage.total"
              @current-change="changeDefinitionPage"
              @size-change="changeDefinitionPageSize"
            />
          </div>
        </div>
      </section>

      <section class="right-column stack">
        <div class="panel page-card" v-if="selectedDefinition">
          <div class="panel-head">
            <div>
              <div class="panel-title">{{ selectedDefinition.processName }}</div>
              <div class="panel-subtitle">
                <el-tag :type="definitionStatusType(selectedDefinition.status)" size="small">{{ selectedDefinition.status }}</el-tag>
                <span class="ml-8">{{ selectedDefinition.processKey }}</span>
                <span v-if="selectedDefinition.category" class="ml-8">· 分类：{{ selectedDefinition.category }}</span>
              </div>
            </div>
            <div class="toolbar wrap compact">
              <el-button @click="openEditDefinition">编辑</el-button>
              <el-dropdown trigger="click" @command="handleDefinitionAction">
                <el-button type="danger" plain>
                  更多操作<el-icon class="el-icon--right"><ArrowDown /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="inactivate" :disabled="selectedDefinition.status === 'INACTIVE' || selectedDefinition.status === 'ARCHIVED'">停用</el-dropdown-item>
                    <el-dropdown-item command="archive" :disabled="selectedDefinition.status === 'ARCHIVED'">归档</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </div>

          <el-descriptions :column="2" border>
            <el-descriptions-item label="流程标识">{{ selectedDefinition.processKey }}</el-descriptions-item>
            <el-descriptions-item label="流程名称">{{ selectedDefinition.processName }}</el-descriptions-item>
            <el-descriptions-item label="分类">{{ selectedDefinition.category || '-' }}</el-descriptions-item>
            <el-descriptions-item label="当前版本">
              {{ selectedDefinition.currentVersionNo ? `v${selectedDefinition.currentVersionNo}` : '-' }}
            </el-descriptions-item>
            <el-descriptions-item label="描述" :span="2">{{ selectedDefinition.description || '暂无描述' }}</el-descriptions-item>
          </el-descriptions>
        </div>

        <el-empty v-else description="请从左侧列表选择一个流程定义，查看或编辑详细信息" class="page-card empty-state" />

        <template v-if="selectedDefinition">
          <el-tabs v-model="activeTab" class="tabs">
            <el-tab-pane label="版本管理" name="versions">
              <div class="stack">
                <div class="panel page-card">
                  <div class="toolbar wrap">
                    <el-button type="primary" @click="openCreateVersion">
                      <el-icon><Plus /></el-icon>
                      新建版本
                    </el-button>
                    <el-button :disabled="!selectedDefinition" @click="loadVersions">刷新</el-button>
                    <el-text type="info">选择版本后进入二级详情页</el-text>
                  </div>

                  <el-table
                    v-loading="versionLoading"
                    :data="versionList"
                    border
                    stripe
                    highlight-current-row
                    row-key="id"
                    @row-click="openVersionDetail"
                  >
                    <el-table-column label="版本号" width="100">
                      <template #default="{ row }">v{{ row.versionNo }}</template>
                    </el-table-column>
                    <el-table-column prop="versionLabel" label="版本标签" min-width="130" />
                    <el-table-column label="状态" width="120">
                      <template #default="{ row }">
                        <el-tag :type="versionStatusType(row.status)">{{ row.status }}</el-tag>
                      </template>
                    </el-table-column>
                    <el-table-column prop="formKey" label="表单 Key" min-width="140" />
                    <el-table-column prop="formVersionId" label="表单版本" width="120" />
                    <el-table-column label="发布时间" min-width="170">
                      <template #default="{ row }">{{ formatDateTime(row.publishedAt) }}</template>
                    </el-table-column>
                    <el-table-column label="说明" min-width="200">
                      <template #default="{ row }">{{ row.changeSummary || '-' }}</template>
                    </el-table-column>
                    <el-table-column label="操作" width="130" fixed="right">
                      <template #default="{ row }">
                        <el-button type="primary" link @click.stop="openVersionDetail(row)">版本详情</el-button>
                      </template>
                    </el-table-column>
                  </el-table>
                </div>
              </div>
            </el-tab-pane>

          </el-tabs>
        </template>
      </section>
    </div>

    <el-dialog v-model="createDefinitionDialogVisible" title="新建流程定义" width="560px">
      <el-form ref="createDefinitionFormRef" :model="createDefinitionForm" :rules="definitionRules" label-position="top" class="form-grid">
        <el-form-item label="流程标识" prop="processKey">
          <el-input v-model="createDefinitionForm.processKey" maxlength="64" show-word-limit placeholder="例如 approvalTravel" />
        </el-form-item>
        <el-form-item label="流程名称" prop="processName">
          <el-input v-model="createDefinitionForm.processName" maxlength="128" show-word-limit placeholder="例如 差旅申请流程" />
        </el-form-item>
        <el-form-item label="分类">
          <el-input v-model="createDefinitionForm.category" maxlength="64" show-word-limit placeholder="例如 OA / 财务" />
        </el-form-item>
        <el-form-item label="描述" class="full-span">
          <el-input v-model="createDefinitionForm.description" type="textarea" :rows="3" maxlength="512" show-word-limit />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createDefinitionDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="createDefinitionLoading" @click="submitCreateDefinition">创建</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="editDefinitionDialogVisible" title="编辑流程定义" width="720px">
      <el-form ref="editDefinitionFormRef" :model="editDefinitionForm" :rules="{ processName: [{ required: true, message: '请输入流程名称', trigger: 'blur' }] }" label-position="top" class="form-grid">
        <el-form-item label="流程名称" prop="processName">
          <el-input v-model="editDefinitionForm.processName" maxlength="128" show-word-limit />
        </el-form-item>
        <el-form-item label="分类">
          <el-input v-model="editDefinitionForm.category" maxlength="64" show-word-limit />
        </el-form-item>
        <el-form-item label="描述" class="full-span">
          <el-input v-model="editDefinitionForm.description" type="textarea" :rows="4" maxlength="512" show-word-limit />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDefinitionDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="editDefinitionLoading" @click="submitEditDefinition">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="createVersionDialogVisible" title="创建版本草稿" width="560px">
      <el-form :model="createVersionForm" label-position="top" class="form-grid">
        <el-form-item label="复制来源版本">
          <el-select v-model="createVersionForm.copyFromVersionId" clearable placeholder="可选，复制已有版本">
            <el-option v-for="item in versionList" :key="item.id" :label="`v${item.versionNo} · ${item.status}`" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="版本标签">
          <el-input v-model="createVersionForm.versionLabel" maxlength="64" show-word-limit />
        </el-form-item>
        <el-form-item label="版本说明" class="full-span">
          <el-input v-model="createVersionForm.changeSummary" type="textarea" :rows="3" maxlength="1000" show-word-limit />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createVersionDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="createVersionLoading" @click="submitCreateVersion">创建</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from "vue";
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from "element-plus";
import { Search, Plus, ArrowDown } from "@element-plus/icons-vue";
import { useRouter } from "vue-router";
import type {
  PageResult,
  WorkflowDefinitionPayload,
  WorkflowDefinitionSummary,
  WorkflowVersionSummary
} from "../types";
import {
  archiveWorkflowDefinition,
  createWorkflowDefinition,
  createWorkflowVersion,
  inactivateWorkflowDefinition,
  listWorkflowDefinitions,
  listWorkflowVersions,
  updateWorkflowDefinition
} from "../api/admin-workflows";

const router = useRouter();

const definitionStatuses = ["DRAFT", "ACTIVE", "INACTIVE", "ARCHIVED"];

const activeTab = ref("versions");
const definitionLoading = ref(false);
const createDefinitionLoading = ref(false);
const editDefinitionLoading = ref(false);
const versionLoading = ref(false);
const createVersionLoading = ref(false);

const createDefinitionFormRef = ref<FormInstance>();
const editDefinitionFormRef = ref<FormInstance>();

const editDefinitionDialogVisible = ref(false);
const createDefinitionDialogVisible = ref(false);
const createVersionDialogVisible = ref(false);

let searchTimer: ReturnType<typeof setTimeout> | null = null;

const query = reactive({
  keyword: "",
  category: "",
  status: "",
  page: 0,
  size: 10
});

const definitionPage = ref<PageResult<WorkflowDefinitionSummary>>({
  content: [],
  total: 0,
  page: 0,
  size: 10,
  totalPages: 0
});

const selectedDefinition = ref<WorkflowDefinitionSummary | null>(null);
const versionList = ref<WorkflowVersionSummary[]>([]);
const selectedVersion = ref<WorkflowVersionSummary | null>(null);

const createDefinitionForm = reactive<WorkflowDefinitionPayload>({
  processKey: "",
  processName: "",
  category: "",
  description: ""
});

const editDefinitionForm = reactive({
  processName: "",
  category: "",
  description: ""
});

const createVersionForm = reactive({
  copyFromVersionId: undefined as number | undefined,
  versionLabel: "",
  changeSummary: ""
});

const definitionRules: FormRules = {
  processKey: [
    { required: true, message: "请输入流程标识", trigger: "blur" },
    { pattern: /^[A-Za-z][A-Za-z0-9_]*$/, message: "流程标识仅支持字母开头的字母数字下划线", trigger: "blur" }
  ],
  processName: [{ required: true, message: "请输入流程名称", trigger: "blur" }]
};

const publishedCount = computed(() => versionList.value.filter((item) => item.status === "PUBLISHED").length);
const draftCount = computed(() => versionList.value.filter((item) => item.status === "DRAFT").length);

onMounted(async () => {
  await loadDefinitions();
});

onBeforeUnmount(() => {
  if (searchTimer) {
    clearTimeout(searchTimer);
  }
});

async function loadDefinitions() {
  definitionLoading.value = true;
  try {
    definitionPage.value = await listWorkflowDefinitions({
      keyword: query.keyword.trim() || undefined,
      category: query.category.trim() || undefined,
      status: query.status || undefined,
      page: query.page,
      size: query.size
    });

    if (selectedDefinition.value) {
      const latest = definitionPage.value.content.find((item) => item.id === selectedDefinition.value?.id);
      if (latest) {
        selectedDefinition.value = latest;
      }
    }

    if (!selectedDefinition.value && definitionPage.value.content.length > 0) {
      await handleDefinitionSelect(definitionPage.value.content[0]);
    }
  } finally {
    definitionLoading.value = false;
  }
}

async function searchDefinitions() {
  query.page = 0;
  await loadDefinitions();
}

function debounceSearch() {
  if (searchTimer) {
    clearTimeout(searchTimer);
  }
  searchTimer = setTimeout(() => {
    void searchDefinitions();
  }, 400);
}

function openCreateDefinitionDialog() {
  resetCreateDefinitionForm();
  createDefinitionDialogVisible.value = true;
}

async function resetQuery() {
  query.keyword = "";
  query.category = "";
  query.status = "";
  query.page = 0;
  await loadDefinitions();
}

async function changeDefinitionPage(page: number) {
  query.page = page - 1;
  await loadDefinitions();
}

async function changeDefinitionPageSize(size: number) {
  query.size = size;
  query.page = 0;
  await loadDefinitions();
}

async function handleDefinitionSelect(row: WorkflowDefinitionSummary | null) {
  if (!row || selectedDefinition.value?.id === row.id) {
    return;
  }
  selectedDefinition.value = row;
  await loadVersions();
}

async function loadVersions() {
  if (!selectedDefinition.value) {
    versionList.value = [];
    selectedVersion.value = null;
    return;
  }
  versionLoading.value = true;
  try {
    versionList.value = await listWorkflowVersions(selectedDefinition.value.id);
    const target = selectedDefinition.value.currentVersionId
      ? versionList.value.find((item) => item.id === selectedDefinition.value?.currentVersionId)
      : versionList.value[0];
    selectedVersion.value = target ?? null;
  } finally {
    versionLoading.value = false;
  }
}

async function openVersionDetail(row: WorkflowVersionSummary) {
  if (!selectedDefinition.value) {
    return;
  }
  await router.push({
    name: "admin-workflow-version-detail",
    params: {
      definitionId: selectedDefinition.value.id,
      versionId: row.id
    }
  });
}

async function submitCreateDefinition() {
  await createDefinitionFormRef.value?.validate();
  createDefinitionLoading.value = true;
  try {
    const definition = await createWorkflowDefinition({
      processKey: createDefinitionForm.processKey.trim(),
      processName: createDefinitionForm.processName.trim(),
      category: createDefinitionForm.category?.trim() || undefined,
      description: createDefinitionForm.description?.trim() || undefined
    });
    ElMessage.success("流程定义已创建");
    createDefinitionDialogVisible.value = false;
    resetCreateDefinitionForm();
    await loadDefinitions();
    await handleDefinitionSelect(definition);
  } finally {
    createDefinitionLoading.value = false;
  }
}

function resetCreateDefinitionForm() {
  createDefinitionForm.processKey = "";
  createDefinitionForm.processName = "";
  createDefinitionForm.category = "";
  createDefinitionForm.description = "";
  createDefinitionFormRef.value?.clearValidate();
}

function openEditDefinition() {
  if (!selectedDefinition.value) {
    return;
  }
  editDefinitionForm.processName = selectedDefinition.value.processName;
  editDefinitionForm.category = selectedDefinition.value.category || "";
  editDefinitionForm.description = selectedDefinition.value.description || "";
  editDefinitionDialogVisible.value = true;
}

async function submitEditDefinition() {
  if (!selectedDefinition.value) {
    return;
  }
  await editDefinitionFormRef.value?.validate();
  editDefinitionLoading.value = true;
  try {
    selectedDefinition.value = await updateWorkflowDefinition(selectedDefinition.value.id, {
      processName: editDefinitionForm.processName.trim(),
      category: editDefinitionForm.category.trim() || undefined,
      description: editDefinitionForm.description.trim() || undefined
    });
    ElMessage.success("流程定义已更新");
    editDefinitionDialogVisible.value = false;
    await loadDefinitions();
  } finally {
    editDefinitionLoading.value = false;
  }
}

async function handleDefinitionAction(command: string) {
  if (!selectedDefinition.value) {
    return;
  }
  const action = command as "inactivate" | "archive";
  const title = action === "archive" ? "归档流程定义" : "停用流程定义";
  const comment = await promptComment(title);
  if (comment === null) {
    return;
  }
  if (action === "archive") {
    await archiveWorkflowDefinition(selectedDefinition.value.id, comment);
    ElMessage.success("流程定义已归档");
  } else {
    await inactivateWorkflowDefinition(selectedDefinition.value.id, comment);
    ElMessage.success("流程定义已停用");
  }
  await loadDefinitions();
  await loadVersions();
}

function openCreateVersion() {
  createVersionForm.copyFromVersionId = selectedVersion.value?.id;
  createVersionForm.versionLabel = "";
  createVersionForm.changeSummary = "";
  createVersionDialogVisible.value = true;
}

async function submitCreateVersion() {
  if (!selectedDefinition.value) {
    return;
  }
  createVersionLoading.value = true;
  try {
    const version = await createWorkflowVersion(selectedDefinition.value.id, {
      copyFromVersionId: createVersionForm.copyFromVersionId,
      versionLabel: createVersionForm.versionLabel.trim() || undefined,
      changeSummary: createVersionForm.changeSummary.trim() || undefined
    });
    ElMessage.success("版本草稿已创建");
    createVersionDialogVisible.value = false;
    await loadVersions();
    await openVersionDetail(version);
    activeTab.value = "versions";
  } finally {
    createVersionLoading.value = false;
  }
}

async function promptComment(title: string) {
  try {
    const result = await ElMessageBox.prompt("请输入操作说明，可为空", title, {
      confirmButtonText: "确认",
      cancelButtonText: "取消",
      inputValue: ""
    });
    return result.value;
  } catch {
    return null;
  }
}

function definitionStatusType(status: string) {
  if (status === "ACTIVE") {
    return "success";
  }
  if (status === "INACTIVE") {
    return "warning";
  }
  if (status === "ARCHIVED") {
    return "info";
  }
  return "primary";
}

function versionStatusType(status: string) {
  if (status === "PUBLISHED") {
    return "success";
  }
  if (status === "INACTIVE") {
    return "warning";
  }
  if (status === "RETIRED") {
    return "info";
  }
  return "primary";
}

function formatDateTime(value?: string | null) {
  if (!value) {
    return "-";
  }
  return value.replace("T", " ").slice(0, 19);
}
</script>


<style scoped>
.stack {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.admin-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.heading {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.summary-grid,
.usage-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
}

.metric {
  padding: 18px;
}

.metric-label {
  color: var(--text-subtle);
  font-size: 13px;
}

.metric-value {
  margin-top: 10px;
  font-size: 28px;
  font-weight: 700;
  color: #0f172a;
}

.workflow-shell {
  display: grid;
  grid-template-columns: minmax(320px, 380px) minmax(0, 1fr);
  gap: 18px;
  align-items: start;
}

.panel {
  padding: 18px;
}

.inner-card {
  border-radius: 12px;
  border: 1px solid rgba(148, 163, 184, 0.28);
  background: linear-gradient(180deg, rgba(248, 250, 252, 0.85) 0%, rgba(241, 245, 249, 0.92) 100%);
  box-shadow: none;
}

.panel-head {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
  align-items: flex-start;
}

.panel-title {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
}

.panel-subtitle {
  margin-top: 6px;
  color: var(--text-subtle);
  font-size: 13px;
}

.toolbar {
  display: flex;
  gap: 10px;
  align-items: center;
  margin-bottom: 16px;
}

.toolbar.wrap {
  flex-wrap: wrap;
}

.toolbar.compact {
  margin-bottom: 0;
}

.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

.empty-state {
  padding: 42px 24px;
}

.full-span {
  grid-column: 1 / -1;
}

.binding-summary {
  padding: 14px 16px;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px 18px;
  font-size: 13px;
  color: var(--text-main);
}

.sub-panel {
  padding: 16px;
}

.panel-title.small {
  font-size: 15px;
}

.mono-input :deep(textarea) {
  font-family: ui-monospace, SFMono-Regular, SFMono-Regular, Menlo, Monaco, Consolas, Liberation Mono, monospace;
  font-size: 12px;
  line-height: 1.55;
}

.two-columns {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.ml-8 {
  margin-left: 8px;
}

.node-expand-content {
  padding: 16px 20px;
  background: #f8fafc;
}

.bpmn-editor {
  width: 100%;
}

.bpmn-editor-content {
  width: 100%;
}

.bpmn-editor-content.is-bpmn-fullscreen {
  position: fixed;
  z-index: 2200;
  margin: 0;
  padding: 16px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 20px 60px rgba(15, 23, 42, 0.22);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.bpmn-editor-content.is-bpmn-fullscreen :deep(.bpmn-visual-designer) {
  flex: 1;
  min-height: 0;
}

.bpmn-editor-content.is-bpmn-fullscreen .source-panel {
  flex: 1;
  min-height: 0;
}

.bpmn-mode-toolbar {
  margin-bottom: 0;
}

.source-panel {
  border: 1px dashed rgba(148, 163, 184, 0.5);
  border-radius: 10px;
  padding: 12px;
  background: rgba(248, 250, 252, 0.9);
}

:global(body.bpmn-editor-fullscreen-lock) {
  overflow: hidden;
}

@media (max-width: 1180px) {
  .workflow-shell {
    grid-template-columns: 1fr;
  }

  .summary-grid,
  .usage-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 768px) {
  .summary-grid,
  .usage-grid,
  .two-columns {
    grid-template-columns: 1fr;
  }

  .binding-summary {
    grid-template-columns: 1fr;
  }

  .panel-head,
  .heading {
    flex-direction: column;
  }
}
</style>
