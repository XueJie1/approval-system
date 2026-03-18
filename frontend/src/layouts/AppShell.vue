<template>
  <div class="shell">
    <aside class="nav page-card">
      <div class="brand">
        <h1>Flowable 审批台</h1>
        <p>Smart Approval Console</p>
      </div>
      <el-menu :default-active="activePath" router class="menu">
        <el-menu-item index="/start">发起申请</el-menu-item>
        <el-menu-item index="/tasks">我的待办</el-menu-item>
        <el-menu-item index="/requests">我的申请</el-menu-item>
        <el-menu-item index="/profile">个人中心</el-menu-item>
      </el-menu>
    </aside>

    <main class="content">
      <header class="topbar page-card">
        <div>
          <div class="hello">{{ greeting }}</div>
          <div class="meta">{{ auth.currentUser?.username }} | UID {{ auth.currentUser?.userId }}</div>
        </div>
        <div class="actions">
          <el-tag v-for="role in auth.currentUser?.roles || []" :key="role" type="success" effect="plain">{{ role }}</el-tag>
          <el-button type="danger" plain @click="logout">退出登录</el-button>
        </div>
      </header>

      <section class="view page-card">
        <router-view />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "../stores/auth";

const auth = useAuthStore();
const route = useRoute();
const router = useRouter();

const activePath = computed(() => route.path);
const greeting = computed(() => {
  const hour = new Date().getHours();
  if (hour < 12) {
    return "上午好";
  }
  if (hour < 18) {
    return "下午好";
  }
  return "晚上好";
});

function logout() {
  auth.clearAuth();
  router.replace("/login");
}
</script>

<style scoped>
.shell {
  min-height: 100vh;
  padding: 18px;
  display: grid;
  grid-template-columns: 230px 1fr;
  gap: 18px;
}

.nav {
  padding: 18px;
  background: linear-gradient(170deg, #ffffff 0%, #ecf8f6 100%);
}

.brand h1 {
  margin: 0;
  font-size: 20px;
}

.brand p {
  margin: 6px 0 18px;
  color: #4b5563;
  font-size: 12px;
  letter-spacing: 0.3px;
}

.menu {
  border-right: none;
  background: transparent;
}

.content {
  display: grid;
  grid-template-rows: auto 1fr;
  gap: 14px;
}

.topbar {
  padding: 16px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.hello {
  font-size: 18px;
  font-weight: 600;
}

.meta {
  margin-top: 4px;
  color: #64748b;
  font-size: 13px;
}

.actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.view {
  padding: 20px;
  overflow: auto;
}

@media (max-width: 980px) {
  .shell {
    grid-template-columns: 1fr;
  }
}
</style>
