import type { InjectionKey, Ref } from 'vue';

export interface ApprovalAiContext {
  mode: 'approval';
  taskId: Ref<string | null>;
  onAdopt: (comment: string, decision: string) => void;
}

export interface FormCommandAiContext {
  mode: 'form-command';
  templateKey: Ref<string>;
  formKey: Ref<string>;
  formVersionId: Ref<number | null>;
  onFillFormData: (data: Record<string, unknown>) => void;
  onTemplateChange: (templateKey: string) => void;
  onStartProcess: () => void;
}

export type AiAssistantContext = ApprovalAiContext | FormCommandAiContext | null;

export const AI_ASSISTANT_KEY: InjectionKey<AiAssistantContext> = Symbol('aiAssistant');
