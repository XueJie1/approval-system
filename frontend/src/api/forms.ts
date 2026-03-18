import type { FormField, FormVersion } from "../types";
import { http } from "./http";

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
