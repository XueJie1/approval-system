import type {
  AdminOpenAiModelListPayload,
  AdminOpenAiModelListResult,
  AdminOpenAiSettings,
  AdminOpenAiSettingsUpdatePayload
} from "../types";
import { http } from "./http";

export async function getAdminOpenAiSettings() {
  const { data } = await http.get<AdminOpenAiSettings>("/admin/settings/ai/openai");
  return data;
}

export async function updateAdminOpenAiSettings(payload: AdminOpenAiSettingsUpdatePayload) {
  const { data } = await http.put<AdminOpenAiSettings>("/admin/settings/ai/openai", payload);
  return data;
}

export async function listAdminOpenAiModels(payload: AdminOpenAiModelListPayload) {
  const { data } = await http.post<AdminOpenAiModelListResult>("/admin/settings/ai/openai/models", payload);
  return data;
}
