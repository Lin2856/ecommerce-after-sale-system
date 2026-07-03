<template>
  <div class="conversation-grid">
    <div class="panel conversation-panel">
      <div class="conversation-panel-header">
        <div>
          <h2 class="section-title">会话列表</h2>
          <span>{{ conversationData.length }} 个咨询会话</span>
        </div>
      </div>
      <div
        v-for="item in conversationData"
        :key="item.id"
        class="conversation-item clickable-line"
        :class="{ active: selectedConversation?.id === item.id }"
        @click="selectConversation(item)"
      >
        <div class="conversation-main">
          <div class="conversation-title-row">
            <strong>{{ conversationTitle(item) }}</strong>
            <el-tag size="small" :type="conversationStatusTagType(item.status)">{{ formatStatus(item.status) }}</el-tag>
          </div>
          <div class="conversation-meta">{{ item.orderNo }} · {{ cleanProductName(item.productName) }}</div>
          <div class="conversation-preview">{{ item.lastMessage || '暂无最近消息' }}</div>
          <div class="conversation-time">{{ formatMessageTime(item.lastMessageAt) || '暂无时间' }}</div>
        </div>
      </div>
    </div>
    <div class="panel chat-panel">
      <div class="chat-header">
        <div>
          <h2 class="section-title">聊天窗口</h2>
          <div class="page-kicker">{{ selectedConversation ? '正在处理消费者咨询' : '请选择会话' }}</div>
        </div>
      </div>
      <div v-if="selectedConversation" class="order-strip">
        <div class="order-strip-main">
          <div class="order-strip-title">{{ cleanProductName(selectedConversation.productName) }}</div>
          <div class="order-strip-meta">
            <span>{{ selectedConversation.platformName || '万象商城' }}</span>
            <span>{{ selectedConversation.orderNo }}</span>
            <span>{{ selectedConversation.merchantName }}</span>
          </div>
        </div>
        <div class="order-strip-actions">
          <el-tag :type="afterSaleStatusTagType(selectedConversation.afterSaleStatus)">{{ selectedConversation.afterSaleStatus || '暂无售后状态' }}</el-tag>
          <el-tag :type="conversationStatusTagType(selectedConversation.status)">{{ formatStatus(selectedConversation.status) }}</el-tag>
          <el-button @click="openOrderDetail(selectedConversation)">查看订单</el-button>
        </div>
      </div>
      <div v-else class="order-strip empty">
        <span>请从左侧选择一个会话</span>
      </div>
      <div class="chat-window">
        <div ref="chatBoxRef" class="chat-box">
          <div
            v-for="message in chatMessages"
            :key="message.id"
            class="message-row"
            :class="{ right: message.senderType === 'STAFF' }"
          >
            <div v-if="message.senderType !== 'STAFF'" class="chat-avatar" :class="avatarClass(message.senderType)">
              <img v-if="messageAvatar(message.senderType)" :src="messageAvatar(message.senderType)" alt="" />
              <span v-else>{{ avatarText(message.senderType) }}</span>
            </div>
            <div class="message-body">
              <div class="speaker">
                <span class="speaker-name">{{ speakerText(message.senderType) }}</span>
                <span class="role-badge" :class="message.senderType.toLowerCase()">{{ roleBadgeText(message.senderType) }}</span>
                <span class="speaker-time">{{ formatMessageTime(message.createdAt) }}</span>
              </div>
              <div class="bubble" :class="message.senderType.toLowerCase()">
                {{ message.content }}
              </div>
            </div>
            <div v-if="message.senderType === 'STAFF'" class="chat-avatar merchant-avatar">
              <img v-if="messageAvatar(message.senderType)" :src="messageAvatar(message.senderType)" alt="" />
              <span v-else>{{ avatarText(message.senderType) }}</span>
            </div>
          </div>
        </div>
        <div class="quick-replies">
          <button v-for="item in quickReplies" :key="item" type="button" @click="useQuickReply(item)">{{ item }}</button>
        </div>
        <div class="chat-input">
          <el-input
            v-model="replyContent"
            type="textarea"
            :autosize="{ minRows: 1, maxRows: 3 }"
            resize="none"
            placeholder="输入回复内容"
            @keydown.enter.exact.prevent="sendReply"
          />
          <div class="input-actions">
            <el-button
              v-if="selectedConversation?.status === 'AGENT_SERVING'"
              plain
              @click="endAgentService"
            >
              结束人工服务
            </el-button>
            <el-button type="primary" @click="sendReply">发送</el-button>
          </div>
        </div>
      </div>
    </div>
    <el-dialog v-model="orderDetailVisible" title="订单详情" width="620px">
      <el-descriptions v-if="detailConversation" :column="2" border>
        <el-descriptions-item label="订单编号">{{ detailConversation.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="所属平台">{{ detailConversation.platformName || '万象商城' }}</el-descriptions-item>
        <el-descriptions-item label="商家名称">{{ detailConversation.merchantName }}</el-descriptions-item>
        <el-descriptions-item label="商品名称">{{ cleanProductName(detailConversation.productName) }}</el-descriptions-item>
        <el-descriptions-item label="售后状态">{{ detailConversation.afterSaleStatus }}</el-descriptions-item>
        <el-descriptions-item label="接待状态">{{ formatStatus(detailConversation.status) }}</el-descriptions-item>
        <el-descriptions-item label="咨询意图">{{ detailConversation.aiIntent }}</el-descriptions-item>
        <el-descriptions-item label="最近消息时间">{{ detailConversation.lastMessageAt }}</el-descriptions-item>
        <el-descriptions-item label="最近消息" :span="2">{{ detailConversation.lastMessage || '暂无' }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button type="primary" @click="orderDetailVisible = false">知道了</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { conversations } from '../data/mock'
import { ElMessage } from 'element-plus'
import { createOperationLog } from '../api'
import { getMerchantBindings, getStoredUser } from '../utils/auth'
import { getConfirmedStaff, requireStaffIdentity } from '../utils/staffAuth'
import aiAvatar from '../assets/avatars/ai-bot.png'

type DemoConversation = {
  id: number
  conversationNo: string
  orderNo: string
  productName: string
  platformName?: string
  consumerAccountNo?: string
  consumerPrimaryAccountNo?: string
  merchantAccountNo?: string
  merchantPrimaryAccountNo?: string
  merchantName: string
  afterSaleStatus: string
  status: string
  aiIntent: string
  lastMessage: string
  lastMessageAt: string
}

type DemoMessage = {
  id: string
  orderNo: string
  senderType: string
  speaker: string
  content: string
  createdAt: string
}

const conversationData = ref<DemoConversation[]>([])
const selectedConversation = ref<DemoConversation | null>(null)
const replyContent = ref('')
const chatMessages = ref<DemoMessage[]>([])
const orderDetailVisible = ref(false)
const detailConversation = ref<DemoConversation | null>(null)
const consumerAvatar = ref('')
const merchantAvatar = ref('')
const chatBoxRef = ref<HTMLElement | null>(null)
const lastMessageKey = ref('')
let pollingTimer = 0
const quickReplies = [
  '请您提供订单编号，我为您核实售后进度。',
  '请上传商品问题照片，方便我们进一步判断。',
  '售后专员正在核实，请您稍等。',
  '已为您记录问题，后续处理结果会同步到订单详情。'
]

onMounted(async () => {
  await loadMerchantAvatar()
  await loadConversations()
  selectedConversation.value = conversationData.value[0] || null
  await loadConsumerAvatar()
  await loadMessages()
  pollingTimer = window.setInterval(async () => {
    await loadConversations(false)
    await loadMessages(false)
  }, 2500)
})

onUnmounted(() => {
  window.clearInterval(pollingTimer)
})

watch(selectedConversation, (next, previous) => {
  if (next?.orderNo !== previous?.orderNo) {
    replyContent.value = ''
    lastMessageKey.value = ''
  }
  loadConsumerAvatar()
  loadMessages()
})

function selectConversation(conversation: DemoConversation) {
  selectedConversation.value = conversation
}

function openOrderDetail(conversation: DemoConversation) {
  detailConversation.value = conversation
  orderDetailVisible.value = true
}

async function loadConversations(showError = true) {
  try {
    const accounts = getMerchantBindings()
      .filter((item) => item.platformCode === 'TWENTY_MALL' && item.accountNo)
      .map((item) => `merchantAccounts=${encodeURIComponent(item.accountNo as string)}`)
      .join('&')
    const response = await fetch(`/api/demo-chat/conversations${accounts ? `?${accounts}` : ''}`)
    const payload = await response.json()
    conversationData.value = payload.data || []
    if (selectedConversation.value) {
      const latestSelected = conversationData.value.find((item) => item.orderNo === selectedConversation.value?.orderNo)
      selectedConversation.value = latestSelected || conversationData.value[0] || null
    }
  } catch {
    conversationData.value = conversations.map((item) => ({
      id: item.id,
      conversationNo: item.conversationNo,
      orderNo: item.orderNo || 'DY202606250001',
      productName: item.productName || 'Aurora X1 智能手机',
      platformName: '抖音商城',
      consumerAccountNo: '',
      consumerPrimaryAccountNo: '',
      merchantName: item.merchantName || '星链数码旗舰店',
      afterSaleStatus: item.afterSaleStatus || '处理中',
      status: item.status,
      aiIntent: item.aiIntent,
      lastMessage: item.lastMessage,
      lastMessageAt: item.lastMessageAt
    }))
    if (showError) {
      ElMessage({ type: 'warning', message: '后端演示对话服务未启动，当前显示本地会话' })
    }
  }
}

async function loadMerchantAvatar() {
  const user = getStoredUser<{ username?: string }>()
  const accountNo = user?.username || '13338907681'
  merchantAvatar.value = await loadPrimaryAvatar(accountNo, 'MERCHANT')
}

async function loadConsumerAvatar() {
  const accountNo = selectedConversation.value?.consumerPrimaryAccountNo
  consumerAvatar.value = accountNo ? await loadPrimaryAvatar(accountNo, 'CONSUMER') : ''
}

async function loadPrimaryAvatar(accountNo: string, accountType: 'CONSUMER' | 'MERCHANT') {
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/primary/profile?accountNo=${encodeURIComponent(accountNo)}&accountType=${accountType}`)
    const payload = await response.json()
    return payload.code === '200' && payload.data?.avatar ? payload.data.avatar : ''
  } catch {
    return ''
  }
}

async function loadMessages(showError = true) {
  const conversation = selectedConversation.value
  if (!conversation) {
    chatMessages.value = [{ id: 'empty', orderNo: '', senderType: 'AI', speaker: 'AI客服', content: '请选择左侧会话', createdAt: '' }]
    return
  }
  try {
    const response = await fetch(`/api/demo-chat/conversations/${conversation.orderNo}/messages`)
    const payload = await response.json()
    const nextMessages = payload.data || []
    const nextKey = messageListKey(nextMessages)
    const shouldScroll = nextKey !== lastMessageKey.value
    chatMessages.value = nextMessages
    lastMessageKey.value = nextKey
    if (shouldScroll) {
      scrollChatToBottom()
    }
  } catch {
    chatMessages.value = [
      { id: 'user-last', orderNo: conversation.orderNo, senderType: 'CONSUMER', speaker: '用户', content: conversation.lastMessage || '暂无用户消息', createdAt: '' },
      { id: 'ai-tip', orderNo: conversation.orderNo, senderType: 'AI', speaker: 'AI客服', content: '请根据订单、售后规则和知识库给出准确回复。', createdAt: '' }
    ]
    if (showError) {
      ElMessage({ type: 'warning', message: '暂时无法读取共享消息' })
    }
  }
}

async function sendReply() {
  const conversation = selectedConversation.value
  const content = replyContent.value.trim()
  if (!conversation) {
    ElMessage({ type: 'warning', message: '请先选择会话' })
    return
  }
  if (!content) {
    ElMessage({ type: 'warning', message: '请输入回复内容' })
    return
  }
  const staff = requireStaffIdentity()
  if (!staff) {
    return
  }
  const optimisticMessage: DemoMessage = {
    id: `local-${Date.now()}`,
    orderNo: conversation.orderNo,
    senderType: 'STAFF',
    speaker: '人工客服',
    content,
    createdAt: formatLocalNow()
  }
  chatMessages.value = [...chatMessages.value, optimisticMessage]
  lastMessageKey.value = messageListKey(chatMessages.value)
  replyContent.value = ''
  scrollChatToBottom()
  try {
    const response = await fetch(`/api/demo-chat/conversations/${conversation.orderNo}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ senderType: 'STAFF', content })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '发送失败')
    }
    await loadConversations(false)
    await loadMessages(false)
    recordChatOperation(conversation, content)
    ElMessage({ type: 'success', message: '回复已发送，用户端会自动刷新显示' })
  } catch (error) {
    chatMessages.value = chatMessages.value.filter((item) => item.id !== optimisticMessage.id)
    lastMessageKey.value = messageListKey(chatMessages.value)
    replyContent.value = content
    ElMessage({ type: 'error', message: error instanceof Error ? error.message : '发送失败，请确认后端服务已启动' })
  }
}

function recordChatOperation(conversation: DemoConversation, content: string) {
  const staff = getConfirmedStaff()
  const user = getStoredUser<{ username?: string; phone?: string }>()
  if (!staff) {
    return
  }
  createOperationLog({
    primaryAccount: user?.username || user?.phone || '',
    staffCode: staff.code,
    staffName: staff.name,
    actionType: 'CUSTOMER_SERVICE_REPLY',
    actionName: '人工客服发送消息',
    targetType: '客服会话',
    targetId: conversation.orderNo,
    detail: `回复消费者：${content}`
  }).catch(() => undefined)
}

function useQuickReply(content: string) {
  replyContent.value = content
}

async function endAgentService() {
  const conversation = selectedConversation.value
  if (!conversation) {
    ElMessage({ type: 'warning', message: '请先选择会话' })
    return
  }
  try {
    const response = await fetch(`/api/demo-chat/conversations/id/${conversation.id}/end-agent`, {
      method: 'POST'
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      ElMessage({ type: 'error', message: payload.message || '结束人工服务失败' })
      return
    }
    await loadConversations(false)
    await loadMessages(false)
    ElMessage({ type: 'success', message: '人工服务已结束，后续由AI客服接待' })
  } catch {
    ElMessage({ type: 'error', message: '结束人工服务失败，请确认后端服务已启动' })
  }
}

function formatStatus(status: string) {
  const statusMap: Record<string, string> = {
    AI_SERVING: 'AI接待中',
    AGENT_SERVING: '人工接待中',
    CLOSED: '已关闭'
  }
  return statusMap[status] || status
}

function conversationStatusTagType(status: string) {
  if (status === 'AGENT_SERVING') {
    return 'warning'
  }
  if (status === 'AI_SERVING') {
    return 'primary'
  }
  if (status === 'CLOSED') {
    return 'info'
  }
  return 'info'
}

function afterSaleStatusTagType(status?: string) {
  if (!status) return 'info'
  if (status.includes('待') || status.includes('处理中')) {
    return 'warning'
  }
  if (status.includes('完成') || status.includes('同意')) {
    return 'success'
  }
  if (status.includes('拒绝')) {
    return 'danger'
  }
  return 'info'
}

function conversationTitle(conversation: DemoConversation) {
  return `${conversation.platformName || '万象商城'} · ${conversation.merchantName}`
}

function cleanProductName(productName: string) {
  return productName.replace(/^万象商城\s*/, '').trim()
}

function formatMessageTime(value?: string) {
  if (!value) return ''
  const text = String(value).replace('T', ' ').replace(/\.\d+$/, '')
  const match = text.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?/)
  if (!match) return text
  const [, year, month, day, hour, minute, second = '00'] = match
  return `${year}.${Number(month)}.${Number(day)} ${hour.padStart(2, '0')}:${minute.padStart(2, '0')}:${second.padStart(2, '0')}`
}

function formatLocalNow() {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`
}

function messageListKey(messages: DemoMessage[]) {
  const latest = messages[messages.length - 1]
  return latest ? `${messages.length}:${latest.id}:${latest.createdAt}:${latest.content}` : '0'
}

function scrollChatToBottom() {
  nextTick(() => {
    const element = chatBoxRef.value
    if (element) {
      element.scrollTop = element.scrollHeight
    }
  })
}

function speakerText(senderType: string) {
  const speakerMap: Record<string, string> = {
    CONSUMER: '用户',
    AI: 'AI客服',
    STAFF: '人工客服'
  }
  return speakerMap[senderType] || senderType
}

function roleBadgeText(senderType: string) {
  const roleMap: Record<string, string> = {
    CONSUMER: '消费者',
    AI: 'AI',
    STAFF: '商家'
  }
  return roleMap[senderType] || senderType
}

function messageAvatar(senderType: string) {
  if (senderType === 'AI') return aiAvatar
  if (senderType === 'CONSUMER') return consumerAvatar.value
  if (senderType === 'STAFF') return merchantAvatar.value
  return ''
}

function avatarText(senderType: string) {
  if (senderType === 'AI') return 'AI'
  if (senderType === 'CONSUMER') return '客'
  if (senderType === 'STAFF') return '商'
  return '系'
}

function avatarClass(senderType: string) {
  if (senderType === 'AI') return 'ai-avatar'
  if (senderType === 'CONSUMER') return 'consumer-avatar'
  return ''
}
</script>

<style scoped>
.conversation-grid {
  display: grid;
  grid-template-columns: 320px minmax(0, 1fr);
  gap: 16px;
  margin-top: 16px;
  height: calc(100vh - 150px);
  min-height: 660px;
}

.conversation-panel,
.chat-panel {
  display: flex;
  min-height: 0;
  flex-direction: column;
}

.conversation-panel {
  padding: 18px;
  overflow: hidden;
}

.conversation-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}

.conversation-panel-header span {
  color: #94a3b8;
  font-size: 13px;
}

.conversation-item {
  position: relative;
  display: flex;
  min-height: 104px;
  padding: 14px 14px 14px 16px;
  border: 1px solid transparent;
  border-radius: 8px;
  background: #fff;
  transition: background 0.18s ease, border-color 0.18s ease;
}

.conversation-item + .conversation-item {
  margin-top: 8px;
}

.conversation-item:hover,
.conversation-item.active {
  border-color: #bfdbfe;
  background: #f4f8ff;
}

.conversation-item.active::before {
  position: absolute;
  top: 12px;
  bottom: 12px;
  left: 0;
  width: 3px;
  border-radius: 0 4px 4px 0;
  background: #1677ff;
  content: '';
}

.conversation-main {
  min-width: 0;
  width: 100%;
}

.conversation-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.conversation-title-row strong {
  overflow: hidden;
  color: #0f172a;
  font-size: 15px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.conversation-meta,
.conversation-preview,
.conversation-time {
  overflow: hidden;
  margin-top: 6px;
  color: #64748b;
  font-size: 12px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.conversation-preview {
  color: #334155;
}

.conversation-time {
  color: #94a3b8;
}

.chat-box {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  border: 1px solid #e4e8f0;
  border-radius: 8px 8px 0 0;
  padding: 18px;
  background: #f8fafc;
}

.chat-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 12px;
}

.chat-header .section-title {
  margin-bottom: 4px;
}

.order-strip {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 14px 16px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #f8fbff;
}

.order-strip.empty {
  justify-content: center;
  color: #94a3b8;
}

.order-strip-main {
  min-width: 0;
}

.order-strip-title {
  overflow: hidden;
  color: #0f172a;
  font-size: 16px;
  font-weight: 800;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.order-strip-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 12px;
  margin-top: 6px;
  color: #64748b;
  font-size: 13px;
}

.order-strip-actions {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  gap: 8px;
}

.chat-window {
  display: flex;
  min-height: 0;
  flex: 1;
  flex-direction: column;
  margin-top: 12px;
}

.bubble {
  display: inline-block;
  width: fit-content;
  max-width: 68%;
  padding: 11px 13px;
  border-radius: 12px;
  line-height: 1.6;
  text-align: left;
  white-space: pre-wrap;
  word-break: break-word;
}

.message-row {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  margin-bottom: 16px;
}

.message-row.right {
  justify-content: flex-end;
  align-items: flex-end;
}

.message-body {
  max-width: 78%;
}

.message-row.right .message-body {
  display: flex;
  max-width: 78%;
  flex-direction: column;
  align-items: flex-end;
  margin-left: auto;
}

.message-row.right .speaker {
  justify-content: flex-end;
  align-self: flex-end;
  text-align: right;
}

.message-row.right .bubble {
  align-self: flex-end;
}

.message-row.right .speaker-name,
.message-row.right .role-badge,
.message-row.right .speaker-time {
  flex: 0 0 auto;
}

.speaker {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #64748b;
  font-size: 12px;
  margin-bottom: 4px;
}

.speaker-time {
  color: #94a3b8;
}

.speaker-name {
  color: #64748b;
}

.role-badge {
  padding: 1px 6px;
  border-radius: 999px;
  background: #eef2ff;
  color: #2563eb;
  font-size: 11px;
  line-height: 18px;
}

.role-badge.consumer {
  background: #f1f5f9;
  color: #475569;
}

.role-badge.staff {
  background: #dbeafe;
  color: #1d4ed8;
}

.consumer {
  background: #fff;
  color: #334155;
}

.ai {
  background: #e8f4ff;
  color: #334155;
}

.staff {
  background: #1677ff;
  color: #fff;
}

.chat-avatar {
  width: 34px;
  height: 34px;
  flex: 0 0 34px;
  overflow: hidden;
  border-radius: 50%;
  background: #eaf2ff;
  color: #1677ff;
  font-size: 12px;
  font-weight: 800;
  line-height: 34px;
  text-align: center;
}

.chat-avatar img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ai-avatar {
  background: #ecfdf3;
  color: #079455;
}

.consumer-avatar {
  background: #f2f4f7;
  color: #344054;
}

.merchant-avatar {
  background: #fff7ed;
  color: #c2410c;
}

.chat-input {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  padding: 12px;
  border: 1px solid #e4e8f0;
  border-top: none;
  border-radius: 0 0 8px 8px;
  background: #fff;
}

.input-actions {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  gap: 8px;
}

.quick-replies {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  padding: 10px 12px;
  border-right: 1px solid #e4e8f0;
  border-left: 1px solid #e4e8f0;
  background: #fff;
}

.quick-replies button {
  height: 28px;
  padding: 0 10px;
  border: 1px solid #dbeafe;
  border-radius: 999px;
  background: #f8fbff;
  color: #2563eb;
  cursor: pointer;
  font-size: 12px;
}

.quick-replies button:hover {
  border-color: #93c5fd;
  background: #eff6ff;
}

.clickable-line {
  cursor: pointer;
}

.clickable-line.active {
  background: #eef6ff;
  border-color: #b7d8ff;
}

@media (max-width: 1200px) {
  .conversation-grid {
    grid-template-columns: 280px minmax(0, 1fr);
  }

  .order-strip {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
