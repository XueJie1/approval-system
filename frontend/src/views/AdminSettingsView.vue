<template>
  <div class="admin-page stack">
    <div class="heading">
      <div>
        <h2 class="page-title">系统设置</h2>
        <p class="page-subtitle">配置 AI 连接参数（Base URL、API Key、模型）并安全持久化</p>
      </div>
      <div class="heading-actions">
        <el-button :loading="loading" @click="loadSettings">刷新</el-button>
      </div>
    </div>

    <el-card shadow="never" class="panel" v-loading="loading">
      <template #header>
        <div class="panel-header">
          <span class="panel-title">OpenAI Provider 设置</span>
          <el-tag :type="settings?.hasApiKey ? 'success' : 'info'">
            {{ settings?.hasApiKey ? "API Key 已配置" : "API Key 未配置" }}
          </el-tag>
        </div>
      </template>

      <el-alert
        :title="settings?.hasApiKey ? `当前密钥：${settings.apiKeyMasked || '已加密保存'}` : '当前未保存 API Key'"
        type="info"
        :closable="false"
        show-icon
      >
        <template #default>
          <div class="alert-body">
            API Key 只会加密存储，页面不会回显明文。
            <span v-if="settings?.updatedAt">最近更新：{{ formatDateTime(settings.updatedAt) }}</span>
          </div>
        </template>
      </el-alert>

      <el-form ref="formRef" :model="form" :rules="formRules" label-position="top" class="form-grid">
        <el-form-item label="Base URL" prop="baseUrl">
          <el-input
            v-model="form.baseUrl"
            placeholder="例如 https://api.openai.com/v1"
            clearable
            :disabled="saving"
          />
          <div class="form-hint">留空将回退到系统默认地址。</div>
        </el-form-item>

        <el-form-item label="模型" prop="model">
          <div class="model-row">
            <el-select
              v-model="form.model"
              class="model-select"
              filterable
              allow-create
              default-first-option
              placeholder="请选择或输入模型"
              :disabled="saving"
            >
              <el-option v-for="modelItem in modelOptions" :key="modelItem" :label="modelItem" :value="modelItem" />
            </el-select>
            <el-button :loading="modelsLoading" :disabled="saving" @click="loadModels()">刷新模型列表</el-button>
          </div>
          <div class="form-hint">从 [Base URL]/models 拉取并列举可用模型。</div>
        </el-form-item>

        <el-form-item label="API Key">
          <el-input
            v-model="form.apiKey"
            type="password"
            show-password
            autocomplete="new-password"
            placeholder="留空表示不修改已保存密钥"
            :disabled="saving || form.clearApiKey"
          />
          <div class="form-hint">输入新值会覆盖旧值；不会显示旧值明文。</div>
        </el-form-item>

        <el-form-item class="full-span">
          <el-checkbox v-model="form.clearApiKey" :disabled="saving">清除已保存 API Key</el-checkbox>
        </el-form-item>
      </el-form>

      <div class="action-row">
        <el-button :disabled="saving" @click="useDefaultBaseUrl">恢复默认 Base URL</el-button>
        <el-button type="primary" :loading="saving" @click="saveSettings">保存设置</el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from "vue";
import { ElMessage, ElMessageBox } from "element-plus";
import type { FormInstance, FormRules } from "element-plus";
import type { AdminOpenAiSettings } from "../types";
import { getAdminOpenAiSettings, listAdminOpenAiModels, updateAdminOpenAiSettings } from "../api/admin-settings";
import { buildOpenAiSettingsUpdatePayload, normalizeBaseUrl, normalizeModel } from "../utils/admin-settings";

const DEFAULT_OPENAI_BASE_URL = "https://api.openai.com/v1";

const loading = ref(false);
const saving = ref(false);
const modelsLoading = ref(false);
const settings = ref<AdminOpenAiSettings | null>(null);
const formRef = ref<FormInstance>();
const modelOptions = ref<string[]>([]);

const form = reactive({
  baseUrl: "",
  apiKey: "",
  model: "gpt-5.4-mini",
  clearApiKey: false
});

const formRules: FormRules = {
  baseUrl: [
    {
      validator: (_rule, value: string, callback) => {
        const normalized = normalizeBaseUrl(value ?? "");
        if (!normalized) {
          callback();
          return;
        }
        try {
          const url = new URL(normalized);
          if (!["http:", "https:"].includes(url.protocol)) {
            callback(new Error("Base URL 必须是 http/https 地址"));
            return;
          }
          callback();
        } catch {
          callback(new Error("请输入合法的 Base URL"));
        }
      },
      trigger: "blur"
    }
  ]
};

const hasPendingApiKeyUpdate = computed(() => Boolean(form.apiKey.trim().length));

onMounted(() => {
  loadSettings();
});

async function loadSettings() {
  loading.value = true;
  try {
    const data = await getAdminOpenAiSettings();
    settings.value = data;
    form.baseUrl = data.baseUrl ?? "";
    form.apiKey = "";
    form.model = data.model ?? "gpt-5.4-mini";
    form.clearApiKey = false;
    await loadModels(true);
  } finally {
    loading.value = false;
  }
}

async function saveSettings() {
  await formRef.value?.validate();

  if (hasPendingApiKeyUpdate.value) {
    await ElMessageBox.confirm("将覆盖当前已保存的 API Key，是否继续？", "确认覆盖", {
      type: "warning",
      confirmButtonText: "覆盖保存",
      cancelButtonText: "取消"
    });
  }

  if (form.clearApiKey) {
    await ElMessageBox.confirm("将删除已保存的 API Key，是否继续？", "确认清除", {
      type: "warning",
      confirmButtonText: "确认清除",
      cancelButtonText: "取消"
    });
  }

  saving.value = true;
  try {
    const payload = buildOpenAiSettingsUpdatePayload(form);
    const data = await updateAdminOpenAiSettings(payload);
    settings.value = data;
    form.baseUrl = data.baseUrl ?? "";
    form.apiKey = "";
    form.model = data.model ?? form.model;
    form.clearApiKey = false;
    await loadModels(true);
    ElMessage.success("系统设置已保存");
  } finally {
    saving.value = false;
  }
}

function useDefaultBaseUrl() {
  form.baseUrl = DEFAULT_OPENAI_BASE_URL;
}

async function loadModels(silent = false) {
  modelsLoading.value = true;
  try {
    const data = await listAdminOpenAiModels({
      baseUrl: normalizeBaseUrl(form.baseUrl),
      apiKey: form.apiKey.trim() || null
    });
    const selectedModel = normalizeModel(form.model);
    const merged = [...data.models];
    if (selectedModel && !merged.includes(selectedModel)) {
      merged.unshift(selectedModel);
    }
    modelOptions.value = merged;
    if (!selectedModel && data.selectedModel) {
      form.model = data.selectedModel;
    }
    if (!silent) {
      ElMessage.success(`已加载 ${data.models.length} 个模型`);
    }
  } catch (error) {
    if (!silent) {
      throw error;
    }
  } finally {
    modelsLoading.value = false;
  }
}

function formatDateTime(value?: string | null) {
  if (!value) {
    return "-";
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }
  return date.toLocaleString("zh-CN", { hour12: false });
}
</script>

<style scoped>
.admin-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.stack {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.heading {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.heading-actions {
  display: flex;
  gap: 8px;
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

.panel {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.panel-title {
  font-weight: 600;
  color: #1f2937;
}

.alert-body {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-grid {
  margin-top: 16px;
}

.form-hint {
  margin-top: 6px;
  font-size: 12px;
  color: #909399;
}

.model-row {
  display: flex;
  gap: 8px;
}

.model-select {
  flex: 1;
}

.full-span {
  width: 100%;
}

.action-row {
  margin-top: 4px;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>
