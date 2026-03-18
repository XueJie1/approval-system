<template>
  <div class="auth-page">
    <div class="auth-panel page-card">
      <h1>智能协同审批系统</h1>
      <p>登录后可发起审批、处理待办、跟踪流程进度</p>

      <el-form v-if="step === 'login'" :model="loginForm" label-position="top" @submit.prevent="submitLogin">
        <el-form-item label="用户名">
          <el-input v-model="loginForm.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="loginForm.password" type="password" show-password placeholder="请输入密码" />
        </el-form-item>
        <el-button type="primary" :loading="loading" class="action-btn" @click="submitLogin">登录</el-button>
      </el-form>

      <el-form v-else :model="twoFaForm" label-position="top" @submit.prevent="submit2fa">
        <el-alert title="检测到该账号已启用 2FA" type="warning" show-icon :closable="false" />
        <el-form-item label="6 位验证码" style="margin-top: 12px">
          <el-input v-model="twoFaForm.code" maxlength="6" placeholder="请输入 TOTP 验证码" />
        </el-form-item>
        <div class="split-actions">
          <el-button @click="step = 'login'">返回</el-button>
          <el-button type="primary" :loading="loading" @click="submit2fa">验证并登录</el-button>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import { ElMessage } from "element-plus";
import { fetchBootstrapStatus, login, verify2fa } from "../api/auth";
import { useAuthStore } from "../stores/auth";
import type { LoginResult } from "../types";

const router = useRouter();
const auth = useAuthStore();

const loading = ref(false);
const step = ref<"login" | "2fa">("login");
const challengeToken = ref("");

const loginForm = reactive({
  username: "",
  password: ""
});

const twoFaForm = reactive({
  code: ""
});

onMounted(async () => {
  try {
    const status = await fetchBootstrapStatus();
    if (status.isBootstrapMode) {
      await router.replace("/bootstrap");
    }
  } catch {
    // allow user to remain on login page when bootstrap check fails
  }
});

function storeAndJump(result: LoginResult) {
  if (!result.accessToken || !result.userId || !result.username) {
    ElMessage.error("登录响应缺少必要字段");
    return;
  }
  auth.setAuth(result.accessToken, {
    userId: result.userId,
    username: result.username,
    roles: result.roles ?? []
  });
  router.replace("/start");
}

async function submitLogin() {
  loading.value = true;
  try {
    const result = await login({ username: loginForm.username.trim(), password: loginForm.password });
    if (result.twoFactorRequired) {
      challengeToken.value = result.challengeToken ?? "";
      step.value = "2fa";
      ElMessage.info("请输入 2FA 验证码");
      return;
    }
    storeAndJump(result);
  } finally {
    loading.value = false;
  }
}

async function submit2fa() {
  if (!challengeToken.value) {
    ElMessage.error("挑战令牌丢失，请重新登录");
    step.value = "login";
    return;
  }
  loading.value = true;
  try {
    const result = await verify2fa({
      challengeToken: challengeToken.value,
      code: twoFaForm.code.trim()
    });
    storeAndJump(result);
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 16px;
}

.auth-panel {
  width: min(460px, 100%);
  padding: 28px;
  background: linear-gradient(165deg, #ffffff 0%, #eefbf7 100%);
}

h1 {
  margin: 0;
  font-size: 26px;
}

p {
  color: #64748b;
  margin-bottom: 20px;
}

.action-btn {
  width: 100%;
}

.split-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>
