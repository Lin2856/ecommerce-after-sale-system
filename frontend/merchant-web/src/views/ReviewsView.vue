<template>
  <div class="panel">
    <div class="toolbar">
      <el-segmented v-model="risk" :options="riskOptions" />
      <el-button type="primary" @click="batchAnalyze">批量分析</el-button>
    </div>
    <el-table v-loading="loading" :data="filteredReviews">
      <el-table-column prop="platformCode" label="平台" width="100" />
      <el-table-column prop="orderNo" label="订单号" min-width="160" />
      <el-table-column prop="merchantName" label="商家" min-width="150" />
      <el-table-column label="商品" min-width="180">
        <template #default="{ row }">{{ cleanProductName(row.productName || '') }}</template>
      </el-table-column>
      <el-table-column label="星级" width="150">
        <template #default="{ row }">
          <span class="star-rating">{{ starText(row) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="评价内容" min-width="320">
        <template #default="{ row }">
          <div class="review-summary">产品质量：{{ productReviewContent(row) }}</div>
          <div class="review-summary">商家服务：{{ merchantReviewContent(row) }}</div>
        </template>
      </el-table-column>
      <el-table-column label="异议状态" width="110">
        <template #default="{ row }">
          <el-tag v-if="row.deleted" type="danger">已删除</el-tag>
          <el-tag v-else-if="row.disputeStatus" :type="disputeTagType(row.disputeStatus)">{{ row.disputeStatus }}</el-tag>
          <span v-else class="muted-text">未提出</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180">
        <template #default="{ row }">
          <el-button link type="primary" @click="openDetail(row)">详细</el-button>
          <el-button v-if="!row.deleted" link type="warning" :disabled="row.disputeStatus === '待审核'" @click="openDispute(row)">异议</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-dialog v-model="detailVisible" title="评价详情" width="720px">
      <el-descriptions v-if="selectedReview" :column="2" border>
        <el-descriptions-item label="平台">{{ selectedReview.platformCode }}</el-descriptions-item>
        <el-descriptions-item label="订单号">{{ selectedReview.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="商家">{{ selectedReview.merchantName }}</el-descriptions-item>
        <el-descriptions-item label="商品">{{ cleanProductName(selectedReview.productName || '') }}</el-descriptions-item>
        <el-descriptions-item label="产品质量星级">{{ starTextByScore(selectedReview.productScore) }}</el-descriptions-item>
        <el-descriptions-item label="商家服务星级">{{ starTextByScore(selectedReview.serviceScore) }}</el-descriptions-item>
        <el-descriptions-item label="情感">{{ sentimentText(selectedReview.sentiment) }}</el-descriptions-item>
        <el-descriptions-item label="风险">{{ riskText(selectedReview.riskLevel) }}</el-descriptions-item>
        <el-descriptions-item label="评价状态">{{ selectedReview.deleted ? '已删除' : '正常展示' }}</el-descriptions-item>
        <el-descriptions-item label="关键词">{{ selectedReview.keywords }}</el-descriptions-item>
        <el-descriptions-item label="产品质量评价" :span="2">{{ productReviewContent(selectedReview) }}</el-descriptions-item>
        <el-descriptions-item label="商家服务评价" :span="2">{{ merchantReviewContent(selectedReview) }}</el-descriptions-item>
        <el-descriptions-item label="异议状态">{{ selectedReview.disputeStatus || '未提出' }}</el-descriptions-item>
        <el-descriptions-item label="审核说明">{{ selectedReview.disputeAdminNote || '-' }}</el-descriptions-item>
        <el-descriptions-item label="异议原因" :span="2">{{ selectedReview.disputeReason || '-' }}</el-descriptions-item>
        <el-descriptions-item label="分析摘要" :span="2">{{ selectedReview.analysisSummary }}</el-descriptions-item>
        <el-descriptions-item label="处理建议" :span="2">{{ selectedReview.suggestion }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button v-if="selectedReview && !selectedReview.deleted" type="warning" :disabled="selectedReview.disputeStatus === '待审核'" @click="openDispute(selectedReview)">提出异议</el-button>
        <el-button v-if="selectedReview" type="primary" @click="analyzeSelectedReview">AI 分析</el-button>
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
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { loadTwentyMallMerchantReviews, submitTwentyMallReviewDispute } from '../api'
import { ElMessage } from 'element-plus'
import { getMerchantBindings } from '../utils/auth'

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

function batchAnalyze() {
  reviewData.value = reviewData.value.map((item) => analyzeReviewItem(item))
  ElMessage({ type: 'success', message: '已完成当前评价列表分析' })
}

function analyzeReview(reviewId: number) {
  reviewData.value = reviewData.value.map((item) => (item.id === reviewId ? analyzeReviewItem(item) : item))
  if (selectedReview.value?.id === reviewId) {
    selectedReview.value = reviewData.value.find((item) => item.id === reviewId) || null
  }
  ElMessage({ type: 'success', message: '已生成该评价的分析结果' })
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
    await submitTwentyMallReviewDispute(disputeReview.value.id, disputeReview.value.accountNo, reason)
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

function analyzeSelectedReview() {
  if (!selectedReview.value) return
  analyzeReview(selectedReview.value.id)
}

function analyzeReviewItem(item: ReviewRow) {
  const negative = item.content.includes('划痕') || item.content.includes('问题') || item.productScore <= 2
  const logistics = item.content.includes('物流')
  const serviceGood = item.content.includes('客服') || item.serviceScore >= 4
  const keywords = [
    item.content.includes('划痕') ? '商品划痕' : '',
    logistics ? '物流体验' : '',
    serviceGood ? '客服服务' : '',
    negative ? '质量风险' : '正向反馈'
  ].filter(Boolean).join('、')

  return {
    ...item,
    sentiment: negative ? 'NEGATIVE' : 'POSITIVE',
    riskLevel: negative ? 'MEDIUM' : 'LOW',
    keywords,
    analysisSummary: negative
      ? '评价包含商品质量或体验风险，需要客服主动跟进。'
      : '评价整体正向，可用于服务质量复盘和优秀案例沉淀。',
    suggestion: negative
      ? '建议在 24 小时内联系用户，核实问题并提供换货、补偿或质检处理方案。'
      : '建议标记为低风险评价，后续用于客服服务质量样本。'
  }
}

async function loadBoundTwentyMallReviews() {
  const twentyMallBindings = getMerchantBindings().filter((item) => item.platformCode === 'TWENTY_MALL' && item.accountNo)
  if (!twentyMallBindings.length) {
    return []
  }
  const result = await Promise.all(twentyMallBindings.map(async (binding) => {
    try {
      const list = await loadTwentyMallMerchantReviews(binding.accountNo as string) as ReviewRow[]
      return list.map((item) => ({ ...item, accountNo: binding.accountNo as string }))
    } catch {
      return []
    }
  }))
  return result.flat()
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

function disputeTagType(status: string) {
  if (status === '待审核') return 'warning'
  if (status === '已通过') return 'success'
  if (status === '已拒绝') return 'danger'
  return 'info'
}

function cleanProductName(productName: string) {
  return productName.replace(/^20商城\s*/, '').trim()
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
.star-rating {
  color: #f59e0b;
  font-size: 18px;
  letter-spacing: 0;
  white-space: nowrap;
}

.review-summary {
  line-height: 1.6;
  color: #344054;
}
</style>
