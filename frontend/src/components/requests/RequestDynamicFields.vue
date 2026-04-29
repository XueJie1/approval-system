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
          v-if="field.fieldType === 'string' && !isTemporalField(field)"
          :model-value="resolveValue(field.fieldKey)"
          @update:model-value="updateValue(field.fieldKey, $event)"
        />
        <el-date-picker
          v-else-if="isTemporalField(field)"
          :model-value="resolveValue(field.fieldKey)"
          :type="resolvePickerType(field)"
          :value-format="resolveValueFormat(field)"
          :placeholder="resolvePickerPlaceholder(field)"
          style="width: 100%"
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
        <div v-else-if="field.fieldType === 'file'" class="file-field">
          <el-upload
            :auto-upload="true"
            :show-file-list="true"
            :file-list="getFileListForField(field.fieldKey)"
            :http-request="(opts: any) => handleFileUpload(field.fieldKey, opts)"
            :before-upload="(f: File) => beforeFileUpload(field, f)"
            :on-remove="(uploadFile: any) => handleFileRemove(field.fieldKey, uploadFile)"
            :on-preview="(uploadFile: any) => handleFilePreview(uploadFile)"
            multiple
            drag
          >
            <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
            <div class="el-upload__text">
              拖拽文件到此处 或 <em>点击上传</em>
            </div>
            <template #tip>
              <div class="el-upload__tip">
                支持 pdf, docx, xlsx, pptx, png, jpg, jpeg 格式，单文件不超过 10MB
              </div>
            </template>
          </el-upload>
        </div>
        <el-input
          v-else
          :model-value="resolveValue(field.fieldKey)"
          @update:model-value="updateValue(field.fieldKey, $event)"
        />
      </el-form-item>
    </div>

    <el-dialog v-model="imagePreviewVisible" title="图片预览" width="80%" :close-on-click-modal="true">
      <div v-if="imagePreviewUrl" style="display: flex; justify-content: center;">
        <img :src="imagePreviewUrl" style="max-width: 100%; max-height: 70vh;" />
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { ElMessage } from "element-plus";
import { UploadFilled } from "@element-plus/icons-vue";
import type { FormField } from "../../types";
import { deleteAttachment, fetchAttachmentPreviewBlob, uploadAttachment } from "../../api/forms";

const ALLOWED_EXTENSIONS = ["pdf", "docx", "xlsx", "pptx", "png", "jpg", "jpeg"];
const MAX_FILE_SIZE = 10 * 1024 * 1024;

interface Props {
  fields: FormField[];
  modelValue: Record<string, unknown>;
  loadedVersionId?: number | null;
  formVersionId?: number | null;
}

const props = withDefaults(defineProps<Props>(), {
  loadedVersionId: null,
  formVersionId: null
});

const emit = defineEmits<{
  (event: "update:modelValue", value: Record<string, unknown>): void;
}>();

const fileLists = ref<Record<string, Array<{ name: string; url?: string; uid: number }>>>({});

const imagePreviewVisible = ref(false);
const imagePreviewUrl = ref("");

function resolveValue(fieldKey: string) {
  return props.modelValue[fieldKey] as string | number | undefined;
}

function updateValue(fieldKey: string, value: string | number | null | undefined) {
  emit("update:modelValue", {
    ...props.modelValue,
    [fieldKey]: value ?? ""
  });
}

function getAttachmentIds(fieldKey: string): number[] {
  const val = props.modelValue[fieldKey];
  if (!val) return [];
  if (Array.isArray(val)) return val as number[];
  if (typeof val === "string") {
    return val.split(",").map(s => Number(s.trim())).filter(n => !isNaN(n));
  }
  return [];
}

function setAttachmentIds(fieldKey: string, ids: number[]) {
  emit("update:modelValue", {
    ...props.modelValue,
    [fieldKey]: ids
  });
}

function getFileListForField(fieldKey: string) {
  return fileLists.value[fieldKey] || [];
}

function beforeFileUpload(_field: FormField, file: File) {
  const ext = file.name.split(".").pop()?.toLowerCase() || "";
  if (!ALLOWED_EXTENSIONS.includes(ext)) {
    ElMessage.error(`不支持的文件格式: ${ext}`);
    return false;
  }
  if (file.size > MAX_FILE_SIZE) {
    ElMessage.error("文件大小不能超过 10MB");
    return false;
  }
  return true;
}

async function handleFileUpload(fieldKey: string, opts: { file: File; onSuccess: (res: unknown) => void; onError: (err: Error) => void }) {
  const versionId = props.formVersionId ?? props.loadedVersionId;
  if (!versionId) {
    opts.onError(new Error("未加载表单版本"));
    return;
  }
  try {
    const attachment = await uploadAttachment(versionId, fieldKey, opts.file);
    const currentIds = getAttachmentIds(fieldKey);
    setAttachmentIds(fieldKey, [...currentIds, attachment.id]);
    if (!fileLists.value[fieldKey]) {
      fileLists.value[fieldKey] = [];
    }
    fileLists.value[fieldKey].push({
      name: attachment.originalName,
      uid: attachment.id
    });
    opts.onSuccess(attachment);
  } catch (e) {
    console.error(e);
    opts.onError(e as Error);
    ElMessage.error("文件上传失败");
  }
}

async function handleFileRemove(fieldKey: string, uploadFile: { uid: number }) {
  const attachmentId = uploadFile.uid;
  try {
    await deleteAttachment(attachmentId);
  } catch (e) {
    console.error(e);
  }
  const currentIds = getAttachmentIds(fieldKey);
  setAttachmentIds(fieldKey, currentIds.filter(id => id !== attachmentId));
  if (fileLists.value[fieldKey]) {
    fileLists.value[fieldKey] = fileLists.value[fieldKey].filter(f => f.uid !== attachmentId);
  }
}

async function handleFilePreview(uploadFile: { uid: number; name: string; url?: string }) {
  try {
    imagePreviewUrl.value = await fetchAttachmentPreviewBlob(uploadFile.uid);
    imagePreviewVisible.value = true;
  } catch (e) {
    console.error(e);
    ElMessage.error('预览图片失败');
  }
}

function isTemporalField(field: FormField) {
  if (field.fieldType === 'date' || field.fieldType === 'datetime') {
    return true;
  }
  const indicator = `${field.fieldKey ?? ''} ${field.label ?? ''}`.toLowerCase();
  return /日期|时间|date|time/.test(indicator);
}

function resolvePickerType(field: FormField) {
  const indicator = `${field.fieldKey ?? ''} ${field.label ?? ''}`.toLowerCase();
  if (field.fieldType === 'datetime' || /时间|time/.test(indicator)) {
    return 'datetime';
  }
  return 'date';
}

function resolveValueFormat(field: FormField) {
  return resolvePickerType(field) === 'datetime' ? 'YYYY-MM-DD HH:mm:ss' : 'YYYY-MM-DD';
}

function resolvePickerPlaceholder(field: FormField) {
  return resolvePickerType(field) === 'datetime' ? '请选择时间' : '请选择日期';
}

function parseOptions(optionsJson?: string) {
  if (!optionsJson) {
    return [] as Array<{ label: string; value: string | number }>;
  }
  try {
    const parsed = JSON.parse(optionsJson) as Array<string | number | { label?: string; value?: string | number }>;
    return parsed
      .map((option) => {
        if (typeof option === 'string' || typeof option === 'number') {
          return {
            label: String(option),
            value: option
          };
        }
        if (option && typeof option === 'object') {
          const value = option.value ?? option.label;
          if (value === undefined || value === null) {
            return null;
          }
          return {
            label: String(option.label ?? value),
            value
          };
        }
        return null;
      })
      .filter((option): option is { label: string; value: string | number } => option !== null);
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

.file-field {
  width: 100%;
}
</style>
