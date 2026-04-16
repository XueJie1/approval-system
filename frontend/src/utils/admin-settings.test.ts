import { describe, expect, it } from "vitest";
import { buildOpenAiSettingsUpdatePayload, normalizeBaseUrl } from "./admin-settings";

describe("admin-settings utils", () => {
  it("buildOpenAiSettingsUpdatePayload omits blank apiKey", () => {
    const payload = buildOpenAiSettingsUpdatePayload({
      baseUrl: " https://api.openai.com/v1/ ",
      apiKey: "   ",
      model: " gpt-5.4-mini ",
      clearApiKey: false
    });

    expect(payload).toEqual({
      baseUrl: "https://api.openai.com/v1",
      model: "gpt-5.4-mini"
    });
  });

  it("buildOpenAiSettingsUpdatePayload prioritizes clearApiKey", () => {
    const payload = buildOpenAiSettingsUpdatePayload({
      baseUrl: "https://proxy.example.com/v1",
      apiKey: "sk-test-1",
      model: "gpt-5.4",
      clearApiKey: true
    });

    expect(payload).toEqual({
      baseUrl: "https://proxy.example.com/v1",
      model: "gpt-5.4",
      clearApiKey: true
    });
  });

  it("normalizeBaseUrl returns null for blank input", () => {
    expect(normalizeBaseUrl("  ")).toBeNull();
  });
});
