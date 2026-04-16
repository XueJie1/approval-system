import { http } from "./http";
import type { ActionResult, LoginResult, TwoFactorSetup, UserProfile } from "../types";

export async function fetchBootstrapStatus() {
  const { data } = await http.get<{ isBootstrapMode: boolean }>("/auth/bootstrap-status");
  return data;
}

export async function bootstrapAdmin(payload: { username: string; password: string }) {
  const { data } = await http.post<LoginResult>("/auth/bootstrap", payload);
  return data;
}

export async function login(payload: { username: string; password: string }) {
  const { data } = await http.post<LoginResult>("/auth/login", payload);
  return data;
}

export async function verify2fa(payload: { challengeToken: string; code: string }) {
  const { data } = await http.post<LoginResult>("/auth/login/2fa", payload);
  return data;
}

export async function me() {
  const { data } = await http.get<UserProfile>("/auth/me");
  return data;
}

export async function setup2fa() {
  const { data } = await http.post<TwoFactorSetup>("/auth/2fa/setup");
  return data;
}

export async function enable2fa(payload: { code: string }) {
  const { data } = await http.post<ActionResult>("/auth/2fa/enable", payload);
  return data;
}

export async function disable2fa(payload: { code: string }) {
  const { data } = await http.post<ActionResult>("/auth/2fa/disable", payload);
  return data;
}

export async function generateRecoveryCodes() {
  const { data } = await http.post<TwoFactorSetup>("/auth/2fa/recovery/generate");
  return data;
}

export async function validateRecoveryCode(payload: { code: string }) {
  const { data } = await http.post<ActionResult>("/auth/2fa/recovery/validate", payload);
  return data;
}

export async function changePassword(payload: { currentPassword: string; newPassword: string }) {
  const { data } = await http.post<ActionResult>("/auth/password/change", payload);
  return data;
}
