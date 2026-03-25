<template>
  <div class="stack">
    <div class="heading">
      <div>
        <h2 class="page-title">个人中心</h2>
        <p class="page-subtitle">查看当前用户资料并管理 2FA</p>
      </div>
      <el-button :loading="loading" @click="refresh">刷新资料</el-button>
    </div>

    <profile-identity-card :profile="profile" :loading="loading" />

    <el-row :gutter="14">
      <el-col :xs="24" :lg="12">
        <two-factor-setup-panel :profile="profile" @changed="refresh" />
      </el-col>
      <el-col :xs="24" :lg="12">
        <recovery-codes-panel :profile="profile" @changed="refresh" />
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import type { UserProfile } from "../types";
import { useAuthStore } from "../stores/auth";
import ProfileIdentityCard from "../components/profile/ProfileIdentityCard.vue";
import TwoFactorSetupPanel from "../components/profile/TwoFactorSetupPanel.vue";
import RecoveryCodesPanel from "../components/profile/RecoveryCodesPanel.vue";

const auth = useAuthStore();
const loading = ref(false);
const profile = computed<UserProfile | null>(() => auth.profile);

onMounted(() => {
  refresh();
});

async function refresh() {
  loading.value = true;
  try {
    await auth.refreshProfile();
  } finally {
    loading.value = false;
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
</style>
