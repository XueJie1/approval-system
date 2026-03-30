<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <h2 class="page-title">角色管理</h2>
        <p class="page-subtitle">创建、编辑和删除系统角色</p>
      </div>
      <div class="heading-actions">
        <el-button :loading="globalLoading" @click="refreshAll">刷新数据</el-button>
      </div>
    </div>

    <el-row :gutter="14" class="summary-grid">
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">角色总数</div>
          <div class="metric-value">{{ rolePage.total }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">启用角色</div>
          <div class="metric-value">{{ enabledCount }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">停用角色</div>
          <div class="metric-value">{{ disabledCount }}</div>
        </div>
      </el-col>
      <el-col :xs="24" :sm="12" :lg="6">
        <div class="metric page-card">
          <div class="metric-label">当前页</div>
          <div class="metric-value">{{ rolePage.page + 1 }}</div>
        </div>
      </el-col>
    </el-row>

    <el-tabs v-model="activeTab" class="tabs">
      <el-tab-pane label="角色列表" name="list">
        <div class="panel page-card">
          <div class="toolbar">
            <el-input v-model="query.keyword" clearable placeholder="按角色编码或名称搜索" @keyup.enter="searchRoles" />
            <el-select v-model="query.status" clearable placeholder="状态" style="width: 140px">
              <el-option label="启用" :value="1" />
              <el-option label="停用" :value="0" />
            </el-select>
            <el-button type="primary" @click="searchRoles">查询</el-button>
            <el-button @click="resetQuery">重置</el-button>
            <el-button type="success" plain @click="activeTab = 'create'">新建角色</el-button>
          </div>

          <el-table
            v-loading="roleLoading"
            :data="rolePage.content"
            border
            stripe
            @row-dblclick="openRoleDetail"
          >
            <el-table-column prop="id" label="ID" width="80" />
            <el-table-column prop="roleCode" label="角色编码" min-width="180" />
            <el-table-column prop="roleName" label="角色名称" min-width="200" />
            <el-table-column label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? "启用" : "停用" }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" min-width="220" fixed="right">
              <template #default="{ row }">
                <el-space wrap>
                  <el-button link type="primary" @click="openRoleDetail(row)">详情</el-button>
                  <el-button link @click="openEditRole(row)">编辑</el-button>
                  <el-button link type="warning" @click="toggleRoleStatus(row)">
                    {{ row.status === 1 ? "禁用" : "启用" }}
                  </el-button>
                  <el-button link type="danger" @click="promptDeleteRole(row)">删除</el-button>
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
              :total="rolePage.total"
              @current-change="changeRolePage"
              @size-change="changeRolePageSize"
            />
          </div>
        </div>
      </el-tab-pane>

      <el-tab-pane label="新建角色" name="create">
        <div class="panel page-card">
          <el-form ref="createFormRef" :model="createForm" :rules="roleFormRules" label-position="top" class="form-grid">
            <el-form-item label="角色编码" prop="roleCode">
              <el-input v-model="createForm.roleCode" maxlength="64" show-word-limit placeholder="例如：ADMIN, MANAGER" />
            </el-form-item>
            <el-form-item label="角色名称" prop="roleName">
              <el-input v-model="createForm.roleName" maxlength="64" show-word-limit placeholder="例如：系统管理员、部门经理" />
            </el-form-item>
            <el-form-item label="状态">
              <el-select v-model="createForm.status">
                <el-option label="启用" :value="1" />
                <el-option label="停用" :value="0" />
              </el-select>
            </el-form-item>
          </el-form>

          <div class="action-row">
            <el-button type="primary" :loading="createLoading" @click="submitCreateRole">创建角色</el-button>
            <el-button @click="resetCreateForm">清空</el-button>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="detailDialogVisible" title="角色详情" width="560px">
      <el-descriptions v-if="selectedRole" :column="1" border>
        <el-descriptions-item label="ID">{{ selectedRole.id }}</el-descriptions-item>
        <el-descriptions-item label="角色编码">{{ selectedRole.roleCode }}</el-descriptions-item>
        <el-descriptions-item label="角色名称">{{ selectedRole.roleName }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="selectedRole.status === 1 ? 'success' : 'info'">{{ selectedRole.status === 1 ? "启用" : "停用" }}</el-tag>
        </el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <el-dialog v-model="editDialogVisible" title="编辑角色" width="560px">
      <el-form ref="editFormRef" :model="editForm" :rules="editFormRules" label-position="top" class="form-grid">
        <el-form-item label="角色编码" prop="roleCode">
          <el-input v-model="editForm.roleCode" maxlength="64" show-word-limit />
        </el-form-item>
        <el-form-item label="角色名称" prop="roleName">
          <el-input v-model="editForm.roleName" maxlength="64" show-word-limit />
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
        <el-button type="primary" :loading="editLoading" @click="submitEditRole">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from "vue";
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from "element-plus";
import { createRole, deleteRole, listRoles, updateRole, type SysRole, type CreateRolePayload, type UpdateRolePayload } from "../api/roles";

const activeTab = ref("list");
const globalLoading = ref(false);
const roleLoading = ref(false);
const createLoading = ref(false);
const editLoading = ref(false);
const detailDialogVisible = ref(false);
const editDialogVisible = ref(false);
const createFormRef = ref<FormInstance>();
const editFormRef = ref<FormInstance>();
const selectedRole = ref<SysRole | null>(null);
const editRoleId = ref<number | null>(null);

const query = reactive({
  keyword: "",
  status: undefined as number | undefined,
  page: 1,
  size: 10
});

const rolePage = ref({
  content: [] as SysRole[],
  total: 0,
  page: 0,
  size: 10,
  totalPages: 0
});

const createForm = reactive<CreateRolePayload & { status: number }>({
  roleCode: "",
  roleName: "",
  status: 1
});

const editForm = reactive<UpdateRolePayload>({
  roleCode: "",
  roleName: "",
  status: 1
});

const roleFormRules: FormRules = {
  roleCode: [{ required: true, message: "请输入角色编码", trigger: "blur" }],
  roleName: [{ required: true, message: "请输入角色名称", trigger: "blur" }]
};

const editFormRules: FormRules = {
  roleCode: [{ required: true, message: "请输入角色编码", trigger: "blur" }],
  roleName: [{ required: true, message: "请输入角色名称", trigger: "blur" }]
};

const enabledCount = computed(() => rolePage.value.content.filter(r => r.status === 1).length);
const disabledCount = computed(() => rolePage.value.content.filter(r => r.status === 0).length);

onMounted(async () => {
  await refreshAll();
});

function refreshAll() {
  globalLoading.value = true;
  return loadRoles().finally(() => {
    globalLoading.value = false;
  });
}

async function loadRoles() {
  roleLoading.value = true;
  try {
    const roles = await listRoles(
      query.keyword.trim() || undefined,
      query.status
    );
    rolePage.value = {
      content: roles,
      total: roles.length,
      page: query.page - 1,
      size: query.size,
      totalPages: Math.ceil(roles.length / query.size)
    };
  } finally {
    roleLoading.value = false;
  }
}

async function searchRoles() {
  query.page = 1;
  await loadRoles();
}

async function resetQuery() {
  query.keyword = "";
  query.status = undefined;
  query.page = 1;
  await loadRoles();
}

async function changeRolePage(page: number) {
  query.page = page;
  await loadRoles();
}

async function changeRolePageSize(size: number) {
  query.size = size;
  query.page = 1;
  await loadRoles();
}

function resetCreateForm() {
  createForm.roleCode = "";
  createForm.roleName = "";
  createForm.status = 1;
  createFormRef.value?.clearValidate();
}

async function submitCreateRole() {
  await createFormRef.value?.validate();
  createLoading.value = true;
  try {
    await createRole({
      roleCode: createForm.roleCode.trim(),
      roleName: createForm.roleName.trim()
    });
    ElMessage.success("角色已创建");
    resetCreateForm();
    activeTab.value = "list";
    await loadRoles();
  } finally {
    createLoading.value = false;
  }
}

async function openRoleDetail(row: SysRole) {
  detailDialogVisible.value = true;
  selectedRole.value = { ...row };
}

async function openEditRole(row: SysRole) {
  editRoleId.value = row.id;
  editForm.roleCode = row.roleCode;
  editForm.roleName = row.roleName;
  editForm.status = row.status;
  editDialogVisible.value = true;
}

async function submitEditRole() {
  if (editRoleId.value == null) {
    return;
  }
  await editFormRef.value?.validate();
  editLoading.value = true;
  try {
    await updateRole(editRoleId.value, {
      roleCode: editForm.roleCode.trim(),
      roleName: editForm.roleName.trim(),
      status: editForm.status
    });
    ElMessage.success("角色已更新");
    editDialogVisible.value = false;
    await loadRoles();
    if (selectedRole.value?.id === editRoleId.value) {
      selectedRole.value = null;
    }
  } finally {
    editLoading.value = false;
  }
}

async function toggleRoleStatus(row: SysRole) {
  const nextStatus = row.status === 1 ? 0 : 1;
  try {
    await ElMessageBox.confirm(`确认${nextStatus === 1 ? "启用" : "禁用"}角色 ${row.roleName} 吗？`, "确认操作", {
      confirmButtonText: "确认",
      cancelButtonText: "取消",
      type: "warning"
    });
  } catch {
    return;
  }
  try {
    await updateRole(row.id, {
      roleCode: row.roleCode,
      roleName: row.roleName,
      status: nextStatus
    });
    ElMessage.success("状态已更新");
    await loadRoles();
    if (selectedRole.value?.id === row.id) {
      selectedRole.value = null;
    }
  } catch (error) {
    ElMessage.error("操作失败：" + (error as Error).message);
  }
}

async function promptDeleteRole(row: SysRole) {
  try {
    await ElMessageBox.confirm(`确认删除角色 "${row.roleName}" 吗？删除后无法恢复。`, "确认删除", {
      confirmButtonText: "确认删除",
      cancelButtonText: "取消",
      type: "warning"
    });
  } catch {
    return;
  }
  try {
    await deleteRole(row.id);
    ElMessage.success("角色已删除");
    await loadRoles();
    if (selectedRole.value?.id === row.id) {
      detailDialogVisible.value = false;
      selectedRole.value = null;
    }
  } catch (error) {
    ElMessage.error("删除失败：" + (error as Error).message);
  }
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

.form-grid {
  display: grid;
  gap: 14px;
}
</style>
