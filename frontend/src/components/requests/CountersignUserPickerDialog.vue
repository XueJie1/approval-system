<template>
  <div class="picker-trigger">
    <el-input
      :model-value="selectedDisplay"
      readonly
      placeholder="请选择会签用户"
      @click="dialogVisible = true"
    >
      <template #append>
        <el-button @click="dialogVisible = true">选择</el-button>
      </template>
    </el-input>
  </div>

  <el-dialog v-model="dialogVisible" title="选择会签用户" width="860px">
    <div class="toolbar">
      <el-input v-model="keyword" placeholder="按用户名搜索" clearable @keyup.enter="reload" />
      <el-select v-model="status" style="width: 160px" @change="reload">
        <el-option label="仅启用用户" :value="1" />
        <el-option label="仅停用用户" :value="0" />
        <el-option label="全部状态" :value="-1" />
      </el-select>
      <el-button :loading="loading" @click="reload">查询</el-button>
    </div>

    <el-table
      ref="tableRef"
      v-loading="loading"
      :data="users"
      border
      @selection-change="handleSelectionChange"
    >
      <el-table-column type="selection" width="52" />
      <el-table-column prop="userId" label="UID" min-width="100" />
      <el-table-column prop="username" label="用户名" min-width="180" />
      <el-table-column label="角色" min-width="180">
        <template #default="{ row }">
          <span>{{ (row.roleCodes ?? []).join(", ") || "-" }}</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" min-width="100">
        <template #default="{ row }">
          <el-tag :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? "启用" : "停用" }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="deptId" label="部门ID" min-width="120" />
      <el-table-column label="2FA" min-width="100">
        <template #default="{ row }">
          <el-tag :type="row.twoFactorEnabled ? 'success' : 'info'">
            {{ row.twoFactorEnabled ? "已启用" : "未启用" }}
          </el-tag>
        </template>
      </el-table-column>
    </el-table>

    <template #footer>
      <div class="footer">
        <div class="summary">已选 {{ draftSelection.length }} 人</div>
        <div class="actions">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="confirmSelection">确认</el-button>
        </div>
      </div>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from "vue";
import { ElMessage, type TableInstance } from "element-plus";
import type { UserDirectoryItem } from "../../types";
import { listUsers } from "../../api/users";

const props = defineProps<{
  modelValue: string[];
}>();

const emit = defineEmits<{
  (event: "update:modelValue", value: string[]): void;
}>();

const tableRef = ref<TableInstance>();
const dialogVisible = ref(false);
const loading = ref(false);
const keyword = ref("");
const status = ref<number>(1);
const users = ref<UserDirectoryItem[]>([]);
const draftSelection = ref<UserDirectoryItem[]>([]);

const selectedDisplay = computed(() => {
  if (props.modelValue.length === 0) {
    return "";
  }
  return props.modelValue.join(", ");
});

onMounted(() => {
  reload();
});

watch(dialogVisible, async (open) => {
  if (!open) {
    return;
  }
  await reload();
  syncSelectionToTable();
});

async function reload() {
  loading.value = true;
  try {
    users.value = await listUsers({
      keyword: keyword.value.trim() || undefined,
      status: status.value >= 0 ? status.value : undefined
    });
    await nextTick();
    syncSelectionToTable();
  } finally {
    loading.value = false;
  }
}

function syncSelectionToTable() {
  const table = tableRef.value;
  if (!table) {
    return;
  }
  table.clearSelection();
  const selectedIds = new Set(props.modelValue);
  users.value.forEach((user) => {
    if (selectedIds.has(String(user.userId))) {
      table.toggleRowSelection(user, true);
    }
  });
  draftSelection.value = users.value.filter((user) => selectedIds.has(String(user.userId)));
}

function handleSelectionChange(selection: UserDirectoryItem[]) {
  draftSelection.value = selection;
}

function confirmSelection() {
  const picked = draftSelection.value
    .filter((user) => user.status === 1 && !user.roleCodes.includes("ADMIN") && !user.roleCodes.includes("SYS_ADMIN"))
    .map((user) => String(user.userId));

  if (picked.length !== draftSelection.value.length) {
    ElMessage.warning("仅可选择启用且非管理员角色的用户");
    return;
  }

  emit("update:modelValue", picked);
  dialogVisible.value = false;
}
</script>

<style scoped>
.toolbar {
  display: flex;
  gap: 10px;
  margin-bottom: 14px;
  flex-wrap: wrap;
}

.footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.summary {
  color: #64748b;
  font-size: 13px;
}

.actions {
  display: flex;
  gap: 8px;
}
</style>
