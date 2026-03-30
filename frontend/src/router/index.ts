import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "../stores/auth";

const routes = [
  { path: "/", redirect: "/login" },
  { path: "/login", name: "login", component: () => import("../views/LoginView.vue"), meta: { guestOnly: true } },
  { path: "/bootstrap", name: "bootstrap", component: () => import("../views/BootstrapView.vue"), meta: { guestOnly: true } },
  
  // 普通用户界面
  {
    path: "/user",
    component: () => import("../layouts/UserLayout.vue"),
    meta: { requiresAuth: true },
    children: [
      { path: "", redirect: "/user/start" },
      { path: "start", name: "user-start", component: () => import("../views/StartRequestView.vue") },
      { path: "tasks", name: "user-tasks", component: () => import("../views/MyTasksView.vue") },
      { path: "requests", name: "user-requests", component: () => import("../views/MyRequestsView.vue") },
      { path: "profile", name: "user-profile", component: () => import("../views/ProfileView.vue") }
    ]
  },
  
  // 管理员界面
  {
    path: "/admin",
    component: () => import("../layouts/AdminLayout.vue"),
    meta: { requiresAuth: true, roles: ["ADMIN", "SYS_ADMIN"] },
    children: [
      { path: "", redirect: "/admin/users" },
      { path: "users", name: "admin-users", component: () => import("../views/AdminUsersView.vue") },
      { path: "roles", name: "admin-roles", component: () => import("../views/AdminRolesView.vue") },
      { path: "departments", name: "admin-departments", component: () => import("../views/AdminDepartmentsView.vue") },
      { path: "positions", name: "admin-positions", component: () => import("../views/AdminPositionsView.vue") },
      { path: "workflows", name: "admin-workflows", component: () => import("../views/AdminWorkflowsView.vue") },
      { path: "settings", name: "admin-settings", component: () => import("../views/AdminSettingsView.vue") }
    ]
  }
];

export const router = createRouter({
  history: createWebHistory(),
  routes
});

router.beforeEach(async (to) => {
  const auth = useAuthStore();
  const isAuthed = Boolean(auth.accessToken);

  if (to.meta.requiresAuth && !isAuthed) {
    return "/login";
  }
  if (to.meta.guestOnly && isAuthed) {
    return determineRedirectPath(auth);
  }

  if (to.meta.requiresAuth && !auth.profile) {
    try {
      await auth.refreshProfile();
    } catch {
      auth.clearAuth();
      return "/login";
    }
  }

  const requiredRoles = (to.meta.roles as string[] | undefined) ?? [];
  if (requiredRoles.length > 0) {
    const userRoles = auth.currentUser?.roles ?? [];
    const hasRole = requiredRoles.some((role) => userRoles.includes(role));
    if (!hasRole) {
      return "/user/start";
    }
  }

  return true;
});

function determineRedirectPath(auth: ReturnType<typeof useAuthStore>): string {
  const isAdmin = (auth.currentUser?.roles ?? []).some((role) => role === "ADMIN" || role === "SYS_ADMIN");
  return isAdmin ? "/admin" : "/user";
}
