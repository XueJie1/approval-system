import { computed, ref } from "vue";
import { defineStore } from "pinia";
import type { UserProfile } from "../types";
import { me } from "../api/auth";

interface StoredUser {
  userId: number;
  username: string;
  roles: string[];
}

const TOKEN_KEY = "approval.accessToken";
const USER_KEY = "approval.user";

function loadStoredUser(): StoredUser | null {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) {
    return null;
  }
  try {
    return JSON.parse(raw) as StoredUser;
  } catch {
    return null;
  }
}

export const useAuthStore = defineStore("auth", () => {
  const accessToken = ref<string | null>(localStorage.getItem(TOKEN_KEY));
  const currentUser = ref<StoredUser | null>(loadStoredUser());
  const profile = ref<UserProfile | null>(null);

  const isAuthenticated = computed(() => Boolean(accessToken.value));

  function setAuth(token: string, user: StoredUser) {
    accessToken.value = token;
    currentUser.value = user;
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  }

  function clearAuth() {
    accessToken.value = null;
    currentUser.value = null;
    profile.value = null;
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
  }

  async function refreshProfile() {
    profile.value = await me();
    currentUser.value = {
      userId: profile.value.userId,
      username: profile.value.username,
      roles: profile.value.roles
    };
    localStorage.setItem(USER_KEY, JSON.stringify(currentUser.value));
  }

  return {
    accessToken,
    currentUser,
    profile,
    isAuthenticated,
    setAuth,
    clearAuth,
    refreshProfile
  };
});
