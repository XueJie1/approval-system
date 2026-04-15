import type { FormAiParseResult } from "../types";
import { http } from "./http";

export async function parseFormCommand(payload: {
  command: string;
  requestTemplateKey?: string;
  formKey?: string;
  formVersionId?: number;
}) {
  const { data } = await http.post<FormAiParseResult>("/ai/form-commands/parse", payload);
  return data;
}

export async function parseAndStartByFormCommand(payload: {
  command: string;
  applicantId?: number;
  businessKey?: string;
  title?: string;
  processKey?: string;
  requestTemplateKey?: string;
  formKey?: string;
  formVersionId?: number;
  requireAllRequiredFields?: boolean;
  useDetectedTemplateForRouting?: boolean;
}) {
  const { data } = await http.post<{
    processInstanceId: string;
    businessKey: string;
    title: string;
    applicantId: number;
    formVersionId: number;
    templateKey?: string | null;
    missingRequiredFields: string[];
    confidence: number;
    startedAt: string;
  }>("/ai/form-commands/parse-and-start", payload);
  return data;
}
