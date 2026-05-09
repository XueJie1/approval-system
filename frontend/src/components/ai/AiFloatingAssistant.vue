<template>
  <div class="ai-floating-assistant" :class="{ open: panelOpen }">
    <transition name="panel-fade">
      <div v-if="panelOpen" class="ai-panel" :class="{ 'sidebar-open': sidebarVisible }">
        <div class="ai-panel-header">
          <div class="ai-panel-title">
            <el-button
              text
              size="small"
              class="sidebar-toggle-btn"
              @click="sidebarVisible = !sidebarVisible"
            >
              <el-icon><Fold v-if="sidebarVisible" /><ChatDotSquare v-else /></el-icon>
            </el-button>
            <span>AI 助手</span>
          </div>
          <div class="ai-panel-actions">
            <el-button
              v-if="ctx?.mode === 'form-command'"
              :type="activeTab === 'form-command' ? 'primary' : 'default'"
              size="small"
              @click="activeTab = 'form-command'"
            >
              帮我填表
            </el-button>
            <el-button
              v-if="ctx?.mode === 'approval'"
              :type="activeTab === 'approval' ? 'primary' : 'default'"
              size="small"
              @click="activeTab = 'approval'"
            >
              帮我审批
            </el-button>
            <el-button
              :type="activeTab === 'chat' ? 'primary' : 'default'"
              size="small"
              @click="handleNewChat"
            >
              新建聊天
            </el-button>
            <el-button text size="small" @click="panelOpen = false">
              <el-icon><Close /></el-icon>
            </el-button>
          </div>
        </div>

        <!-- Sidebar -->
        <transition name="sidebar-slide">
          <div v-if="sidebarVisible && activeTab === 'chat'" class="ai-sidebar">
            <div class="sidebar-header">
              <span>聊天记录</span>
            </div>
            <div class="sidebar-list">
              <div
                v-for="conv in conversations"
                :key="conv.id"
                class="sidebar-item"
                :class="{ active: conv.id === activeConversationId }"
                @click="switchConversation(conv.id)"
              >
                <div class="sidebar-item-title">{{ conv.title }}</div>
                <div class="sidebar-item-time">{{ conv.createdAt }}</div>
                <el-button
                  text
                  size="small"
                  class="sidebar-item-delete"
                  @click.stop="deleteConversation(conv.id)"
                >
                  <el-icon><Delete /></el-icon>
                </el-button>
              </div>
              <div v-if="conversations.length === 0" class="sidebar-empty">
                暂无聊天记录
              </div>
            </div>
          </div>
        </transition>

        <div class="ai-panel-body">
          <!-- Approval mode -->
          <template v-if="ctx?.mode === 'approval' && activeTab === 'approval'">
            <div v-if="!ctx.taskId.value" class="ai-idle">
              <p>请在任务列表中选中一个待办任务，即可使用 AI 审批建议</p>
            </div>

            <template v-else>
              <div v-if="suggestionState.loading" class="ai-loading">
                <el-icon class="is-loading" :size="24"><Loading /></el-icon>
                <span>正在分析申请内容...</span>
              </div>

              <div v-else-if="suggestionState.suggestion" class="ai-suggestion-content">
                <div class="ai-decision" :class="{ approve: suggestionState.suggestion.decision === 'APPROVE' }">
                  <el-icon v-if="suggestionState.suggestion.decision === 'APPROVE'"><CircleCheck /></el-icon>
                  <el-icon v-else><CircleClose /></el-icon>
                  <span>{{ suggestionState.suggestion.decision === 'APPROVE' ? '建议通过' : '建议拒绝' }}</span>
                </div>

                <p class="ai-recommendation">{{ suggestionState.suggestion.recommendation || suggestionState.suggestion.summary }}</p>

                <div v-if="suggestionState.suggestion.riskWarnings?.length" class="ai-info-block warnings">
                  <div class="block-label">风险提示</div>
                  <ul>
                    <li v-for="(w, i) in suggestionState.suggestion.riskWarnings" :key="i">{{ w }}</li>
                  </ul>
                </div>

                <div v-if="suggestionState.suggestion.anomalies?.length" class="ai-info-block anomalies">
                  <div class="block-label">异常检测</div>
                  <ul>
                    <li v-for="(a, i) in suggestionState.suggestion.anomalies" :key="i">{{ a }}</li>
                  </ul>
                </div>

                <div v-if="suggestionState.suggestion.supplementaryInfo?.length" class="ai-info-block supplementary">
                  <div class="block-label">补充信息</div>
                  <ul>
                    <li v-for="(info, i) in suggestionState.suggestion.supplementaryInfo" :key="i">{{ info }}</li>
                  </ul>
                </div>

                <div v-if="suggestedUpdatesEntries.length" class="ai-info-block updates">
                  <div class="block-label">建议补充字段</div>
                  <div v-for="[key, value] in suggestedUpdatesEntries" :key="key" class="update-row">
                    <code>{{ key }}</code>
                    <span>{{ formatSuggestedValue(value) }}</span>
                  </div>
                </div>

                <div v-if="suggestionState.suggestion.approvalComment" class="ai-comment-block">
                  <div class="block-label">建议审批意见</div>
                  <div class="comment-preview">{{ suggestionState.suggestion.approvalComment }}</div>
                  <el-button size="small" type="primary" @click="handleAdopt">采用意见</el-button>
                </div>

                <div v-if="suggestionState.conversation.length" class="ai-conversation">
                  <div v-for="(turn, i) in suggestionState.conversation" :key="i" class="turn">
                    <div class="turn-q">问：{{ turn.question }}</div>
                    <div class="turn-a">答：{{ turn.answer }}</div>
                  </div>
                </div>

                <div class="ai-follow-up-row">
                  <el-input
                    v-model="suggestionState.question"
                    size="small"
                    placeholder="追问 AI..."
                    @keyup.enter="handleFollowUp"
                  />
                  <el-button size="small" type="primary" :loading="suggestionState.asking" @click="handleFollowUp">
                    追问
                  </el-button>
                </div>
              </div>

              <div v-else class="ai-idle">
                <p>点击下方按钮，AI 将分析当前申请并生成审批建议</p>
              </div>

              <div class="ai-action-bar">
                <el-button
                  type="primary"
                  :loading="suggestionState.loading"
                  :disabled="!ctx.taskId.value"
                  @click="handleGetSuggestion"
                >
                  {{ suggestionState.suggestion ? '重新分析' : '获取 AI 建议' }}
                </el-button>
              </div>
            </template>
          </template>

          <!-- Form Command mode -->
          <template v-if="ctx?.mode === 'form-command' && activeTab === 'form-command'">
            <div class="ai-command-input">
              <el-input
                v-model="commandState.command"
                type="textarea"
                :rows="4"
                placeholder="用自然语言描述你要发起的申请，例如：我要请假，类型年假，开始时间2026-06-01，结束时间2026-06-03，原因陪伴家人"
              />
            </div>

            <el-alert
              v-if="commandState.result"
              :title="commandState.result.title"
              :type="commandState.result.type"
              :closable="false"
              show-icon
              class="ai-command-result"
            >
              <template v-if="commandState.result.details.length">
                <ul class="result-details">
                  <li v-for="d in commandState.result.details" :key="d">{{ d }}</li>
                </ul>
              </template>
            </el-alert>

            <div class="ai-action-bar">
              <el-button :loading="commandState.parsing" :disabled="!commandState.command.trim()" @click="handleParse">
                解析并预填
              </el-button>
              <el-button type="primary" :loading="commandState.starting" :disabled="!commandState.command.trim()" @click="handleParseAndStart">
                解析并发起
              </el-button>
            </div>
          </template>

          <!-- Chat mode -->
          <template v-if="activeTab === 'chat'">
            <div class="ai-chat-messages" ref="chatMessagesEl">
              <div v-for="(msg, i) in chatState.messages" :key="i" class="chat-bubble-row" :class="msg.role">
                <div class="chat-bubble">
                  <div class="bubble-text">{{ msg.content }}</div>
                  <div class="bubble-time">{{ msg.time }}</div>
                </div>
              </div>
              <div v-if="chatState.loading" class="chat-bubble-row assistant">
                <div class="chat-bubble typing">
                  <span class="dot"></span><span class="dot"></span><span class="dot"></span>
                </div>
              </div>
            </div>
            <div class="ai-chat-input-row">
              <el-input
                v-model="chatState.input"
                size="small"
                placeholder="输入你的问题..."
                :disabled="chatState.loading"
                @keyup.enter="handleChatSend"
              />
              <el-button size="small" type="primary" :loading="chatState.loading" :disabled="!chatState.input.trim()" @click="handleChatSend">
                发送
              </el-button>
            </div>
          </template>

          <!-- No context available -->
          <template v-if="!ctx && activeTab !== 'chat'">
            <div class="ai-idle">
              <p>AI 助手可以帮你审批、填表</p>
              <p class="hint">进入「我的任务」或「发起申请」页面即可使用</p>
            </div>
          </template>
        </div>
      </div>
    </transition>

    <button class="ai-float-btn" :class="{ pulse: !panelOpen }" @click="togglePanel">
      <el-icon :size="24">
        <ChatDotRound v-if="!panelOpen" />
        <Close v-else />
      </el-icon>
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed, inject, nextTick, reactive, ref, watch } from 'vue';
import {
  ChatDotRound, ChatDotSquare, CircleCheck, CircleClose,
  Close, Delete, Fold, Loading
} from '@element-plus/icons-vue';
import { ElMessage } from 'element-plus';
import type { AiSuggestion } from '../../types';
import { aiSuggestion, aiSuggestionFollowUp } from '../../api/workflow';
import { aiChat, parseAndStartByFormCommand, parseFormCommand, type ChatTurn } from '../../api/ai-form-commands';
import { useAuthStore } from '../../stores/auth';
import { AI_ASSISTANT_KEY } from './types';

const auth = useAuthStore();

interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  time: string;
}

interface Conversation {
  id: string;
  title: string;
  messages: ChatMessage[];
  createdAt: string;
}

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function storageKey(): string {
  const uid = auth.currentUser?.userId;
  return uid != null ? `ai-chat-${uid}` : 'ai-chat-anonymous';
}

function loadConversations(): Conversation[] {
  try {
    const raw = localStorage.getItem(storageKey());
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveConversations(list: Conversation[]) {
  try {
    localStorage.setItem(storageKey(), JSON.stringify(list));
  } catch { /* quota exceeded, silently ignore */ }
}

const ctx = inject(AI_ASSISTANT_KEY, null);

const panelOpen = ref(false);
const activeTab = ref<'approval' | 'form-command' | 'chat'>('chat');
const sidebarVisible = ref(false);

const chatMessagesEl = ref<HTMLElement | null>(null);

const conversations = reactive<Conversation[]>(loadConversations());
const activeConversationId = ref<string | null>(null);

const suggestionState = reactive({
  loading: false,
  asking: false,
  suggestion: null as AiSuggestion | null,
  conversation: [] as { question: string; answer: string }[],
  question: ''
});

const commandState = reactive({
  command: '',
  parsing: false,
  starting: false,
  result: null as { title: string; type: 'success' | 'warning' | 'info' | 'error'; details: string[] } | null
});

const chatState = reactive({
  loading: false,
  input: '',
  messages: [] as ChatMessage[]
});

// persist conversations on change
watch(
  () => conversations.map(c => ({ id: c.id, title: c.title, messages: [...c.messages], createdAt: c.createdAt })),
  (val) => saveConversations(val as Conversation[]),
  { deep: true }
);

watch(
  () => auth.currentUser?.userId,
  () => {
    conversations.splice(0, conversations.length, ...loadConversations());
    activeConversationId.value = null;
    chatState.messages = [];
  }
);

function now() {
  return new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
}

function dateLabel() {
  const d = new Date();
  return `${d.getMonth() + 1}/${d.getDate()} ${d.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })}`;
}

function syncCurrentConversation() {
  if (!activeConversationId.value) return;
  const conv = conversations.find(c => c.id === activeConversationId.value);
  if (conv) {
    conv.messages = [...chatState.messages];
    if (conv.messages.length > 0) {
      const first = conv.messages.find(m => m.role === 'user');
      if (first && conv.title === '新对话') {
        conv.title = first.content.slice(0, 40);
      }
    }
  }
}

function handleNewChat() {
  if (activeTab.value !== 'chat') {
    activeTab.value = 'chat';
  }
  // save current conversation first
  syncCurrentConversation();
  // create new
  const conv: Conversation = {
    id: generateId(),
    title: '新对话',
    messages: [],
    createdAt: dateLabel()
  };
  conversations.unshift(conv);
  activeConversationId.value = conv.id;
  chatState.messages = [];
  chatState.input = '';
}

function switchConversation(id: string) {
  syncCurrentConversation();
  const conv = conversations.find(c => c.id === id);
  if (conv) {
    activeConversationId.value = conv.id;
    chatState.messages = [...conv.messages];
  }
}

function deleteConversation(id: string) {
  const idx = conversations.findIndex(c => c.id === id);
  if (idx === -1) return;
  conversations.splice(idx, 1);
  if (activeConversationId.value === id) {
    if (conversations.length > 0) {
      const next = conversations[Math.min(idx, conversations.length - 1)];
      activeConversationId.value = next.id;
      chatState.messages = [...next.messages];
    } else {
      activeConversationId.value = null;
      chatState.messages = [];
    }
  }
}

async function handleChatSend() {
  const text = chatState.input.trim();
  if (!text || chatState.loading) return;

  // auto-create conversation if none active
  if (!activeConversationId.value) {
    const conv: Conversation = {
      id: generateId(),
      title: text.slice(0, 40),
      messages: [],
      createdAt: dateLabel()
    };
    conversations.unshift(conv);
    activeConversationId.value = conv.id;
  }

  chatState.messages.push({ role: 'user', content: text, time: now() });
  chatState.input = '';
  chatState.loading = true;
  await nextTick();
  scrollChatToBottom();
  try {
    const history: ChatTurn[] = [];
    for (let i = 0; i < chatState.messages.length - 1; i += 2) {
      const q = chatState.messages[i];
      const a = chatState.messages[i + 1];
      if (q && q.role === 'user' && a && a.role === 'assistant') {
        history.push({ question: q.content, answer: a.content });
      }
    }
    const res = await aiChat({ message: text, history });
    chatState.messages.push({ role: 'assistant', content: res.reply, time: now() });
  } catch (e) {
    console.error(e);
    chatState.messages.push({ role: 'assistant', content: '抱歉，AI 服务暂时不可用，请稍后再试。', time: now() });
  } finally {
    chatState.loading = false;
    syncCurrentConversation();
    await nextTick();
    scrollChatToBottom();
  }
}

function scrollChatToBottom() {
  if (chatMessagesEl.value) {
    chatMessagesEl.value.scrollTop = chatMessagesEl.value.scrollHeight;
  }
}

const suggestedUpdatesEntries = computed(() => {
  const updates = suggestionState.suggestion?.suggestedFormUpdates;
  if (!updates || typeof updates !== 'object') return [];
  return Object.entries(updates).filter(([, v]) => v != null);
});

function togglePanel() {
  panelOpen.value = !panelOpen.value;
  if (panelOpen.value) {
    if (ctx) {
      activeTab.value = ctx.mode;
    } else {
      activeTab.value = 'chat';
    }
    // ensure a conversation is active when opening chat
    if (activeTab.value === 'chat' && !activeConversationId.value && conversations.length > 0) {
      activeConversationId.value = conversations[0].id;
      chatState.messages = [...conversations[0].messages];
    }
  }
}

function formatSuggestedValue(value: unknown): string {
  if (value === null || value === undefined || value === '') return '-';
  if (typeof value === 'boolean') return value ? '是' : '否';
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
}

async function handleGetSuggestion() {
  if (!ctx || ctx.mode !== 'approval' || !ctx.taskId.value) return;
  suggestionState.loading = true;
  suggestionState.suggestion = null;
  suggestionState.conversation = [];
  suggestionState.question = '';
  try {
    const result = await aiSuggestion(ctx.taskId.value);
    suggestionState.suggestion = result;
    if (result.conversation) {
      suggestionState.conversation = result.conversation;
    }
  } catch (e) {
    console.error(e);
    ElMessage.error('获取 AI 建议失败');
  } finally {
    suggestionState.loading = false;
  }
}

async function handleFollowUp() {
  if (!ctx || ctx.mode !== 'approval' || !ctx.taskId.value || !suggestionState.suggestion) return;
  if (!suggestionState.question.trim()) return;
  suggestionState.asking = true;
  try {
    const result = await aiSuggestionFollowUp(
      ctx.taskId.value,
      suggestionState.suggestion.recordId,
      suggestionState.question.trim()
    );
    suggestionState.suggestion = result;
    if (result.conversation) {
      suggestionState.conversation = result.conversation;
    }
    suggestionState.question = '';
    ElMessage.success('追问成功');
  } catch (e) {
    console.error(e);
    ElMessage.error('追问失败');
  } finally {
    suggestionState.asking = false;
  }
}

function handleAdopt() {
  if (!ctx || ctx.mode !== 'approval' || !suggestionState.suggestion?.approvalComment) return;
  ctx.onAdopt(
    suggestionState.suggestion.approvalComment,
    suggestionState.suggestion.decision || ''
  );
  ElMessage.success('已填入审批意见');
  panelOpen.value = false;
}

async function handleParse() {
  if (!ctx || ctx.mode !== 'form-command' || !commandState.command.trim()) {
    ElMessage.warning('请输入表单指令');
    return;
  }
  commandState.parsing = true;
  commandState.result = null;
  try {
    const parsed = await parseFormCommand({
      command: commandState.command.trim(),
      requestTemplateKey: ctx.templateKey.value || undefined,
      formKey: ctx.formKey.value || undefined,
      formVersionId: ctx.formVersionId.value ?? undefined
    });

    if (parsed.templateKey && parsed.templateKey !== ctx.templateKey.value) {
      ctx.onTemplateChange(parsed.templateKey);
    }

    ctx.onFillFormData(parsed.formData);

    const details: string[] = [];
    details.push(`模型：${parsed.model}`);
    details.push(`置信度：${Math.round(parsed.confidence * 100)}%`);
    const formDataKeys = Object.keys(parsed.formData);
    if (formDataKeys.length > 0) {
      details.push(`已填入字段：${formDataKeys.join('、')}`);
    } else {
      details.push('未识别到可填入的字段');
    }

    if (parsed.missingRequiredFields.length) {
      commandState.result = {
        title: `预填完成，仍缺少必填字段：${parsed.missingRequiredFields.join('、')}`,
        type: 'warning',
        details
      };
    } else {
      commandState.result = {
        title: '已完成预填，可直接提交或继续补充',
        type: 'success',
        details
      };
    }
    ElMessage.success('AI 解析完成');
  } catch (e) {
    console.error(e);
    commandState.result = {
      title: 'AI 解析失败，请检查输入或手动填写表单',
      type: 'error',
      details: []
    };
    ElMessage.error('AI 解析失败');
  } finally {
    commandState.parsing = false;
  }
}

async function handleParseAndStart() {
  if (!ctx || ctx.mode !== 'form-command' || !commandState.command.trim()) {
    ElMessage.warning('请输入表单指令');
    return;
  }
  commandState.starting = true;
  commandState.result = null;
  try {
    const result = await parseAndStartByFormCommand({
      command: commandState.command.trim(),
      requestTemplateKey: ctx.templateKey.value || undefined,
      formKey: ctx.formKey.value || undefined,
      formVersionId: ctx.formVersionId.value ?? undefined,
      requireAllRequiredFields: true
    });

    const details: string[] = [];
    details.push(`流程实例：${result.processInstanceId}`);
    if (result.missingRequiredFields?.length) {
      details.push(`缺少的必填字段：${result.missingRequiredFields.join('、')}`);
    }
    if (result.confidence !== undefined) {
      details.push(`置信度：${Math.round((result.confidence ?? 0) * 100)}%`);
    }
    commandState.result = {
      title: 'AI 已直接发起流程',
      type: 'success',
      details
    };
    ElMessage.success('AI 已发起申请');
    ctx.onStartProcess();
  } catch (e) {
    console.error(e);
    const msg = (e as { response?: { data?: { error?: string } } })?.response?.data?.error;
    commandState.result = {
      title: msg || 'AI 发起失败，请先执行解析预填并手工补充',
      type: 'error',
      details: []
    };
    ElMessage.error(msg || 'AI 发起失败');
  } finally {
    commandState.starting = false;
  }
}
</script>

<style scoped>
.ai-floating-assistant {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 2000;
}

.ai-float-btn {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  border: none;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  cursor: pointer;
  box-shadow: 0 4px 16px rgba(102, 126, 234, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s, box-shadow 0.2s;
}

.ai-float-btn:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 24px rgba(102, 126, 234, 0.5);
}

.ai-float-btn.pulse {
  animation: float-pulse 2s ease-in-out infinite;
}

@keyframes float-pulse {
  0%, 100% { box-shadow: 0 4px 16px rgba(102, 126, 234, 0.4); }
  50% { box-shadow: 0 4px 28px rgba(102, 126, 234, 0.65); }
}

.ai-panel {
  position: absolute;
  right: 0;
  bottom: 72px;
  width: 500px;
  height: 620px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.12);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.ai-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid #f1f5f9;
  background: #fafbfc;
  flex-shrink: 0;
}

.ai-panel-title {
  display: flex;
  align-items: center;
  gap: 2px;
  font-weight: 600;
  font-size: 15px;
  color: #1e293b;
}

.sidebar-toggle-btn {
  margin-right: 4px;
}

.ai-panel-actions {
  display: flex;
  align-items: center;
  gap: 6px;
}

/* Sidebar */
.ai-sidebar {
  position: absolute;
  left: 0;
  top: 49px;
  bottom: 0;
  width: 280px;
  background: #fafbfc;
  border-right: 1px solid #e5e7eb;
  z-index: 10;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.sidebar-header {
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}

.sidebar-list {
  flex: 1;
  overflow-y: auto;
  padding: 6px;
}

.sidebar-item {
  position: relative;
  padding: 8px 10px;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.15s;
  margin-bottom: 2px;
}

.sidebar-item:hover {
  background: #eef2ff;
}

.sidebar-item.active {
  background: #e0e7ff;
}

.sidebar-item-title {
  font-size: 13px;
  color: #334155;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  padding-right: 24px;
}

.sidebar-item-time {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.sidebar-item-delete {
  position: absolute;
  right: 4px;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0;
  transition: opacity 0.15s;
}

.sidebar-item:hover .sidebar-item-delete {
  opacity: 1;
}

.sidebar-empty {
  text-align: center;
  padding: 24px 12px;
  color: #94a3b8;
  font-size: 13px;
}

/* sidebar slide transition */
.sidebar-slide-enter-active,
.sidebar-slide-leave-active {
  transition: transform 0.25s ease, opacity 0.25s ease;
}

.sidebar-slide-enter-from {
  transform: translateX(-100%);
  opacity: 0;
}

.sidebar-slide-leave-to {
  transform: translateX(-100%);
  opacity: 0;
}

.ai-panel-body {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.ai-idle {
  text-align: center;
  color: #94a3b8;
  font-size: 13px;
  padding: 16px 0;
}

.ai-idle p {
  margin: 0;
}

.ai-idle .hint {
  font-size: 12px;
  color: #b0bec5;
  margin-top: 4px;
}

.ai-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 32px;
  color: #64748b;
  font-size: 14px;
}

.ai-suggestion-content {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.ai-decision {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: #fef2f2;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  color: #dc2626;
}

.ai-decision.approve {
  background: #f0fdf4;
  color: #16a34a;
}

.ai-recommendation {
  margin: 0;
  font-size: 13px;
  line-height: 1.6;
  color: #334155;
}

.ai-info-block {
  padding: 10px 12px;
  background: #f8fafc;
  border-radius: 8px;
  font-size: 12px;
}

.block-label {
  font-weight: 600;
  font-size: 12px;
  margin-bottom: 6px;
  color: #475569;
}

.ai-info-block.warnings .block-label { color: #dc2626; }
.ai-info-block.anomalies .block-label { color: #d97706; }
.ai-info-block.supplementary .block-label { color: #2563eb; }
.ai-info-block.updates .block-label { color: #7c3aed; }

.ai-info-block ul {
  margin: 0;
  padding-left: 18px;
}

.ai-info-block li {
  margin: 2px 0;
  color: #475569;
}

.ai-info-block.warnings li { color: #dc2626; }
.ai-info-block.anomalies li { color: #d97706; }

.update-row {
  display: flex;
  gap: 8px;
  align-items: baseline;
  padding: 4px 8px;
  background: #fff;
  border-radius: 4px;
  border: 1px dashed #e2e8f0;
  margin-bottom: 4px;
}

.update-row:last-child { margin-bottom: 0; }

.update-row code {
  font-size: 11px;
  color: #7c3aed;
  background: #f5f3ff;
  padding: 1px 4px;
  border-radius: 3px;
}

.update-row span {
  color: #475569;
}

.ai-comment-block {
  padding: 10px 12px;
  background: #f8fafc;
  border-radius: 8px;
}

.ai-comment-block .block-label {
  margin-bottom: 6px;
}

.comment-preview {
  white-space: pre-wrap;
  font-size: 12px;
  margin-bottom: 8px;
  padding: 6px 8px;
  background: #fff;
  border-radius: 4px;
  border: 1px dashed #e2e8f0;
  color: #475569;
}

.ai-conversation {
  max-height: 120px;
  overflow-y: auto;
}

.turn {
  padding: 6px 0;
  border-bottom: 1px solid #f1f5f9;
  font-size: 12px;
}

.turn:last-child { border-bottom: none; }

.turn-q {
  font-weight: 500;
  color: #334155;
  margin-bottom: 2px;
}

.turn-a {
  color: #64748b;
}

.ai-follow-up-row {
  display: flex;
  gap: 6px;
}

.ai-action-bar {
  display: flex;
  gap: 8px;
  justify-content: center;
  padding-top: 4px;
}

.ai-command-input {
  margin-bottom: 4px;
}

.ai-command-result {
  margin-bottom: 4px;
}

.result-details {
  margin: 4px 0 0;
  padding-left: 18px;
  font-size: 12px;
}

.panel-fade-enter-active,
.panel-fade-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}

.panel-fade-enter-from,
.panel-fade-leave-to {
  opacity: 0;
  transform: translateY(12px) scale(0.96);
}

/* Chat area */
.ai-chat-messages {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 0;
}

.chat-bubble-row {
  display: flex;
}

.chat-bubble-row.user {
  justify-content: flex-end;
}

.chat-bubble-row.assistant {
  justify-content: flex-start;
}

.chat-bubble {
  max-width: 80%;
  padding: 8px 12px;
  border-radius: 12px;
  font-size: 13px;
  line-height: 1.5;
}

.chat-bubble-row.user .chat-bubble {
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  border-bottom-right-radius: 4px;
}

.chat-bubble-row.assistant .chat-bubble {
  background: #f1f5f9;
  color: #334155;
  border-bottom-left-radius: 4px;
}

.bubble-text {
  white-space: pre-wrap;
  word-break: break-word;
}

.bubble-time {
  font-size: 10px;
  margin-top: 4px;
  opacity: 0.6;
  text-align: right;
}

.chat-bubble.typing {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 12px 16px;
}

.chat-bubble.typing .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #94a3b8;
  animation: typing-dot 1.4s ease-in-out infinite;
}

.chat-bubble.typing .dot:nth-child(2) {
  animation-delay: 0.2s;
}

.chat-bubble.typing .dot:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing-dot {
  0%, 60%, 100% { opacity: 0.3; transform: scale(0.8); }
  30% { opacity: 1; transform: scale(1); }
}

.ai-chat-input-row {
  display: flex;
  gap: 6px;
  padding-top: 4px;
  border-top: 1px solid #f1f5f9;
}

@media (max-width: 480px) {
  .ai-panel {
    position: fixed;
    right: 0;
    bottom: 0;
    left: 0;
    width: auto;
    height: auto;
    max-height: 75vh;
    border-radius: 12px 12px 0 0;
  }

  .ai-sidebar {
    top: 49px;
  }
}
</style>
