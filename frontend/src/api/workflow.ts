import { http } from "./http";
import type {
  AiSuggestion,
  DraftSaveResult,
  SaveDraftPayload,
  StartRequestPayload,
  SubmitDraftPayload,
  TaskInfo,
  WorkflowStartResult
} from "../types";

const AI_REQUEST_TIMEOUT = 60000;

export async function saveDraft(payload: SaveDraftPayload) {
  const { data } = await http.post<DraftSaveResult>("/workflow/drafts", payload);
  return data;
}

export async function submitDraft(businessKey: string, payload: SubmitDraftPayload) {
  const { data } = await http.post<WorkflowStartResult>(`/workflow/drafts/${encodeURIComponent(businessKey)}/submit`, payload);
  return data;
}

export async function startRequest(payload: StartRequestPayload) {
  const { data } = await http.post<WorkflowStartResult>("/workflow/requests", payload);
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

export async function fetchReturnableNodes(taskId: string): Promise<{ activityId: string; activityName: string }[]> {
  const { data } = await http.get(`/workflow/tasks/${taskId}/returnable-nodes`);
  return data;
}

export async function cancelProcess(processInstanceId: string, payload: { userId: string; comment: string }) {
  await http.post(`/workflow/process/${processInstanceId}/cancel`, payload);
}

export async function suspendProcess(processInstanceId: string, payload: { comment: string }) {
  await http.post(`/workflow/process/${processInstanceId}/suspend`, payload);
}

export async function activateProcess(processInstanceId: string, payload: { comment: string }) {
  await http.post(`/workflow/process/${processInstanceId}/activate`, payload);
}

export async function aiSuggestion(taskId: string) {
  const { data } = await http.get<AiSuggestion>(`/workflow/tasks/${taskId}/ai-suggestion`, {
    timeout: AI_REQUEST_TIMEOUT
  });
  return data;
}

export async function aiSuggestionFollowUp(taskId: string, recordId: number, question: string) {
  const { data } = await http.post<AiSuggestion>(
    `/workflow/tasks/${taskId}/ai-suggestion/${recordId}/follow-up`,
    { question },
    { timeout: AI_REQUEST_TIMEOUT }
  );
  return data;
}

export async function adoptAiSuggestion(taskId: string, recordId: number) {
  const { data } = await http.post<AiSuggestion>(
    `/workflow/tasks/${taskId}/ai-suggestion/${recordId}/adopt`,
    {},
    { timeout: AI_REQUEST_TIMEOUT }
  );
  return data;
}

export async function aiSuggestionHistory(taskId: string) {
  const { data } = await http.get<AiSuggestion[]>(`/workflow/tasks/${taskId}/ai-suggestion/history`, {
    timeout: AI_REQUEST_TIMEOUT
  });
  return data;
}
