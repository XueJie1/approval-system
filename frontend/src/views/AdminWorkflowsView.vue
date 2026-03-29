<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <h2 class="page-title">流程管理</h2>
        <p class="page-subtitle">工作流定义、版本管理和部署</p>
      </div>
    </div>

    <div class="placeholder-content">
      <el-empty description="功能开发中" />
    </div>
  </div>
</template>

<script setup lang="ts">
</script>

<style scoped>
.admin-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.heading {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.page-title {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  color: #1f2937;
}

.page-subtitle {
  margin: 6px 0 0;
  color: #6b7280;
  font-size: 14px;
}

.placeholder-content {
  padding: 48px;
  text-align: center;
}

.stack {
  display: flex;
  flex-direction: column;
  gap: 18px;
}
</style>
