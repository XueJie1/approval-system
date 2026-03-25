<template>
  <section class="draft-panel page-card">
    <div class="head">
      <div>
        <div class="title">草稿</div>
        <div class="subtitle">保存后可以继续在同一个 businessKey 上提交</div>
      </div>
      <el-tag v-if="effectiveBusinessKey" type="success" effect="plain">可提交：{{ effectiveBusinessKey }}</el-tag>
    </div>

    <div class="grid">
      <el-form-item label="业务单号">
        <el-input
          :model-value="businessKey"
          placeholder="可留空自动生成"
          @update:model-value="onBusinessKeyChange"
        />
      </el-form-item>
    </div>

    <div class="actions">
      <el-button type="primary" :loading="saving" @click="$emit('save')">保存草稿</el-button>
      <el-button :disabled="!effectiveBusinessKey" :loading="submitting" @click="$emit('submit')">
        提交草稿
      </el-button>
    </div>

    <el-alert
      v-if="lastSavedBusinessKey"
      type="success"
      :closable="false"
      :title="`最近保存的草稿编号：${lastSavedBusinessKey}`"
    />
  </section>
</template>

<script setup lang="ts">
import { computed } from "vue";

interface Props {
  businessKey: string;
  fallbackBusinessKey?: string;
  saving?: boolean;
  submitting?: boolean;
  lastSavedBusinessKey?: string;
}

const props = withDefaults(defineProps<Props>(), {
  fallbackBusinessKey: "",
  saving: false,
  submitting: false,
  lastSavedBusinessKey: ""
});

const emit = defineEmits<{
  (event: "update:businessKey", value: string): void;
  (event: "save"): void;
  (event: "submit"): void;
}>();

const effectiveBusinessKey = computed(() => props.businessKey.trim() || props.fallbackBusinessKey.trim());

function onBusinessKeyChange(value: string | number | null | undefined) {
  emit("update:businessKey", value == null ? "" : String(value));
}
</script>

<style scoped>
.draft-panel {
  padding: 18px 20px;
  display: grid;
  gap: 14px;
}

.head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.title {
  font-size: 16px;
  font-weight: 700;
}

.subtitle {
  margin-top: 4px;
  color: var(--text-subtle);
  font-size: 13px;
}

.grid {
  display: grid;
  gap: 12px;
}

.actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

@media (max-width: 768px) {
  .head {
    flex-direction: column;
  }
}
</style>
