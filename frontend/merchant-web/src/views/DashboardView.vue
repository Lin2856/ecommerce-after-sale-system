<template>
  <div>
    <div class="metric-grid">
      <div v-for="item in metrics" :key="item.label" class="metric-card">
        <span>{{ item.label }}</span>
        <div class="metric-value">{{ item.value }}</div>
        <el-tag :type="tagType(item.tone)" effect="light">{{ item.trend }}</el-tag>
      </div>
    </div>
    <div class="split-grid">
      <div class="panel">
        <h2 class="section-title">待处理售后</h2>
        <el-table v-loading="loading" :data="afterSaleData" height="310">
          <el-table-column label="订单编号" min-width="150">
            <template #default="{ row }">{{ displayOrderNo(row) }}</template>
          </el-table-column>
          <el-table-column label="原因">
            <template #default="{ row }">{{ reasonText(row.reasonType) }}</template>
          </el-table-column>
          <el-table-column prop="requestedAmount" label="金额" width="100" />
          <el-table-column label="状态" width="130">
            <template #default="{ row }">{{ afterSaleStatusText(row.status) }}</template>
          </el-table-column>
          <el-table-column label="优先级" width="100">
            <template #default="{ row }">{{ priorityText(row.priority) }}</template>
          </el-table-column>
        </el-table>
      </div>
      <div class="panel">
        <h2 class="section-title">服务动态</h2>
        <el-empty v-if="visibleMailData.length === 0" description="暂无新邮件" />
        <div v-else class="mail-list">
          <div
            v-for="item in visibleMailData"
            :key="item.id"
            class="mail-item"
            :class="{ unread: !isMailRead(item.id) }"
            @click="openMail(item)"
          >
            <span v-if="!isMailRead(item.id)" class="mail-dot" />
            <div class="mail-main">
              <div class="mail-head">
                <strong>{{ item.title }}</strong>
                <span>{{ item.occurredAt }}</span>
              </div>
              <p>{{ item.summary }}</p>
              <div class="mail-meta">
                <el-tag :type="mailTypeTag(item.type)" effect="light">{{ item.typeText }}</el-tag>
                <el-tag :type="item.tone || 'info'" effect="plain">{{ item.statusText }}</el-tag>
                <span>关联单号：{{ item.relatedNo }}</span>
              </div>
            </div>
            <div class="mail-actions" @click.stop>
              <el-button size="small" type="primary" link @click="handleMail(item)">查看详细</el-button>
              <el-button size="small" type="danger" link @click="deleteMail(item)">删除</el-button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <el-dialog v-model="mailDetailVisible" title="服务动态邮件" width="640px">
      <el-descriptions v-if="selectedMail" border :column="1">
        <el-descriptions-item label="邮件类型">{{ selectedMail.typeText }}</el-descriptions-item>
        <el-descriptions-item label="标题">{{ selectedMail.title }}</el-descriptions-item>
        <el-descriptions-item label="关联单号">{{ selectedMail.relatedNo }}</el-descriptions-item>
        <el-descriptions-item label="当前状态">{{ selectedMail.statusText }}</el-descriptions-item>
        <el-descriptions-item label="接收时间">{{ selectedMail.occurredAt }}</el-descriptions-item>
        <el-descriptions-item label="内容摘要">{{ selectedMail.summary }}</el-descriptions-item>
        <el-descriptions-item label="详细说明">{{ selectedMail.detail }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="mailDetailVisible = false">关闭</el-button>
        <el-button v-if="selectedMail" type="danger" plain @click="deleteSelectedMail">删除</el-button>
        <el-button v-if="selectedMail" type="primary" @click="handleSelectedMail">查看详细</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadTwentyMallMerchantAfterSales, loadTwentyMallMerchantNotifications, loadTwentyMallMerchantReviews } from '../api'
import { ElMessage } from 'element-plus'
import { afterSales, reviews } from '../data/mock'
import { getMerchantBindings, getStoredUser } from '../utils/auth'

type MailRow = {
  id: string
  type: string
  typeText: string
  title: string
  summary: string
  detail: string
  relatedId: number
  relatedNo: string
  targetPath: string
  statusCode?: string
  riskLevel?: string
  statusText: string
  tone: 'success' | 'warning' | 'danger' | 'primary' | 'info' | ''
  occurredAt: string
}

const router = useRouter()
const afterSaleData = ref<typeof afterSales>([])
const reviewData = ref<typeof reviews>([])
const mailData = ref<MailRow[]>([])
const loading = ref(false)
const mailDetailVisible = ref(false)
const selectedMail = ref<MailRow | null>(null)
const readMailIds = ref<string[]>([])
const deletedMailIds = ref<string[]>([])

onMounted(async () => {
  loadMailState()
  loading.value = true
  try {
    const merchantAccounts = boundMerchantAccounts()
    const [loadedAfterSales, loadedReviews, loadedMails] = await Promise.all([
      Promise.all(merchantAccounts.map((accountNo) => loadTwentyMallMerchantAfterSales(accountNo))),
      Promise.all(merchantAccounts.map((accountNo) => loadTwentyMallMerchantReviews(accountNo))),
      Promise.all(merchantAccounts.map((accountNo) => loadTwentyMallMerchantNotifications(accountNo)))
    ])
    afterSaleData.value = loadedAfterSales.flat().slice(0, 8) as typeof afterSales
    reviewData.value = loadedReviews.flat() as typeof reviews
    mailData.value = dedupeMails(loadedMails.flat() as MailRow[])
  } catch {
    afterSaleData.value = []
    reviewData.value = []
    mailData.value = []
    ElMessage({ type: 'error', message: '工作台数据读取失败，请确认后端服务和数据库已启动' })
  }
  loading.value = false
})

const pendingAfterSaleCount = computed(() => afterSaleData.value.filter((item) => !['COMPLETED', 'CLOSED', 'REJECTED'].includes(item.status)).length)
const unreadMailCount = computed(() => visibleMailData.value.filter((item) => !isMailRead(item.id)).length)
const highRiskReviewCount = computed(() => reviewData.value.filter((item) => item.riskLevel === 'HIGH').length)
const visibleMailData = computed(() => mailData.value.filter((item) => !deletedMailIds.value.includes(item.id)).slice(0, 8))

const metrics = computed(() => [
  { label: '待处理售后', value: String(pendingAfterSaleCount.value), trend: `共 ${afterSaleData.value.length} 单`, tone: 'warning' },
  { label: '未读邮件', value: String(unreadMailCount.value), trend: `共 ${visibleMailData.value.length} 条`, tone: unreadMailCount.value ? 'primary' : 'success' },
  { label: '高风险评价', value: String(highRiskReviewCount.value), trend: `共 ${reviewData.value.length} 条`, tone: highRiskReviewCount.value ? 'danger' : 'success' }
])

function tagType(tone: string) {
  return tone === 'danger' ? 'danger' : tone === 'warning' ? 'warning' : tone === 'success' ? 'success' : 'primary'
}

function reasonText(value: string) {
  const map: Record<string, string> = {
    PRODUCT_QUALITY: '商品质量问题',
    LOGISTICS_DELAY: '物流延迟',
    WRONG_GOODS: '商品错发',
    SIZE_MISMATCH: '尺码不符',
    NOT_AS_DESCRIBED: '描述不符',
    OTHER: '其他原因'
  }
  return map[value] || value
}

function afterSaleStatusText(value: string) {
  const map: Record<string, string> = {
    PROCESSING: '处理中',
    PENDING_REVIEW: '待审核',
    APPROVED: '已通过',
    REJECTED: '已拒绝',
    COMPLETED: '已完成',
    CLOSED: '已关闭'
  }
  return map[value] || value
}

function priorityText(value: string) {
  const map: Record<string, string> = {
    HIGH: '高',
    MEDIUM: '中',
    NORMAL: '普通',
    LOW: '低'
  }
  return map[value] || value
}

function displayOrderNo(row: { orderNo?: string; afterSaleNo?: string }) {
  if (row.orderNo) return row.orderNo
  return row.afterSaleNo ? row.afterSaleNo.replace(/^TMAS/, 'TM') : '-'
}

function boundMerchantAccounts() {
  return getMerchantBindings()
    .filter((item) => item.platformCode === 'TWENTY_MALL' && item.accountNo)
    .map((item) => item.accountNo as string)
}

function mailStoragePrefix() {
  return `merchant_service_mail_${currentPrimaryAccountNo()}`
}

function loadMailState() {
  readMailIds.value = readStringList(`${mailStoragePrefix()}_read`)
  deletedMailIds.value = readStringList(`${mailStoragePrefix()}_deleted`)
}

function readStringList(key: string) {
  try {
    const value = JSON.parse(localStorage.getItem(key) || '[]')
    return Array.isArray(value) ? value.filter((item) => typeof item === 'string') : []
  } catch {
    return []
  }
}

function saveMailState() {
  localStorage.setItem(`${mailStoragePrefix()}_read`, JSON.stringify(readMailIds.value))
  localStorage.setItem(`${mailStoragePrefix()}_deleted`, JSON.stringify(deletedMailIds.value))
}

function dedupeMails(rows: MailRow[]) {
  const map = new Map<string, MailRow>()
  rows.forEach((item) => {
    if (item?.id && !map.has(item.id)) {
      map.set(item.id, item)
    }
  })
  return Array.from(map.values())
}

function isMailRead(id: string) {
  return readMailIds.value.includes(id)
}

function markMailRead(id: string) {
  if (!readMailIds.value.includes(id)) {
    readMailIds.value = [...readMailIds.value, id]
    saveMailState()
  }
}

function openMail(item: MailRow) {
  selectedMail.value = item
  mailDetailVisible.value = true
  markMailRead(item.id)
}

function handleMail(item: MailRow) {
  markMailRead(item.id)
  if (item.type === 'REVIEW_DISPUTE') {
    const risk = isReviewDisputeApproved(item) ? 'DELETED' : normalizeReviewRisk(item.riskLevel)
    router.push({ path: '/reviews', query: { risk, tab: risk === 'DELETED' ? 'deleted' : undefined } })
    return
  }
  if (item.type === 'REVIEW') {
    router.push({ path: '/reviews', query: { risk: normalizeReviewRisk(item.riskLevel || item.statusCode) } })
    return
  }
  router.push(item.targetPath || '/dashboard')
}

function normalizeReviewRisk(value?: string) {
  return value && ['HIGH', 'MEDIUM', 'LOW'].includes(value) ? value : '全部'
}

function isReviewDisputeApproved(item: MailRow) {
  return item.statusCode === 'APPROVED' || item.statusText === '已通过' || item.summary.includes('通过异议并删除评价')
}

function handleSelectedMail() {
  if (!selectedMail.value) return
  mailDetailVisible.value = false
  handleMail(selectedMail.value)
}

function deleteMail(item: MailRow) {
  deletedMailIds.value = [...new Set([...deletedMailIds.value, item.id])]
  saveMailState()
  if (selectedMail.value?.id === item.id) {
    selectedMail.value = null
    mailDetailVisible.value = false
  }
  ElMessage({ type: 'success', message: '邮件已删除' })
}

function deleteSelectedMail() {
  if (!selectedMail.value) return
  deleteMail(selectedMail.value)
}

function mailTypeTag(type: string) {
  if (type === 'AFTER_SALE') return 'warning'
  if (type === 'REVIEW') return 'primary'
  if (type === 'REVIEW_DISPUTE') return 'success'
  return 'info'
}

function currentPrimaryAccountNo() {
  const user = getStoredUser<{ username?: string; userId?: number }>()
  return user?.username || String(user?.userId || '13338907681')
}

</script>

<style scoped>
.mail-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 384px;
  overflow: auto;
  padding-right: 4px;
}

.mail-item {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 12px;
  padding: 14px 14px 13px 16px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  transition: border-color 0.15s ease, background 0.15s ease;
}

.mail-item:hover {
  border-color: #93c5fd;
  background: #f8fbff;
}

.mail-item.unread {
  border-color: #bfdbfe;
  background: #f8fbff;
}

.mail-dot {
  position: absolute;
  top: 14px;
  right: 12px;
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: #ef4444;
}

.mail-main {
  min-width: 0;
}

.mail-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding-right: 12px;
}

.mail-head strong {
  min-width: 0;
  color: #0f172a;
  font-size: 15px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mail-head span {
  flex: 0 0 auto;
  color: #94a3b8;
  font-size: 12px;
}

.mail-main p {
  margin: 7px 0 9px;
  color: #475569;
  font-size: 13px;
  line-height: 1.5;
}

.mail-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  color: #64748b;
  font-size: 12px;
}

.mail-actions {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  gap: 4px;
  padding-top: 24px;
}
</style>
