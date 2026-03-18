import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "../stores/auth";

const routes = [
  { path: "/login", name: "login", component: () => import("../views/LoginView.vue"), meta: { guestOnly: true } },
  { path: "/bootstrap", name: "bootstrap", component: () => import("../views/BootstrapView.vue"), meta: { guestOnly: true } },
  {
    path: "/",
    component: () => import("../layouts/AppShell.vue"),
    meta: { requiresAuth: true },
    children: [
      { path: "", redirect: "/start" },
      { path: "start", name: "start", component: () => import("../views/StartRequestView.vue") },
      { path: "tasks", name: "tasks", component: () => import("../views/MyTasksView.vue") },
      { path: "requests", name: "requests", component: () => import("../views/MyRequestsView.vue") },
      { path: "profile", name: "profile", component: () => import("../views/ProfileView.vue") }
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
    return "/start";
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
      return "/start";
    }
  }

  return true;
});
