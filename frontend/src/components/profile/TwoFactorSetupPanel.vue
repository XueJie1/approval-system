<template>
  <el-card shadow="never" class="panel">
    <template #header>双因素认证</template>

    <el-alert
      title="先获取配置，再用验证器生成 6 位验证码完成启用或禁用。"
      type="info"
      show-icon
      :closable="false"
      class="hint"
    />

    <div class="ops">
      <el-button :loading="loadingSetup" @click="loadSetup">获取配置</el-button>
      <el-button type="success" :disabled="profile?.twoFactorEnabled || !setupData.secret" :loading="working" @click="enable">
        启用 2FA
      </el-button>
      <el-button type="danger" plain :disabled="!profile?.twoFactorEnabled" :loading="working" @click="disable">
        禁用 2FA
      </el-button>
    </div>

    <el-form label-position="top" class="code-form">
      <el-form-item label="验证码">
        <el-input
          v-model="code"
          maxlength="6"
          placeholder="输入验证器生成的 6 位验证码"
          inputmode="numeric"
        />
      </el-form-item>
    </el-form>

    <div v-if="setupData.secret" class="setup-block">
      <div class="setup-title">配置详情</div>
      <div class="qr-section">
        <canvas ref="qrCanvas" class="qr-canvas" />
        <p class="qr-hint">使用 Microsoft Authenticator、Google Authenticator 等验证器应用扫描二维码以添加验证码。</p>
      </div>
      <div class="setup-row">
        <span>Secret（手动输入时使用）</span>
        <code>{{ setupData.secret }}</code>
      </div>
      <div class="setup-actions">
        <el-button size="small" @click="copySecret">复制 Secret</el-button>
        <el-button size="small" @click="copyUri">复制配置 URI</el-button>
      </div>
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { reactive, ref, nextTick } from "vue";
import { ElMessage } from "element-plus";
import QRCode from "qrcode";
import type { UserProfile } from "../../types";
import { enable2fa, disable2fa, setup2fa } from "../../api/auth";

const props = defineProps<{
  profile: UserProfile | null;
}>();

const emit = defineEmits<{
  (event: "changed"): void;
}>();

const loadingSetup = ref(false);
const working = ref(false);
const code = ref("");
const qrCanvas = ref<HTMLCanvasElement | null>(null);
const setupData = reactive({
  secret: "",
  otpAuthUri: ""
});

async function loadSetup() {
  loadingSetup.value = true;
  try {
    const data = await setup2fa();
    setupData.secret = data.secret;
    setupData.otpAuthUri = data.otpAuthUri;
    ElMessage.success("2FA 配置已加载");
    await nextTick();
    if (qrCanvas.value) {
      await QRCode.toCanvas(qrCanvas.value, data.otpAuthUri, { width: 200, margin: 2 });
    }
  } finally {
    loadingSetup.value = false;
  }
}

async function enable() {
  if (!validateCode()) {
    return;
  }
  working.value = true;
  try {
    await enable2fa({ code: code.value.trim() });
    code.value = "";
    ElMessage.success("2FA 已启用");
    emit("changed");
  } finally {
    working.value = false;
  }
}

async function disable() {
  if (!validateCode()) {
    return;
  }
  working.value = true;
  try {
    await disable2fa({ code: code.value.trim() });
    code.value = "";
    setupData.secret = "";
    setupData.otpAuthUri = "";
    if (qrCanvas.value) {
      const ctx = qrCanvas.value.getContext("2d");
      ctx?.clearRect(0, 0, qrCanvas.value.width, qrCanvas.value.height);
    }
    ElMessage.success("2FA 已禁用");
    emit("changed");
  } finally {
    working.value = false;
  }
}

function validateCode() {
  if (!/^\d{6}$/.test(code.value.trim())) {
    ElMessage.warning("请输入 6 位验证码");
    return false;
  }
  return true;
}

async function copyText(value: string, label: string) {
  if (!value) {
    ElMessage.warning(`没有可复制的${label}`);
    return;
  }
  try {
    await navigator.clipboard.writeText(value);
    ElMessage.success(`${label}已复制`);
  } catch {
    ElMessage.error("复制失败");
  }
}

function copySecret() {
  return copyText(setupData.secret, "Secret");
}

function copyUri() {
  return copyText(setupData.otpAuthUri, "配置 URI");
}
</script>

<style scoped>
.panel {
  border-radius: 14px;
  border-color: #d8e4ed;
}

.hint {
  margin-bottom: 12px;
}

.ops {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.code-form {
  margin-top: 12px;
}

.setup-block {
  margin-top: 12px;
  padding: 12px;
  border: 1px solid #d8e4ed;
  border-radius: 12px;
  background: #f8fffd;
}

.setup-title {
  font-weight: 700;
  margin-bottom: 10px;
}

.setup-row {
  display: grid;
  gap: 6px;
  margin-top: 10px;
}

.setup-row span {
  color: #64748b;
  font-size: 12px;
}

.setup-row code {
  display: block;
  padding: 8px 10px;
  border-radius: 10px;
  background: #fff;
  border: 1px dashed #cbd5e1;
  word-break: break-all;
}

.uri {
  font-size: 12px;
}

.qr-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 12px;
}

.qr-canvas {
  border-radius: 8px;
  border: 1px solid #d8e4ed;
}

.qr-hint {
  margin-top: 8px;
  font-size: 12px;
  color: #64748b;
  text-align: center;
  max-width: 260px;
}

.setup-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 12px;
}
</style>
