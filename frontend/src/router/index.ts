import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "../stores/auth";

const BUSINESS_ADMIN_ROLES = ["ADMIN", "SYS_ADMIN"] as const;
const FORM_DESIGNER_ROLES = ["DESIGNER", "ADMIN", "SYS_ADMIN"] as const;
const TECH_ADMIN_ROLES = ["SYS_ADMIN"] as const;

type AppRole = (typeof BUSINESS_ADMIN_ROLES)[number];

function hasAnyRole(userRoles: string[], requiredRoles: readonly string[]) {
  return requiredRoles.some((role) => userRoles.includes(role));
}

function isBusinessAdmin(userRoles: string[]) {
  return hasAnyRole(userRoles, BUSINESS_ADMIN_ROLES);
}

function isFormDesigner(userRoles: string[]) {
  return hasAnyRole(userRoles, FORM_DESIGNER_ROLES);
}

function isTechAdmin(userRoles: string[]) {
  return hasAnyRole(userRoles, TECH_ADMIN_ROLES);
}

function determineAdminDefaultPath(userRoles: string[]) {
  if (isTechAdmin(userRoles)) {
    return "/admin/home";
  }
  if (isFormDesigner(userRoles)) {
    return "/admin/forms";
  }
  if (isBusinessAdmin(userRoles)) {
    return "/admin/request-templates";
  }
  return "/user/start";
}

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
      { path: "", redirect: "/user/home" },
      { path: "home", name: "user-home", component: () => import("../views/UserHomeView.vue") },
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
    meta: { requiresAuth: true, roles: [...FORM_DESIGNER_ROLES] },
    children: [
      { path: "", name: "admin-root", component: () => import("../views/AdminWelcomeView.vue"), meta: { requiresAuth: true, roles: [...FORM_DESIGNER_ROLES] } },
      { path: "home", name: "admin-home", component: () => import("../views/AdminWelcomeView.vue"), meta: { requiresAuth: true, roles: [...FORM_DESIGNER_ROLES] } },
      { path: "forms", name: "admin-forms", component: () => import("../views/AdminFormsView.vue"), meta: { requiresAuth: true, roles: [...FORM_DESIGNER_ROLES] } },
      { path: "users", name: "admin-users", component: () => import("../views/AdminUsersView.vue"), meta: { requiresAuth: true, roles: [...TECH_ADMIN_ROLES] } },
      { path: "roles", name: "admin-roles", component: () => import("../views/AdminRolesView.vue"), meta: { requiresAuth: true, roles: [...TECH_ADMIN_ROLES] } },
      { path: "request-templates", name: "admin-request-templates", component: () => import("../views/AdminRequestTemplatesView.vue"), meta: { requiresAuth: true, roles: [...BUSINESS_ADMIN_ROLES] } },
      { path: "departments", name: "admin-departments", component: () => import("../views/AdminDepartmentsView.vue"), meta: { requiresAuth: true, roles: [...TECH_ADMIN_ROLES] } },
      { path: "positions", name: "admin-positions", component: () => import("../views/AdminPositionsView.vue"), meta: { requiresAuth: true, roles: [...TECH_ADMIN_ROLES] } },
      { path: "workflows", name: "admin-workflows", component: () => import("../views/AdminWorkflowsView.vue"), meta: { requiresAuth: true, roles: [...TECH_ADMIN_ROLES] } },
      { path: "workflows/:definitionId/versions/:versionId", name: "admin-workflow-version-detail", component: () => import("../views/AdminWorkflowVersionDetailView.vue"), meta: { requiresAuth: true, roles: [...TECH_ADMIN_ROLES] } },
      { path: "settings", name: "admin-settings", component: () => import("../views/AdminSettingsView.vue"), meta: { requiresAuth: true, roles: [...TECH_ADMIN_ROLES] } }
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

  const requiredRoles = (to.meta.roles as AppRole[] | undefined) ?? [];
  if (requiredRoles.length > 0) {
    const userRoles = auth.currentUser?.roles ?? [];
    if (!hasAnyRole(userRoles, requiredRoles)) {
      if (isBusinessAdmin(userRoles) && to.path.startsWith("/admin")) {
        return determineAdminDefaultPath(userRoles);
      }
      return "/user/start";
    }
  }

  if (to.path === "/admin") {
    return determineAdminDefaultPath(auth.currentUser?.roles ?? []);
  }

  return true;
});

function determineRedirectPath(auth: ReturnType<typeof useAuthStore>): string {
  const userRoles = auth.currentUser?.roles ?? [];
  if (isBusinessAdmin(userRoles) || isFormDesigner(userRoles)) {
    return determineAdminDefaultPath(userRoles);
  }
  return "/user";
}
