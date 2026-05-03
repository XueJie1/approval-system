<template>
  <router-view />
  <AiFloatingAssistant v-if="!route.meta.guestOnly" />
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router';
import AiFloatingAssistant from './components/ai/AiFloatingAssistant.vue';

const route = useRoute();
</script>
