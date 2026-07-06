<template>
  <div class="statistics-page">
    <div class="stats-header">
      <div>
        <div class="page-kicker">基于已绑定自建商城店铺实时汇总</div>
        <h2>统计分析</h2>
      </div>
      <el-button class="refresh-button" type="primary" :loading="loading" @click="loadStatistics">刷新数据</el-button>
    </div>

    <div class="analysis-grid">
      <div v-for="item in summaryCards" :key="item.label" class="analysis-card" :class="`tone-${item.tone}`">
        <div class="card-topline">
          <span>{{ item.label }}</span>
          <i></i>
        </div>
        <strong>{{ item.value }}</strong>
        <p>{{ item.desc }}</p>
      </div>
    </div>

    <div v-loading="loading" class="analysis-panels insight-panels">
      <section class="panel">
        <div class="panel-title">
          <h3>售后状态分布</h3>
          <span>总售后 {{ afterSales.length }} 单</span>
        </div>
        <div class="bar-list">
          <div v-for="item in afterSaleStatusRows" :key="item.label" class="bar-row">
            <div class="bar-info">
              <strong>{{ item.label }}</strong>
              <span>{{ item.count }} 单 · {{ item.rate }}%</span>
            </div>
            <div class="bar-track">
              <i :style="{ width: `${item.rate}%`, background: item.color }"></i>
            </div>
          </div>
        </div>
      </section>

      <section class="panel">
        <div class="panel-title">
          <h3>评价风险分布</h3>
          <span>有效评价 {{ activeReviews.length }} 条</span>
        </div>
        <div class="risk-list">
          <div v-for="item in reviewRiskRows" :key="item.label" class="risk-item">
            <span :style="{ background: item.color }"></span>
            <div>
              <strong>{{ item.count }}</strong>
              <em>{{ item.label }}</em>
            </div>
          </div>
        </div>
      </section>
    </div>

    <div v-loading="loading" class="analysis-panels business-panels">
      <section class="panel">
        <div class="panel-title">
          <h3>店铺业务概览</h3>
          <span>{{ shopRows.length }} 个店铺</span>
        </div>
        <el-table class="shop-table" :data="shopRows" stripe>
          <el-table-column prop="shopName" label="店铺" min-width="170" />
          <el-table-column prop="orderCount" label="订单数" width="90" />
          <el-table-column prop="afterSaleCount" label="售后数" width="90" />
          <el-table-column prop="reviewCount" label="评价数" width="90" />
          <el-table-column label="售后率" width="100">
            <template #default="{ row }">{{ row.afterSaleRate }}%</template>
          </el-table-column>
          <el-table-column label="平均评分" width="110">
            <template #default="{ row }">{{ row.averageScore }} 星</template>
          </el-table-column>
        </el-table>
      </section>

      <section class="panel">
        <div class="panel-title">
          <h3>商品售后排行</h3>
          <span>按售后单数排序</span>
        </div>
        <div v-if="productAfterSaleRows.length" class="rank-list">
          <div v-for="(item, index) in productAfterSaleRows" :key="item.productName" class="rank-item">
            <span class="rank-badge" :class="{ podium: index < 3 }">{{ index + 1 }}</span>
            <div class="rank-content">
              <div class="rank-main">
                <strong>{{ cleanProductName(item.productName) }}</strong>
                <em>{{ item.shopName }}</em>
              </div>
              <div class="rank-progress">
                <i :style="{ width: `${rankRate(item.count)}%` }"></i>
              </div>
            </div>
            <div class="rank-count">
              <strong>{{ item.count }}</strong>
              <span>单售后</span>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无售后排行数据" />
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { loadSelfBuiltMerchantAfterSales, loadSelfBuiltMerchantOrders, loadSelfBuiltMerchantReviews } from '../api'
import { getMerchantBindings, getStoredUser, type MerchantPlatformBinding } from '../utils/auth'

type OrderRow = {
  id: number
  externalOrderNo: string
  orderStatus: string
  afterSaleStatus: string
  totalAmount: number
  orderedAt: string
  productName: string
  merchantName: string
  platformCode?: string
  platformName?: string
}

type AfterSaleRow = {
  id: number
  orderNo: string
  productName: string
  status: string
  shopName: string
  platformCode?: string
  platformName?: string
}

type ReviewRow = {
  id: number
  productScore: number
  serviceScore: number
  riskLevel: string
  deleted?: boolean
  merchantName?: string
  platformCode?: string
  platformName?: string
}

const loading = ref(false)
const orders = ref<OrderRow[]>([])
const afterSales = ref<AfterSaleRow[]>([])
const reviews = ref<ReviewRow[]>([])

onMounted(loadStatistics)

const activeReviews = computed(() => reviews.value.filter((item) => !item.deleted))

const summaryCards = computed(() => {
  const orderCount = orders.value.length
  const afterSaleCount = afterSales.value.length
  const afterSaleRate = rate(afterSaleCount, orderCount)
  const totalAmount = orders.value.reduce((sum, item) => sum + Number(item.totalAmount || 0), 0)
  const averageScore = average(activeReviews.value.map((item) => average([item.productScore, item.serviceScore])))
  const pendingCount = afterSales.value.filter((item) => item.status === 'PENDING_REVIEW').length
  return [
    { label: '订单总数', value: String(orderCount), desc: `订单金额 ${formatMoney(totalAmount)}`, tone: 'orders' },
    { label: '售后总数', value: String(afterSaleCount), desc: `售后率 ${afterSaleRate}%`, tone: 'after-sale' },
    { label: '待审核售后', value: String(pendingCount), desc: '需要优先处理的售后申请', tone: 'pending' },
    { label: '平均评分', value: `${averageScore.toFixed(1)} 星`, desc: `来自 ${activeReviews.value.length} 条有效评价`, tone: 'score' }
  ]
})

const afterSaleStatusRows = computed(() => {
  const rows = [
    { key: 'PENDING_REVIEW', label: '待审核', color: '#f97316' },
    { key: 'PROCESSING', label: '处理中', color: '#2563eb' },
    { key: 'WAITING_RETURN', label: '待寄回', color: '#7c3aed' },
    { key: 'RETURN_SHIPPED', label: '已寄回', color: '#0f766e' },
    { key: 'COMPLETED', label: '已完成', color: '#16a34a' },
    { key: 'REJECTED', label: '已拒绝', color: '#dc2626' },
    { key: 'CLOSED', label: '已关闭', color: '#64748b' }
  ]
  return rows.map((row) => {
    const count = afterSales.value.filter((item) => item.status === row.key).length
    return { ...row, count, rate: rate(count, afterSales.value.length) }
  })
})

const reviewRiskRows = computed(() => {
  const rows = [
    { key: 'HIGH', label: '高风险', color: '#dc2626' },
    { key: 'MEDIUM', label: '中风险', color: '#f97316' },
    { key: 'LOW', label: '低风险', color: '#16a34a' }
  ]
  return rows.map((row) => ({
    ...row,
    count: activeReviews.value.filter((item) => item.riskLevel === row.key).length
  }))
})

const shopRows = computed(() => {
  const names = new Set([
    ...orders.value.map((item) => item.merchantName),
    ...afterSales.value.map((item) => item.shopName),
    ...activeReviews.value.map((item) => item.merchantName || '').filter(Boolean)
  ])
  return Array.from(names).map((shopName) => {
    const shopOrders = orders.value.filter((item) => item.merchantName === shopName)
    const shopAfterSales = afterSales.value.filter((item) => item.shopName === shopName)
    const shopReviews = activeReviews.value.filter((item) => item.merchantName === shopName)
    const score = average(shopReviews.map((item) => average([item.productScore, item.serviceScore])))
    return {
      shopName,
      orderCount: shopOrders.length,
      afterSaleCount: shopAfterSales.length,
      reviewCount: shopReviews.length,
      afterSaleRate: rate(shopAfterSales.length, shopOrders.length),
      averageScore: score.toFixed(1)
    }
  })
})

const productAfterSaleRows = computed(() => {
  const map = new Map<string, { productName: string; shopName: string; count: number }>()
  afterSales.value.forEach((item) => {
    const key = `${item.shopName}:${item.productName}`
    const current = map.get(key) || { productName: item.productName, shopName: item.shopName, count: 0 }
    current.count += 1
    map.set(key, current)
  })
  return Array.from(map.values()).sort((a, b) => b.count - a.count).slice(0, 6)
})

const maxProductAfterSaleCount = computed(() => Math.max(...productAfterSaleRows.value.map((item) => item.count), 1))

async function loadStatistics() {
  const bindings = await boundMerchantBindings()
  if (!bindings.length) {
    orders.value = []
    afterSales.value = []
    reviews.value = []
    ElMessage({ type: 'warning', message: '请先绑定至少一个自建商城商家账号' })
    return
  }
  loading.value = true
  try {
    const [orderGroups, afterSaleGroups, reviewGroups] = await Promise.all([
      Promise.all(bindings.map(async (binding) => attachPlatformRows(await loadSelfBuiltMerchantOrders(binding.accountNo as string, binding.platformCode), binding))),
      Promise.all(bindings.map(async (binding) => attachPlatformRows(await loadSelfBuiltMerchantAfterSales(binding.accountNo as string, binding.platformCode), binding))),
      Promise.all(bindings.map(async (binding) => attachPlatformRows(await loadSelfBuiltMerchantReviews(binding.accountNo as string, binding.platformCode), binding)))
    ])
    orders.value = orderGroups.flat() as OrderRow[]
    afterSales.value = afterSaleGroups.flat() as AfterSaleRow[]
    reviews.value = reviewGroups.flat() as ReviewRow[]
  } catch (error) {
    orders.value = []
    afterSales.value = []
    reviews.value = []
    ElMessage({ type: 'error', message: error instanceof Error ? error.message : '统计数据读取失败，请确认后端服务已启动' })
  } finally {
    loading.value = false
  }
}

async function boundMerchantBindings() {
  const databaseBindings = await loadDatabaseSelfBuiltBindings()
  const source = databaseBindings.length ? databaseBindings : getMerchantBindings()
  return source.filter((item) => isSelfBuiltPlatform(item.platformCode) && item.accountNo)
}

async function loadDatabaseSelfBuiltBindings() {
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/primary/bindings?primaryAccountNo=${encodeURIComponent(currentPrimaryAccountNo())}&primaryAccountType=MERCHANT&secondaryAccountRole=MERCHANT`)
    const payload = await response.json()
    if (payload.code !== '200') {
      return []
    }
    return (payload.data || [])
      .filter((item: { bindStatus?: string; platformCode?: string; platformName?: string }) => item.bindStatus === '已绑定' && isSelfBuiltPlatform(item.platformCode || platformCodeByName(item.platformName)))
      .map((item: {
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

function attachPlatformRows(rows: unknown, binding: MerchantPlatformBinding) {
  return ((Array.isArray(rows) ? rows : []) as Record<string, unknown>[]).map((row) => ({
    ...row,
    platformCode: binding.platformCode,
    platformName: binding.platformName || platformNameByCode(binding.platformCode)
  }))
}

function isSelfBuiltPlatform(platformCode = '') {
  return platformCode === 'TWENTY_MALL' || platformCode === 'YUEGOU_MARKET'
}

function platformNameByCode(platformCode = 'TWENTY_MALL') {
  return platformCode === 'YUEGOU_MARKET' ? '悦购集市' : '万象商城'
}

function platformCodeByName(platformName = '') {
  return platformName === '悦购集市' ? 'YUEGOU_MARKET' : 'TWENTY_MALL'
}

function rate(value: number, total: number) {
  if (!total) return 0
  return Number(((value / total) * 100).toFixed(1))
}

function average(values: number[]) {
  const valid = values.filter((item) => Number.isFinite(item))
  if (!valid.length) return 0
  return valid.reduce((sum, item) => sum + item, 0) / valid.length
}

function formatMoney(value: number) {
  return `¥${value.toFixed(2)}`
}

function cleanProductName(productName = '') {
  return productName.replace(/^(万象商城|悦购集市)\s*/, '').trim()
}

function rankRate(count: number) {
  return Math.max(12, Math.round((count / maxProductAfterSaleCount.value) * 100))
}
</script>

<style scoped>
.statistics-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.stats-header,
.panel-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.stats-header h2,
.panel-title h3 {
  margin: 0;
  color: #0f172a;
}

.stats-header {
  padding: 2px 0 4px;
}

.stats-header h2 {
  font-size: 28px;
  font-weight: 900;
  letter-spacing: 0;
}

.page-kicker {
  margin-bottom: 4px;
  color: #7c8aa0;
  font-size: 13px;
  font-weight: 700;
}

.refresh-button {
  height: 40px;
  min-width: 104px;
  border-radius: 8px;
  font-weight: 800;
}

.panel-title {
  margin-bottom: 18px;
}

.panel-title h3 {
  font-size: 18px;
  font-weight: 900;
}

.panel-title span {
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
}

.analysis-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.analysis-card {
  position: relative;
  min-height: 126px;
  overflow: hidden;
  padding: 20px 22px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
  box-shadow: 0 12px 28px rgba(15, 23, 42, 0.05);
}

.analysis-card::after {
  position: absolute;
  right: -24px;
  bottom: -34px;
  width: 112px;
  height: 112px;
  border-radius: 999px;
  background: rgba(37, 99, 235, 0.08);
  content: '';
}

.card-topline {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.analysis-card span,
.analysis-card p {
  color: #64748b;
}

.analysis-card span {
  font-size: 14px;
  font-weight: 800;
}

.card-topline i {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  background: #2563eb;
}

.analysis-card strong {
  position: relative;
  z-index: 1;
  display: block;
  margin-top: 14px;
  color: #0f172a;
  font-size: 34px;
  font-weight: 900;
  line-height: 1;
}

.analysis-card p {
  position: relative;
  z-index: 1;
  margin: 10px 0 0;
  font-size: 13px;
  font-weight: 700;
}

.tone-orders .card-topline i,
.tone-orders::after {
  background: rgba(37, 99, 235, 0.12);
}

.tone-after-sale .card-topline i,
.tone-after-sale::after {
  background: rgba(14, 116, 144, 0.13);
}

.tone-pending .card-topline i,
.tone-pending::after {
  background: rgba(249, 115, 22, 0.14);
}

.tone-score .card-topline i,
.tone-score::after {
  background: rgba(22, 163, 74, 0.14);
}

.analysis-panels {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(360px, 0.8fr);
  gap: 16px;
}

.insight-panels {
  grid-template-columns: minmax(0, 1.35fr) minmax(420px, 0.65fr);
}

.business-panels {
  grid-template-columns: minmax(0, 1.25fr) minmax(390px, 0.75fr);
  align-items: start;
}

.panel {
  padding: 22px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  box-shadow: 0 12px 28px rgba(15, 23, 42, 0.045);
}

.bar-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.rank-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.bar-row {
  display: grid;
  grid-template-columns: 132px minmax(0, 1fr);
  align-items: center;
  gap: 18px;
  padding: 10px 0;
}

.bar-info strong,
.bar-info span {
  display: block;
}

.bar-info strong {
  color: #0f172a;
  font-size: 15px;
  font-weight: 900;
}

.bar-info span {
  margin-top: 3px;
  color: #64748b;
  font-size: 12px;
}

.bar-track {
  height: 12px;
  overflow: hidden;
  border-radius: 999px;
  background: #eef2f7;
}

.bar-track i {
  display: block;
  height: 100%;
  min-width: 4px;
  border-radius: inherit;
}

.risk-list {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.risk-item {
  display: flex;
  align-items: center;
  gap: 14px;
  min-height: 92px;
  padding: 16px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}

.risk-item > span {
  width: 10px;
  height: 42px;
  border-radius: 999px;
}

.risk-item strong,
.risk-item em {
  display: block;
}

.risk-item strong {
  color: #0f172a;
  font-size: 30px;
  font-weight: 900;
  line-height: 1;
}

.risk-item em {
  margin-top: 5px;
  color: #64748b;
  font-size: 12px;
  font-style: normal;
}

.rank-item {
  position: relative;
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr) 64px;
  align-items: center;
  gap: 12px;
  min-height: 82px;
  overflow: hidden;
  padding: 15px 16px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background:
    linear-gradient(90deg, rgba(37, 99, 235, 0.06) 0%, rgba(255, 255, 255, 0) 42%),
    linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
  box-shadow: 0 10px 22px rgba(15, 23, 42, 0.04);
  transition: transform 0.18s ease, border-color 0.18s ease, box-shadow 0.18s ease;
}

.rank-item:hover {
  transform: translateY(-2px);
  border-color: #bfdbfe;
  box-shadow: 0 16px 28px rgba(37, 99, 235, 0.09);
}

.rank-badge {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #e8eef7;
  color: #475569;
  font-size: 16px;
  font-weight: 900;
}

.rank-badge.podium {
  background: #14213d;
  color: #ffffff;
  box-shadow: 0 8px 18px rgba(20, 33, 61, 0.2);
}

.rank-content {
  min-width: 0;
}

.rank-main {
  display: grid;
  gap: 5px;
}

.rank-item strong {
  display: block;
}

.rank-main strong {
  overflow: hidden;
  color: #0f172a;
  font-size: 15.5px;
  font-weight: 900;
  line-height: 1.35;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.rank-main em {
  overflow: hidden;
  color: #64748b;
  font-size: 12px;
  font-style: normal;
  font-weight: 700;
  line-height: 1.2;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.rank-progress {
  height: 7px;
  margin-top: 12px;
  overflow: hidden;
  border-radius: 999px;
  background: #edf2f7;
}

.rank-progress i {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: linear-gradient(90deg, #2563eb, #14b8a6);
}

.rank-count {
  display: grid;
  justify-items: end;
  gap: 2px;
}

.rank-count strong {
  color: #0f172a;
  font-size: 24px;
  font-weight: 950;
  line-height: 1;
}

.rank-count span {
  color: #64748b;
  font-size: 12px;
  font-weight: 800;
  white-space: nowrap;
}

.shop-table {
  overflow: hidden;
  border: 1px solid #edf2f7;
  border-radius: 8px;
}

.shop-table :deep(.el-table__header th) {
  background: #f8fafc;
  color: #64748b;
  font-weight: 900;
}

.shop-table :deep(.el-table__row td) {
  color: #475569;
  font-weight: 700;
}

.shop-table :deep(.el-table__cell) {
  padding: 12px 0;
}

@media (max-width: 1200px) {
  .analysis-grid,
  .analysis-panels {
    grid-template-columns: 1fr;
  }
}
</style>
