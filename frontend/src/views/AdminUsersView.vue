<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <h2 class="page-title">用户管理</h2>
        <p class="page-subtitle">管理员创建、修改和批量导入系统用户</p>
      </div>
      <div class="heading-actions">
        <el-button :loading="globalLoading" @click="refreshAll">刷新数据</el-button>
      </div>
    </div>

    <el-row :gutter="14" class="summary-grid">
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">用户总数</div>
          <div class="metric-value">{{ userPage.total }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">当前页</div>
          <div class="metric-value">{{ userPage.page + 1 }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">导入任务</div>
          <div class="metric-value">{{ importJobs.total }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">待校验文件</div>
          <div class="metric-value">{{ importValidation ? 1 : 0 }}</div>
        </div>
      </el-col>
    </el-row>

    <el-tabs v-model="activeTab" class="tabs">
      <el-tab-pane label="用户列表" name="list">
        <div class="panel page-card">
          <div class="toolbar">
            <el-input v-model="query.keyword" clearable placeholder="按用户名搜索" @keyup.enter="searchUsers" />
            <el-select v-model="query.status" clearable placeholder="状态" style="width: 140px">
              <el-option label="启用" :value="1" />
              <el-option label="停用" :value="0" />
            </el-select>
            <el-select v-model="query.deptId" clearable filterable placeholder="部门" style="width: 180px">
              <el-option v-for="dept in options.depts" :key="dept.id" :label="dept.deptName" :value="dept.id" />
            </el-select>
            <el-select v-model="query.roleId" clearable filterable placeholder="角色" style="width: 180px">
              <el-option v-for="role in options.roles" :key="role.id" :label="`${role.roleCode} · ${role.roleName}`" :value="role.id" />
            </el-select>
            <el-button type="primary" @click="searchUsers">查询</el-button>
            <el-button @click="resetQuery">重置</el-button>
            <el-button type="success" plain @click="activeTab = 'create'">新建用户</el-button>
          </div>

          <el-table
            v-loading="userLoading"
            :data="userPage.content"
            border
            stripe
            @row-dblclick="openUserDetail"
          >
            <el-table-column prop="username" label="用户名" min-width="180" />
            <el-table-column label="部门" min-width="160">
              <template #default="{ row }">
                {{ resolveDeptName(row.deptId) }}
              </template>
            </el-table-column>
            <el-table-column label="角色" min-width="220">
              <template #default="{ row }">
                <span>{{ formatNames(row.roleNames) }}</span>
              </template>
            </el-table-column>
            <el-table-column label="岗位" min-width="220">
              <template #default="{ row }">
                <span>{{ formatNames(row.postNames) }}</span>
              </template>
            </el-table-column>
            <el-table-column label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? "启用" : "停用" }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="2FA" width="100">
              <template #default="{ row }">
                <el-tag :type="row.twoFactorEnabled ? 'success' : 'info'">{{ row.twoFactorEnabled ? "已启用" : "未启用" }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="锁定" width="100">
              <template #default="{ row }">
                <el-tag :type="row.locked ? 'danger' : 'info'">{{ row.locked ? "锁定中" : "正常" }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="最近登录" min-width="180">
              <template #default="{ row }">
                {{ row.lastLoginAt ? formatDateTime(row.lastLoginAt) : "-" }}
              </template>
            </el-table-column>
            <el-table-column label="操作" min-width="260" fixed="right">
              <template #default="{ row }">
                <el-space wrap>
                  <el-button link type="primary" @click="openUserDetail(row)">详情</el-button>
                  <el-button link @click="openEditUser(row)">编辑</el-button>
                  <el-button link type="warning" @click="toggleUserStatus(row)">
                    {{ row.status === 1 ? "禁用" : "启用" }}
                  </el-button>
                  <el-button link type="danger" @click="promptResetPassword(row)">重置密码</el-button>
                </el-space>
              </template>
            </el-table-column>
          </el-table>

          <div class="pager">
            <el-pagination
              background
              layout="total, sizes, prev, pager, next, jumper"
              :current-page="query.page"
              :page-size="query.size"
              :page-sizes="[10, 20, 50, 100]"
              :total="userPage.total"
              @current-change="changeUserPage"
              @size-change="changeUserPageSize"
            />
          </div>
        </div>
      </el-tab-pane>

      <el-tab-pane label="新建用户" name="create">
        <div class="panel page-card">
          <el-form ref="createFormRef" :model="createForm" :rules="userFormRules" label-position="top" class="form-grid">
            <el-form-item label="用户名" prop="username">
              <el-input v-model="createForm.username" maxlength="64" show-word-limit />
            </el-form-item>
            <el-form-item label="初始密码" prop="password">
              <el-input v-model="createForm.password" type="password" show-password maxlength="128" />
            </el-form-item>
            <el-form-item label="部门">
              <el-select v-model="createForm.deptId" clearable filterable placeholder="选择部门">
                <el-option v-for="dept in options.depts" :key="dept.id" :label="dept.deptName" :value="dept.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="角色" prop="roleIds">
              <el-select v-model="createForm.roleIds" multiple filterable collapse-tags placeholder="选择角色">
                <el-option v-for="role in options.roles" :key="role.id" :label="`${role.roleCode} · ${role.roleName}`" :value="role.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="岗位">
              <el-select v-model="createForm.postIds" multiple filterable collapse-tags placeholder="选择岗位">
                <el-option v-for="post in options.posts" :key="post.id" :label="`${post.postCode} · ${post.postName}`" :value="post.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="状态">
              <el-select v-model="createForm.status">
                <el-option label="启用" :value="1" />
                <el-option label="停用" :value="0" />
              </el-select>
            </el-form-item>
          </el-form>

          <div class="action-row">
            <el-button type="primary" :loading="createLoading" @click="submitCreateUser">创建用户</el-button>
            <el-button @click="resetCreateForm">清空</el-button>
          </div>
        </div>
      </el-tab-pane>

      <el-tab-pane label="批量导入" name="import">
        <div class="stack">
          <div class="panel page-card">
            <div class="toolbar">
              <el-select v-model="importStrategy" style="width: 180px">
                <el-option label="仅创建" value="CREATE_ONLY" />
                <el-option label="存在则更新" value="UPSERT" />
              </el-select>
              <el-button @click="downloadTemplate">下载模板</el-button>
              <el-button :loading="importValidateLoading" type="primary" @click="validateImportFile">预校验</el-button>
              <el-button :disabled="!importValidation" :loading="importExecuteLoading" type="success" @click="executeImport">确认导入</el-button>
              <el-checkbox v-model="skipErrorRows">跳过错误行</el-checkbox>
            </div>

            <div class="upload-box">
              <div class="upload-meta">
                <div class="upload-title">{{ importFileName }}</div>
                <div class="upload-desc">支持 CSV / XLSX 文件，建议先预校验再执行。</div>
              </div>
              <div class="upload-actions">
                <input ref="importFileInput" class="file-input" type="file" accept=".csv,.xlsx" @change="handleImportFileChange" />
                <el-button @click="openFilePicker">选择文件</el-button>
                <el-button v-if="importFile" @click="clearImportFile">清空文件</el-button>
              </div>
            </div>
          </div>

          <el-alert
            v-if="importValidation"
            :title="`任务 ${importValidation.jobId} 已完成预校验`"
            type="success"
            show-icon
            :closable="false"
          >
            <template #default>
              总行数 {{ importValidation.totalRows }}，成功 {{ importValidation.successRows }}，失败 {{ importValidation.failedRows }}。
            </template>
          </el-alert>

          <div v-if="importValidation" class="panel page-card">
            <div class="panel-title">预校验明细</div>
            <el-table :data="importValidation.errors" border stripe>
              <el-table-column prop="rowNo" label="行号" width="80" />
              <el-table-column prop="username" label="用户名" min-width="160" />
              <el-table-column prop="message" label="错误原因" min-width="360" />
            </el-table>

            <div class="sub-section">
              <div class="panel-title">预览通过行</div>
              <el-table :data="importValidation.preview" border stripe>
                <el-table-column prop="rowNo" label="行号" width="80" />
                <el-table-column prop="username" label="用户名" min-width="160" />
                <el-table-column label="部门" min-width="160">
                  <template #default="{ row }">
                    {{ row.deptName || row.deptCode || "-" }}
                  </template>
                </el-table-column>
                <el-table-column label="角色编码" min-width="180">
                  <template #default="{ row }">
                    {{ formatNames(row.roleCodes) }}
                  </template>
                </el-table-column>
                <el-table-column label="岗位编码" min-width="180">
                  <template #default="{ row }">
                    {{ formatNames(row.postCodes) }}
                  </template>
                </el-table-column>
                <el-table-column prop="status" label="状态" width="90" />
                <el-table-column label="结果" width="110">
                  <template #default="{ row }">
                    <el-tag :type="row.valid ? 'success' : 'danger'">{{ row.valid ? "通过" : "失败" }}</el-tag>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </div>
        </div>
      </el-tab-pane>

      <el-tab-pane label="导入记录" name="records">
        <div class="stack">
          <div class="panel page-card">
            <div class="toolbar">
              <el-select v-model="importQuery.status" clearable placeholder="状态" style="width: 160px">
                <el-option label="已校验" value="VALIDATED" />
                <el-option label="执行中" value="RUNNING" />
                <el-option label="已完成" value="COMPLETED" />
              </el-select>
              <el-button :loading="importJobsLoading" type="primary" @click="loadImportJobs">查询</el-button>
              <el-button @click="clearImportFilters">重置</el-button>
            </div>

            <el-table
              :data="importJobs.content"
              border
              stripe
              highlight-current-row
              @row-click="selectImportJob"
            >
              <el-table-column prop="jobId" label="任务号" width="100" />
              <el-table-column prop="fileName" label="文件名" min-width="200" />
              <el-table-column prop="fileType" label="类型" width="100" />
              <el-table-column prop="strategy" label="策略" width="120" />
              <el-table-column prop="status" label="状态" width="120" />
              <el-table-column prop="totalRows" label="总行数" width="100" />
              <el-table-column prop="successRows" label="成功" width="100" />
              <el-table-column prop="failedRows" label="失败" width="100" />
              <el-table-column label="创建时间" min-width="180">
                <template #default="{ row }">
                  {{ formatDateTime(row.createdAt) }}
                </template>
              </el-table-column>
            </el-table>

            <div class="pager">
              <el-pagination
                background
                layout="total, sizes, prev, pager, next, jumper"
                :current-page="importQuery.page"
                :page-size="importQuery.size"
                :page-sizes="[10, 20, 50, 100]"
                :total="importJobs.total"
                @current-change="changeImportPage"
                @size-change="changeImportPageSize"
              />
            </div>
          </div>

          <div class="panel page-card">
            <div class="panel-title">
              任务明细
              <span class="panel-subtitle">{{ currentImportJob ? `任务 ${currentImportJob.jobId}` : "请选择一个任务" }}</span>
            </div>

            <el-table v-loading="importItemsLoading" :data="importJobItems" border stripe>
              <el-table-column prop="rowNo" label="行号" width="80" />
              <el-table-column prop="username" label="用户名" min-width="160" />
              <el-table-column prop="result" label="结果" width="110" />
              <el-table-column prop="errorMessage" label="错误原因" min-width="320" />
              <el-table-column prop="createdUserId" label="创建用户ID" width="120" />
            </el-table>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="detailDialogVisible" title="用户详情" width="720px">
      <el-descriptions v-if="selectedUser" :column="2" border>
        <el-descriptions-item label="用户名">{{ selectedUser.username }}</el-descriptions-item>
        <el-descriptions-item label="部门">{{ resolveDeptName(selectedUser.deptId) }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="selectedUser.status === 1 ? 'success' : 'info'">{{ selectedUser.status === 1 ? "启用" : "停用" }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="2FA">
          <el-tag :type="selectedUser.twoFactorEnabled ? 'success' : 'info'">
            {{ selectedUser.twoFactorEnabled ? "已启用" : "未启用" }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="锁定状态">
          <el-tag :type="selectedUser.locked ? 'danger' : 'info'">{{ selectedUser.locked ? "锁定中" : "正常" }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="最近登录">
          {{ selectedUser.lastLoginAt ? formatDateTime(selectedUser.lastLoginAt) : "-" }}
        </el-descriptions-item>
        <el-descriptions-item label="角色" :span="2">{{ formatNames(selectedUser.roleNames) }}</el-descriptions-item>
        <el-descriptions-item label="岗位" :span="2">{{ formatNames(selectedUser.postNames) }}</el-descriptions-item>
        <el-descriptions-item label="锁定截止" :span="2">
          {{ selectedUser.lockedUntil ? formatDateTime(selectedUser.lockedUntil) : "-" }}
        </el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <el-dialog v-model="editDialogVisible" title="编辑用户" width="720px">
      <el-form ref="editFormRef" :model="editForm" :rules="editFormRules" label-position="top" class="form-grid">
        <el-form-item label="用户名">
          <el-input :model-value="editUserName" disabled />
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="editForm.deptId" clearable filterable placeholder="选择部门">
            <el-option v-for="dept in options.depts" :key="dept.id" :label="dept.deptName" :value="dept.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="角色" prop="roleIds">
          <el-select v-model="editForm.roleIds" multiple filterable collapse-tags placeholder="选择角色">
            <el-option v-for="role in options.roles" :key="role.id" :label="`${role.roleCode} · ${role.roleName}`" :value="role.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="岗位">
          <el-select v-model="editForm.postIds" multiple filterable collapse-tags placeholder="选择岗位">
            <el-option v-for="post in options.posts" :key="post.id" :label="`${post.postCode} · ${post.postName}`" :value="post.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="editForm.status">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="editLoading" @click="submitEditUser">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from "vue";
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from "element-plus";
import {
  createAdminUser,
  downloadUserImportTemplate,
  executeUserImport,
  fetchAdminUserDetail,
  fetchAdminUserOptions,
  listAdminUsers,
  listUserImportJobItems,
  listUserImportJobs,
  resetAdminUserPassword,
  updateAdminUser,
  updateAdminUserStatus,
  validateUserImport
} from "../api/admin-users";
import type {
  AdminUserDetail,
  AdminUserFormPayload,
  AdminUserOptions,
  AdminUserSummary,
  AdminUserUpdatePayload,
  PageResult,
  UserImportJobItem,
  UserImportJobSummary,
  UserImportValidateResult
} from "../types";

const activeTab = ref("list");
const globalLoading = ref(false);
const userLoading = ref(false);
const createLoading = ref(false);
const editLoading = ref(false);
const importValidateLoading = ref(false);
const importExecuteLoading = ref(false);
const importJobsLoading = ref(false);
const importItemsLoading = ref(false);
const detailDialogVisible = ref(false);
const editDialogVisible = ref(false);
const createFormRef = ref<FormInstance>();
const editFormRef = ref<FormInstance>();
const importFileInput = ref<HTMLInputElement | null>(null);
const importFile = ref<File | null>(null);
const importStrategy = ref("CREATE_ONLY");
const skipErrorRows = ref(true);
const options = ref<AdminUserOptions>({ depts: [], roles: [], posts: [] });
const userPage = ref<PageResult<AdminUserSummary>>({ content: [], total: 0, page: 0, size: 10, totalPages: 0 });
const importJobs = ref<PageResult<UserImportJobSummary>>({ content: [], total: 0, page: 0, size: 10, totalPages: 0 });
const importJobItems = ref<UserImportJobItem[]>([]);
const importValidation = ref<UserImportValidateResult | null>(null);
const selectedUser = ref<AdminUserDetail | null>(null);
const editUserId = ref<number | null>(null);
const editUserName = ref("");
const currentImportJobId = ref<number | null>(null);

const query = reactive({
  keyword: "",
  status: undefined as number | undefined,
  deptId: undefined as number | undefined,
  roleId: undefined as number | undefined,
  page: 1,
  size: 10
});

const importQuery = reactive({
  status: undefined as string | undefined,
  page: 1,
  size: 10
});

const createForm = reactive<AdminUserFormPayload>({
  username: "",
  password: "",
  deptId: undefined,
  roleIds: [],
  postIds: [],
  status: 1
});

const editForm = reactive<AdminUserUpdatePayload>({
  deptId: undefined,
  roleIds: [],
  postIds: [],
  status: 1
});

const userFormRules: FormRules = {
  username: [{ required: true, message: "请输入用户名", trigger: "blur" }],
  password: [
    { required: true, message: "请输入初始密码", trigger: "blur" },
    { min: 8, max: 128, message: "密码长度必须为 8-128 个字符", trigger: "blur" }
  ],
  roleIds: [
    { required: true, message: "请选择至少一个角色", trigger: "change" },
    {
      validator: (rule, value, callback) => {
        if (!value || value.length === 0) {
          callback(new Error("请选择至少一个角色"));
        } else {
          callback();
        }
      },
      trigger: "change"
    }
  ]
};

const editFormRules: FormRules = {
  roleIds: [
    { required: true, message: "请选择至少一个角色", trigger: "change" },
    {
      validator: (rule, value, callback) => {
        if (!value || value.length === 0) {
          callback(new Error("请选择至少一个角色"));
        } else {
          callback();
        }
      },
      trigger: "change"
    }
  ]
};

const currentImportJob = computed(() => {
  if (currentImportJobId.value == null) {
    return null;
  }
  return importJobs.value.content.find((job) => job.jobId === currentImportJobId.value) ?? null;
});

const importFileName = computed(() => importFile.value?.name ?? "未选择文件");

watch(activeTab, async (tab) => {
  if (tab === "records" && importJobs.value.content.length === 0) {
    await loadImportJobs();
  }
});

onMounted(async () => {
  await refreshAll();
});

function refreshAll() {
  globalLoading.value = true;
  return Promise.all([loadOptions(), loadUsers(), loadImportJobs()]).finally(() => {
    globalLoading.value = false;
  });
}

async function loadOptions() {
  options.value = await fetchAdminUserOptions();
}

async function loadUsers() {
  userLoading.value = true;
  try {
    userPage.value = await listAdminUsers({
      keyword: query.keyword.trim() || undefined,
      status: query.status,
      deptId: query.deptId,
      roleId: query.roleId,
      page: query.page - 1,
      size: query.size
    });
  } finally {
    userLoading.value = false;
  }
}

async function loadImportJobs() {
  importJobsLoading.value = true;
  try {
    importJobs.value = await listUserImportJobs({
      status: importQuery.status,
      page: importQuery.page - 1,
      size: importQuery.size
    });
    const hasCurrentJob = importJobs.value.content.some((job) => job.jobId === currentImportJobId.value);
    if (!hasCurrentJob) {
      currentImportJobId.value = null;
      importJobItems.value = [];
    }
    if (currentImportJobId.value == null && importJobs.value.content.length > 0) {
      await selectImportJob(importJobs.value.content[0]);
    }
  } finally {
    importJobsLoading.value = false;
  }
}

async function searchUsers() {
  query.page = 1;
  await loadUsers();
}

async function resetQuery() {
  query.keyword = "";
  query.status = undefined;
  query.deptId = undefined;
  query.roleId = undefined;
  query.page = 1;
  await loadUsers();
}

async function changeUserPage(page: number) {
  query.page = page;
  await loadUsers();
}

async function changeUserPageSize(size: number) {
  query.size = size;
  query.page = 1;
  await loadUsers();
}

async function changeImportPage(page: number) {
  importQuery.page = page;
  await loadImportJobs();
}

async function changeImportPageSize(size: number) {
  importQuery.size = size;
  importQuery.page = 1;
  await loadImportJobs();
}

function resetCreateForm() {
  createForm.username = "";
  createForm.password = "";
  createForm.deptId = undefined;
  createForm.roleIds = [];
  createForm.postIds = [];
  createForm.status = 1;
  createFormRef.value?.clearValidate();
}

async function submitCreateUser() {
  await createFormRef.value?.validate();
  createLoading.value = true;
  try {
    await createAdminUser({
      username: createForm.username.trim(),
      password: createForm.password,
      deptId: createForm.deptId,
      roleIds: [...createForm.roleIds],
      postIds: [...createForm.postIds],
      status: createForm.status
    });
    ElMessage.success("用户已创建");
    resetCreateForm();
    activeTab.value = "list";
    await loadUsers();
  } finally {
    createLoading.value = false;
  }
}

async function openUserDetail(row: AdminUserSummary) {
  detailDialogVisible.value = true;
  selectedUser.value = null;
  selectedUser.value = await fetchAdminUserDetail(row.userId);
}

async function openEditUser(row: AdminUserSummary) {
  const detail = await fetchAdminUserDetail(row.userId);
  editUserId.value = detail.userId;
  editUserName.value = detail.username;
  editForm.deptId = detail.deptId ?? undefined;
  editForm.roleIds = detail.roleIds?.length ? [...detail.roleIds] : (detail.roles ?? []).map((role) => role.id);
  editForm.postIds = detail.postIds?.length ? [...detail.postIds] : (detail.posts ?? []).map((post) => post.id);
  editForm.status = detail.status;
  editDialogVisible.value = true;
}

async function submitEditUser() {
  if (editUserId.value == null) {
    return;
  }
  await editFormRef.value?.validate();
  editLoading.value = true;
  try {
    await updateAdminUser(editUserId.value, {
      deptId: editForm.deptId,
      roleIds: editForm.roleIds?.length ? [...editForm.roleIds] : [],
      postIds: editForm.postIds?.length ? [...editForm.postIds] : [],
      status: editForm.status
    });
    ElMessage.success("用户已更新");
    editDialogVisible.value = false;
    await loadUsers();
    if (selectedUser.value?.userId === editUserId.value) {
      selectedUser.value = await fetchAdminUserDetail(editUserId.value);
    }
  } finally {
    editLoading.value = false;
  }
}

async function toggleUserStatus(row: AdminUserSummary) {
  const nextStatus = row.status === 1 ? 0 : 1;
  try {
    await ElMessageBox.confirm(`确认${nextStatus === 1 ? "启用" : "禁用"}用户 ${row.username} 吗？`, "确认操作", {
      confirmButtonText: "确认",
      cancelButtonText: "取消",
      type: "warning"
    });
  } catch {
    return;
  }
  await updateAdminUserStatus(row.userId, { status: nextStatus });
  ElMessage.success("状态已更新");
  await loadUsers();
  if (selectedUser.value?.userId === row.userId) {
    selectedUser.value = await fetchAdminUserDetail(row.userId);
  }
}

async function promptResetPassword(row: AdminUserSummary) {
  try {
    const { value } = await ElMessageBox.prompt(`为 ${row.username} 设置新的初始密码`, "重置密码", {
      confirmButtonText: "确认",
      cancelButtonText: "取消",
      inputType: "password",
      inputPlaceholder: "请输入至少 8 位新密码",
      inputValidator: (inputValue) => {
        if (!inputValue || inputValue.length < 8) {
          return "密码至少 8 位";
        }
        return true;
      }
    });
    await resetAdminUserPassword(row.userId, { newPassword: value });
    ElMessage.success("密码已重置");
  } catch {
    return;
  }
}

function openFilePicker() {
  importFileInput.value?.click();
}

function clearImportFile() {
  importFile.value = null;
  if (importFileInput.value) {
    importFileInput.value.value = "";
  }
  importValidation.value = null;
}

function handleImportFileChange(event: Event) {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0] ?? null;
  if (!file) {
    importFile.value = null;
    return;
  }
  const lowerName = file.name.toLowerCase();
  if (!lowerName.endsWith(".csv") && !lowerName.endsWith(".xlsx")) {
    ElMessage.warning("仅支持 CSV 或 XLSX 文件");
    target.value = "";
    importFile.value = null;
    return;
  }
  importFile.value = file;
  importValidation.value = null;
}

async function validateImportFile() {
  if (!importFile.value) {
    ElMessage.warning("请先选择文件");
    return;
  }
  importValidateLoading.value = true;
  try {
    importValidation.value = await validateUserImport(importFile.value, importStrategy.value);
    ElMessage.success("预校验完成");
  } finally {
    importValidateLoading.value = false;
  }
}

async function executeImport() {
  if (!importValidation.value) {
    ElMessage.warning("请先完成预校验");
    return;
  }
  try {
    await ElMessageBox.confirm("确认执行导入吗？", "执行导入", {
      confirmButtonText: "确认",
      cancelButtonText: "取消",
      type: "warning"
    });
  } catch {
    return;
  }
  importExecuteLoading.value = true;
  try {
    const result = await executeUserImport(importValidation.value.jobId, { skipErrorRows: skipErrorRows.value });
    ElMessage.success(`导入完成，成功 ${result.successRows}，失败 ${result.failedRows}`);
    await loadImportJobs();
    await loadUsers();
  } finally {
    importExecuteLoading.value = false;
  }
}

async function downloadTemplate() {
  const blob = await downloadUserImportTemplate();
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "user-import-template.csv";
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
}

async function selectImportJob(job: UserImportJobSummary) {
  currentImportJobId.value = job.jobId;
  importItemsLoading.value = true;
  try {
    importJobItems.value = await listUserImportJobItems(job.jobId);
  } finally {
    importItemsLoading.value = false;
  }
}

function clearImportFilters() {
  importQuery.status = undefined;
  importQuery.page = 1;
  void loadImportJobs();
}

function resolveDeptName(deptId?: number | null) {
  if (deptId == null) {
    return "-";
  }
  return options.value.depts.find((dept) => dept.id === deptId)?.deptName ?? `#${deptId}`;
}

function formatNames(values?: string[] | null) {
  if (!values || values.length === 0) {
    return "-";
  }
  return values.join(", ");
}

function formatDateTime(value?: string | null) {
  if (!value) {
    return "-";
  }
  return value.replace("T", " ").replace("Z", "");
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
  align-items: flex-start;
  gap: 12px;
  flex-wrap: wrap;
}

.summary-grid {
  margin-top: -4px;
}

.metric {
  padding: 16px 18px;
  background: linear-gradient(160deg, #ffffff 0%, #f8fbff 100%);
}

.metric-label {
  color: var(--text-subtle);
  font-size: 13px;
}

.metric-value {
  margin-top: 10px;
  font-size: 26px;
  font-weight: 700;
}

.panel {
  padding: 18px;
}

.toolbar {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  margin-bottom: 14px;
}

.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 14px;
}

.action-row {
  margin-top: 18px;
  display: flex;
  gap: 10px;
}

.upload-box {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  padding: 18px;
  border: 1px dashed var(--border-soft);
  border-radius: var(--radius-md);
  background: linear-gradient(160deg, #fcfffe 0%, #f6fbff 100%);
}

.upload-title {
  font-weight: 600;
}

.upload-desc,
.panel-subtitle {
  color: var(--text-subtle);
  font-size: 13px;
}

.upload-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.file-input {
  display: none;
}

.panel-title {
  margin-bottom: 12px;
  font-weight: 600;
}

.sub-section {
  margin-top: 18px;
}

@media (max-width: 980px) {
  .upload-box {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
