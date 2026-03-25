<template>
  <el-card shadow="never" class="panel">
    <template #header>相关任务</template>

    <el-empty v-if="!loading && tasks.length === 0" description="当前筛选条件下没有关联任务" />
    <el-table v-else :data="tasks" border v-loading="loading">
      <el-table-column prop="taskId" label="任务ID" min-width="240" show-overflow-tooltip />
      <el-table-column prop="taskName" label="任务名称" min-width="160" />
      <el-table-column prop="processInstanceId" label="流程实例" min-width="220" show-overflow-tooltip />
      <el-table-column prop="assignee" label="办理人" min-width="120" />
      <el-table-column prop="createTime" label="创建时间" min-width="170" />
    </el-table>
  </el-card>
</template>

<script setup lang="ts">
import type { TaskInfo } from "../../types";

defineProps<{
  tasks: TaskInfo[];
  loading: boolean;
}>();
</script>

<style scoped>
.panel {
  border-radius: 14px;
  border-color: #d8e4ed;
}
</style>
