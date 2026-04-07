import type { RequestTemplateApprovalPreviewStep, RequestTemplateSummary } from "../types";
import { http } from "./http";

export async function listRequestTemplates() {
  const { data } = await http.get<RequestTemplateSummary[]>("/request-templates");
  return data;
}

export async function previewRequestTemplateApproval(templateKey: string, payload: { applicantId?: number | null; variables: Record<string, unknown> }) {
  const { data } = await http.post<RequestTemplateApprovalPreviewStep[]>(`/request-templates/${encodeURIComponent(templateKey)}/approval-preview`, payload);
  return data;
}
