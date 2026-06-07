<template>
  <div class="picker-trigger">
    <el-input
      :model-value="selectedDisplay"
      readonly
      :placeholder="placeholder"
      @click="dialogVisible = true"
    >
      <template #append>
        <el-button @click="dialogVisible = true">选择</el-button>
      </template>
    </el-input>
  </div>

  <el-dialog v-model="dialogVisible" title="选择用户" width="700px">
    <div class="toolbar">
      <el-input v-model="keyword" placeholder="按用户名搜索" clearable @keyup.enter="search" />
      <el-button :loading="loading" @click="search">查询</el-button>
    </div>

    <el-table
      v-loading="loading"
      :data="users"
      border
      highlight-current-row
      :current-row-key="draft?.userId"
      row-key="userId"
      :row-class-name="({ row }: { row: UserDirectoryItem }) => isExcluded(row) ? 'row-excluded' : ''"
      @current-change="handleCurrentChange"
    >
      <el-table-column prop="userId" label="UID" width="80" />
      <el-table-column prop="username" label="用户名" min-width="160" />
      <el-table-column label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">
            {{ row.status === 1 ? '启用' : '停用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="角色" min-width="140">
        <template #default="{ row }">
          <span>{{ (row.roleCodes ?? []).join(', ') || '-' }}</span>
        </template>
      </el-table-column>
    </el-table>

    <div class="pagination-bar">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50]"
        layout="total, sizes, prev, pager, next"
        @size-change="reload"
        @current-change="reload"
      />
    </div>

    <template #footer>
      <div class="footer">
        <div class="summary">{{ draft ? `已选：${draft.username}（ID: ${draft.userId}）` : '未选择' }}</div>
        <div class="actions">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" :disabled="!draft" @click="confirmSelection">确认</el-button>
        </div>
      </div>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { ElMessage } from "element-plus";
import type { UserDirectoryItem } from "../../types";
import { listUsers } from "../../api/users";

const props = defineProps<{
  modelValue: string;
  placeholder?: string;
  excludeUserIds?: string[];
}>();

const emit = defineEmits<{
  (event: "update:modelValue", value: string): void;
}>();

const dialogVisible = ref(false);
const loading = ref(false);
const keyword = ref("");
const users = ref<UserDirectoryItem[]>([]);
const draft = ref<UserDirectoryItem | null>(null);
const currentPage = ref(1);
const pageSize = ref(10);
const total = ref(0);

const selectedDisplay = computed(() => {
  if (!props.modelValue) return "";
  const matched = users.value.find(u => String(u.userId) === props.modelValue);
  return matched ? `${matched.username}（ID: ${matched.userId}）` : props.modelValue;
});

watch(dialogVisible, async (open) => {
  if (!open) return;
  currentPage.value = 1;
  await reload();
  draft.value = users.value.find(u => String(u.userId) === props.modelValue) ?? null;
});

function search() {
  currentPage.value = 1;
  reload();
}

async function reload() {
  loading.value = true;
  try {
    const result = await listUsers({
      keyword: keyword.value.trim() || undefined,
      status: 1,
      page: currentPage.value - 1,
      size: pageSize.value,
    });
    users.value = result.content;
    total.value = result.total;
  } finally {
    loading.value = false;
  }
}

function isExcluded(row: UserDirectoryItem) {
  return props.excludeUserIds?.includes(String(row.userId)) ?? false;
}

function handleCurrentChange(row: UserDirectoryItem | null) {
  if (row && isExcluded(row)) return;
  draft.value = row;
}

function confirmSelection() {
  if (!draft.value) return;
  if (draft.value.roleCodes.includes("ADMIN") || draft.value.roleCodes.includes("SYS_ADMIN")) {
    ElMessage.warning("不可选择管理员用户");
    return;
  }
  if (props.excludeUserIds?.includes(String(draft.value.userId))) {
    ElMessage.warning("不可选择该用户");
    return;
  }
  emit("update:modelValue", String(draft.value.userId));
  dialogVisible.value = false;
}
</script>

<style scoped>
.toolbar {
  display: flex;
  gap: 10px;
  margin-bottom: 14px;
}

.pagination-bar {
  margin-top: 14px;
  display: flex;
  justify-content: flex-end;
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

<style>
.el-table .row-excluded {
  opacity: 0.45;
  pointer-events: none;
}
</style>
