import type { AdminOpenAiSettingsUpdatePayload } from "../types";

export interface OpenAiSettingsFormState {
  baseUrl: string;
  apiKey: string;
  model: string;
  clearApiKey: boolean;
}

export function buildOpenAiSettingsUpdatePayload(form: OpenAiSettingsFormState): AdminOpenAiSettingsUpdatePayload {
  const normalizedBaseUrl = normalizeBaseUrl(form.baseUrl);
  const normalizedApiKey = normalizeOptionalText(form.apiKey);

  const payload: AdminOpenAiSettingsUpdatePayload = {
    baseUrl: normalizedBaseUrl,
    model: normalizeModel(form.model)
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

export function normalizeModel(value: string): string | null {
  return normalizeOptionalText(value);
}

function normalizeOptionalText(value: string): string | null {
  const text = value.trim();
  return text.length > 0 ? text : null;
}
