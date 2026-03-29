<template>
  <div class="page">
    <h2>岗位管理</h2>
    
    <div class="toolbar">
      <el-input
        v-model="searchKeyword"
        placeholder="搜索岗位..."
        style="width: 280px"
        clearable
        @input="handleSearch"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
      <el-button type="primary" @click="handleCreate">新增岗位</el-button>
    </div>

    <el-table :data="filteredPositions" border stripe style="width: 100%">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="postCode" label="岗位代码" width="150" />
      <el-table-column prop="postName" label="岗位名称" />
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
      :title="isEditing ? '编辑岗位' : '新增岗位'"
      width="500px"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="岗位代码" prop="postCode">
          <el-input v-model="form.postCode" placeholder="如 MANAGER" />
        </el-form-item>
        <el-form-item label="岗位名称" prop="postName">
          <el-input v-model="form.postName" placeholder="请输入岗位名称" />
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
import { positionApi, type Position, type CreatePositionRequest, type UpdatePositionRequest } from "../api/positions";

const positions = ref<Position[]>([]);
const searchKeyword = ref("");
const dialogVisible = ref(false);
const isEditing = ref(false);
const submitting = ref(false);
const formRef = ref<FormInstance>();

const form = ref<CreatePositionRequest & { id?: number }>({
  postCode: "",
  postName: ""
});

const rules = {
  postCode: [{ required: true, message: "请输入岗位代码", trigger: "blur" }],
  postName: [{ required: true, message: "请输入岗位名称", trigger: "blur" }]
};

const filteredPositions = computed(() => {
  if (!searchKeyword.value) {
    return positions.value;
  }
  return positions.value.filter(pos => 
    pos.postName.toLowerCase().includes(searchKeyword.value.toLowerCase()) ||
    pos.postCode.toLowerCase().includes(searchKeyword.value.toLowerCase())
  );
});

onMounted(() => {
  loadPositions();
});

async function loadPositions() {
  try {
    const response = await positionApi.list();
    positions.value = response.data;
  } catch (error) {
    console.error("加载岗位列表失败", error);
  }
}

function handleSearch() {
  // 搜索在 filteredPositions 中自动处理
}

function handleCreate() {
  isEditing.value = false;
  form.value = { postCode: "", postName: "" };
  dialogVisible.value = true;
}

function handleEdit(row: Position) {
  isEditing.value = true;
  form.value = {
    id: row.id,
    postCode: row.postCode,
    postName: row.postName
  };
  dialogVisible.value = true;
}

async function handleSubmit() {
  if (!formRef.value) return;
  
  try {
    await formRef.value.validate();
    submitting.value = true;

    if (isEditing.value && form.value.id) {
      await positionApi.update(form.value.id, form.value as UpdatePositionRequest);
      ElMessage.success("更新成功");
    } else {
      await positionApi.create(form.value);
      ElMessage.success("创建成功");
    }

    dialogVisible.value = false;
    loadPositions();
  } catch (error) {
    console.error("提交失败", error);
  } finally {
    submitting.value = false;
  }
}

async function handleDelete(row: Position) {
  try {
    await ElMessageBox.confirm(
      `确定要删除岗位 "${row.postName}" 吗？`,
      "警告",
      {
        confirmButtonText: "确定",
        cancelButtonText: "取消",
        type: "warning"
      }
    );

    await positionApi.delete(row.id);
    ElMessage.success("删除成功");
    loadPositions();
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
