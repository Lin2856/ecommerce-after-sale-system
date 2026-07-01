<template>
  <div class="panel">
    <div class="after-sale-summary">
      <button
        v-for="item in summaryCards"
        :key="item.value"
        type="button"
        class="summary-card"
        :class="{ active: status === item.value }"
        @click="status = item.value"
      >
        <span>{{ item.label }}</span>
        <strong>{{ item.count }}</strong>
        <em>{{ item.description }}</em>
      </button>
    </div>
    <div class="toolbar after-sale-toolbar">
      <div class="filter-group">
        <span>筛选售后状态</span>
        <el-segmented v-model="status" :options="filterOptions" />
      </div>
      <el-button v-if="status === '全部' && filteredAfterSales.length" type="primary" @click="writeBackAllAfterSales">批量回写处理结果</el-button>
    </div>
    <div v-loading="loading">
      <el-empty v-if="!groupedAfterSales.length" description="暂无售后单" />
      <section v-for="platform in groupedAfterSales" :key="platform.key" class="platform-group">
        <div class="platform-heading">
          <img :src="platform.icon" :alt="platform.name" />
          <div>
            <strong>{{ platform.name }} - {{ platform.shopNames }}</strong>
            <span>共 {{ platform.total }} 条售后单，待审核 {{ platform.pending }} 条，处理中 {{ platform.processing }} 条，已结束 {{ platform.finished }} 条，争议订单 {{ platform.dispute }} 条</span>
          </div>
        </div>
        <div v-for="shop in platform.shops" :key="shop.key" class="shop-group">
          <div class="shop-heading">
            <div>
              <span>{{ shop.name }}</span>
              <small>待审核 {{ countByFilter(shop.items, 'PENDING_REVIEW') }} 条 · 处理中 {{ countByFilter(shop.items, 'IN_PROGRESS') }} 条 · 已结束 {{ countByFilter(shop.items, 'FINISHED') }} 条 · 争议订单 {{ countByFilter(shop.items, 'DISPUTE_REVIEW') }} 条</small>
            </div>
            <em>{{ shop.items.length }} 条</em>
          </div>
          <el-table :data="shop.items" class="after-sale-table" row-class-name="after-sale-row">
            <el-table-column prop="orderNo" label="订单编号" min-width="170" />
            <el-table-column label="类型" width="140">
              <template #default="{ row }">{{ labelText.afterSaleType[row.afterSaleType] || row.afterSaleType }}</template>
            </el-table-column>
            <el-table-column prop="productName" label="商品名称" min-width="220" />
            <el-table-column label="状态" width="140">
              <template #default="{ row }">
                <el-tag :type="statusTagType(row.status, row)" effect="light">{{ displayStatus(row) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createdAt" label="创建时间" min-width="160" />
            <el-table-column label="操作" width="190">
              <template #default="{ row }">
                <span class="row-actions">
                  <span v-if="hasUnreadMark(row)" class="unread-dot" />
                  <el-button v-if="canReview(row)" class="action-link urgent" link type="primary" @click="openReview(row)">去审核</el-button>
                  <el-button v-else class="action-link" link type="primary" @click="openDetail(row)">查看详细</el-button>
                </span>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </section>
    </div>
    <el-dialog v-model="detailVisible" title="售后详情" width="860px">
      <el-descriptions v-if="selectedAfterSale" class="after-sale-descriptions" :column="2" border>
        <el-descriptions-item label="订单编号">{{ selectedAfterSale.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="商品名称">{{ selectedAfterSale.productName }}</el-descriptions-item>
        <el-descriptions-item label="所属平台">{{ selectedAfterSale.platformName }}</el-descriptions-item>
        <el-descriptions-item label="所属店铺">{{ selectedAfterSale.shopName }}</el-descriptions-item>
        <el-descriptions-item label="类型">{{ labelText.afterSaleType[selectedAfterSale.afterSaleType] || selectedAfterSale.afterSaleType }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ displayStatus(selectedAfterSale) }}</el-descriptions-item>
        <el-descriptions-item label="申请原因">{{ selectedAfterSale.description || labelText.reason[selectedAfterSale.reasonType] || selectedAfterSale.reasonType }}</el-descriptions-item>
        <el-descriptions-item label="申请金额">{{ selectedAfterSale.requestedAmount }}</el-descriptions-item>
        <el-descriptions-item label="优先级">{{ labelText.priority[selectedAfterSale.priority] || selectedAfterSale.priority }}</el-descriptions-item>
        <el-descriptions-item label="回写状态">{{ labelText.writeBack[selectedAfterSale.writeBackStatus] || selectedAfterSale.writeBackStatus }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ selectedAfterSale.createdAt }}</el-descriptions-item>
        <el-descriptions-item label="退货单号">{{ selectedAfterSale.returnTrackingNo || '暂无' }}</el-descriptions-item>
        <el-descriptions-item label="寄回时间">{{ selectedAfterSale.returnShippedAt || '暂无' }}</el-descriptions-item>
        <el-descriptions-item label="审核意见" :span="2">{{ selectedAfterSale.reviewOpinion || '暂无' }}</el-descriptions-item>
        <el-descriptions-item v-if="selectedDispute" label="平台介入" :span="2">
          <div class="dispute-box">
            <p><strong>消费者说明：</strong>{{ selectedDispute.consumerReason }}</p>
            <p><strong>处理状态：</strong>{{ selectedDispute.status }}</p>
            <p v-if="selectedDispute.adminResult"><strong>平台裁决：</strong>{{ selectedDispute.adminResult }}，{{ selectedDispute.adminNote || '暂无说明' }}</p>
            <p v-if="selectedDispute.merchantEvidenceText"><strong>商家举证：</strong>{{ selectedDispute.merchantEvidenceText }}</p>
            <div v-if="selectedDispute.consumerEvidenceImages?.length" class="dispute-evidence-block">
              <strong>消费者二次凭证：</strong>
              <div class="evidence-list">
                <el-image
                  v-for="(image, index) in selectedDispute.consumerEvidenceImages"
                  :key="`consumer-${index}`"
                  :src="image"
                  :preview-src-list="selectedDispute.consumerEvidenceImages"
                  fit="cover"
                  class="evidence-image"
                />
              </div>
            </div>
            <div v-if="selectedDispute.merchantEvidenceImages?.length" class="dispute-evidence-block">
              <strong>商家二次举证图片：</strong>
              <div class="evidence-list">
                <el-image
                  v-for="(image, index) in selectedDispute.merchantEvidenceImages"
                  :key="`merchant-${index}`"
                  :src="image"
                  :preview-src-list="selectedDispute.merchantEvidenceImages"
                  fit="cover"
                  class="evidence-image"
                />
              </div>
            </div>
          </div>
        </el-descriptions-item>
        <el-descriptions-item label="凭证照片" :span="2">
          <div v-if="selectedAfterSale.evidenceImages?.length" class="evidence-list">
            <el-image
              v-for="(image, index) in selectedAfterSale.evidenceImages"
              :key="index"
              :src="image"
              :preview-src-list="selectedAfterSale.evidenceImages"
              fit="cover"
              class="evidence-image"
            />
          </div>
          <span v-else>暂无</span>
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button v-if="selectedAfterSale && canReview(selectedAfterSale)" type="danger" @click="openRejectDialog">拒绝</el-button>
        <el-button v-if="selectedAfterSale && canReview(selectedAfterSale)" type="primary" @click="approveSelectedAfterSale">同意</el-button>
        <el-button v-if="selectedAfterSale && canRejectRefundOnly(selectedAfterSale)" type="danger" @click="openRejectDialog">拒绝</el-button>
        <el-button v-if="selectedAfterSale && canAgreeRefund(selectedAfterSale)" type="primary" @click="confirmAgreeRefund">同意退款</el-button>
        <el-button v-if="selectedDispute && selectedDispute.status === '待审核'" type="primary" @click="openDisputeEvidenceDialog">二次举证</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="reviewVisible" title="拒绝售后申请" width="520px">
      <el-form label-width="88px">
        <el-form-item label="拒绝原因">
          <el-input
            v-model="reviewForm.reason"
            type="textarea"
            :rows="4"
            placeholder="请输入拒绝售后申请的具体原因"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="reviewVisible = false">取消</el-button>
        <el-button type="primary" @click="submitReview">确认</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="refundConfirmVisible" title="确认同意退款" width="520px" append-to-body>
      <div class="refund-confirm-text">
        请确认仓库已签收退回商品并检查商品是否有损坏，在不影响二次售卖的情况下可同意退款（生鲜等特殊产品除外）
      </div>
      <template #footer>
        <el-button @click="refundConfirmVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAgreeRefund">确认同意退款</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="disputeEvidenceVisible" title="商家二次举证" width="560px" append-to-body>
      <el-input
        v-model="disputeEvidenceText"
        type="textarea"
        :rows="5"
        placeholder="请说明商家拒绝售后的依据，例如商品检测结果、订单履约情况、售后规则等"
      />
      <div class="dispute-upload-row">
        <el-button @click="chooseDisputeEvidenceImages">上传图片</el-button>
        <span>最多3张，用于平台管理员审核</span>
      </div>
      <div v-if="disputeEvidenceImages.length" class="evidence-list dispute-upload-preview">
        <div v-for="(image, index) in disputeEvidenceImages" :key="index" class="upload-preview-item">
          <el-image :src="image" :preview-src-list="disputeEvidenceImages" fit="cover" class="evidence-image" />
          <button type="button" @click="removeDisputeEvidenceImage(index)">×</button>
        </div>
      </div>
      <template #footer>
        <el-button @click="disputeEvidenceVisible = false">取消</el-button>
        <el-button type="primary" @click="submitDisputeEvidence">提交举证</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { afterSales } from '../data/mock'
import {
  loadTwentyMallMerchantAfterSaleDisputes,
  loadTwentyMallMerchantAfterSales,
  refundTwentyMallAfterSale,
  reviewTwentyMallAfterSale,
  submitTwentyMallMerchantDisputeEvidence
} from '../api'
import { ElMessage } from 'element-plus'
import twentyMallIcon from '../assets/platforms/twenty-mall.png'
import { getMerchantBindings } from '../utils/auth'

type AfterSaleRow = typeof afterSales[number] & {
  orderNo: string
  productName: string
  platformCode: string
  platformName: string
  platformIcon: string
  shopName: string
  description?: string
  evidenceImages?: string[]
  returnTrackingNo?: string
  returnShippedAt?: string
}
type AfterSaleDisputeRow = {
  id: number
  afterSaleId: number
  orderNo: string
  consumerReason: string
  consumerEvidenceImages?: string[]
  merchantEvidenceText?: string
  merchantEvidenceImages?: string[]
  adminResult?: string
  adminNote?: string
  status: string
}

const status = ref('全部')
const READ_AFTER_SALE_KEY = 'merchant_read_after_sale_ids'
const afterSalesData = ref<AfterSaleRow[]>([])
const disputeData = ref<AfterSaleDisputeRow[]>([])
const loading = ref(false)
const reviewVisible = ref(false)
const detailVisible = ref(false)
const refundConfirmVisible = ref(false)
const disputeEvidenceVisible = ref(false)
const disputeEvidenceText = ref('')
const disputeEvidenceImages = ref<string[]>([])
const selectedAfterSale = ref<AfterSaleRow | null>(null)
const reviewingId = ref<number | null>(null)
const readAfterSaleIds = ref<Set<number>>(readStoredAfterSaleIds())
const reviewForm = ref({ reason: '' })
const filterOptions = [
  { label: '全部', value: '全部' },
  { label: '待审核', value: 'PENDING_REVIEW' },
  { label: '处理中', value: 'IN_PROGRESS' },
  { label: '已结束', value: 'FINISHED' },
  { label: '争议订单', value: 'DISPUTE_REVIEW' }
]
const labelText = {
  afterSaleType: { RETURN_REFUND: '退货退款', REFUND_ONLY: '仅退款', PRICE_PROTECTION: '价保' } as Record<string, string>,
  reason: { PRODUCT_QUALITY: '商品质量问题', LOGISTICS_DELAY: '物流延迟', WRONG_GOODS: '错发/漏发', PRICE_PROTECTION: '价格保护', OTHER: '其他原因' } as Record<string, string>,
  status: { PENDING_REVIEW: '待审核', PROCESSING: '处理中', WAITING_RETURN: '待用户寄回', RETURN_SHIPPED: '用户已寄回', REJECTED: '已拒绝', COMPLETED: '已完成', CLOSED: '已关闭' } as Record<string, string>,
  priority: { HIGH: '高', NORMAL: '普通', LOW: '低' } as Record<string, string>,
  writeBack: { PENDING: '待回写', WAITING: '等待中', SUCCESS: '已回写', FAILED: '回写失败' } as Record<string, string>
}

onMounted(async () => {
  loading.value = true
  const [loaded, disputes] = await Promise.all([loadBoundAfterSales(), loadBoundDisputes()])
  afterSalesData.value = loaded.map(normalizeAfterSaleRow)
  disputeData.value = disputes.map(normalizeDisputeRow)
  loading.value = false
})

async function loadBoundAfterSales() {
  const bindings = getMerchantBindings().filter((item) => item.platformCode === 'TWENTY_MALL' && item.accountNo)
  if (!bindings.length) {
    return []
  }
  try {
    const result = await Promise.all(bindings.map((binding) => loadTwentyMallMerchantAfterSales(binding.accountNo as string)))
    return result.flat() as typeof afterSales
  } catch {
    ElMessage({ type: 'error', message: '暂时无法读取后端售后申请，请确认后端服务和数据库已启动' })
    return []
  }
}

async function loadBoundDisputes() {
  const bindings = getMerchantBindings().filter((item) => item.platformCode === 'TWENTY_MALL' && item.accountNo)
  if (!bindings.length) {
    return []
  }
  try {
    const result = await Promise.all(bindings.map((binding) => loadTwentyMallMerchantAfterSaleDisputes(binding.accountNo as string)))
    return result.flat() as AfterSaleDisputeRow[]
  } catch {
    return []
  }
}

const selectedDispute = computed(() => {
  if (!selectedAfterSale.value) {
    return null
  }
  return disputeData.value.find((item) => item.afterSaleId === selectedAfterSale.value?.id) || null
})

const summaryCards = computed(() => [
  {
    label: '全部售后',
    value: '全部',
    count: afterSalesData.value.length,
    description: '当前绑定店铺售后总量'
  },
  {
    label: '待审核',
    value: 'PENDING_REVIEW',
    count: countByFilter(afterSalesData.value, 'PENDING_REVIEW'),
    description: '需要商家优先处理'
  },
  {
    label: '处理中',
    value: 'IN_PROGRESS',
    count: countByFilter(afterSalesData.value, 'IN_PROGRESS'),
    description: '已进入售后履约环节'
  },
  {
    label: '已结束',
    value: 'FINISHED',
    count: countByFilter(afterSalesData.value, 'FINISHED'),
    description: '已完成、已拒绝或关闭'
  },
  {
    label: '争议订单',
    value: 'DISPUTE_REVIEW',
    count: countByFilter(afterSalesData.value, 'DISPUTE_REVIEW'),
    description: '平台正在审核的争议'
  }
])

const filteredAfterSales = computed(() => {
  if (status.value === '全部') {
    return afterSalesData.value
  }
  if (status.value === 'IN_PROGRESS') {
    return afterSalesData.value.filter((item) => ['PROCESSING', 'WAITING_RETURN', 'RETURN_SHIPPED'].includes(item.status))
  }
  if (status.value === 'FINISHED') {
    return afterSalesData.value.filter((item) => ['COMPLETED', 'REJECTED', 'CLOSED'].includes(item.status) && !hasPendingDispute(item))
  }
  if (status.value === 'DISPUTE_REVIEW') {
    return afterSalesData.value.filter((item) => hasPendingDispute(item))
  }
  return afterSalesData.value.filter((item) => item.status === status.value)
})

const groupedAfterSales = computed(() => {
  const platformMap = new Map<string, {
    key: string
    name: string
    icon: string
    total: number
    pending: number
    processing: number
    finished: number
    dispute: number
    shopNames: Set<string>
    shops: Map<string, { key: string; name: string; items: AfterSaleRow[] }>
  }>()

  filteredAfterSales.value.forEach((item) => {
    if (!platformMap.has(item.platformCode)) {
      platformMap.set(item.platformCode, {
        key: item.platformCode,
        name: item.platformName,
        icon: item.platformIcon,
        total: 0,
        pending: 0,
        processing: 0,
        finished: 0,
        dispute: 0,
        shopNames: new Set(),
        shops: new Map()
      })
    }
    const platform = platformMap.get(item.platformCode)!
    platform.total += 1
    if (hasPendingDispute(item)) {
      platform.dispute += 1
    } else if (item.status === 'PENDING_REVIEW') {
      platform.pending += 1
    } else if (['PROCESSING', 'WAITING_RETURN', 'RETURN_SHIPPED'].includes(item.status)) {
      platform.processing += 1
    } else if (['COMPLETED', 'REJECTED', 'CLOSED'].includes(item.status)) {
      platform.finished += 1
    }
    platform.shopNames.add(item.shopName)
    const shopKey = `${item.platformCode}:${item.shopName}`
    if (!platform.shops.has(shopKey)) {
      platform.shops.set(shopKey, { key: shopKey, name: item.shopName, items: [] })
    }
    platform.shops.get(shopKey)!.items.push(item)
  })

  return Array.from(platformMap.values()).map((platform) => ({
    ...platform,
    shopNames: Array.from(platform.shopNames).join('、'),
    shops: Array.from(platform.shops.values())
  }))
})

function countByFilter(items: AfterSaleRow[], filter: string) {
  if (filter === 'PENDING_REVIEW') {
    return items.filter((item) => item.status === 'PENDING_REVIEW').length
  }
  if (filter === 'IN_PROGRESS') {
    return items.filter((item) => ['PROCESSING', 'WAITING_RETURN', 'RETURN_SHIPPED'].includes(item.status)).length
  }
  if (filter === 'FINISHED') {
    return items.filter((item) => ['COMPLETED', 'REJECTED', 'CLOSED'].includes(item.status) && !hasPendingDispute(item)).length
  }
  if (filter === 'DISPUTE_REVIEW') {
    return items.filter((item) => hasPendingDispute(item)).length
  }
  return items.length
}

function hasPendingDispute(item: AfterSaleRow) {
  return disputeData.value.some((dispute) => (
    dispute.afterSaleId === item.id
    && ['待审核', '平台审核中', 'PENDING_REVIEW', 'REVIEWING'].includes(dispute.status)
  ))
}

function displayStatus(row: AfterSaleRow) {
  if (hasPendingDispute(row)) {
    return '争议审核中'
  }
  return labelText.status[row.status] || row.status
}

function statusTagType(currentStatus: string, row?: AfterSaleRow) {
  if (row && hasPendingDispute(row)) {
    return 'warning'
  }
  if (currentStatus === 'PENDING_REVIEW') {
    return 'warning'
  }
  if (['PROCESSING', 'WAITING_RETURN', 'RETURN_SHIPPED'].includes(currentStatus)) {
    return 'primary'
  }
  if (currentStatus === 'COMPLETED') {
    return 'success'
  }
  if (currentStatus === 'REJECTED') {
    return 'danger'
  }
  return 'info'
}

function openDetail(row: AfterSaleRow) {
  markAfterSaleRead(row)
  selectedAfterSale.value = row
  detailVisible.value = true
}

function openReview(row: AfterSaleRow) {
  markAfterSaleRead(row)
  selectedAfterSale.value = row
  detailVisible.value = true
}

function submitReview() {
  if (reviewingId.value === null) {
    return
  }
  if (!reviewForm.value.reason.trim()) {
    ElMessage({ type: 'warning', message: '请输入拒绝原因' })
    return
  }
  approveAfterSale(reviewingId.value, 'REJECT', reviewForm.value.reason.trim())
  reviewVisible.value = false
}

function approveSelectedAfterSale() {
  if (!selectedAfterSale.value) {
    return
  }
  approveAfterSale(selectedAfterSale.value.id, 'APPROVE')
}

function openRejectDialog() {
  if (!selectedAfterSale.value) {
    return
  }
  reviewingId.value = selectedAfterSale.value.id
  reviewForm.value = { reason: '' }
  reviewVisible.value = true
}

async function approveAfterSale(afterSaleId: number, result = 'APPROVE', reason = '') {
  try {
    const updated = await reviewTwentyMallAfterSale(afterSaleId, result as 'APPROVE' | 'REJECT', reason) as AfterSaleRow
    afterSalesData.value = afterSalesData.value.map((item) => (
      item.id === afterSaleId ? normalizeAfterSaleRow({ ...item, ...updated }) : item
    ))
    ElMessage({
      type: 'success',
      message: result === 'REJECT' ? '售后申请已拒绝并写入数据库' : '售后审核已通过并写入数据库'
    })
    syncSelectedAfterSale(afterSaleId)
    detailVisible.value = false
  } catch {
    ElMessage({ type: 'error', message: '审核失败，请确认后端服务和数据库已启动' })
  }
}

function writeBackAfterSale(afterSaleId: number) {
  afterSalesData.value = afterSalesData.value.map((item) => {
    if (item.id !== afterSaleId) {
      return item
    }
    return {
      ...item,
      writeBackStatus: 'SUCCESS',
      reviewOpinion: item.reviewOpinion || '处理结果已同步外部平台'
    }
  })
  ElMessage({ type: 'success', message: '售后处理结果已模拟回写到抖音平台' })
  syncSelectedAfterSale(afterSaleId)
}

function writeBackAllAfterSales() {
  const writableStatuses = ['PROCESSING', 'WAITING_RETURN', 'RETURN_SHIPPED', 'COMPLETED', 'REJECTED', 'CLOSED']
  let changed = 0
  afterSalesData.value = afterSalesData.value.map((item) => {
    if (!writableStatuses.includes(item.status) || item.writeBackStatus === 'SUCCESS') {
      return item
    }
    changed += 1
    return {
      ...item,
      writeBackStatus: 'SUCCESS',
      reviewOpinion: item.reviewOpinion || '处理结果已同步外部平台'
    }
  })
  if (selectedAfterSale.value) {
    syncSelectedAfterSale(selectedAfterSale.value.id)
  }
  ElMessage({
    type: changed ? 'success' : 'info',
    message: changed ? `已统一回写 ${changed} 条售后处理结果` : '当前没有需要回写的售后单'
  })
}

function canReview(row: AfterSaleRow) {
  return row.status === 'PENDING_REVIEW'
}

function canAgreeRefund(row: AfterSaleRow) {
  return row.status === 'RETURN_SHIPPED' || (
    row.afterSaleType === 'REFUND_ONLY' && !['COMPLETED', 'REJECTED', 'CLOSED'].includes(row.status)
  )
}

function canRejectRefundOnly(row: AfterSaleRow) {
  return row.afterSaleType === 'REFUND_ONLY' && !['PENDING_REVIEW', 'COMPLETED', 'REJECTED', 'CLOSED'].includes(row.status)
}

async function confirmAgreeRefund() {
  if (!selectedAfterSale.value) {
    return
  }
  refundConfirmVisible.value = true
}

async function submitAgreeRefund() {
  if (!selectedAfterSale.value) {
    return
  }
  try {
    const afterSaleId = selectedAfterSale.value.id
    const updated = await refundTwentyMallAfterSale(afterSaleId) as AfterSaleRow
    afterSalesData.value = afterSalesData.value.map((item) => (
      item.id === afterSaleId ? normalizeAfterSaleRow({ ...item, ...updated }) : item
    ))
    syncSelectedAfterSale(afterSaleId)
    refundConfirmVisible.value = false
    detailVisible.value = false
    status.value = 'FINISHED'
    ElMessage({ type: 'success', message: '已同意退款，本次退货退款售后流程已完成' })
  } catch {
    ElMessage({ type: 'error', message: '同意退款失败，请确认后端服务和数据库已启动' })
  }
}

function openDisputeEvidenceDialog() {
  disputeEvidenceText.value = selectedDispute.value?.merchantEvidenceText || ''
  disputeEvidenceImages.value = [...(selectedDispute.value?.merchantEvidenceImages || [])]
  disputeEvidenceVisible.value = true
}

async function submitDisputeEvidence() {
  if (!selectedDispute.value) {
    return
  }
  if (!disputeEvidenceText.value.trim() && disputeEvidenceImages.value.length === 0) {
    ElMessage({ type: 'warning', message: '请填写二次举证内容或上传举证图片' })
    return
  }
  try {
    const updated = await submitTwentyMallMerchantDisputeEvidence(
      selectedDispute.value.id,
      disputeEvidenceText.value.trim(),
      disputeEvidenceImages.value
    ) as AfterSaleDisputeRow
    disputeData.value = disputeData.value.map((item) => item.id === updated.id ? normalizeDisputeRow(updated) : item)
    disputeEvidenceVisible.value = false
    disputeEvidenceImages.value = []
    ElMessage({ type: 'success', message: '二次举证已提交，等待平台管理员处理' })
  } catch {
    ElMessage({ type: 'error', message: '二次举证提交失败，请确认后端服务和数据库已启动' })
  }
}

function chooseDisputeEvidenceImages() {
  const remainCount = 3 - disputeEvidenceImages.value.length
  if (remainCount <= 0) {
    ElMessage({ type: 'warning', message: '最多上传3张图片' })
    return
  }
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/*'
  input.multiple = true
  input.onchange = () => {
    const files = Array.from(input.files || []).slice(0, remainCount)
    Promise.all(files.map(fileToDataUrl)).then((images) => {
      disputeEvidenceImages.value = disputeEvidenceImages.value.concat(images).slice(0, 3)
    })
  }
  input.click()
}

function removeDisputeEvidenceImage(index: number) {
  disputeEvidenceImages.value = disputeEvidenceImages.value.filter((_, currentIndex) => currentIndex !== index)
}

function fileToDataUrl(file: File) {
  return new Promise<string>((resolve) => {
    const reader = new FileReader()
    reader.onload = () => resolve(String(reader.result || ''))
    reader.onerror = () => resolve('')
    reader.readAsDataURL(file)
  })
}

function hasUnreadMark(row: AfterSaleRow) {
  return row.status === 'PENDING_REVIEW' && !readAfterSaleIds.value.has(row.id)
}

function markAfterSaleRead(row: AfterSaleRow) {
  if (row.status !== 'PENDING_REVIEW') {
    return
  }
  readAfterSaleIds.value.add(row.id)
  localStorage.setItem(READ_AFTER_SALE_KEY, JSON.stringify(Array.from(readAfterSaleIds.value)))
}

function readStoredAfterSaleIds() {
  const raw = localStorage.getItem(READ_AFTER_SALE_KEY)
  if (!raw) {
    return new Set<number>()
  }
  try {
    return new Set((JSON.parse(raw) as number[]).map(Number))
  } catch {
    return new Set<number>()
  }
}

function syncSelectedAfterSale(afterSaleId: number) {
  if (selectedAfterSale.value?.id === afterSaleId) {
    selectedAfterSale.value = afterSalesData.value.find((item) => item.id === afterSaleId) || null
  }
}

function normalizeAfterSaleRow(item: typeof afterSales[number]) {
  const productNameMap: Record<number, string> = {
    1: '青轴机械键盘',
    2: '便携保温杯'
  }
  const productNameByNo: Record<string, string> = {
    AS202606250001: '青轴机械键盘',
    AS202606250002: '便携保温杯'
  }
  const shopNameMap: Record<number, string> = {
    1: '极光外设旗舰店',
    2: '极光外设旗舰店'
  }
  const productName = productNameByNo[item.afterSaleNo] || (
    'productName' in item && typeof item.productName === 'string'
      ? removePlatformPrefix(item.productName)
      : productNameMap[item.id] || '售后商品'
  )
  return {
    ...item,
    orderNo: 'orderNo' in item && typeof item.orderNo === 'string'
      ? item.orderNo
      : fallbackOrderNo(item.afterSaleNo),
    productName,
    platformCode: 'TWENTY_MALL',
    platformName: '万象商城',
    platformIcon: twentyMallIcon,
    shopName: 'shopName' in item && typeof item.shopName === 'string'
      ? item.shopName
      : shopNameMap[item.id] || '万象商城店铺'
  }
}

function normalizeDisputeRow(item: AfterSaleDisputeRow) {
  return {
    ...item,
    id: Number(item.id),
    afterSaleId: Number(item.afterSaleId),
    consumerEvidenceImages: normalizeEvidenceUrls(item.consumerEvidenceImages || []),
    merchantEvidenceImages: normalizeEvidenceUrls(item.merchantEvidenceImages || [])
  }
}

function normalizeEvidenceUrls(images: string[]) {
  return images.map((image) => image && image.startsWith('/api/') ? image : image).filter(Boolean)
}

function removePlatformPrefix(productName: string) {
  return productName.replace(/^万象商城\s*/, '').trim()
}

function fallbackOrderNo(afterSaleNo: string) {
  const map: Record<string, string> = {
    TMAS202606270001: 'TM202606270001',
    TMAS202606270002: 'TM202606270004',
    AS202606250001: 'TM202606270001',
    AS202606250002: 'TM202606270004'
  }
  return map[afterSaleNo] || afterSaleNo.replace(/^TMAS/, 'TM')
}
</script>

<style scoped>
.panel {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.after-sale-summary {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 14px;
}

.summary-card {
  min-height: 112px;
  padding: 16px 18px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #fff;
  text-align: left;
  cursor: pointer;
  transition: border-color 0.18s ease, background 0.18s ease, transform 0.18s ease;
}

.summary-card:hover,
.summary-card.active {
  border-color: #409eff;
  background: #f4f8ff;
}

.summary-card:hover {
  transform: translateY(-1px);
}

.summary-card span,
.summary-card em {
  display: block;
}

.summary-card span {
  color: #64748b;
  font-size: 13px;
}

.summary-card strong {
  display: block;
  margin-top: 8px;
  color: #0f172a;
  font-size: 32px;
  line-height: 1;
}

.summary-card em {
  margin-top: 10px;
  color: #64748b;
  font-size: 12px;
  font-style: normal;
}

.after-sale-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 16px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #fff;
}

.filter-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.filter-group > span {
  color: #64748b;
  font-size: 13px;
  font-weight: 600;
}

.platform-group {
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  overflow: hidden;
  background: #fff;
}

.platform-heading {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 18px;
  background: linear-gradient(180deg, #f8fbff 0%, #f3f7fc 100%);
  border-bottom: 1px solid #e4e8f0;
}

.platform-heading img {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  object-fit: cover;
}

.platform-heading strong,
.platform-heading span {
  display: block;
}

.platform-heading strong {
  color: #0f172a;
  font-size: 16px;
}

.platform-heading span {
  margin-top: 4px;
  color: #64748b;
  font-size: 13px;
}

.shop-group + .shop-group {
  border-top: 1px solid #e4e8f0;
}

.shop-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 18px;
  color: #334155;
  font-weight: 600;
  background: #fff;
}

.shop-heading span,
.shop-heading small {
  display: block;
}

.shop-heading span {
  color: #0f172a;
  font-size: 15px;
}

.shop-heading small {
  margin-top: 4px;
  color: #64748b;
  font-size: 12px;
  font-weight: 400;
}

.shop-heading em {
  color: #64748b;
  font-size: 12px;
  font-style: normal;
  font-weight: 400;
}

.row-actions {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.action-link {
  font-weight: 600;
}

.action-link.urgent {
  color: #ef4444;
}

.unread-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #ef4444;
  box-shadow: 0 0 0 2px #fee2e2;
}

.after-sale-table :deep(.el-table__header th) {
  background: #f8fafc;
  color: #64748b;
  font-weight: 700;
}

.after-sale-table :deep(.after-sale-row:hover > td) {
  background: #f6faff !important;
}

.evidence-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.evidence-image {
  width: 88px;
  height: 88px;
  border-radius: 6px;
  overflow: hidden;
  border: 1px solid #e4e8f0;
}

.after-sale-descriptions :deep(.el-descriptions__label) {
  width: 108px;
  min-width: 108px;
  white-space: nowrap;
}

.after-sale-descriptions :deep(.el-descriptions__content) {
  min-width: 230px;
  word-break: break-word;
}

.refund-confirm-text {
  color: #1f2937;
  font-size: 15px;
  line-height: 1.8;
}

.dispute-box {
  color: #334155;
  line-height: 1.7;
}

.dispute-box p {
  margin: 0 0 6px;
}

.dispute-evidence-block {
  margin-top: 10px;
}

.dispute-upload-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 14px;
  color: #64748b;
  font-size: 13px;
}

.dispute-upload-preview {
  margin-top: 12px;
}

.upload-preview-item {
  position: relative;
}

.upload-preview-item button {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 22px;
  height: 22px;
  border: none;
  border-radius: 50%;
  background: #ef4444;
  color: #fff;
  cursor: pointer;
  line-height: 20px;
}
</style>
