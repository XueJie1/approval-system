<template>
  <el-card shadow="never" class="panel">
    <template #header>账户概览</template>
    <el-skeleton v-if="loading && !profile" :rows="3" animated />
    <el-descriptions v-else :column="2" border>
      <el-descriptions-item label="用户ID">{{ profile?.userId }}</el-descriptions-item>
      <el-descriptions-item label="用户名">{{ profile?.username }}</el-descriptions-item>
      <el-descriptions-item label="角色">{{ profile?.roles.join(", ") }}</el-descriptions-item>
      <el-descriptions-item label="2FA 状态">
        <el-tag :type="profile?.twoFactorEnabled ? 'success' : 'info'">
          {{ profile?.twoFactorEnabled ? "已启用" : "未启用" }}
        </el-tag>
      </el-descriptions-item>
      <el-descriptions-item label="恢复码状态">
        <el-tag :type="profile?.hasRecoveryCodes ? 'warning' : 'info'">
          {{ profile?.hasRecoveryCodes ? "可用" : "未生成" }}
        </el-tag>
      </el-descriptions-item>
    </el-descriptions>
  </el-card>
</template>

<script setup lang="ts">
import type { UserProfile } from "../../types";

defineProps<{
  profile: UserProfile | null;
  loading: boolean;
}>();
</script>

<style scoped>
.panel {
  border-radius: 14px;
  border-color: #d8e4ed;
}
</style>
