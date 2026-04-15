import type { AdminOpenAiSettingsUpdatePayload } from "../types";

export interface OpenAiSettingsFormState {
  baseUrl: string;
  apiKey: string;
  clearApiKey: boolean;
}

export function buildOpenAiSettingsUpdatePayload(form: OpenAiSettingsFormState): AdminOpenAiSettingsUpdatePayload {
  const normalizedBaseUrl = normalizeBaseUrl(form.baseUrl);
  const normalizedApiKey = normalizeOptionalText(form.apiKey);

  const payload: AdminOpenAiSettingsUpdatePayload = {
    baseUrl: normalizedBaseUrl
  };

  if (form.clearApiKey) {
    payload.clearApiKey = true;
    return payload;
  }

  if (normalizedApiKey) {
    payload.apiKey = normalizedApiKey;
  }

  return payload;
}

export function normalizeBaseUrl(value: string): string | null {
  const normalized = normalizeOptionalText(value);
  if (!normalized) {
    return null;
  }
  return normalized.replace(/\/+$/, "");
}

function normalizeOptionalText(value: string): string | null {
  const text = value.trim();
  return text.length > 0 ? text : null;
}
