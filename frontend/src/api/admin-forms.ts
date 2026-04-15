import type {
  AdminFormDefinitionSummary,
  AdminFormVersionSummary,
  FormField,
  FormSampleValidationResult,
  FormVersionImpact
} from "../types";
import { http } from "./http";

export async function listAdminFormDefinitions(params?: { keyword?: string; status?: number }) {
  const { data } = await http.get<AdminFormDefinitionSummary[]>("/admin/forms/definitions", { params });
  return data;
}

export async function createAdminFormDefinition(payload: { formKey: string; formName: string }) {
  const { data } = await http.post<AdminFormDefinitionSummary>("/admin/forms/definitions", payload);
  return data;
}

export async function updateAdminFormDefinition(definitionId: number, payload: { formName?: string; status?: number }) {
  const { data } = await http.put<AdminFormDefinitionSummary>(`/admin/forms/definitions/${definitionId}`, payload);
  return data;
}

export async function listAdminFormVersions(definitionId: number) {
  const { data } = await http.get<AdminFormVersionSummary[]>(`/admin/forms/definitions/${definitionId}/versions`);
  return data;
}

export async function createAdminFormVersion(definitionId: number, payload: { schemaJson?: string; copyFromVersionId?: number | null }) {
  const { data } = await http.post<AdminFormVersionSummary>(`/admin/forms/definitions/${definitionId}/versions`, payload);
  return data;
}

export async function publishAdminFormVersion(versionId: number) {
  const { data } = await http.post<AdminFormVersionSummary>(`/admin/forms/versions/${versionId}/publish`);
  return data;
}

export async function archiveAdminFormVersion(versionId: number) {
  const { data } = await http.post<AdminFormVersionSummary>(`/admin/forms/versions/${versionId}/archive`);
  return data;
}

export async function listAdminFormVersionFields(versionId: number) {
  const { data } = await http.get<FormField[]>(`/admin/forms/versions/${versionId}/fields`);
  return data;
}

export async function saveAdminFormVersionFields(versionId: number, fields: object[]) {
  const { data } = await http.put<FormField[]>(`/admin/forms/versions/${versionId}/fields`, { fields });
  return data;
}

export async function getAdminFormVersionImpacts(versionId: number) {
  const { data } = await http.get<FormVersionImpact>(`/admin/forms/versions/${versionId}/impacts`);
  return data;
}

export async function validateAdminFormVersionSample(versionId: number, sampleData: Record<string, unknown>) {
  const { data } = await http.post<FormSampleValidationResult>(`/admin/forms/versions/${versionId}/validate-sample`, {
    data: sampleData
  });
  return data;
}
