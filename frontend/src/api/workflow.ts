import { http } from "./http";
import type { AiSuggestion, TaskInfo } from "../types";

export async function startRequest(payload: Record<string, unknown>) {
  const { data } = await http.post<{ processInstanceId: string; message: string }>("/workflow/requests", payload);
  return data;
}

export async function fetchTasks(assignee: string, includeCandidate: boolean) {
  const { data } = await http.get<TaskInfo[]>("/workflow/tasks", {
    params: { assignee, includeCandidate }
  });
  return data;
}

export async function claimTask(taskId: string, userId: string) {
  await http.post(`/workflow/tasks/${taskId}/claim`, { userId });
}

export async function completeTask(taskId: string, payload: { userId: string; approvalResult: string; comments: string }) {
  await http.post(`/workflow/tasks/${taskId}/complete`, payload);
}

export async function delegateTask(taskId: string, payload: { userId: string; delegateUserId: string; comment: string }) {
  await http.post(`/workflow/tasks/${taskId}/delegate`, payload);
}

export async function resolveTask(taskId: string, payload: { userId: string; approvalResult: string; comment: string }) {
  await http.post(`/workflow/tasks/${taskId}/resolve`, payload);
}

export async function reassignTask(taskId: string, payload: { userId: string; newAssigneeId: string; comment: string }) {
  await http.post(`/workflow/tasks/${taskId}/reassign`, payload);
}

export async function returnToPrevious(taskId: string, payload: { userId: string; comment: string }) {
  await http.post(`/workflow/tasks/${taskId}/return/previous`, payload);
}

export async function returnToTarget(taskId: string, payload: { userId: string; targetActivityId: string; comment: string }) {
  await http.post(`/workflow/tasks/${taskId}/return/target`, payload);
}

export async function returnToApplicant(taskId: string, payload: { userId: string; comment: string }) {
  await http.post(`/workflow/tasks/${taskId}/return/applicant`, payload);
}

export async function cancelProcess(processInstanceId: string, payload: { userId: string; comment: string }) {
  await http.post(`/workflow/process/${processInstanceId}/cancel`, payload);
}

export async function aiSuggestion(taskId: string) {
  const { data } = await http.get<AiSuggestion>(`/workflow/tasks/${taskId}/ai-suggestion`);
  return data;
}
