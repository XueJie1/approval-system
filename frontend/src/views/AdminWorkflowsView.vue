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
                    <el-button :disabled="!selectedVersion" @click="loadVersionRelatedData">刷新</el-button>
                    <el-dropdown trigger="click" @command="handleVersionAction">
                      <el-button :disabled="!selectedVersion">
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

                  <el-table
                    v-loading="versionLoading"
                    :data="versionList"
                    border
                    stripe
                    highlight-current-row
                    row-key="id"
                    @row-click="handleVersionSelect"
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
                  </el-table>
                </div>

                <div v-if="selectedVersion" class="panel page-card stack">
                  <div class="panel-title">版本详情 · v{{ selectedVersion.versionNo }}</div>
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
                          ref="bpmnEditorRef"
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
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from "vue";
import type { AxiosError } from "axios";
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from "element-plus";
import { Search, Plus, ArrowDown } from "@element-plus/icons-vue";
import BpmnVisualDesigner from "../components/workflow/BpmnVisualDesigner.vue";
import { onBeforeRouteLeave } from "vue-router";
import { useAuthStore } from "../stores/auth";
import type {
  ApiErrorResponse,
  PageResult,
  WorkflowDefinitionPayload,
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
  archiveWorkflowDefinition,
  createWorkflowDefinition,
  createWorkflowVersion,
  deleteWorkflowVersion,
  getWorkflowVersionUsage,
  inactivateWorkflowDefinition,
  inactivateWorkflowVersion,
  listWorkflowDefinitions,
  listWorkflowNodeConfigs,
  listWorkflowPublishLogs,
  listWorkflowVersions,
  publishWorkflowVersion,
  retireWorkflowVersion,
  saveWorkflowNodeConfigs,
  updateWorkflowDefinition,
  updateWorkflowVersion
} from "../api/admin-workflows";
import { fetchFormFields, listFormDefinitions, listFormVersions } from "../api/forms";

const definitionStatuses = ["DRAFT", "ACTIVE", "INACTIVE", "ARCHIVED"];
const approvalTypes = ["APPROVE", "COUNTERSIGN", "ORSIGN", "SEQUENTIAL"];
const assigneeStrategies = ["USER", "ROLE", "POST", "DEPT_MANAGER", "INITIATOR_SUPERVISOR", "FORM_FIELD"];

const activeTab = ref("versions");
const globalLoading = ref(false);
const definitionLoading = ref(false);
const createDefinitionLoading = ref(false);
const editDefinitionLoading = ref(false);
const versionLoading = ref(false);
const createVersionLoading = ref(false);
const nodeLoading = ref(false);
const logLoading = ref(false);
const usageLoading = ref(false);

const createDefinitionFormRef = ref<FormInstance>();
const editDefinitionFormRef = ref<FormInstance>();
const versionFormRef = ref<FormInstance>();

const editDefinitionDialogVisible = ref(false);
const createDefinitionDialogVisible = ref(false);
const createVersionDialogVisible = ref(false);

let searchTimer: ReturnType<typeof setTimeout> | null = null;
const expandedNodeRows = ref<string[]>([]);

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
const nodeConfigs = ref<WorkflowNodeConfigItem[]>([]);
const publishLogs = ref<WorkflowPublishLogItem[]>([]);
const versionUsage = ref<WorkflowVersionUsage | null>(null);
const formDefinitions = ref<FormDefinitionSummary[]>([]);
const formVersionsByDefinition = ref<Record<number, FormVersionSummary[]>>({});
const selectedFormDefinitionId = ref<number | undefined>();
const formFields = ref<FormField[]>([]);

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
const bpmnEditorRef = ref<HTMLElement | null>(null);
const bpmnFullscreen = ref(false);
const bpmnFullscreenStyle = ref<Record<string, string>>({});
const bpmnBaselineXml = ref("");
const bpmnDirty = ref(false);
const pendingDesignerInitSync = ref(false);
const suppressBpmnDirtyTracking = ref(false);
const auth = useAuthStore();

const definitionRules: FormRules = {
  processKey: [
    { required: true, message: "请输入流程标识", trigger: "blur" },
    { pattern: /^[A-Za-z][A-Za-z0-9_]*$/, message: "流程标识仅支持字母开头的字母数字下划线", trigger: "blur" }
  ],
  processName: [{ required: true, message: "请输入流程名称", trigger: "blur" }]
};

const versionRules: FormRules = {
  formVersionId: [{ required: true, message: "请输入表单版本 ID", trigger: "blur" }],
  bpmnXml: [{ required: true, message: "请输入 BPMN XML", trigger: "blur" }]
};

const publishedCount = computed(() => versionList.value.filter((item) => item.status === "PUBLISHED").length);
const draftCount = computed(() => versionList.value.filter((item) => item.status === "DRAFT").length);
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

onMounted(async () => {
  window.addEventListener("keydown", handleGlobalShortcut);
  window.addEventListener("beforeunload", handleBeforeUnload);
  await loadFormDefinitions();
  await refreshAll();
});

onBeforeUnmount(() => {
  window.removeEventListener("keydown", handleGlobalShortcut);
  window.removeEventListener("beforeunload", handleBeforeUnload);
  window.removeEventListener("resize", updateBpmnFullscreenRect);
  document.body.classList.remove("bpmn-editor-fullscreen-lock");
});

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

onBeforeRouteLeave((_to, _from, next) => {
  if (!hasUnsavedBpmnChanges()) {
    next();
    return;
  }
  const confirmLeave = window.confirm("当前 BPMN 修改尚未保存，确定离开当前页面吗？");
  next(confirmLeave);
});

async function refreshAll() {
  globalLoading.value = true;
  try {
    await loadDefinitions();
  } finally {
    globalLoading.value = false;
  }
}

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
      const latest = definitionPage.value.content.find((item) => item.id === selectedDefinition.value?.id) ?? selectedDefinition.value;
      selectedDefinition.value = latest;
    }

    if (!selectedDefinition.value && definitionPage.value.content.length > 0) {
      await handleDefinitionSelect(definitionPage.value.content[0]);
    }
  } finally {
    definitionLoading.value = false;
  }
}

async function loadFormDefinitions() {
  formDefinitions.value = await listFormDefinitions();
}

async function searchDefinitions() {
  query.page = 0;
  await loadDefinitions();
}

function debounceSearch() {
  if (searchTimer) clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    searchDefinitions();
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
  selectedVersion.value = null;
  nodeConfigs.value = [];
  publishLogs.value = [];
  versionUsage.value = null;
  await loadVersions();
}

async function loadVersions() {
  if (!selectedDefinition.value) {
    return;
  }
  versionLoading.value = true;
  try {
    versionList.value = await listWorkflowVersions(selectedDefinition.value.id);
    const target = selectedDefinition.value.currentVersionId
      ? versionList.value.find((item) => item.id === selectedDefinition.value?.currentVersionId)
      : versionList.value[0];
    if (target) {
      await handleVersionSelect(target);
    }
  } finally {
    versionLoading.value = false;
  }
}

async function handleVersionSelect(row: WorkflowVersionSummary) {
  exitBpmnFullscreen();
  selectedVersion.value = row;
  syncVersionForm(row);
  bpmnEditMode.value = "visual";
  sourcePanelExpanded.value = false;
  bpmnImportError.value = null;
  designerReloadToken.value += 1;
  await loadVersionRelatedData();
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
    if (activeTab.value === "versions" && canEditVisual.value) {
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
  const editorEl = bpmnEditorRef.value;
  const viewEl = editorEl?.closest(".view") as HTMLElement | null;
  if (!viewEl) {
    return;
  }
  const rect = viewEl.getBoundingClientRect();
  bpmnFullscreenStyle.value = {
    left: `${Math.round(rect.left)}px`,
    top: `${Math.round(rect.top)}px`,
    width: `${Math.round(rect.width)}px`,
    height: `${Math.round(rect.height)}px`
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

async function loadVersionRelatedData() {
  if (!selectedVersion.value) {
    return;
  }
  await Promise.all([loadNodes(), loadLogs(), loadUsage()]);
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

const submitEditDefinition = async () => {
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
};

async function changeDefinitionState(action: "inactivate" | "archive") {
  if (!selectedDefinition.value) {
    return;
  }
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
  await refreshAll();
}

async function handleDefinitionAction(command: string) {
  await changeDefinitionState(command as "inactivate" | "archive");
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

function handleNodeExpand(_row: WorkflowNodeConfigItem, expandedRows: WorkflowNodeConfigItem[]) {
  expandedNodeRows.value = expandedRows.map((r) => r.nodeId);
}

function openCreateVersion() {
  createVersionForm.copyFromVersionId = selectedVersion.value?.id;
  createVersionForm.versionLabel = "";
  createVersionForm.changeSummary = "";
  createVersionDialogVisible.value = true;
}

const submitCreateVersion = async () => {
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
    await handleVersionSelect(version);
    activeTab.value = "versions";
  } finally {
    createVersionLoading.value = false;
  }
};

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
  selectedVersion.value = updated;
  syncVersionForm(updated);
  await loadVersions();
}

async function deleteSelectedVersion() {
  if (!selectedVersion.value || selectedVersion.value.status !== "DRAFT") {
    return;
  }
  await ElMessageBox.confirm(`确认删除版本 v${selectedVersion.value.versionNo} 吗？`, "删除草稿", { type: "warning" });
  await deleteWorkflowVersion(selectedVersion.value.id);
  ElMessage.success("草稿版本已删除");
  selectedVersion.value = null;
  await loadVersions();
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

  await loadDefinitions();
  if (selectedDefinition.value) {
    await loadVersions();
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
