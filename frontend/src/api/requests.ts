import { http } from "./http";
import type { AiSuggestion, BizRequest, ProcessInfo, RequestLog, TaskInfo } from "../types";

export async function listRequests(params: { userId?: number; status?: number }) {
  const { data } = await http.get<BizRequest[]>("/requests", { params });
  return data;
}

export async function listRequestTasks(params: { userId?: number; status?: number }) {
  const { data } = await http.get<TaskInfo[]>("/requests/tasks", { params });
  return data;
}

export async function listRequestLogs(params: { userId?: number; status?: number }) {
  const { data } = await http.get<RequestLog[]>("/requests/logs", { params });
  return data;
}

export async function listProcesses(params: { userId?: number; status?: number }) {
  const { data } = await http.get<ProcessInfo[]>("/requests/processes", { params });
  return data;
}

export async function listAiSuggestions(params: { userId?: number; status?: number }) {
  const { data } = await http.get<AiSuggestion[]>("/requests/ai-suggestions", { params });
  return data;
}
