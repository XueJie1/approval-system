<template>
  <div class="shell">
    <aside class="nav page-card">
      <div class="brand">
        <h1>管理员控制台</h1>
        <p>Administration Console</p>
      </div>
      <el-menu :default-active="activePath" router class="menu">
        <el-menu-item index="/admin/home">欢迎页</el-menu-item>
        <el-menu-item index="/admin/users">用户管理</el-menu-item>
        <el-menu-item index="/admin/roles">角色管理</el-menu-item>
        <el-menu-item index="/admin/request-templates">申请模板</el-menu-item>
        <el-menu-item index="/admin/departments">部门管理</el-menu-item>
        <el-menu-item index="/admin/positions">岗位管理</el-menu-item>
        <el-menu-item index="/admin/workflows">流程管理</el-menu-item>
        <el-menu-item index="/admin/settings">系统设置</el-menu-item>
      </el-menu>
    </aside>

    <main class="content">
      <header class="topbar page-card">
        <div>
          <div class="hello">{{ greeting }}</div>
          <div class="meta">{{ auth.currentUser?.username }} | UID {{ auth.currentUser?.userId }}</div>
        </div>
        <div class="actions">
          <el-tag v-for="role in auth.currentUser?.roles || []" :key="role" type="warning" effect="plain">{{ role }}</el-tag>
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
  background: linear-gradient(170deg, #2c3e50 0%, #34495e 100%);
  color: #fff;
}

.nav .page-card {
  box-shadow: none;
  background: transparent;
}

.brand h1 {
  margin: 0;
  font-size: 20px;
  color: #fff;
}

.brand p {
  margin: 6px 0 18px;
  color: #95a5a6;
  font-size: 12px;
  letter-spacing: 0.3px;
}

.menu {
  border-right: none;
  background: transparent;
}

.menu .el-menu-item {
  color: #ecf0f1;
}

.menu .el-menu-item:hover {
  background-color: rgba(255, 255, 255, 0.1);
  color: #fff;
}

.menu .el-menu-item.is-active {
  background-color: rgba(255, 255, 255, 0.15);
  color: #fff;
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
  background: linear-gradient(90deg, #2c3e50 0%, #34495e 100%);
  color: #fff;
}

.topbar .page-card {
  box-shadow: none;
  background: transparent;
}

.hello {
  font-size: 18px;
  font-weight: 600;
  color: #fff;
}

.meta {
  margin-top: 4px;
  color: #bdc3c7;
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
