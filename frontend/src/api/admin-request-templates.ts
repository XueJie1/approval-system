import type { ActionResult, AdminRoleOption, RequestTemplateSummary, RequestTemplateUpsertPayload } from "../types";
import { http } from "./http";

export async function listAdminRequestTemplates() {
  const { data } = await http.get<RequestTemplateSummary[]>('/admin/request-templates');
  return data;
}

export async function createRequestTemplate(payload: RequestTemplateUpsertPayload) {
  const { data } = await http.post<RequestTemplateSummary>('/admin/request-templates', payload);
  return data;
}

export async function updateRequestTemplate(templateId: number, payload: RequestTemplateUpsertPayload) {
  const { data } = await http.put<RequestTemplateSummary>(`/admin/request-templates/${templateId}`, payload);
  return data;
}

export async function listRequestTemplateLaunchRoleOptions() {
  const { data } = await http.get<AdminRoleOption[]>('/admin/request-templates/launch-role-options');
  return data;
}

export type { ActionResult };
