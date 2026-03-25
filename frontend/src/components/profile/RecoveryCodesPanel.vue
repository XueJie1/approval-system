<template>
  <el-card shadow="never" class="panel">
    <template #header>恢复码</template>

    <el-alert
      title="恢复码只在紧急情况下使用；校验成功后，当前整组恢复码都会失效。"
      type="warning"
      show-icon
      :closable="false"
      class="hint"
    />

    <div class="ops">
      <el-button type="warning" plain :loading="generating" :disabled="!profile?.twoFactorEnabled" @click="generate">
        生成恢复码
      </el-button>
    </div>

    <div class="status-row">
      <span>当前状态</span>
      <el-tag :type="profile?.hasRecoveryCodes ? 'warning' : 'info'">
        {{ profile?.hasRecoveryCodes ? "已有恢复码" : "尚未生成" }}
      </el-tag>
    </div>

    <div v-if="generatedCodes.length > 0" class="codes-block">
      <div class="codes-head">
        <div>
          <div class="codes-title">最近生成的恢复码</div>
          <div class="codes-subtitle">请妥善保存，使用后可在这里重新生成。</div>
        </div>
        <el-button size="small" @click="copyCodes">复制全部</el-button>
      </div>

      <div class="codes-list">
        <el-tag v-for="codeItem in generatedCodes" :key="codeItem" type="warning" effect="plain">
          {{ codeItem }}
        </el-tag>
      </div>

      <div v-if="generatedSetup.secret" class="setup-mini">
        <div class="setup-row">
          <span>Secret</span>
          <code>{{ generatedSetup.secret }}</code>
        </div>
        <div class="setup-row">
          <span>OtpAuthUri</span>
          <code>{{ generatedSetup.otpAuthUri }}</code>
        </div>
      </div>
    </div>

    <el-divider />

    <el-form label-position="top">
      <el-form-item label="恢复码校验">
        <el-input
          v-model="validationCode"
          placeholder="输入恢复码，例如 1234-5678"
          inputmode="text"
        />
      </el-form-item>
    </el-form>

    <div class="ops">
      <el-button :loading="validating" type="primary" :disabled="!validationCode.trim()" @click="validate">
        校验恢复码
      </el-button>
    </div>

    <el-alert
      v-if="validationMessage"
      :type="validationSuccess ? 'success' : 'error'"
      :closable="false"
      :title="validationMessage"
      class="result"
    />
  </el-card>
</template>

<script setup lang="ts">
import { reactive, ref } from "vue";
import { ElMessage } from "element-plus";
import type { UserProfile, TwoFactorSetup } from "../../types";
import { generateRecoveryCodes, validateRecoveryCode } from "../../api/auth";

const props = defineProps<{
  profile: UserProfile | null;
}>();

const emit = defineEmits<{
  (event: "changed"): void;
}>();

const generating = ref(false);
const validating = ref(false);
const validationCode = ref("");
const validationMessage = ref("");
const validationSuccess = ref(false);
const generatedCodes = ref<string[]>([]);
const generatedSetup = reactive<TwoFactorSetup>({
  secret: "",
  otpAuthUri: "",
  recoveryCodes: ""
});

async function generate() {
  if (!props.profile?.twoFactorEnabled) {
    ElMessage.warning("请先启用 2FA 再生成恢复码");
    return;
  }

  generating.value = true;
  try {
    validationSuccess.value = false;
    const data = await generateRecoveryCodes();
    generatedSetup.secret = data.secret;
    generatedSetup.otpAuthUri = data.otpAuthUri;
    generatedSetup.recoveryCodes = data.recoveryCodes ?? "";
    generatedCodes.value = normalizeCodes(data.recoveryCodes);
    validationMessage.value = "";
    ElMessage.success("恢复码已生成");
    emit("changed");
  } finally {
    generating.value = false;
  }
}

async function validate() {
  if (!validationCode.value.trim()) {
    ElMessage.warning("请输入恢复码");
    return;
  }

  validationSuccess.value = false;
  validationMessage.value = "";
  validating.value = true;
  try {
    const result = await validateRecoveryCode({ code: validationCode.value.trim() });
    validationSuccess.value = result.success;
    validationMessage.value = result.message;
    if (result.success) {
      validationCode.value = "";
      generatedCodes.value = [];
      generatedSetup.secret = "";
      generatedSetup.otpAuthUri = "";
      generatedSetup.recoveryCodes = "";
      emit("changed");
    }
  } finally {
    validating.value = false;
  }
}

function normalizeCodes(codes?: string) {
  if (!codes) {
    return [] as string[];
  }
  return codes
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

async function copyCodes() {
  if (generatedCodes.value.length === 0) {
    ElMessage.warning("没有可复制的恢复码");
    return;
  }
  try {
    await navigator.clipboard.writeText(generatedCodes.value.join(","));
    ElMessage.success("恢复码已复制");
  } catch {
    ElMessage.error("复制失败");
  }
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

.status-row {
  margin-top: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.codes-block {
  margin-top: 14px;
  padding: 12px;
  border-radius: 12px;
  border: 1px solid #e6d6b7;
  background: #fffaf1;
}

.codes-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.codes-title {
  font-weight: 700;
}

.codes-subtitle {
  margin-top: 4px;
  color: #7c6a58;
  font-size: 12px;
}

.codes-list {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 12px;
}

.setup-mini {
  display: grid;
  gap: 10px;
  margin-top: 12px;
}

.setup-row {
  display: grid;
  gap: 6px;
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

.result {
  margin-top: 12px;
}
</style>
