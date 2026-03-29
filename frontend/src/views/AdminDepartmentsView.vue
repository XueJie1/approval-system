<template>
  <div class="page">
    <h2>部门管理</h2>
    
    <div class="toolbar">
      <el-input
        v-model="searchKeyword"
        placeholder="搜索部门名称..."
        style="width: 280px"
        clearable
        @input="handleSearch"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
      <el-button type="primary" @click="handleCreate">新增部门</el-button>
    </div>

    <el-table :data="filteredDepartments" border stripe style="width: 100%">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="deptCode" label="部门代码" width="150" />
      <el-table-column prop="deptName" label="部门名称" />
      <el-table-column prop="parentId" label="父部门" width="100">
        <template #default="{ row }">
          <span>{{ row.parentId ? `ID: ${row.parentId}` : '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180" fixed="right">
        <template #default="{ row }">
          <el-button type="primary" size="small" @click="handleEdit(row)">编辑</el-button>
          <el-button type="danger" size="small" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 新增/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEditing ? '编辑部门' : '新增部门'"
      width="500px"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="部门代码" prop="deptCode">
          <el-input v-model="form.deptCode" placeholder="可选，如 DEPT001" />
        </el-form-item>
        <el-form-item label="部门名称" prop="deptName">
          <el-input v-model="form.deptName" placeholder="请输入部门名称" />
        </el-form-item>
        <el-form-item label="父部门" prop="parentId">
          <el-select v-model="form.parentId" placeholder="选择父部门" allow-clear style="width: 100%">
            <el-option label="无（顶级部门）" :value="null" />
            <el-option
              v-for="dept in parentDepartmentOptions"
              :key="dept.id"
              :label="dept.deptName"
              :value="dept.id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from "vue";
import { ElMessage, ElMessageBox } from "element-plus";
import { Search } from "@element-plus/icons-vue";
import type { FormInstance } from "element-plus";
import { departmentApi, type Department, type CreateDepartmentRequest, type UpdateDepartmentRequest } from "../api/departments";

const departments = ref<Department[]>([]);
const searchKeyword = ref("");
const dialogVisible = ref(false);
const isEditing = ref(false);
const submitting = ref(false);
const formRef = ref<FormInstance>();

const form = ref<CreateDepartmentRequest & { id?: number }>({
  deptCode: "",
  deptName: "",
  parentId: null
});

const rules = {
  deptName: [{ required: true, message: "请输入部门名称", trigger: "blur" }]
};

const filteredDepartments = computed(() => {
  if (!searchKeyword.value) {
    return departments.value;
  }
  return departments.value.filter(dept => 
    dept.deptName.toLowerCase().includes(searchKeyword.value.toLowerCase()) ||
    (dept.deptCode && dept.deptCode.toLowerCase().includes(searchKeyword.value.toLowerCase()))
  );
});

const parentDepartmentOptions = computed(() => {
  return departments.value.filter(dept => !dept.parentId || dept.parentId === null);
});

onMounted(() => {
  loadDepartments();
});

async function loadDepartments() {
  try {
    const response = await departmentApi.list();
    departments.value = response.data;
  } catch (error) {
    console.error("加载部门列表失败", error);
  }
}

function handleSearch() {
  // 搜索在 filteredDepartments 中自动处理
}

function handleCreate() {
  isEditing.value = false;
  form.value = { deptCode: "", deptName: "", parentId: null };
  dialogVisible.value = true;
}

function handleEdit(row: Department) {
  isEditing.value = true;
  form.value = {
    deptCode: row.deptCode || "",
    deptName: row.deptName,
    parentId: row.parentId
  };
  dialogVisible.value = true;
}

async function handleSubmit() {
  if (!formRef.value) return;
  
  try {
    await formRef.value.validate();
    submitting.value = true;

    if (isEditing.value) {
      await departmentApi.update(form.value.id!, form.value as UpdateDepartmentRequest);
      ElMessage.success("更新成功");
    } else {
      await departmentApi.create(form.value);
      ElMessage.success("创建成功");
    }

    dialogVisible.value = false;
    loadDepartments();
  } catch (error) {
    console.error("提交失败", error);
  } finally {
    submitting.value = false;
  }
}

async function handleDelete(row: Department) {
  try {
    await ElMessageBox.confirm(
      `确定要删除部门 "${row.deptName}" 吗？`,
      "警告",
      {
        confirmButtonText: "确定",
        cancelButtonText: "取消",
        type: "warning"
      }
    );

    await departmentApi.delete(row.id);
    ElMessage.success("删除成功");
    loadDepartments();
  } catch (error: any) {
    if (error !== "cancel") {
      console.error("删除失败", error);
    }
  }
}
</script>

<style scoped>
.page {
  padding: 20px;
}

.page h2 {
  margin: 0 0 20px 0;
  font-size: 20px;
  color: #333;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  gap: 12px;
}
</style>
