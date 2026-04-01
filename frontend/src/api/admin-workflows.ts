import type {
  ActionResult,
  PageResult,
  WorkflowDefinitionPayload,
  WorkflowDefinitionSummary,
  WorkflowDefinitionUpdatePayload,
  WorkflowNodeConfigItem,
  WorkflowPublishLogItem,
  WorkflowVersionCreatePayload,
  WorkflowVersionSummary,
  WorkflowVersionUpdatePayload,
  WorkflowVersionUsage
} from "../types";
import { http } from "./http";

export async function listWorkflowDefinitions(params: {
  keyword?: string;
  category?: string;
  status?: string;
  page?: number;
  size?: number;
}) {
  const { data } = await http.get<PageResult<WorkflowDefinitionSummary>>("/admin/workflow-definitions", { params });
  return normalizePageResult(data);
}

export async function createWorkflowDefinition(payload: WorkflowDefinitionPayload) {
  const { data } = await http.post<WorkflowDefinitionSummary>("/admin/workflow-definitions", payload);
  return data;
}

export async function getWorkflowDefinition(definitionId: number) {
  const { data } = await http.get<WorkflowDefinitionSummary>(`/admin/workflow-definitions/${definitionId}`);
  return data;
}

export async function updateWorkflowDefinition(definitionId: number, payload: WorkflowDefinitionUpdatePayload) {
  const { data } = await http.put<WorkflowDefinitionSummary>(`/admin/workflow-definitions/${definitionId}`, payload);
  return data;
}

export async function inactivateWorkflowDefinition(definitionId: number, comment?: string) {
  const { data } = await http.post<ActionResult>(`/admin/workflow-definitions/${definitionId}/inactivate`, { comment });
  return data;
}

export async function archiveWorkflowDefinition(definitionId: number, comment?: string) {
  const { data } = await http.post<ActionResult>(`/admin/workflow-definitions/${definitionId}/archive`, { comment });
  return data;
}

export async function listWorkflowVersions(definitionId: number) {
  const { data } = await http.get<WorkflowVersionSummary[]>(`/admin/workflow-definitions/${definitionId}/versions`);
  return data;
}

export async function createWorkflowVersion(definitionId: number, payload: WorkflowVersionCreatePayload) {
  const { data } = await http.post<WorkflowVersionSummary>(`/admin/workflow-definitions/${definitionId}/versions`, payload);
  return data;
}

export async function getWorkflowVersion(versionId: number) {
  const { data } = await http.get<WorkflowVersionSummary>(`/admin/workflow-definition-versions/${versionId}`);
  return data;
}

export async function updateWorkflowVersion(versionId: number, payload: WorkflowVersionUpdatePayload) {
  const { data } = await http.put<WorkflowVersionSummary>(`/admin/workflow-definition-versions/${versionId}`, payload);
  return data;
}

export async function deleteWorkflowVersion(versionId: number) {
  const { data } = await http.delete<ActionResult>(`/admin/workflow-definition-versions/${versionId}`);
  return data;
}

export async function listWorkflowNodeConfigs(versionId: number) {
  const { data } = await http.get<WorkflowNodeConfigItem[]>(`/admin/workflow-definition-versions/${versionId}/nodes`);
  return data;
}

export async function saveWorkflowNodeConfigs(versionId: number, nodes: WorkflowNodeConfigItem[]) {
  const { data } = await http.put<WorkflowNodeConfigItem[]>(`/admin/workflow-definition-versions/${versionId}/nodes`, { nodes });
  return data;
}

export async function publishWorkflowVersion(versionId: number, comment?: string) {
  const { data } = await http.post<WorkflowVersionSummary>(`/admin/workflow-definition-versions/${versionId}/publish`, { comment });
  return data;
}

export async function inactivateWorkflowVersion(versionId: number, comment?: string) {
  const { data } = await http.post<ActionResult>(`/admin/workflow-definition-versions/${versionId}/inactivate`, { comment });
  return data;
}

export async function activateWorkflowVersion(versionId: number, comment?: string) {
  const { data } = await http.post<WorkflowVersionSummary>(`/admin/workflow-definition-versions/${versionId}/activate`, { comment });
  return data;
}

export async function retireWorkflowVersion(versionId: number, comment?: string) {
  const { data } = await http.post<ActionResult>(`/admin/workflow-definition-versions/${versionId}/retire`, { comment });
  return data;
}

export async function listWorkflowPublishLogs(versionId: number) {
  const { data } = await http.get<WorkflowPublishLogItem[]>(`/admin/workflow-definition-versions/${versionId}/publish-logs`);
  return data;
}

export async function getWorkflowVersionUsage(versionId: number) {
  const { data } = await http.get<WorkflowVersionUsage>(`/admin/workflow-definition-versions/${versionId}/usage`);
  return data;
}

function normalizePageResult<T>(data: PageResult<T>) {
  return {
    ...data,
    total: data.total ?? data.totalElements ?? 0
  };
}
