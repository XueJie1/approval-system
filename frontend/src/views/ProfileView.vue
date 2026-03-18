<template>
  <div class="stack">
    <div>
      <h2 class="page-title">个人中心</h2>
      <p class="page-subtitle">查看当前用户资料并管理 2FA</p>
    </div>

    <el-card shadow="never" class="panel">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="用户ID">{{ profile?.userId }}</el-descriptions-item>
        <el-descriptions-item label="用户名">{{ profile?.username }}</el-descriptions-item>
        <el-descriptions-item label="角色">{{ profile?.roles.join(", ") }}</el-descriptions-item>
        <el-descriptions-item label="2FA 状态">
          <el-tag :type="profile?.twoFactorEnabled ? 'success' : 'info'">{{ profile?.twoFactorEnabled ? "已启用" : "未启用" }}</el-tag>
        </el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="panel">
      <template #header>双因素认证</template>
      <div class="ops">
        <el-button :disabled="profile?.twoFactorEnabled" @click="loadSetup">获取 2FA 配置</el-button>
        <el-button type="success" @click="enable">启用 2FA</el-button>
        <el-button type="danger" plain @click="disable">禁用 2FA</el-button>
        <el-button type="warning" plain @click="generateRecovery">生成恢复码</el-button>
      </div>

      <div v-if="setupData.secret" class="result">
        <p><strong>Secret:</strong> {{ setupData.secret }}</p>
        <p><strong>OtpAuthUri:</strong> {{ setupData.otpAuthUri }}</p>
      </div>

      <el-form inline style="margin-top: 12px">
        <el-form-item label="验证码">
          <el-input v-model="code" placeholder="6 位验证码" />
        </el-form-item>
      </el-form>

      <el-alert v-if="recoveryCodes" type="warning" :closable="false" :title="`恢复码：${recoveryCodes}`" />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from "vue";
import { ElMessage } from "element-plus";
import { disable2fa, enable2fa, generateRecoveryCodes, me, setup2fa } from "../api/auth";
import type { UserProfile } from "../types";

const profile = ref<UserProfile | null>(null);
const code = ref("");
const recoveryCodes = ref("");
const setupData = reactive({
  secret: "",
  otpAuthUri: ""
});

onMounted(() => {
  refresh();
});

async function refresh() {
  profile.value = await me();
}

async function loadSetup() {
  const data = await setup2fa();
  setupData.secret = data.secret;
  setupData.otpAuthUri = data.otpAuthUri;
}

async function enable() {
  if (code.value.trim().length !== 6) {
    ElMessage.warning("请输入 6 位验证码");
    return;
  }
  await enable2fa({ code: code.value.trim() });
  ElMessage.success("2FA 已启用");
  await refresh();
}

async function disable() {
  if (code.value.trim().length !== 6) {
    ElMessage.warning("请输入 6 位验证码");
    return;
  }
  await disable2fa({ code: code.value.trim() });
  ElMessage.success("2FA 已禁用");
  await refresh();
}

async function generateRecovery() {
  if (!profile.value?.twoFactorEnabled) {
    ElMessage.warning("请先完成 2FA 启用后再生成恢复码");
    return;
  }
  const data = await generateRecoveryCodes();
  recoveryCodes.value = data.recoveryCodes ?? "(后端未返回恢复码文本)";
}
</script>

<style scoped>
.stack {
  display: grid;
  gap: 14px;
}

.panel {
  border-radius: 14px;
  border-color: #d8e4ed;
}

.ops {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.result {
  margin-top: 10px;
  padding: 10px;
  border: 1px solid #d8e4ed;
  border-radius: 10px;
  background: #f8fffd;
}
</style>
