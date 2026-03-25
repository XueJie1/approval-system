<template>
  <div v-if="fields.length > 0" class="dynamic-block">
    <div class="head">
      <div>
        <h4>动态表单</h4>
        <p v-if="loadedVersionId" class="meta">版本 {{ loadedVersionId }}</p>
      </div>
    </div>

    <div class="form-grid">
      <el-form-item v-for="field in fields" :key="field.fieldKey" :label="field.label || field.fieldKey">
        <el-input
          v-if="field.fieldType === 'string' || field.fieldType === 'date'"
          :model-value="resolveValue(field.fieldKey)"
          :placeholder="field.fieldType === 'date' ? 'YYYY-MM-DD' : ''"
          @update:model-value="updateValue(field.fieldKey, $event)"
        />
        <el-input-number
          v-else-if="field.fieldType === 'number'"
          :model-value="resolveValue(field.fieldKey)"
          :min="0"
          :controls="false"
          style="width: 100%"
          @update:model-value="updateValue(field.fieldKey, $event)"
        />
        <el-select
          v-else-if="field.fieldType === 'select'"
          :model-value="resolveValue(field.fieldKey)"
          style="width: 100%"
          @update:model-value="updateValue(field.fieldKey, $event)"
        >
          <el-option
            v-for="option in parseOptions(field.optionsJson)"
            :key="String(option.value)"
            :label="String(option.label)"
            :value="option.value"
          />
        </el-select>
        <el-input
          v-else
          :model-value="resolveValue(field.fieldKey)"
          @update:model-value="updateValue(field.fieldKey, $event)"
        />
      </el-form-item>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { FormField } from "../../types";

interface Props {
  fields: FormField[];
  modelValue: Record<string, unknown>;
  loadedVersionId?: number | null;
}

const props = withDefaults(defineProps<Props>(), {
  loadedVersionId: null
});

const emit = defineEmits<{
  (event: "update:modelValue", value: Record<string, unknown>): void;
}>();

function resolveValue(fieldKey: string) {
  return props.modelValue[fieldKey] as string | number | undefined;
}

function updateValue(fieldKey: string, value: string | number | null | undefined) {
  emit("update:modelValue", {
    ...props.modelValue,
    [fieldKey]: value ?? ""
  });
}

function parseOptions(optionsJson?: string) {
  if (!optionsJson) {
    return [] as Array<{ label: string; value: string | number }>;
  }
  try {
    return JSON.parse(optionsJson) as Array<{ label: string; value: string | number }>;
  } catch {
    return [];
  }
}
</script>

<style scoped>
.dynamic-block {
  display: grid;
  gap: 10px;
}

.head h4 {
  margin: 0;
  font-size: 16px;
}

.meta {
  margin: 4px 0 0;
  color: var(--text-subtle);
  font-size: 12px;
}
</style>
