<template>
  <div class="review-page">
    <section class="review-hero">
      <div>
        <span class="page-kicker">评价分析</span>
        <h1>用户评价洞察</h1>
        <p>聚合自建商城订单评价，识别风险反馈、服务体验和可复盘的优质评价。</p>
      </div>
      <el-button class="hero-action" type="primary" :loading="storeAiAnalyzing" @click="openStoreReviewAnalysis">查看店铺评价 AI 分析</el-button>
    </section>

    <section class="review-metrics">
      <button
        v-for="item in metricCards"
        :key="item.value"
        type="button"
        class="metric-card review-metric"
        :class="{ active: risk === item.value }"
        @click="risk = item.value"
      >
        <span>{{ item.label }}</span>
        <strong>{{ item.count }}</strong>
        <em>{{ item.description }}</em>
      </button>
    </section>

    <div class="review-toolbar">
      <el-segmented v-model="risk" :options="riskOptions" />
      <span>{{ filteredReviews.length }} 条评价</span>
    </div>

    <section v-loading="loading" class="review-list">
      <article v-for="row in filteredReviews" :key="row.id" class="review-card">
        <div class="review-card-main">
          <div class="review-card-head">
            <div>
              <div class="review-title-line">
                <strong>{{ cleanProductName(row.productName || '') }}</strong>
                <el-tag size="small" :type="riskTagType(row.riskLevel)">{{ row.deleted ? '已删除' : riskText(row.riskLevel) }}</el-tag>
              </div>
              <div class="review-meta">
                <span>{{ platformNameByCode(row.platformCode) }}</span>
                <span>{{ row.orderNo }}</span>
                <span>{{ row.merchantName }}</span>
              </div>
            </div>
            <div class="review-score-block">
              <span class="star-rating">{{ starText(row) }}</span>
              <em>综合星级</em>
            </div>
          </div>

          <div class="review-content-grid">
            <div>
              <span>产品质量</span>
              <p>{{ productReviewContent(row) }}</p>
            </div>
            <div>
              <span>商家服务</span>
              <p>{{ merchantReviewContent(row) }}</p>
            </div>
          </div>
        </div>

        <aside class="review-side">
          <div class="status-line">
            <span>异议状态</span>
            <el-tag v-if="row.deleted" size="small" type="danger">已删除</el-tag>
            <el-tag v-else-if="row.disputeStatus" size="small" :type="disputeTagType(row.disputeStatus)">{{ row.disputeStatus }}</el-tag>
            <em v-else>未提出</em>
          </div>
          <div class="review-actions">
            <el-button type="primary" plain @click="openDetail(row)">查看详情</el-button>
            <el-button v-if="!row.deleted" type="warning" plain :disabled="row.disputeStatus === '待审核'" @click="openDispute(row)">提出异议</el-button>
          </div>
        </aside>
      </article>
      <el-empty v-if="!loading && filteredReviews.length === 0" description="暂无符合条件的评价" />
    </section>

    <el-dialog v-model="detailVisible" title="评价详情" width="780px" class="review-detail-dialog">
      <el-descriptions v-if="selectedReview" :column="2" border>
        <el-descriptions-item label="平台">{{ platformNameByCode(selectedReview.platformCode) }}</el-descriptions-item>
        <el-descriptions-item label="订单号">{{ selectedReview.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="商家">{{ selectedReview.merchantName }}</el-descriptions-item>
        <el-descriptions-item label="商品">{{ cleanProductName(selectedReview.productName || '') }}</el-descriptions-item>
        <el-descriptions-item label="产品质量星级">{{ starTextByScore(selectedReview.productScore) }}</el-descriptions-item>
        <el-descriptions-item label="商家服务星级">{{ starTextByScore(selectedReview.serviceScore) }}</el-descriptions-item>
        <el-descriptions-item label="风险">{{ riskText(selectedReview.riskLevel) }}</el-descriptions-item>
        <el-descriptions-item label="评价状态">{{ selectedReview.deleted ? '已删除' : '正常展示' }}</el-descriptions-item>
        <el-descriptions-item label="关键词">{{ selectedReview.keywords }}</el-descriptions-item>
        <el-descriptions-item label="产品质量评价" :span="2">{{ productReviewContent(selectedReview) }}</el-descriptions-item>
        <el-descriptions-item label="商家服务评价" :span="2">{{ merchantReviewContent(selectedReview) }}</el-descriptions-item>
        <el-descriptions-item label="异议状态">{{ selectedReview.disputeStatus || '未提出' }}</el-descriptions-item>
        <el-descriptions-item label="审核说明">{{ selectedReview.disputeAdminNote || '-' }}</el-descriptions-item>
        <el-descriptions-item label="异议原因" :span="2">{{ selectedReview.disputeReason || '-' }}</el-descriptions-item>
        <template v-if="selectedReview.aiAnalyzed">
          <el-descriptions-item label="情感" :span="2">{{ selectedReview.aiSentiment }}</el-descriptions-item>
          <el-descriptions-item label="分析摘要" :span="2">{{ selectedReview.aiAnalysisSummary }}</el-descriptions-item>
          <el-descriptions-item label="处理建议" :span="2">{{ selectedReview.aiSuggestion }}</el-descriptions-item>
        </template>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button v-if="selectedReview && !selectedReview.deleted" type="warning" :disabled="selectedReview.disputeStatus === '待审核'" @click="openDispute(selectedReview)">提出异议</el-button>
        <el-button v-if="selectedReview" type="primary" :loading="aiAnalyzing" @click="analyzeSelectedReview">AI 分析</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="disputeVisible" title="提交评价异议" width="560px">
      <el-form label-width="88px">
        <el-form-item label="订单号">
          <el-input :model-value="disputeReview?.orderNo || ''" disabled />
        </el-form-item>
        <el-form-item label="商品">
          <el-input :model-value="cleanProductName(disputeReview?.productName || '')" disabled />
        </el-form-item>
        <el-form-item label="异议原因">
          <el-input
            v-model="disputeReason"
            type="textarea"
            :rows="5"
            placeholder="请说明评价存在的问题，例如评价内容与订单不符、包含不实描述、恶意差评或已经协商解决等"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="disputeVisible = false">取消</el-button>
        <el-button type="primary" :loading="submittingDispute" @click="submitDispute">提交异议</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="storeAnalysisVisible" width="960px" class="store-analysis-dialog" align-center>
      <template #header>
        <div class="store-analysis-header">
          <span>店铺评价 AI 分析</span>
          <em>{{ storeAnalysisSubtitle }}</em>
        </div>
      </template>
      <div class="store-analysis-controls">
        <el-segmented
          v-model="storeAnalysisScope"
          :options="storeAnalysisScopeOptions"
          @change="handleStoreAnalysisScopeChange"
        />
        <el-select
          v-if="storeAnalysisScope === 'MERCHANT'"
          v-model="selectedStoreAnalysisMerchantKey"
          class="store-analysis-select"
          placeholder="选择二级商家"
          filterable
          @change="handleStoreAnalysisMerchantChange"
        >
          <el-option
            v-for="item in storeAnalysisMerchantOptions"
            :key="item.key"
            :label="item.label"
            :value="item.key"
          />
        </el-select>
      </div>
      <div v-if="storeAnalysisResult" class="store-analysis-panel">
        <div class="store-analysis-summary">
          <div>
            <span>总体情感</span>
            <strong>{{ storeAnalysisResult.sentiment }}</strong>
          </div>
          <div>
            <span>{{ storeAnalysisScope === 'PRIMARY' ? '涉及店铺' : '当前商家' }}</span>
            <div class="merchant-chip-list">
              <em v-for="name in currentStoreAnalysisMerchantNames" :key="name">{{ name }}</em>
            </div>
          </div>
        </div>
        <section>
          <h3>评价摘要</h3>
          <p>{{ storeAnalysisResult.analysisSummary }}</p>
        </section>
        <section>
          <h3>处理建议</h3>
          <p>{{ storeAnalysisResult.suggestion }}</p>
        </section>
      </div>
      <el-empty v-else description="暂无店铺评价分析结果" />
      <template #footer>
        <el-button @click="storeAnalysisVisible = false">关闭</el-button>
        <el-button type="primary" :loading="storeAiAnalyzing" @click="runStoreReviewAnalysis">重新分析</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { loadSelfBuiltMerchantReviews, recordAiCallLog, submitSelfBuiltReviewDispute } from '../api'
import { ElMessage } from 'element-plus'
import { getMerchantBindings, getStoredUser, type MerchantPlatformBinding } from '../utils/auth'

type ReviewRow = {
  id: number
  platformCode: string
  productScore: number
  serviceScore: number
  content: string
  sentiment: string
  riskLevel: string
  keywords: string
  analysisSummary: string
  suggestion: string
  aiAnalyzed?: boolean
  aiSentiment?: string
  aiAnalysisSummary?: string
  aiSuggestion?: string
  orderNo?: string
  productName?: string
  merchantName?: string
  disputeId?: number | null
  disputeStatus?: string
  disputeReason?: string
  disputeAdminNote?: string
  accountNo?: string
  deleted?: boolean
}

const route = useRoute()
const risk = ref(normalizeRiskRoute(route.query.risk, route.query.tab))
const riskOptions = [
  { label: '全部', value: '全部' },
  { label: '高风险', value: 'HIGH' },
  { label: '中风险', value: 'MEDIUM' },
  { label: '低风险', value: 'LOW' },
  { label: '已删除', value: 'DELETED' }
]
const reviewData = ref<ReviewRow[]>([])
const loading = ref(false)
const detailVisible = ref(false)
const selectedReview = ref<ReviewRow | null>(null)
const disputeVisible = ref(false)
const disputeReview = ref<ReviewRow | null>(null)
const disputeReason = ref('')
const submittingDispute = ref(false)
const aiAnalyzing = ref(false)
const storeAiAnalyzing = ref(false)
const storeAnalysisVisible = ref(false)
const storeAnalysisScope = ref<'PRIMARY' | 'MERCHANT'>('PRIMARY')
const selectedStoreAnalysisMerchantKey = ref('')
const storeAnalysisScopeOptions = [
  { label: '一级账号整体', value: 'PRIMARY' },
  { label: '单个二级商家', value: 'MERCHANT' }
]
const storeAnalysisResult = ref<{
  sentiment: string
  analysisSummary: string
  suggestion: string
} | null>(null)

onMounted(async () => {
  loading.value = true
  reviewData.value = await loadBoundTwentyMallReviews()
  loading.value = false
})

watch(() => [route.query.risk, route.query.tab], ([riskValue, tabValue]) => {
  risk.value = normalizeRiskRoute(riskValue, tabValue)
})

const filteredReviews = computed(() => {
  if (risk.value === '全部') {
    return reviewData.value.filter((item) => !item.deleted)
  }
  if (risk.value === 'DELETED') {
    return reviewData.value.filter((item) => item.deleted)
  }
  return reviewData.value.filter((item) => !item.deleted && item.riskLevel === risk.value)
})

const metricCards = computed(() => {
  const activeReviews = reviewData.value.filter((item) => !item.deleted)
  return [
    { label: '全部评价', value: '全部', count: activeReviews.length, description: '当前展示中的评价' },
    { label: '高风险', value: 'HIGH', count: activeReviews.filter((item) => item.riskLevel === 'HIGH').length, description: '需要优先跟进' },
    { label: '中风险', value: 'MEDIUM', count: activeReviews.filter((item) => item.riskLevel === 'MEDIUM').length, description: '建议主动回访' },
    { label: '低风险', value: 'LOW', count: activeReviews.filter((item) => item.riskLevel === 'LOW').length, description: '可沉淀复盘' },
    { label: '已删除', value: 'DELETED', count: reviewData.value.filter((item) => item.deleted).length, description: '管理员已处理' }
  ]
})

const activeReviews = computed(() => reviewData.value.filter((item) => !item.deleted))
const storeAnalysisMerchantOptions = computed(() => {
  const map = new Map<string, { key: string; label: string; accountNo: string; platformCode: string; merchantName: string }>()
  activeReviews.value.forEach((item) => {
    const accountNo = item.accountNo || ''
    const platformCode = item.platformCode || 'TWENTY_MALL'
    const merchantName = item.merchantName || `${platformNameByCode(platformCode)}商家`
    const key = `${platformCode}:${accountNo || merchantName}`
    if (!map.has(key)) {
      map.set(key, {
        key,
        label: accountNo ? `${merchantName}（${accountNo}）` : merchantName,
        accountNo,
        platformCode,
        merchantName
      })
    }
  })
  return Array.from(map.values())
})
const storeAnalysisMerchantNames = computed(() => {
  const names = Array.from(new Set(activeReviews.value.map((item) => item.merchantName).filter(Boolean))) as string[]
  return names.length ? names : ['当前一级账号']
})
const selectedStoreAnalysisMerchant = computed(() => (
  storeAnalysisMerchantOptions.value.find((item) => item.key === selectedStoreAnalysisMerchantKey.value)
  || storeAnalysisMerchantOptions.value[0]
  || null
))
const currentStoreAnalysisReviews = computed(() => {
  if (storeAnalysisScope.value === 'PRIMARY') {
    return activeReviews.value
  }
  const selected = selectedStoreAnalysisMerchant.value
  if (!selected) {
    return []
  }
  return activeReviews.value.filter((item) => {
    const itemKey = `${item.platformCode || 'TWENTY_MALL'}:${item.accountNo || item.merchantName || ''}`
    return itemKey === selected.key
  })
})
const currentStoreAnalysisMerchantNames = computed(() => {
  if (storeAnalysisScope.value === 'PRIMARY') {
    return storeAnalysisMerchantNames.value
  }
  return selectedStoreAnalysisMerchant.value ? [selectedStoreAnalysisMerchant.value.label] : ['请选择二级商家']
})
const storeAnalysisMerchantText = computed(() => currentStoreAnalysisMerchantNames.value.join('、'))
const storeAnalysisSubtitle = computed(() => (
  storeAnalysisScope.value === 'PRIMARY'
    ? '基于当前一级账号下全部二级商家的未删除评价生成'
    : '基于选中二级商家的未删除评价生成'
))

async function openStoreReviewAnalysis() {
  if (storeAnalysisScope.value === 'MERCHANT' && !selectedStoreAnalysisMerchantKey.value && storeAnalysisMerchantOptions.value.length) {
    selectedStoreAnalysisMerchantKey.value = storeAnalysisMerchantOptions.value[0].key
  }
  storeAnalysisVisible.value = true
  await runStoreReviewAnalysis()
}

async function runStoreReviewAnalysis() {
  const targets = currentStoreAnalysisReviews.value
  if (!targets.length) {
    ElMessage({ type: 'warning', message: storeAnalysisScope.value === 'PRIMARY' ? '当前一级账号暂无未删除评价可分析' : '当前二级商家暂无未删除评价可分析' })
    return
  }
  storeAiAnalyzing.value = true
  try {
    storeAnalysisResult.value = await requestStoreReviewAnalysis(targets)
    storeAnalysisVisible.value = true
  } catch {
    ElMessage({ type: 'error', message: '店铺评价 AI 分析失败，请确认 AI 服务已启动' })
  } finally {
    storeAiAnalyzing.value = false
  }
}

async function handleStoreAnalysisScopeChange() {
  storeAnalysisResult.value = null
  if (storeAnalysisScope.value === 'MERCHANT' && !selectedStoreAnalysisMerchantKey.value && storeAnalysisMerchantOptions.value.length) {
    selectedStoreAnalysisMerchantKey.value = storeAnalysisMerchantOptions.value[0].key
  }
  await runStoreReviewAnalysis()
}

async function handleStoreAnalysisMerchantChange() {
  storeAnalysisResult.value = null
  await runStoreReviewAnalysis()
}

async function analyzeReview(reviewId: number, showMessage = true) {
  const review = reviewData.value.find((item) => item.id === reviewId)
  if (!review) return
  const analysis = await requestAiReviewAnalysis(review)
  reviewData.value = reviewData.value.map((item) => (item.id === reviewId ? {
    ...item,
    aiAnalyzed: true,
    aiSentiment: analysis.sentiment,
    aiAnalysisSummary: analysis.analysisSummary,
    aiSuggestion: analysis.suggestion
  } : item))
  if (selectedReview.value?.id === reviewId) {
    selectedReview.value = reviewData.value.find((item) => item.id === reviewId) || null
  }
  if (showMessage) {
    ElMessage({ type: 'success', message: '已生成该评价的 AI 分析结果' })
  }
}

function openDetail(row: ReviewRow) {
  selectedReview.value = row
  detailVisible.value = true
}

function openDispute(row: ReviewRow) {
  if (row.deleted) {
    ElMessage({ type: 'warning', message: '已删除的评价不能再次提出异议' })
    return
  }
  disputeReview.value = row
  disputeReason.value = row.disputeReason || ''
  disputeVisible.value = true
}

async function submitDispute() {
  if (!disputeReview.value) return
  const reason = disputeReason.value.trim()
  if (!reason) {
    ElMessage({ type: 'warning', message: '请填写异议原因' })
    return
  }
  if (!disputeReview.value.accountNo) {
    ElMessage({ type: 'error', message: '未找到当前评价对应的商家账号' })
    return
  }
  submittingDispute.value = true
  try {
    await submitSelfBuiltReviewDispute(
      disputeReview.value.id,
      disputeReview.value.accountNo,
      reason,
      disputeReview.value.platformCode || 'TWENTY_MALL'
    )
    ElMessage({ type: 'success', message: '评价异议已提交，等待管理员审核' })
    disputeVisible.value = false
    reviewData.value = await loadBoundTwentyMallReviews()
    selectedReview.value = reviewData.value.find((item) => item.id === disputeReview.value?.id) || selectedReview.value
  } catch (error) {
    ElMessage({ type: 'error', message: error instanceof Error ? error.message : '提交异议失败' })
  } finally {
    submittingDispute.value = false
  }
}

async function analyzeSelectedReview() {
  if (!selectedReview.value) return
  aiAnalyzing.value = true
  try {
    await analyzeReview(selectedReview.value.id)
  } catch {
    ElMessage({ type: 'error', message: 'AI 分析失败，请确认 AI 服务已启动' })
  } finally {
    aiAnalyzing.value = false
  }
}

async function requestAiReviewAnalysis(item: ReviewRow) {
  const startedAt = Date.now()
  const requestBody = {
    platformName: item.platformCode,
    orderNo: item.orderNo,
    merchantName: item.merchantName,
    productName: cleanProductName(item.productName || ''),
    productScore: item.productScore,
    serviceScore: item.serviceScore,
    productReview: productReviewContent(item),
    merchantReview: merchantReviewContent(item)
  }
  const response = await fetch('http://localhost:9000/api/ai/review-analysis', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody)
  })
  if (!response.ok) {
    recordAiCallLog({
      businessType: 'REVIEW',
      businessId: item.id,
      taskType: 'REVIEW_ANALYSIS',
      requestText: JSON.stringify(requestBody),
      success: false,
      errorMessage: 'AI review analysis failed',
      latencyMs: Date.now() - startedAt
    })
    throw new Error('AI review analysis failed')
  }
  const payload = await response.json()
  recordAiCallLog({
    businessType: 'REVIEW',
    businessId: item.id,
    taskType: 'REVIEW_ANALYSIS',
    requestText: JSON.stringify(requestBody),
    responseText: JSON.stringify(payload),
    success: true,
    latencyMs: Date.now() - startedAt
  })
  return {
    sentiment: payload.sentiment || '中性',
    analysisSummary: payload.analysisSummary || '暂无分析摘要',
    suggestion: payload.suggestion || '暂无处理建议'
  }
}

async function requestStoreReviewAnalysis(items: ReviewRow[]) {
  const platformNames = Array.from(new Set(items.map((item) => platformNameByCode(item.platformCode)).filter(Boolean)))
  const startedAt = Date.now()
  const requestBody = {
    platformName: platformNames.join('、') || '自建商城',
    merchantName: storeAnalysisMerchantText.value,
    reviews: items.map((item) => ({
      orderNo: item.orderNo,
      merchantName: item.merchantName,
      productName: cleanProductName(item.productName || ''),
      productScore: item.productScore,
      serviceScore: item.serviceScore,
      productReview: productReviewContent(item),
      merchantReview: merchantReviewContent(item),
      riskLevel: riskText(item.riskLevel)
    }))
  }
  const response = await fetch('http://localhost:9000/api/ai/store-review-analysis', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody)
  })
  if (!response.ok) {
    recordAiCallLog({
      businessType: 'STORE_REVIEW',
      taskType: 'STORE_REVIEW_ANALYSIS',
      requestText: JSON.stringify(requestBody),
      success: false,
      errorMessage: '店铺评价 AI 分析失败',
      latencyMs: Date.now() - startedAt
    })
    throw new Error('店铺评价 AI 分析失败')
  }
  const payload = await response.json()
  recordAiCallLog({
    businessType: 'STORE_REVIEW',
    taskType: 'STORE_REVIEW_ANALYSIS',
    requestText: JSON.stringify(requestBody),
    responseText: JSON.stringify(payload),
    success: true,
    latencyMs: Date.now() - startedAt
  })
  return {
    sentiment: payload.sentiment || '中性',
    analysisSummary: payload.analysisSummary || payload.analysis_summary || '暂无评价摘要',
    suggestion: payload.suggestion || '暂无处理建议'
  }
}

async function loadBoundTwentyMallReviews() {
  const bindings = await loadCurrentSelfBuiltBindings()
  if (!bindings.length) {
    return []
  }
  const result = await Promise.all(bindings.map(async (binding) => {
    try {
      const list = await loadSelfBuiltMerchantReviews(binding.accountNo as string, binding.platformCode) as ReviewRow[]
      return list.map((item) => ({
        ...item,
        platformCode: item.platformCode || binding.platformCode,
        accountNo: binding.accountNo as string
      }))
    } catch {
      return []
    }
  }))
  return result.flat()
}

async function loadCurrentSelfBuiltBindings() {
  const databaseBindings = await loadDatabaseSelfBuiltBindings()
  const source = databaseBindings.length ? databaseBindings : getMerchantBindings()
  return source.filter((item) => (
    (item.platformCode === 'TWENTY_MALL' || item.platformCode === 'YUEGOU_MARKET') && item.accountNo
  ))
}

async function loadDatabaseSelfBuiltBindings() {
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/primary/bindings?primaryAccountNo=${encodeURIComponent(currentPrimaryAccountNo())}&primaryAccountType=MERCHANT&secondaryAccountRole=MERCHANT`)
    const payload = await response.json()
    if (payload.code !== '200') {
      return []
    }
    return (payload.data || []).filter((item: { bindStatus?: string }) => item.bindStatus === '已绑定').map((item: {
      platformCode?: string
      platformName?: string
      secondaryAccountNo: string
      secondaryDisplayName?: string
      boundAt?: string
    }) => {
      const platformCode = item.platformCode || platformCodeByName(item.platformName)
      const platformName = item.platformName || platformNameByCode(platformCode)
      return {
        id: Number(item.secondaryAccountNo) || Date.now(),
        platformCode,
        platformName,
        authStatus: 'ACTIVE',
        externalShopId: `${platformCode}_SHOP_${item.secondaryAccountNo}`,
        shopName: item.secondaryDisplayName || `${platformName}店铺（${item.secondaryAccountNo}）`,
        sellerNick: item.secondaryDisplayName || `${platformName}店铺（${item.secondaryAccountNo}）`,
        accountNo: item.secondaryAccountNo,
        lastSyncedAt: item.boundAt
      }
    }) as MerchantPlatformBinding[]
  } catch {
    return []
  }
}

function currentPrimaryAccountNo() {
  const user = getStoredUser<{ username?: string; userId?: number }>()
  return user?.username || String(user?.userId || '13338907681')
}

function sentimentText(value: string) {
  const map: Record<string, string> = {
    POSITIVE: '正向',
    NEGATIVE: '负向',
    NEUTRAL: '中性',
    MIXED: '混合'
  }
  return map[value] || value
}

function riskText(value: string) {
  const map: Record<string, string> = {
    HIGH: '高风险',
    MEDIUM: '中风险',
    LOW: '低风险',
    NONE: '无风险'
  }
  return map[value] || value
}

function riskTagType(value: string) {
  if (value === 'HIGH') return 'danger'
  if (value === 'MEDIUM') return 'warning'
  if (value === 'LOW') return 'success'
  return 'info'
}

function disputeTagType(status: string) {
  if (status === '待审核') return 'warning'
  if (status === '已通过') return 'success'
  if (status === '已拒绝') return 'danger'
  return 'info'
}

function cleanProductName(productName: string) {
  return productName.replace(/^(万象商城|悦购集市)\s*/, '').trim()
}

function platformNameByCode(platformCode = 'TWENTY_MALL') {
  return platformCode === 'YUEGOU_MARKET' ? '悦购集市' : '万象商城'
}

function platformCodeByName(platformName = '') {
  return platformName === '悦购集市' ? 'YUEGOU_MARKET' : 'TWENTY_MALL'
}

function starText(row: ReviewRow) {
  const score = Math.round(((row.productScore || 0) + (row.serviceScore || 0)) / 2)
  return starTextByScore(score)
}

function starTextByScore(score: number) {
  const normalized = Math.max(0, Math.min(5, score))
  return '★'.repeat(normalized) + '☆'.repeat(5 - normalized)
}

function productReviewContent(row: ReviewRow) {
  return splitReviewContent(row.content).product || row.content || '-'
}

function merchantReviewContent(row: ReviewRow) {
  return splitReviewContent(row.content).merchant || row.content || '-'
}

function splitReviewContent(content: string) {
  const productMatch = content.match(/产品质量评价：([\s\S]*?)(?:\n商家服务评价：|$)/)
  const merchantMatch = content.match(/商家服务评价：([\s\S]*)$/)
  return {
    product: productMatch?.[1]?.trim() || '',
    merchant: merchantMatch?.[1]?.trim() || ''
  }
}

function normalizeRiskQuery(value: unknown) {
  return typeof value === 'string' && ['全部', 'HIGH', 'MEDIUM', 'LOW', 'DELETED'].includes(value) ? value : '全部'
}

function normalizeRiskRoute(riskValue: unknown, tabValue: unknown) {
  if (tabValue === 'deleted') return 'DELETED'
  return normalizeRiskQuery(riskValue)
}
</script>

<style scoped>
.review-page {
  display: grid;
  gap: 18px;
}

.review-hero {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 24px 28px;
  overflow: hidden;
  border: 1px solid #dce7f5;
  border-radius: 8px;
  background:
    linear-gradient(135deg, rgba(37, 99, 235, 0.1), rgba(255, 255, 255, 0) 42%),
    linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 14px 34px rgba(15, 23, 42, 0.06);
}

.page-kicker {
  display: inline-flex;
  margin-bottom: 8px;
  color: #2563eb;
  font-size: 13px;
  font-weight: 800;
}

.review-hero h1 {
  margin: 0;
  color: #0f172a;
  font-size: 28px;
  font-weight: 900;
  letter-spacing: 0;
}

.review-hero p {
  margin: 8px 0 0;
  color: #64748b;
  font-size: 14px;
}

.hero-action {
  min-width: 128px;
  height: 42px;
  border-radius: 8px;
  font-weight: 800;
}

.review-metrics {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 12px;
}

.review-metric {
  min-height: 108px;
  padding: 16px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
  text-align: left;
  cursor: pointer;
  transition: border-color 0.18s ease, box-shadow 0.18s ease, transform 0.18s ease;
}

.review-metric:hover,
.review-metric.active {
  border-color: #60a5fa;
  box-shadow: 0 14px 30px rgba(37, 99, 235, 0.1);
  transform: translateY(-1px);
}

.review-metric span,
.review-metric em {
  display: block;
  color: #64748b;
  font-style: normal;
}

.review-metric span {
  font-size: 13px;
  font-weight: 800;
}

.review-metric strong {
  display: block;
  margin: 8px 0 6px;
  color: #0f172a;
  font-size: 28px;
  line-height: 1;
}

.review-metric em {
  font-size: 12px;
}

.review-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 16px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
}

.review-toolbar span {
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
}

.review-list {
  display: grid;
  gap: 14px;
  min-height: 220px;
}

.review-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 220px;
  gap: 18px;
  padding: 18px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
  box-shadow: 0 10px 26px rgba(15, 23, 42, 0.04);
}

.review-card-head,
.review-title-line,
.review-meta,
.status-line,
.review-actions {
  display: flex;
  align-items: center;
}

.review-card-head {
  justify-content: space-between;
  gap: 18px;
}

.review-title-line {
  gap: 10px;
}

.review-title-line strong {
  color: #0f172a;
  font-size: 18px;
  font-weight: 900;
}

.review-meta {
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 8px;
}

.review-meta span {
  padding: 4px 8px;
  border-radius: 6px;
  background: #f1f5f9;
  color: #64748b;
  font-size: 12px;
  font-weight: 700;
}

.review-score-block {
  flex-shrink: 0;
  text-align: right;
}

.star-rating {
  color: #f59e0b;
  font-size: 18px;
  letter-spacing: 0;
  white-space: nowrap;
}

.review-score-block em {
  display: block;
  margin-top: 4px;
  color: #94a3b8;
  font-size: 12px;
  font-style: normal;
}

.review-content-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin-top: 16px;
}

.review-content-grid div {
  min-height: 96px;
  padding: 14px;
  border: 1px solid #edf2f7;
  border-radius: 8px;
  background: #f8fafc;
}

.review-content-grid span {
  display: block;
  color: #2563eb;
  font-size: 13px;
  font-weight: 800;
}

.review-content-grid p {
  margin: 8px 0 0;
  color: #334155;
  font-size: 14px;
  line-height: 1.65;
}

.review-side {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 14px;
  padding-left: 18px;
  border-left: 1px solid #edf2f7;
}

.status-line {
  justify-content: space-between;
  gap: 10px;
}

.status-line span {
  color: #64748b;
  font-size: 13px;
  font-weight: 800;
}

.status-line em {
  color: #94a3b8;
  font-size: 13px;
  font-style: normal;
}

.review-actions {
  justify-content: flex-end;
  gap: 8px;
}

.review-actions :deep(.el-button) {
  margin-left: 0;
  border-radius: 8px;
  font-weight: 800;
}

:deep(.review-detail-dialog .el-dialog) {
  border-radius: 8px;
}

:deep(.store-analysis-dialog .el-dialog) {
  max-width: calc(100vw - 72px);
  border-radius: 8px;
  overflow: hidden;
}

.store-analysis-dialog :deep(.el-dialog__header) {
  margin: 0;
  padding: 0;
}

.store-analysis-dialog :deep(.el-dialog__body) {
  max-height: min(68vh, 720px);
  overflow: auto;
  padding: 24px 28px;
  background: #f8fafc;
}

.store-analysis-dialog :deep(.el-dialog__footer) {
  padding: 16px 28px 20px;
  border-top: 1px solid #e2e8f0;
  background: #fff;
}

.store-analysis-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  margin-bottom: 18px;
  padding: 14px 16px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
}

.store-analysis-select {
  width: min(380px, 100%);
}

.store-analysis-header {
  padding: 24px 28px 20px;
  border-bottom: 1px solid #e2e8f0;
  background:
    linear-gradient(135deg, rgba(37, 99, 235, 0.1), rgba(255, 255, 255, 0) 48%),
    #ffffff;
}

.store-analysis-header span,
.store-analysis-header em {
  display: block;
}

.store-analysis-header span {
  color: #0f172a;
  font-size: 24px;
  font-weight: 900;
}

.store-analysis-header em {
  margin-top: 6px;
  color: #64748b;
  font-size: 13px;
  font-style: normal;
  font-weight: 700;
}

.store-analysis-panel {
  display: grid;
  gap: 18px;
}

.store-analysis-summary {
  display: grid;
  grid-template-columns: minmax(280px, 0.7fr) minmax(0, 1.3fr);
  gap: 16px;
}

.store-analysis-summary div,
.store-analysis-panel section {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #f8fafc;
}

.store-analysis-summary div {
  min-height: 112px;
  padding: 18px;
}

.store-analysis-summary span,
.store-analysis-panel h3 {
  display: block;
  margin: 0;
  color: #64748b;
  font-size: 13px;
  font-weight: 800;
}

.store-analysis-summary strong {
  display: block;
  margin-top: 10px;
  color: #0f172a;
  font-size: 22px;
  font-weight: 900;
  line-height: 1.35;
}

.merchant-chip-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 12px;
}

.merchant-chip-list em {
  max-width: 100%;
  padding: 6px 10px;
  border-radius: 8px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 13px;
  font-style: normal;
  font-weight: 800;
}

.store-analysis-panel section {
  padding: 20px 22px;
  background: #ffffff;
}

.store-analysis-panel p {
  margin: 12px 0 0;
  color: #334155;
  font-size: 15px;
  line-height: 1.9;
}

:deep(.el-segmented) {
  --el-segmented-item-selected-bg-color: #2563eb;
  --el-segmented-item-selected-color: #fff;
  border-radius: 8px;
}

@media (max-width: 1200px) {
  .review-metrics {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .review-card {
    grid-template-columns: 1fr;
  }

  .review-side {
    padding-left: 0;
    border-left: 0;
    border-top: 1px solid #edf2f7;
    padding-top: 14px;
  }
}

@media (max-width: 760px) {
  .review-hero,
  .review-toolbar,
  .review-card-head {
    align-items: stretch;
    flex-direction: column;
  }

  .review-metrics,
  .review-content-grid,
  .store-analysis-summary {
    grid-template-columns: 1fr;
  }

  .store-analysis-controls {
    align-items: stretch;
    flex-direction: column;
  }

  .store-analysis-select {
    width: 100%;
  }

  .store-analysis-dialog :deep(.el-dialog) {
    width: calc(100vw - 24px) !important;
  }

  .review-score-block {
    text-align: left;
  }
}
</style>
