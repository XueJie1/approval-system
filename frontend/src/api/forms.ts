import type { FormAttachment, FormDefinitionSummary, FormField, FormVersion, FormVersionSummary } from "../types";
import { http } from "./http";

export async function listFormDefinitions() {
  const { data } = await http.get<FormDefinitionSummary[]>("/forms/definitions");
  return data;
}

export async function listFormVersions(formId: number) {
  const { data } = await http.get<FormVersionSummary[]>("/forms/versions", {
    params: { formId }
  });
  return data;
}

export async function latestFormVersion(formKey: string) {
  const { data } = await http.get<FormVersion>("/forms/versions/latest", {
    params: { formKey }
  });
  return data;
}

export async function fetchFormFields(formVersionId: number) {
  const { data } = await http.get<FormField[]>("/forms/fields", {
    params: { formVersionId }
  });
  return data;
}

export async function validateForm(payload: {
  userId: number;
  formVersionId: number;
  data: Record<string, unknown>;
}) {
  await http.post("/forms/validate", payload);
}

export async function uploadAttachment(formVersionId: number, fieldKey: string, file: File) {
  const formData = new FormData();
  formData.append("formVersionId", String(formVersionId));
  formData.append("fieldKey", fieldKey);
  formData.append("file", file);
  const { data } = await http.post<FormAttachment>("/forms/attachments/upload", formData, {
    headers: { "Content-Type": "multipart/form-data" }
  });
  return data;
}

export function attachmentPreviewUrl(attachmentId: number) {
  return `/api/forms/attachments/${attachmentId}/preview`;
}

export async function fetchAttachmentBlob(attachmentId: number): Promise<{ blob: Blob; fileName: string; contentType: string }> {
  const response = await http.get(`/forms/attachments/${attachmentId}`, {
    responseType: 'blob'
  });
  const contentDisposition = (response.headers as Record<string, string>)?.['content-disposition'] ?? '';
  const fileNameMatch = contentDisposition.match(/filename="?(.+?)"?$/);
  const fileName = fileNameMatch?.[1] ?? 'download';
  const contentType = (response.headers as Record<string, string>)?.['content-type'] ?? 'application/octet-stream';
  return { blob: response.data as Blob, fileName, contentType };
}

export async function fetchAttachmentPreviewBlob(attachmentId: number): Promise<string> {
  const { blob } = await fetchAttachmentBlob(attachmentId);
  return URL.createObjectURL(blob);
}

export function downloadAttachmentBlob(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

export async function listInstanceAttachments(formInstanceId: number) {
  const { data } = await http.get<FormAttachment[]>(`/forms/instances/${formInstanceId}/attachments`);
  return data;
}

export async function getFormInstanceData(formInstanceId: number) {
  const { data } = await http.get<FormInstanceData>(`/forms/instances/${formInstanceId}/data`);
  return data;
}

export interface FormInstanceData {
  formVersionId: number;
  fields: FormField[];
  data: Record<string, unknown>;
  attachments: FormAttachment[];
}

export async function deleteAttachment(attachmentId: number) {
  await http.delete(`/forms/attachments/${attachmentId}`);
}
