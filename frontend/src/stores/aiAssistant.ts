import { shallowRef } from 'vue';
import { defineStore } from 'pinia';
import type { AiAssistantContext } from '../components/ai/types';

export const useAiAssistantStore = defineStore('aiAssistant', () => {
  const current = shallowRef<AiAssistantContext>(null);

  function set(ctx: AiAssistantContext) {
    current.value = ctx;
  }

  function clear() {
    current.value = null;
  }

  return { current, set, clear };
});
