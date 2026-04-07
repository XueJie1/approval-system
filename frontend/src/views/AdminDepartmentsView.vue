<template>
  <div class="page stack">
    <div class="page-header">
      <div>
        <h2>部门管理</h2>
        <p>左侧查看部门层级，右侧维护当前选中部门。</p>
      </div>
      <div class="header-actions">
        <el-button @click="loadDepartments">刷新</el-button>
        <el-button type="primary" @click="startCreateRoot">新增顶级部门</el-button>
      </div>
    </div>

    <div class="layout-grid">
      <section class="tree-panel">
        <div class="panel-toolbar">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索部门名称"
            clearable
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </div>

        <el-tree
          ref="treeRef"
          class="department-tree"
          :data="treeData"
          node-key="id"
          default-expand-all
          highlight-current
          :expand-on-click-node="true"
          :filter-node-method="filterTreeNode"
          @node-click="handleSelectDepartment"
        >
          <template #default="{ data }">
            <div class="tree-node">
              <div class="tree-node__main">
                <div class="tree-node__title">{{ data.deptName }}</div>
                <div class="tree-node__meta">{{ data.deptCode || '未设置编码' }}</div>
              </div>
              <el-button link type="primary" @click.stop="startCreateChild(data)">新增下级</el-button>
            </div>
          </template>
        </el-tree>

        <div v-if="!treeData.length" class="empty-state">
          暂无部门数据
        </div>
      </section>

      <section class="editor-panel">
        <div class="editor-header">
          <div>
            <div class="editor-title">{{ isCreating ? '新增部门' : '编辑部门' }}</div>
            <div class="editor-subtitle">
              {{ selectedDepartment ? `当前部门：${selectedDepartment.deptName}` : '请选择左侧部门，或新建一个部门' }}
            </div>
          </div>
          <div class="header-actions">
            <el-button v-if="selectedDepartment && !isCreating" type="danger" plain @click="handleDelete(selectedDepartment)">删除部门</el-button>
            <el-button @click="resetEditor">清空</el-button>
          </div>
        </div>

        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" class="editor-form">
          <el-form-item label="部门代码" prop="deptCode">
            <el-input v-model="form.deptCode" placeholder="可选，如 DEPT001" />
          </el-form-item>

          <el-form-item label="部门名称" prop="deptName">
            <el-input v-model="form.deptName" placeholder="请输入部门名称" />
          </el-form-item>

          <el-form-item label="父部门" prop="parentId">
            <el-select v-model="form.parentId" placeholder="选择父部门" clearable filterable style="width: 100%">
              <el-option label="无（顶级部门）" :value="null" />
              <el-option
                v-for="dept in parentDepartmentOptions"
                :key="dept.id"
                :label="dept.deptName"
                :value="dept.id"
              />
            </el-select>
          </el-form-item>

          <el-form-item label="部门负责人" prop="leaderUserId">
            <el-select v-model="form.leaderUserId" placeholder="选择部门负责人" clearable filterable style="width: 100%">
              <el-option label="未设置" :value="null" />
              <el-option v-for="user in users" :key="user.id" :label="user.username" :value="user.id" />
            </el-select>
          </el-form-item>
        </el-form>

        <div class="editor-actions">
          <el-button type="primary" :loading="submitting" @click="handleSubmit">
            {{ isCreating ? '创建部门' : '保存修改' }}
          </el-button>
          <el-button v-if="selectedDepartment" @click="startCreateChild(selectedDepartment)">基于当前部门新增下级</el-button>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Search } from '@element-plus/icons-vue';
import type { FormInstance } from 'element-plus';
import { departmentApi, type Department, type CreateDepartmentRequest, type UpdateDepartmentRequest } from '../api/departments';
import { fetchAdminUserOptions } from '../api/admin-users';

type DepartmentTreeNode = Department & { children?: DepartmentTreeNode[] };

const departments = ref<Department[]>([]);
const users = ref<Array<{ id: number; username: string }>>([]);
const searchKeyword = ref('');
const submitting = ref(false);
const formRef = ref<FormInstance>();
const treeRef = ref<any>();
const selectedDepartmentId = ref<number | null>(null);
const isCreating = ref(false);

const form = ref<CreateDepartmentRequest & { id?: number }>({
  deptCode: '',
  deptName: '',
  parentId: null,
  leaderUserId: null
});

const rules = {
  deptName: [{ required: true, message: '请输入部门名称', trigger: 'blur' }]
};

const selectedDepartment = computed(() => departments.value.find(dept => dept.id === selectedDepartmentId.value) ?? null);

const treeData = computed<DepartmentTreeNode[]>(() => {
  const childrenMap = new Map<number | null, DepartmentTreeNode[]>();
  for (const dept of departments.value) {
    const parentKey = dept.parentId ?? null;
    const current = childrenMap.get(parentKey) ?? [];
    current.push({ ...dept, children: [] });
    childrenMap.set(parentKey, current);
  }
  const buildNodes = (parentId: number | null): DepartmentTreeNode[] => {
    return (childrenMap.get(parentId) ?? [])
      .sort((a, b) => a.deptName.localeCompare(b.deptName, 'zh-Hans-CN'))
      .map(node => ({
        ...node,
        children: buildNodes(node.id)
      }));
  };
  return buildNodes(null);
});

const parentDepartmentOptions = computed(() => {
  const currentId = form.value.id ?? null;
  const excludedIds = currentId == null ? new Set<number>() : collectDescendantIds(currentId);
  if (currentId != null) {
    excludedIds.add(currentId);
  }
  return departments.value
    .filter(dept => !excludedIds.has(dept.id))
    .sort((a, b) => a.deptName.localeCompare(b.deptName, 'zh-Hans-CN'));
});

onMounted(() => {
  loadDepartments();
  loadUsers();
});

watch(searchKeyword, value => {
  treeRef.value?.filter(value);
});

async function loadDepartments() {
  try {
    const response = await departmentApi.list();
    departments.value = response.data;
    if (!selectedDepartmentId.value && response.data.length) {
      handleSelectDepartment(response.data[0]);
      return;
    }
    if (selectedDepartmentId.value != null) {
      const current = response.data.find(item => item.id === selectedDepartmentId.value);
      if (current) {
        syncFormWithDepartment(current);
      } else {
        resetEditor();
      }
    }
  } catch (error) {
    console.error('加载部门列表失败', error);
  }
}

async function loadUsers() {
  try {
    const options = await fetchAdminUserOptions();
    users.value = options.users;
  } catch (error) {
    console.error('加载用户列表失败', error);
  }
}

function handleSelectDepartment(row: Department) {
  selectedDepartmentId.value = row.id;
  isCreating.value = false;
  syncFormWithDepartment(row);
}

function syncFormWithDepartment(row: Department) {
  form.value = {
    id: row.id,
    deptCode: row.deptCode || '',
    deptName: row.deptName,
    parentId: row.parentId,
    leaderUserId: row.leaderUserId ?? null
  };
}

function startCreateRoot() {
  selectedDepartmentId.value = null;
  isCreating.value = true;
  form.value = { deptCode: '', deptName: '', parentId: null, leaderUserId: null };
}

function startCreateChild(parent: Department) {
  selectedDepartmentId.value = parent.id;
  isCreating.value = true;
  form.value = { deptCode: '', deptName: '', parentId: parent.id, leaderUserId: null };
}

function resetEditor() {
  if (selectedDepartment.value) {
    isCreating.value = false;
    syncFormWithDepartment(selectedDepartment.value);
    return;
  }
  startCreateRoot();
}

async function handleSubmit() {
  if (!formRef.value) {
    return;
  }
  try {
    await formRef.value.validate();
    submitting.value = true;
    if (isCreating.value) {
      const response = await departmentApi.create(form.value as CreateDepartmentRequest);
      ElMessage.success('创建成功');
      selectedDepartmentId.value = response.data.id;
      isCreating.value = false;
    } else if (form.value.id != null) {
      await departmentApi.update(form.value.id, form.value as UpdateDepartmentRequest);
      ElMessage.success('更新成功');
    } else {
      ElMessage.warning('请先选择部门或新建部门');
      return;
    }
    await loadDepartments();
  } catch (error) {
    console.error('提交失败', error);
  } finally {
    submitting.value = false;
  }
}

async function handleDelete(row: Department) {
  try {
    await ElMessageBox.confirm(`确定要删除部门 "${row.deptName}" 吗？`, '警告', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    });
    await departmentApi.delete(row.id);
    ElMessage.success('删除成功');
    if (selectedDepartmentId.value === row.id) {
      selectedDepartmentId.value = null;
    }
    await loadDepartments();
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除失败', error);
    }
  }
}

function filterTreeNode(value: string, data: DepartmentTreeNode) {
  if (!value) {
    return true;
  }
  const keyword = value.toLowerCase();
  return data.deptName.toLowerCase().includes(keyword) || (data.deptCode ?? '').toLowerCase().includes(keyword);
}

function collectDescendantIds(deptId: number) {
  const result = new Set<number>();
  const childrenMap = new Map<number, number[]>();
  for (const dept of departments.value) {
    if (!dept.parentId) {
      continue;
    }
    const children = childrenMap.get(dept.parentId) ?? [];
    children.push(dept.id);
    childrenMap.set(dept.parentId, children);
  }
  const stack = [...(childrenMap.get(deptId) ?? [])];
  while (stack.length) {
    const current = stack.pop();
    if (current == null || result.has(current)) {
      continue;
    }
    result.add(current);
    stack.push(...(childrenMap.get(current) ?? []));
  }
  return result;
}
</script>

<style scoped>
.page {
  padding: 20px;
}

.stack {
  display: grid;
  gap: 16px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
}

.page-header h2 {
  margin: 0;
  font-size: 20px;
  color: #0f172a;
}

.page-header p {
  margin: 8px 0 0;
  color: #64748b;
}

.header-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.layout-grid {
  display: grid;
  grid-template-columns: minmax(280px, 360px) minmax(0, 1fr);
  gap: 16px;
  align-items: start;
}

.tree-panel,
.editor-panel {
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  background: #fff;
  padding: 16px;
}

.panel-toolbar {
  margin-bottom: 12px;
}

.department-tree {
  min-height: 420px;
}

.tree-node {
  display: flex;
  width: 100%;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
  padding: 6px 0;
}

.tree-node__main {
  min-width: 0;
}

:deep(.department-tree .el-tree-node__content) {
  height: auto;
  min-height: 48px;
  align-items: flex-start;
  padding-right: 8px;
}

:deep(.department-tree .el-tree-node__expand-icon) {
  margin-top: 10px;
}

.tree-node__title {
  color: #0f172a;
}

.tree-node__meta {
  margin-top: 2px;
  font-size: 12px;
  color: #64748b;
}

.empty-state {
  padding: 24px 0;
  text-align: center;
  color: #94a3b8;
}

.editor-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 16px;
}

.editor-title {
  font-size: 18px;
  font-weight: 600;
  color: #0f172a;
}

.editor-subtitle {
  margin-top: 6px;
  color: #64748b;
}

.editor-form {
  display: grid;
  gap: 4px;
}

.editor-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 8px;
}

@media (max-width: 960px) {
  .layout-grid {
    grid-template-columns: 1fr;
  }
}
</style>
