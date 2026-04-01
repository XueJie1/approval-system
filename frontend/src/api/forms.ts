import type { FormDefinitionSummary, FormField, FormVersion, FormVersionSummary } from "../types";
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
