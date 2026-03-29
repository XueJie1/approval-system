<template>
  <div class="auth-page">
    <div class="auth-panel page-card">
      <h1>管理员初始化</h1>
      <p>系统首次启动请创建管理员账号，此入口初始化后自动关闭。</p>

      <el-alert title="请设置强密码并妥善保管" type="warning" show-icon :closable="false" />

      <el-form :model="form" label-position="top" style="margin-top: 16px">
        <el-form-item label="管理员用户名">
          <el-input v-model="form.username" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="form.password" type="password" show-password />
        </el-form-item>
        <el-form-item label="确认密码">
          <el-input v-model="form.confirmPassword" type="password" show-password />
        </el-form-item>
        <el-button type="primary" class="action-btn" :loading="loading" @click="submit">创建管理员并进入系统</el-button>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted } from "vue";
import { ElMessage } from "element-plus";
import { useRouter } from "vue-router";
import { bootstrapAdmin, fetchBootstrapStatus } from "../api/auth";
import { useAuthStore } from "../stores/auth";

const router = useRouter();
const auth = useAuthStore();
const loading = ref(false);

const form = reactive({
  username: "",
  password: "",
  confirmPassword: ""
});

onMounted(async () => {
  try {
    const status = await fetchBootstrapStatus();
    if (!status.isBootstrapMode) {
      router.replace("/login");
    }
  } catch {
    router.replace("/login");
  }
});

async function submit() {
  if (!form.username.trim()) {
    ElMessage.warning("请输入用户名");
    return;
  }
  if (form.password.length < 8) {
    ElMessage.warning("密码至少 8 位");
    return;
  }
  if (form.password !== form.confirmPassword) {
    ElMessage.warning("两次密码不一致");
    return;
  }

  loading.value = true;
  try {
    const result = await bootstrapAdmin({ username: form.username.trim(), password: form.password });
    if (result.accessToken && result.userId && result.username) {
      auth.setAuth(result.accessToken, {
        userId: result.userId,
        username: result.username,
        roles: result.roles ?? []
      });
      ElMessage.success("管理员初始化完成");
      router.replace("/admin");
      return;
    }
    ElMessage.success("初始化完成，请登录");
    router.replace("/login");
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
  width: min(500px, 100%);
  padding: 28px;
  background: linear-gradient(170deg, #ffffff 0%, #fff5ec 100%);
}

h1 {
  margin: 0;
  font-size: 26px;
}

p {
  color: #64748b;
}

.action-btn {
  width: 100%;
}
</style>
