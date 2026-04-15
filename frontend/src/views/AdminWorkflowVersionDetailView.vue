<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <div class="page-path">流程管理 / 版本详情</div>
        <h2 class="page-title">版本详情</h2>
        <p v-if="selectedDefinition" class="page-subtitle">
          {{ selectedDefinition.processName }}（{{ selectedDefinition.processKey }}）
        </p>
      </div>
      <div class="toolbar wrap compact">
        <el-button @click="goBackToWorkflowList">
          <el-icon><ArrowLeft /></el-icon>
          返回流程管理
        </el-button>
        <el-button :loading="pageLoading" @click="refreshPage">刷新</el-button>
      </div>
    </div>

    <el-empty v-if="!selectedDefinition || !selectedVersion" description="未找到对应版本，请返回流程管理重新选择" class="page-card empty-state" />

    <template v-else>
      <div class="panel page-card">
        <div class="panel-head">
          <div>
            <div class="panel-title">{{ selectedDefinition.processName }} · v{{ selectedVersion.versionNo }}</div>
            <div class="panel-subtitle">
              <el-tag :type="definitionStatusType(selectedDefinition.status)" size="small">{{ selectedDefinition.status }}</el-tag>
              <el-tag :type="versionStatusType(selectedVersion.status)" size="small" class="ml-8">{{ selectedVersion.status }}</el-tag>
              <span v-if="selectedDefinition.category" class="ml-8">分类：{{ selectedDefinition.category }}</span>
            </div>
          </div>
          <div class="toolbar wrap compact">
            <el-dropdown trigger="click" @command="handleVersionAction">
              <el-button>
                版本操作<el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="saveDraft" :disabled="selectedVersion?.status !== 'DRAFT'">保存草稿</el-dropdown-item>
                  <el-dropdown-item command="publish" :disabled="selectedVersion?.status !== 'DRAFT'">发布</el-dropdown-item>
                  <el-dropdown-item command="inactivate" :disabled="selectedVersion?.status !== 'PUBLISHED'">停用</el-dropdown-item>
                  <el-dropdown-item command="activate" :disabled="selectedVersion?.status !== 'INACTIVE'">启用</el-dropdown-item>
                  <el-dropdown-item command="retire" :disabled="!selectedVersion || !['PUBLISHED', 'INACTIVE'].includes(selectedVersion.status)">退休</el-dropdown-item>
                  <el-dropdown-item command="delete" divided :disabled="selectedVersion?.status !== 'DRAFT'">删除草稿</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </div>
      </div>

      <div class="workflow-shell">
        <section class="left-column stack">
          <div class="panel page-card">
            <div class="toolbar wrap">
              <el-button type="primary" @click="openCreateVersion">
                <el-icon><Plus /></el-icon>
                新建版本
              </el-button>
              <el-button :loading="versionLoading" @click="refreshVersionList">刷新版本</el-button>
            </div>
            <el-table
              v-loading="versionLoading"
              :data="versionList"
              border
              stripe
              highlight-current-row
              row-key="id"
              :current-row-key="selectedVersion?.id"
              @row-click="handleVersionSelect"
            >
              <el-table-column label="版本号" width="90">
                <template #default="{ row }">v{{ row.versionNo }}</template>
              </el-table-column>
              <el-table-column label="状态" width="110">
                <template #default="{ row }">
                  <el-tag :type="versionStatusType(row.status)">{{ row.status }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="versionLabel" label="标签" min-width="130" />
              <el-table-column label="操作" width="90" fixed="right">
                <template #default="{ row }">
                  <el-button type="primary" link @click.stop="handleVersionSelect(row)">进入</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </section>

        <section class="right-column stack">
          <el-tabs v-model="activeTab" class="tabs">
            <el-tab-pane label="版本详情" name="detail">
              <div class="panel page-card stack">
                <el-form ref="versionFormRef" :model="versionForm" :rules="versionRules" label-position="top" class="form-grid two-columns">
                  <el-form-item label="版本标签">
                    <el-input v-model="versionForm.versionLabel" :disabled="!isDraftVersion" maxlength="64" show-word-limit />
                  </el-form-item>
                  <el-form-item label="表单定义">
                    <el-select
                      v-model="selectedFormDefinitionId"
                      :disabled="!isDraftVersion"
                      clearable
                      filterable
                      placeholder="请选择表单定义"
                      @change="handleFormDefinitionChange"
                    >
                      <el-option
                        v-for="form in formDefinitions"
                        :key="form.id"
                        :label="`${form.formName} · ${form.formKey}`"
                        :value="form.id"
                      />
                    </el-select>
                  </el-form-item>
                  <el-form-item label="表单版本" prop="formVersionId">
                    <el-select
                      v-model="versionForm.formVersionId"
                      :disabled="!isDraftVersion || !selectedFormDefinitionId"
                      clearable
                      filterable
                      placeholder="请选择表单版本"
                      @change="handleFormVersionChange"
                    >
                      <el-option
                        v-for="item in currentFormVersions"
                        :key="item.id"
                        :label="`v${item.version} · ID ${item.id}${latestFormVersionId === item.id ? ' · 最新' : ''}`"
                        :value="item.id"
                      />
                    </el-select>
                  </el-form-item>
                  <el-form-item label="表单 Key">
                    <el-input v-model="versionForm.formKey" :disabled="!isDraftVersion" maxlength="64" show-word-limit placeholder="随表单定义自动回填，也可手工调整" />
                  </el-form-item>
                  <el-form-item label="版本说明">
                    <el-input v-model="versionForm.changeSummary" :disabled="!isDraftVersion" type="textarea" :rows="3" maxlength="1000" show-word-limit />
                  </el-form-item>
                  <el-form-item label="表单绑定摘要" class="full-span">
                    <div class="binding-summary page-card inner-card">
                      <div><strong>表单定义：</strong>{{ selectedFormDefinition?.formName || '-' }}</div>
                      <div><strong>表单 Key：</strong>{{ versionForm.formKey || '-' }}</div>
                      <div><strong>绑定版本：</strong>{{ selectedFormVersion ? `v${selectedFormVersion.version} / ID ${selectedFormVersion.id}` : '-' }}</div>
                      <div><strong>字段数：</strong>{{ formFields.length }}</div>
                    </div>
                  </el-form-item>
                  <el-form-item label="BPMN 编辑" prop="bpmnXml" class="full-span">
                    <div class="bpmn-editor stack">
                      <div class="toolbar wrap bpmn-mode-toolbar">
                        <el-radio-group v-model="bpmnEditMode" size="small">
                          <el-radio-button value="visual">可视化</el-radio-button>
                          <el-radio-button value="source">源码</el-radio-button>
                        </el-radio-group>
                        <el-button size="small" :disabled="!canEditVisual" @click="saveVersionDraft">保存草稿</el-button>
                        <el-button size="small" @click="toggleSourcePanel">
                          {{ sourcePanelExpanded ? "收起源码" : "展开源码" }}
                        </el-button>
                        <el-button size="small" @click="reloadDesignerFromSource">重载画布</el-button>
                        <el-button size="small" :type="bpmnFullscreen ? 'danger' : 'primary'" @click="toggleBpmnFullscreen">
                          {{ bpmnFullscreen ? "退出全屏" : "全屏编辑" }}
                        </el-button>
                        <el-tag v-if="bpmnFullscreen" size="small" type="success">ESC 退出全屏 / Ctrl+S 保存</el-tag>
                        <el-tag v-if="!canVisualEditRole" size="small" type="warning">仅管理员可编辑</el-tag>
                      </div>

                      <div
                        class="bpmn-editor-content"
                        :class="{ 'is-bpmn-fullscreen': bpmnFullscreen }"
                        :style="bpmnFullscreenStyle"
                      >
                        <BpmnVisualDesigner
                          v-if="bpmnEditMode === 'visual'"
                          :xml="versionForm.bpmnXml"
                          :process-id="selectedDefinition?.processKey || ''"
                          :process-name="selectedDefinition?.processName || '流程'"
                          :disabled="!canEditVisual"
                          :can-edit="canEditVisual"
                          :fullscreen="bpmnFullscreen"
                          :reload-token="designerReloadToken"
                          @xml-change="handleDesignerXmlChange"
                          @save="handleDesignerSave"
                          @import-error="handleDesignerImportError"
                        />

                        <el-alert
                          v-if="bpmnImportError"
                          type="error"
                          :title="bpmnImportError.message"
                          :description="bpmnImportError.details"
                          show-icon
                          :closable="false"
                        />

                        <el-collapse-transition>
                          <div v-show="sourcePanelExpanded" class="source-panel stack">
                            <el-input
                              v-model="versionForm.bpmnXml"
                              :disabled="!canEditVisual"
                              type="textarea"
                              :rows="16"
                              class="mono-input"
                            />
                          </div>
                        </el-collapse-transition>
                      </div>
                    </div>
                  </el-form-item>
                </el-form>

                <div class="sub-panel page-card inner-card stack">
                  <div class="panel-title small">表单字段预览</div>
                  <el-empty v-if="!versionForm.formVersionId" description="请选择表单版本" />
                  <el-table v-else :data="formFields" border stripe>
                    <el-table-column prop="fieldKey" label="字段 Key" min-width="140" />
                    <el-table-column prop="label" label="字段名称" min-width="160" />
                    <el-table-column prop="fieldType" label="类型" width="110" />
                    <el-table-column label="必填" width="90">
                      <template #default="{ row }">
                        <el-tag :type="row.required === 1 ? 'danger' : 'info'">{{ row.required === 1 ? '是' : '否' }}</el-tag>
                      </template>
                    </el-table-column>
                  </el-table>
                </div>
              </div>
            </el-tab-pane>

            <el-tab-pane label="节点配置" name="nodes">
              <div class="panel page-card stack">
                <div class="toolbar wrap">
                  <el-button :disabled="!selectedVersion" @click="loadNodes">刷新节点</el-button>
                  <el-button :disabled="!selectedVersion || !isDraftVersion" type="primary" @click="saveNodes">保存节点配置</el-button>
                  <el-tag v-if="selectedVersion && !isDraftVersion" type="warning" size="small">仅草稿版本可编辑</el-tag>
                </div>

                <el-empty v-if="!selectedVersion" description="请先选择一个版本" />
                <el-table v-else v-loading="nodeLoading" :data="nodeConfigs" border stripe row-key="nodeId" :expand-row-keys="expandedNodeRows" @expand-change="handleNodeExpand">
                  <el-table-column type="expand">
                    <template #default="{ row }">
                      <div class="node-expand-content">
                        <el-descriptions :column="2" border size="small">
                          <el-descriptions-item label="节点 ID">{{ row.nodeId }}</el-descriptions-item>
                          <el-descriptions-item label="节点类型">{{ row.nodeType }}</el-descriptions-item>
                          <el-descriptions-item label="节点名称">
                            <el-input v-model="row.nodeName" :disabled="!isDraftVersion" size="small" />
                          </el-descriptions-item>
                          <el-descriptions-item label="审批类型">
                            <el-select v-model="row.approvalType" :disabled="!isDraftVersion" clearable size="small" style="width: 100%">
                              <el-option v-for="item in approvalTypes" :key="item" :label="item" :value="item" />
                            </el-select>
                          </el-descriptions-item>
                          <el-descriptions-item label="审批人策略">
                            <el-select v-model="row.assigneeStrategy" :disabled="!isDraftVersion" clearable size="small" style="width: 100%">
                              <el-option v-for="item in assigneeStrategies" :key="item" :label="item" :value="item" />
                            </el-select>
                          </el-descriptions-item>
                          <el-descriptions-item label="意见必填">
                            <el-switch v-model="row.commentRequired" :disabled="!isDraftVersion" size="small" />
                          </el-descriptions-item>
                          <el-descriptions-item label="允许委派">
                            <el-switch v-model="row.allowDelegate" :disabled="!isDraftVersion" size="small" />
                          </el-descriptions-item>
                          <el-descriptions-item label="允许转办">
                            <el-switch v-model="row.allowReassign" :disabled="!isDraftVersion" size="small" />
                          </el-descriptions-item>
                          <el-descriptions-item label="允许退回上一节点">
                            <el-switch v-model="row.allowReturnPrevious" :disabled="!isDraftVersion" size="small" />
                          </el-descriptions-item>
                          <el-descriptions-item label="允许退回申请人">
                            <el-switch v-model="row.allowReturnApplicant" :disabled="!isDraftVersion" size="small" />
                          </el-descriptions-item>
                          <el-descriptions-item label="AI 建议">
                            <el-switch v-model="row.aiEnabled" :disabled="!isDraftVersion" size="small" />
                          </el-descriptions-item>
                        </el-descriptions>
                      </div>
                    </template>
                  </el-table-column>
                  <el-table-column label="序号" type="index" width="60" />
                  <el-table-column prop="nodeId" label="节点 ID" min-width="150" show-overflow-tooltip />
                  <el-table-column prop="nodeName" label="节点名称" min-width="160" show-overflow-tooltip />
                  <el-table-column prop="nodeType" label="类型" width="120" />
                </el-table>
              </div>
            </el-tab-pane>

            <el-tab-pane label="发布日志" name="logs">
              <div class="panel page-card">
                <div class="toolbar wrap">
                  <el-button :disabled="!selectedVersion" @click="loadLogs">刷新日志</el-button>
                </div>
                <el-empty v-if="!selectedVersion" description="请先选择一个版本" />
                <el-empty v-else-if="!logLoading && publishLogs.length === 0" description="暂无发布日志" />
                <el-table v-else v-loading="logLoading" :data="publishLogs" border stripe>
                  <el-table-column prop="action" label="动作" width="120" />
                  <el-table-column prop="result" label="结果" width="100" />
                  <el-table-column prop="message" label="说明" min-width="220" />
                  <el-table-column prop="operatorId" label="操作人" width="100" />
                  <el-table-column label="时间" min-width="180">
                    <template #default="{ row }">{{ formatDateTime(row.operatedAt) }}</template>
                  </el-table-column>
                </el-table>
              </div>
            </el-tab-pane>

            <el-tab-pane label="使用情况" name="usage">
              <div class="stack">
                <div class="usage-grid">
                  <div class="metric page-card">
                    <div class="metric-label">实例总数</div>
                    <div class="metric-value">{{ versionUsage?.totalCount ?? 0 }}</div>
                  </div>
                  <div class="metric page-card">
                    <div class="metric-label">运行中</div>
                    <div class="metric-value">{{ versionUsage?.runningCount ?? 0 }}</div>
                  </div>
                  <div class="metric page-card">
                    <div class="metric-label">已完成</div>
                    <div class="metric-value">{{ versionUsage?.finishedCount ?? 0 }}</div>
                  </div>
                </div>

                <div class="panel page-card">
                  <div class="toolbar wrap">
                    <el-button :disabled="!selectedVersion" @click="loadUsage">刷新使用情况</el-button>
                  </div>
                  <el-empty v-if="!selectedVersion" description="请先选择一个版本" />
                  <el-empty v-else-if="!usageLoading && (!versionUsage?.recentRequests || versionUsage.recentRequests.length === 0)" description="暂无使用记录" />
                  <el-table v-else v-loading="usageLoading" :data="versionUsage?.recentRequests || []" border stripe>
                    <el-table-column prop="requestId" label="申请 ID" width="100" />
                    <el-table-column prop="businessKey" label="业务键" min-width="180" />
                    <el-table-column prop="title" label="标题" min-width="180" />
                    <el-table-column prop="status" label="状态" width="90" />
                    <el-table-column label="提交时间" min-width="170">
                      <template #default="{ row }">{{ formatDateTime(row.submitTime) }}</template>
                    </el-table-column>
                    <el-table-column label="结束时间" min-width="170">
                      <template #default="{ row }">{{ formatDateTime(row.finishTime) }}</template>
                    </el-table-column>
                  </el-table>
                </div>
              </div>
            </el-tab-pane>
          </el-tabs>
        </section>
      </div>
    </template>

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
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from "vue";
import type { AxiosError } from "axios";
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from "element-plus";
import { ArrowLeft, ArrowDown, Plus } from "@element-plus/icons-vue";
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRoute, useRouter } from "vue-router";
import { useAuthStore } from "../stores/auth";
import BpmnVisualDesigner from "../components/workflow/BpmnVisualDesigner.vue";
import type {
  ApiErrorResponse,
  FormDefinitionSummary,
  FormField,
  FormVersionSummary,
  WorkflowDefinitionSummary,
  WorkflowNodeConfigItem,
  WorkflowPublishLogItem,
  WorkflowVersionSummary,
  WorkflowVersionUsage
} from "../types";
import {
  activateWorkflowVersion,
  createWorkflowVersion,
  deleteWorkflowVersion,
  getWorkflowDefinition,
  getWorkflowVersionUsage,
  inactivateWorkflowVersion,
  listWorkflowNodeConfigs,
  listWorkflowPublishLogs,
  listWorkflowVersions,
  publishWorkflowVersion,
  retireWorkflowVersion,
  saveWorkflowNodeConfigs,
  updateWorkflowVersion
} from "../api/admin-workflows";
import { fetchFormFields, listFormDefinitions, listFormVersions } from "../api/forms";

const approvalTypes = ["APPROVE", "COUNTERSIGN", "ORSIGN", "SEQUENTIAL"];
const assigneeStrategies = ["USER", "ROLE", "POST", "DEPT_MANAGER", "INITIATOR_SUPERVISOR", "FORM_FIELD"];

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();

const activeTab = ref("detail");
const pageLoading = ref(false);
const versionLoading = ref(false);
const createVersionLoading = ref(false);
const nodeLoading = ref(false);
const logLoading = ref(false);
const usageLoading = ref(false);

const versionFormRef = ref<FormInstance>();

const createVersionDialogVisible = ref(false);

const expandedNodeRows = ref<string[]>([]);

const selectedDefinition = ref<WorkflowDefinitionSummary | null>(null);
const versionList = ref<WorkflowVersionSummary[]>([]);
const selectedVersion = ref<WorkflowVersionSummary | null>(null);
const nodeConfigs = ref<WorkflowNodeConfigItem[]>([]);
const publishLogs = ref<WorkflowPublishLogItem[]>([]);
const versionUsage = ref<WorkflowVersionUsage | null>(null);
const formDefinitions = ref<FormDefinitionSummary[]>([]);
const formVersionsByDefinition = ref<Record<number, FormVersionSummary[]>>({});
const selectedFormDefinitionId = ref<number | undefined>();
const formFields = ref<FormField[]>([]);

const createVersionForm = reactive({
  copyFromVersionId: undefined as number | undefined,
  versionLabel: "",
  changeSummary: ""
});

const versionForm = reactive({
  versionLabel: "",
  formKey: "",
  formVersionId: undefined as number | undefined,
  changeSummary: "",
  bpmnXml: ""
});

const bpmnEditMode = ref<"visual" | "source">("visual");
const sourcePanelExpanded = ref(false);
const designerReloadToken = ref(0);
const bpmnImportError = ref<{ message: string; details?: string } | null>(null);
const bpmnFullscreen = ref(false);
const bpmnFullscreenStyle = ref<Record<string, string>>({});
const bpmnBaselineXml = ref("");
const bpmnDirty = ref(false);
const pendingDesignerInitSync = ref(false);
const suppressBpmnDirtyTracking = ref(false);

const versionRules: FormRules = {
  formVersionId: [{ required: true, message: "请输入表单版本 ID", trigger: "blur" }],
  bpmnXml: [{ required: true, message: "请输入 BPMN XML", trigger: "blur" }]
};

const isDraftVersion = computed(() => selectedVersion.value?.status === "DRAFT");
const canVisualEditRole = computed(() => (auth.currentUser?.roles ?? []).some((role) => role === "SYS_ADMIN" || role === "ADMIN"));
const canEditVisual = computed(() => isDraftVersion.value && canVisualEditRole.value);
const currentFormVersions = computed(() => {
  if (!selectedFormDefinitionId.value) {
    return [];
  }
  return formVersionsByDefinition.value[selectedFormDefinitionId.value] || [];
});
const selectedFormDefinition = computed(() => formDefinitions.value.find((item) => item.id === selectedFormDefinitionId.value));
const selectedFormVersion = computed(() => currentFormVersions.value.find((item) => item.id === versionForm.formVersionId));
const latestFormVersionId = computed(() => currentFormVersions.value[0]?.id);

watch(activeTab, async (tab) => {
  if (!selectedVersion.value) {
    return;
  }
  if (tab === "nodes") {
    await loadNodes();
  }
  if (tab === "logs") {
    await loadLogs();
  }
  if (tab === "usage") {
    await loadUsage();
  }
});

watch(bpmnEditMode, (mode) => {
  if (mode === "source") {
    sourcePanelExpanded.value = true;
    if (bpmnFullscreen.value) {
      exitBpmnFullscreen();
    }
  }
});

watch(
  () => [route.params.definitionId, route.params.versionId],
  async () => {
    await loadByRoute();
  },
  { immediate: true }
);

watch(
  () => versionForm.formVersionId,
  async (value) => {
    if (!value || !formDefinitions.value.length) {
      formFields.value = [];
      return;
    }
    const matchedDefinition = formDefinitions.value.find((definition) =>
      (formVersionsByDefinition.value[definition.id] || []).some((item) => item.id === value)
    );
    if (matchedDefinition) {
      selectedFormDefinitionId.value = matchedDefinition.id;
      versionForm.formKey = matchedDefinition.formKey;
    }
    await loadFormFields(value);
  }
);

watch(
  () => versionForm.bpmnXml,
  (xml) => {
    if (suppressBpmnDirtyTracking.value || pendingDesignerInitSync.value) {
      return;
    }
    bpmnDirty.value = normalizeXmlText(xml) !== bpmnBaselineXml.value;
  }
);

onMounted(async () => {
  window.addEventListener("keydown", handleGlobalShortcut);
  window.addEventListener("beforeunload", handleBeforeUnload);
  await loadFormDefinitions();
});

onBeforeUnmount(() => {
  window.removeEventListener("keydown", handleGlobalShortcut);
  window.removeEventListener("beforeunload", handleBeforeUnload);
  window.removeEventListener("resize", updateBpmnFullscreenRect);
  document.body.classList.remove("bpmn-editor-fullscreen-lock");
});

onBeforeRouteLeave((_to, _from, next) => {
  if (!hasUnsavedBpmnChanges()) {
    next();
    return;
  }
  const confirmLeave = window.confirm("当前 BPMN 修改尚未保存，确定离开当前页面吗？");
  next(confirmLeave);
});

onBeforeRouteUpdate((to, from, next) => {
  const routeChanged = to.params.definitionId !== from.params.definitionId || to.params.versionId !== from.params.versionId;
  if (!routeChanged || !hasUnsavedBpmnChanges()) {
    next();
    return;
  }
  const confirmLeave = window.confirm("当前 BPMN 修改尚未保存，确定切换版本吗？");
  next(confirmLeave);
});

async function loadByRoute() {
  const definitionId = parseRouteParamToNumber(route.params.definitionId);
  const versionId = parseRouteParamToNumber(route.params.versionId);
  if (!definitionId || !versionId) {
    ElMessage.error("版本路径参数无效");
    await router.replace({ name: "admin-workflows" });
    return;
  }

  pageLoading.value = true;
  try {
    selectedDefinition.value = await getWorkflowDefinition(definitionId);
    await refreshVersionList(versionId);
  } finally {
    pageLoading.value = false;
  }
}

async function refreshPage() {
  await loadByRoute();
}

async function refreshVersionList(preferredVersionId?: number) {
  if (!selectedDefinition.value) {
    return;
  }
  versionLoading.value = true;
  try {
    versionList.value = await listWorkflowVersions(selectedDefinition.value.id);
    if (!versionList.value.length) {
      selectedVersion.value = null;
      nodeConfigs.value = [];
      publishLogs.value = [];
      versionUsage.value = null;
      return;
    }

    const preferredId = preferredVersionId ?? parseRouteParamToNumber(route.params.versionId);
    const target = versionList.value.find((item) => item.id === preferredId) || versionList.value[0];
    if (!target) {
      return;
    }

    if (target.id !== preferredId) {
      await router.replace({
        name: "admin-workflow-version-detail",
        params: {
          definitionId: selectedDefinition.value.id,
          versionId: target.id
        }
      });
      return;
    }

    await applyVersionSelection(target);
  } finally {
    versionLoading.value = false;
  }
}

async function handleVersionSelect(row: WorkflowVersionSummary) {
  if (!selectedDefinition.value || selectedVersion.value?.id === row.id) {
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

async function applyVersionSelection(row: WorkflowVersionSummary) {
  exitBpmnFullscreen();
  selectedVersion.value = row;
  nodeConfigs.value = [];
  publishLogs.value = [];
  versionUsage.value = null;
  expandedNodeRows.value = [];
  syncVersionForm(row);
  bpmnEditMode.value = "visual";
  sourcePanelExpanded.value = false;
  bpmnImportError.value = null;
  designerReloadToken.value += 1;

  if (activeTab.value === "nodes") {
    await loadNodes();
  }
  if (activeTab.value === "logs") {
    await loadLogs();
  }
  if (activeTab.value === "usage") {
    await loadUsage();
  }
}

function syncVersionForm(row: WorkflowVersionSummary) {
  suppressBpmnDirtyTracking.value = true;
  versionForm.versionLabel = row.versionLabel || "";
  versionForm.formKey = row.formKey || "";
  versionForm.formVersionId = row.formVersionId ?? undefined;
  versionForm.changeSummary = row.changeSummary || "";
  versionForm.bpmnXml = row.bpmnXml || "";
  bpmnBaselineXml.value = normalizeXmlText(row.bpmnXml || "");
  bpmnDirty.value = false;
  pendingDesignerInitSync.value = true;
  nextTick(() => {
    suppressBpmnDirtyTracking.value = false;
  });
  bpmnImportError.value = null;
  void syncSelectedForm(row.formKey || undefined, row.formVersionId ?? undefined);
}

function handleDesignerXmlChange(xml: string) {
  if (!canEditVisual.value) {
    return;
  }
  bpmnImportError.value = null;
  if (pendingDesignerInitSync.value) {
    pendingDesignerInitSync.value = false;
    bpmnBaselineXml.value = normalizeXmlText(xml);
    bpmnDirty.value = false;
  }
  versionForm.bpmnXml = xml;
}

async function handleDesignerSave(xml: string) {
  if (!canEditVisual.value) {
    return;
  }
  bpmnImportError.value = null;
  versionForm.bpmnXml = xml;
  await saveVersionDraft();
}

function handleDesignerImportError(payload: { message: string; details?: string }) {
  bpmnImportError.value = payload;
  bpmnEditMode.value = "source";
  sourcePanelExpanded.value = true;
  ElMessage.error(payload.message);
}

function toggleSourcePanel() {
  sourcePanelExpanded.value = !sourcePanelExpanded.value;
  if (sourcePanelExpanded.value && bpmnEditMode.value !== "source") {
    bpmnEditMode.value = "source";
  }
}

function reloadDesignerFromSource() {
  if (!canEditVisual.value) {
    ElMessage.warning("仅管理员可编辑草稿 BPMN");
    return;
  }
  if (bpmnEditMode.value !== "visual") {
    bpmnEditMode.value = "visual";
  }
  bpmnImportError.value = null;
  designerReloadToken.value += 1;
}

function normalizeXmlText(xml: string) {
  return (xml || "").trim();
}

function hasUnsavedBpmnChanges() {
  return Boolean(selectedVersion.value && canEditVisual.value && bpmnDirty.value);
}

function handleBeforeUnload(event: BeforeUnloadEvent) {
  if (!hasUnsavedBpmnChanges()) {
    return;
  }
  event.preventDefault();
  event.returnValue = "";
}

function handleGlobalShortcut(event: KeyboardEvent) {
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "s") {
    if (activeTab.value === "detail" && canEditVisual.value) {
      event.preventDefault();
      void saveVersionDraft();
    }
    return;
  }
  if (event.key === "Escape" && bpmnFullscreen.value) {
    event.preventDefault();
    exitBpmnFullscreen();
  }
}

function updateBpmnFullscreenRect() {
  if (!bpmnFullscreen.value) {
    return;
  }
  const margin = 12;
  const width = Math.max(window.innerWidth - margin * 2, 320);
  const height = Math.max(window.innerHeight - margin * 2, 320);
  bpmnFullscreenStyle.value = {
    left: `${margin}px`,
    top: `${margin}px`,
    width: `${Math.round(width)}px`,
    height: `${Math.round(height)}px`
  };
}

function enterBpmnFullscreen() {
  if (bpmnEditMode.value !== "visual") {
    bpmnEditMode.value = "visual";
  }
  bpmnFullscreen.value = true;
  document.body.classList.add("bpmn-editor-fullscreen-lock");
  nextTick(() => {
    updateBpmnFullscreenRect();
  });
  window.addEventListener("resize", updateBpmnFullscreenRect);
}

function exitBpmnFullscreen() {
  if (!bpmnFullscreen.value) {
    return;
  }
  bpmnFullscreen.value = false;
  bpmnFullscreenStyle.value = {};
  window.removeEventListener("resize", updateBpmnFullscreenRect);
  document.body.classList.remove("bpmn-editor-fullscreen-lock");
}

function toggleBpmnFullscreen() {
  if (bpmnFullscreen.value) {
    exitBpmnFullscreen();
    return;
  }
  enterBpmnFullscreen();
}

function extractMainProcessIdFromXml(xml: string) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(xml, "application/xml");
  if (doc.querySelector("parsererror")) {
    return null;
  }
  const processElements = Array.from(doc.getElementsByTagNameNS("*", "process"));
  if (processElements.length !== 1) {
    return null;
  }
  return processElements[0]?.getAttribute("id")?.trim() || null;
}

function validateProcessKeyMatchForDraftSave() {
  const definition = selectedDefinition.value;
  if (!definition) {
    return true;
  }
  const processId = extractMainProcessIdFromXml(versionForm.bpmnXml || "");
  if (!processId) {
    ElMessage.error("BPMN 主流程解析失败，请确认仅包含 1 个 Process 且 XML 合法");
    return false;
  }
  if (processId !== definition.processKey) {
    ElMessage.error(`流程标识不一致：processKey=${definition.processKey}，BPMN process id=${processId}`);
    return false;
  }
  return true;
}

async function syncSelectedForm(formKey?: string, formVersionId?: number) {
  if (!formDefinitions.value.length) {
    await loadFormDefinitions();
  }
  const matchedDefinition = formDefinitions.value.find((item) => item.formKey === formKey)
    || formDefinitions.value.find((item) => (formVersionsByDefinition.value[item.id] || []).some((version) => version.id === formVersionId));
  if (!matchedDefinition) {
    selectedFormDefinitionId.value = undefined;
    return;
  }
  selectedFormDefinitionId.value = matchedDefinition.id;
  await ensureFormVersionsLoaded(matchedDefinition.id);
  if (formVersionId) {
    await loadFormFields(formVersionId);
  }
}

async function loadFormDefinitions() {
  formDefinitions.value = await listFormDefinitions();
}

async function ensureFormVersionsLoaded(formId: number) {
  if (formVersionsByDefinition.value[formId]) {
    return;
  }
  const versions = await listFormVersions(formId);
  formVersionsByDefinition.value = {
    ...formVersionsByDefinition.value,
    [formId]: versions
  };
}

async function handleFormDefinitionChange(formId?: number) {
  if (!formId) {
    versionForm.formKey = "";
    versionForm.formVersionId = undefined;
    formFields.value = [];
    return;
  }
  const definition = formDefinitions.value.find((item) => item.id === formId);
  versionForm.formKey = definition?.formKey || "";
  await ensureFormVersionsLoaded(formId);
  versionForm.formVersionId = currentFormVersions.value[0]?.id;
  if (versionForm.formVersionId) {
    await loadFormFields(versionForm.formVersionId);
  } else {
    formFields.value = [];
  }
}

async function handleFormVersionChange(versionId?: number) {
  if (!versionId || !selectedFormDefinitionId.value) {
    formFields.value = [];
    return;
  }
  const definition = formDefinitions.value.find((item) => item.id === selectedFormDefinitionId.value);
  if (definition) {
    versionForm.formKey = definition.formKey;
  }
  await loadFormFields(versionId);
}

async function loadFormFields(formVersionId: number) {
  formFields.value = await fetchFormFields(formVersionId);
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
    await router.push({
      name: "admin-workflow-version-detail",
      params: {
        definitionId: selectedDefinition.value.id,
        versionId: version.id
      }
    });
  } finally {
    createVersionLoading.value = false;
  }
}

async function saveVersionDraft() {
  if (!selectedVersion.value || !canEditVisual.value) {
    return;
  }
  await versionFormRef.value?.validate();
  if (!validateProcessKeyMatchForDraftSave()) {
    return;
  }
  const updated = await updateWorkflowVersion(selectedVersion.value.id, {
    versionLabel: versionForm.versionLabel.trim() || undefined,
    formKey: versionForm.formKey.trim() || undefined,
    formVersionId: Number(versionForm.formVersionId),
    changeSummary: versionForm.changeSummary.trim() || undefined,
    bpmnXml: versionForm.bpmnXml
  });
  ElMessage.success("草稿版本已保存");
  await refreshVersionList(updated.id);
}

async function deleteSelectedVersion() {
  if (!selectedVersion.value || selectedVersion.value.status !== "DRAFT" || !selectedDefinition.value) {
    return;
  }
  await ElMessageBox.confirm(`确认删除版本 v${selectedVersion.value.versionNo} 吗？`, "删除草稿", { type: "warning" });
  await deleteWorkflowVersion(selectedVersion.value.id);
  ElMessage.success("草稿版本已删除");
  await refreshVersionList();
  if (!versionList.value.length) {
    await router.replace({ name: "admin-workflows" });
    return;
  }
  const nextVersion = versionList.value[0];
  if (!nextVersion) {
    return;
  }
  await router.replace({
    name: "admin-workflow-version-detail",
    params: {
      definitionId: selectedDefinition.value.id,
      versionId: nextVersion.id
    }
  });
}

async function loadNodes() {
  if (!selectedVersion.value) {
    return;
  }
  nodeLoading.value = true;
  try {
    nodeConfigs.value = await listWorkflowNodeConfigs(selectedVersion.value.id);
  } finally {
    nodeLoading.value = false;
  }
}

async function saveNodes() {
  if (!selectedVersion.value || !isDraftVersion.value) {
    return;
  }
  await saveWorkflowNodeConfigs(selectedVersion.value.id, nodeConfigs.value);
  ElMessage.success("节点配置已保存");
  await loadNodes();
}

async function loadLogs() {
  if (!selectedVersion.value) {
    return;
  }
  logLoading.value = true;
  try {
    publishLogs.value = await listWorkflowPublishLogs(selectedVersion.value.id);
  } finally {
    logLoading.value = false;
  }
}

async function loadUsage() {
  if (!selectedVersion.value) {
    return;
  }
  usageLoading.value = true;
  try {
    versionUsage.value = await getWorkflowVersionUsage(selectedVersion.value.id);
  } finally {
    usageLoading.value = false;
  }
}

function handleNodeExpand(_row: WorkflowNodeConfigItem, expandedRows: WorkflowNodeConfigItem[]) {
  expandedNodeRows.value = expandedRows.map((r) => r.nodeId);
}

async function handleVersionAction(command: string) {
  if (command === "saveDraft") {
    await saveVersionDraft();
  } else if (command === "delete") {
    await deleteSelectedVersion();
  } else {
    await changeVersionState(command as "publish" | "inactivate" | "activate" | "retire");
  }
}

async function changeVersionState(action: "publish" | "inactivate" | "activate" | "retire") {
  if (!selectedVersion.value) {
    return;
  }
  const titles: Record<string, string> = {
    publish: "发布版本",
    inactivate: "停用版本",
    activate: "启用版本",
    retire: "退休版本"
  };
  const comment = await promptComment(titles[action]);
  if (comment === null) {
    return;
  }

  try {
    if (action === "publish") {
      await publishWorkflowVersion(selectedVersion.value.id, comment);
      ElMessage.success("版本已发布");
    } else if (action === "inactivate") {
      await inactivateWorkflowVersion(selectedVersion.value.id, comment);
      ElMessage.success("版本已停用");
    } else if (action === "activate") {
      await activateWorkflowVersion(selectedVersion.value.id, comment);
      ElMessage.success("版本已启用");
    } else {
      await retireWorkflowVersion(selectedVersion.value.id, comment);
      ElMessage.success("版本已退休");
    }
  } catch (e) {
    const error = e as AxiosError<ApiErrorResponse>;
    if (action === "publish" && error.response?.data?.code === "NODE_CONFIG_MISMATCH") {
      ElMessage.warning("发布失败：节点配置与 BPMN 节点不一致，请先在“节点配置”页签同步后重试");
      activeTab.value = "nodes";
      await loadNodes();
      return;
    }
    throw e;
  }

  if (selectedDefinition.value) {
    selectedDefinition.value = await getWorkflowDefinition(selectedDefinition.value.id);
  }
  await refreshVersionList(selectedVersion.value.id);
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

async function goBackToWorkflowList() {
  if (hasUnsavedBpmnChanges()) {
    const confirmLeave = window.confirm("当前 BPMN 修改尚未保存，确定返回流程管理吗？");
    if (!confirmLeave) {
      return;
    }
  }
  await router.push({ name: "admin-workflows" });
}

function parseRouteParamToNumber(param: unknown) {
  const value = Number(param);
  if (!Number.isInteger(value) || value <= 0) {
    return null;
  }
  return value;
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

.page-path {
  color: var(--text-subtle);
  font-size: 12px;
  margin-bottom: 4px;
}

.workflow-shell {
  display: grid;
  grid-template-columns: minmax(280px, 340px) minmax(0, 1fr);
  gap: 18px;
  align-items: start;
}

.panel {
  padding: 18px;
}

.panel-head {
  display: flex;
  justify-content: space-between;
  gap: 16px;
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

.inner-card {
  border-radius: 12px;
  border: 1px solid rgba(148, 163, 184, 0.28);
  background: linear-gradient(180deg, rgba(248, 250, 252, 0.85) 0%, rgba(241, 245, 249, 0.92) 100%);
  box-shadow: none;
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
  overflow: auto;
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

.usage-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
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

:global(body.bpmn-editor-fullscreen-lock) {
  overflow: hidden;
}

@media (max-width: 1180px) {
  .workflow-shell {
    grid-template-columns: 1fr;
  }

  .usage-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 768px) {
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
