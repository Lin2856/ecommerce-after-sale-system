<template>
  <div class="statistics-page">
    <div class="stats-header">
      <div>
        <div class="page-kicker">基于已绑定 20 商城店铺实时汇总</div>
        <h2>统计分析</h2>
      </div>
      <el-button type="primary" :loading="loading" @click="loadStatistics">刷新数据</el-button>
    </div>

    <div class="analysis-grid">
      <div v-for="item in summaryCards" :key="item.label" class="analysis-card">
        <span>{{ item.label }}</span>
        <strong>{{ item.value }}</strong>
        <p>{{ item.desc }}</p>
      </div>
    </div>

    <div v-loading="loading" class="analysis-panels">
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

    <div v-loading="loading" class="analysis-panels">
      <section class="panel">
        <div class="panel-title">
          <h3>店铺业务概览</h3>
          <span>{{ shopRows.length }} 个店铺</span>
        </div>
        <el-table :data="shopRows" border>
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
            <span>{{ index + 1 }}</span>
            <div>
              <strong>{{ cleanProductName(item.productName) }}</strong>
              <em>{{ item.shopName }} · {{ item.count }} 单售后</em>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无售后排行数据" />
      </section>
    </div>

    <section v-loading="loading" class="panel">
      <div class="panel-title">
        <h3>订单状态明细</h3>
        <span>按已绑定店铺汇总</span>
      </div>
      <el-table :data="orderRows" border>
        <el-table-column prop="externalOrderNo" label="订单号" min-width="160" />
        <el-table-column prop="merchantName" label="店铺" min-width="160" />
        <el-table-column label="商品" min-width="190">
          <template #default="{ row }">{{ cleanProductName(row.productName) }}</template>
        </el-table-column>
        <el-table-column label="订单状态" width="110">
          <template #default="{ row }">{{ orderStatusText(row.orderStatus) }}</template>
        </el-table-column>
        <el-table-column label="售后状态" width="110">
          <template #default="{ row }">{{ orderAfterSaleText(row.afterSaleStatus) }}</template>
        </el-table-column>
        <el-table-column prop="totalAmount" label="订单金额" width="110" />
        <el-table-column prop="orderedAt" label="下单时间" min-width="160" />
      </el-table>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { loadTwentyMallMerchantAfterSales, loadTwentyMallMerchantOrders, loadTwentyMallMerchantReviews } from '../api'
import { getMerchantBindings } from '../utils/auth'

type OrderRow = {
  id: number
  externalOrderNo: string
  orderStatus: string
  afterSaleStatus: string
  totalAmount: number
  orderedAt: string
  productName: string
  merchantName: string
}

type AfterSaleRow = {
  id: number
  orderNo: string
  productName: string
  status: string
  shopName: string
}

type ReviewRow = {
  id: number
  productScore: number
  serviceScore: number
  riskLevel: string
  deleted?: boolean
  merchantName?: string
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
    { label: '订单总数', value: String(orderCount), desc: `订单金额 ${formatMoney(totalAmount)}` },
    { label: '售后总数', value: String(afterSaleCount), desc: `售后率 ${afterSaleRate}%` },
    { label: '待审核售后', value: String(pendingCount), desc: '需要优先处理的售后申请' },
    { label: '平均评分', value: `${averageScore.toFixed(1)} 星`, desc: `来自 ${activeReviews.value.length} 条有效评价` }
  ]
})

const afterSaleStatusRows = computed(() => {
  const rows = [
    { key: 'PENDING_REVIEW', label: '待审核', color: '#f97316' },
    { key: 'PROCESSING', label: '处理中', color: '#2563eb' },
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

const orderRows = computed(() => [...orders.value].sort((a, b) => String(b.orderedAt).localeCompare(String(a.orderedAt))))

async function loadStatistics() {
  const accounts = boundMerchantAccounts()
  if (!accounts.length) {
    orders.value = []
    afterSales.value = []
    reviews.value = []
    ElMessage({ type: 'warning', message: '请先绑定至少一个万象商城商家账号' })
    return
  }
  loading.value = true
  try {
    const [orderGroups, afterSaleGroups, reviewGroups] = await Promise.all([
      Promise.all(accounts.map((accountNo) => loadTwentyMallMerchantOrders(accountNo))),
      Promise.all(accounts.map((accountNo) => loadTwentyMallMerchantAfterSales(accountNo))),
      Promise.all(accounts.map((accountNo) => loadTwentyMallMerchantReviews(accountNo)))
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

function boundMerchantAccounts() {
  return getMerchantBindings()
    .filter((item) => item.platformCode === 'TWENTY_MALL' && item.accountNo)
    .map((item) => item.accountNo as string)
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
  return productName.replace(/^万象商城\s*/, '').trim()
}

function orderStatusText(value: string) {
  const map: Record<string, string> = {
    COMPLETED: '已完成',
    SHIPPED: '已发货',
    PENDING: '待付款',
    CANCELED: '已取消'
  }
  return map[value] || value
}

function orderAfterSaleText(value: string) {
  const map: Record<string, string> = {
    NONE: '未申请',
    AFTER_SALE: '售后中',
    COMPLETED: '已结束'
  }
  return map[value] || value
}
</script>

<style scoped>
.statistics-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
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

.stats-header h2 {
  font-size: 24px;
}

.panel-title {
  margin-bottom: 14px;
}

.panel-title h3 {
  font-size: 17px;
}

.panel-title span {
  color: #64748b;
  font-size: 13px;
}

.analysis-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.analysis-card {
  min-height: 112px;
  padding: 18px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #fff;
}

.analysis-card span {
  color: #64748b;
  font-size: 14px;
}

.analysis-card strong {
  display: block;
  margin-top: 10px;
  color: #0f172a;
  font-size: 30px;
  line-height: 1;
}

.analysis-card p {
  margin: 10px 0 0;
  color: #64748b;
  font-size: 13px;
}

.analysis-panels {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(360px, 0.8fr);
  gap: 16px;
}

.bar-list,
.rank-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.bar-row {
  display: grid;
  grid-template-columns: 150px minmax(0, 1fr);
  align-items: center;
  gap: 12px;
}

.bar-info strong,
.bar-info span {
  display: block;
}

.bar-info strong {
  color: #0f172a;
  font-size: 14px;
}

.bar-info span {
  margin-top: 3px;
  color: #64748b;
  font-size: 12px;
}

.bar-track {
  height: 10px;
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
  gap: 12px;
}

.risk-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #f8fafc;
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
  font-size: 26px;
  line-height: 1;
}

.risk-item em,
.rank-item em {
  margin-top: 5px;
  color: #64748b;
  font-size: 12px;
  font-style: normal;
}

.rank-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #f8fafc;
}

.rank-item > span {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #14213d;
  color: #fff;
  font-weight: 800;
}

.rank-item strong {
  color: #0f172a;
}

@media (max-width: 1200px) {
  .analysis-grid,
  .analysis-panels {
    grid-template-columns: 1fr;
  }
}
</style>
