<template>
  <el-card shadow="never" class="panel">
    <template #header>修改密码</template>

    <el-alert
      title="仅普通用户可在此修改自己的登录密码。"
      type="info"
      show-icon
      :closable="false"
      class="hint"
    />

    <el-form ref="formRef" :model="form" label-position="top">
      <el-form-item label="当前密码">
        <el-input
          v-model="form.currentPassword"
          type="password"
          show-password
          autocomplete="current-password"
          placeholder="请输入当前密码"
        />
      </el-form-item>

      <el-form-item label="新密码">
        <el-input
          v-model="form.newPassword"
          type="password"
          show-password
          autocomplete="new-password"
          placeholder="请输入新密码（8-128 位）"
        />
      </el-form-item>

      <el-form-item label="确认新密码">
        <el-input
          v-model="form.confirmPassword"
          type="password"
          show-password
          autocomplete="new-password"
          placeholder="请再次输入新密码"
          @keyup.enter="submit"
        />
      </el-form-item>
    </el-form>

    <el-button type="primary" :loading="submitting" @click="submit">保存新密码</el-button>
  </el-card>
</template>

<script setup lang="ts">
import { reactive, ref } from "vue";
import type { FormInstance } from "element-plus";
import { ElMessage } from "element-plus";
import { changePassword } from "../../api/auth";

const formRef = ref<FormInstance>();
const submitting = ref(false);
const form = reactive({
  currentPassword: "",
  newPassword: "",
  confirmPassword: ""
});

async function submit() {
  if (!form.currentPassword) {
    ElMessage.warning("请输入当前密码");
    return;
  }
  if (!form.newPassword) {
    ElMessage.warning("请输入新密码");
    return;
  }
  if (form.newPassword.length < 8 || form.newPassword.length > 128) {
    ElMessage.warning("新密码长度必须为 8-128 个字符");
    return;
  }
  if (form.newPassword === form.currentPassword) {
    ElMessage.warning("新密码不能与当前密码相同");
    return;
  }
  if (form.newPassword !== form.confirmPassword) {
    ElMessage.warning("两次输入的新密码不一致");
    return;
  }

  submitting.value = true;
  try {
    await changePassword({
      currentPassword: form.currentPassword,
      newPassword: form.newPassword
    });
    form.currentPassword = "";
    form.newPassword = "";
    form.confirmPassword = "";
    formRef.value?.clearValidate();
    ElMessage.success("密码修改成功");
  } finally {
    submitting.value = false;
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
</style>
