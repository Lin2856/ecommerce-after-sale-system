<template>
  <div class="panel">
    <div class="toolbar">
      <div>
        <h2 class="section-title">店铺绑定</h2>
        <span class="page-kicker">用于同步订单、售后、评价和回写处理结果</span>
      </div>
    </div>
    <div class="binding-overview">
      <div v-for="item in overviewMetrics" :key="item.label" class="overview-card">
        <span>{{ item.label }}</span>
        <strong>{{ item.value }}</strong>
        <em>{{ item.description }}</em>
      </div>
    </div>
    <div class="platform-grid">
      <div
        v-for="item in platformOptions"
        :key="item.code"
        class="platform-card"
        :class="{ bound: platformBindingCount(item.code) > 0, planned: !isSelfBuiltPlatform(item.code) }"
      >
        <img :src="item.icon" :alt="item.name" />
        <div class="platform-info">
          <div class="platform-title-row">
            <strong>{{ item.name }}</strong>
            <el-tag v-if="platformBindingCount(item.code) > 0" type="success" size="small">已绑定 {{ platformBindingCount(item.code) }}</el-tag>
            <el-tag v-else-if="!isSelfBuiltPlatform(item.code)" type="info" size="small">待接入</el-tag>
            <el-tag v-else type="warning" size="small">未绑定</el-tag>
          </div>
          <span>{{ item.desc }}</span>
        </div>
          <el-button :type="isSelfBuiltPlatform(item.code) ? 'primary' : 'default'" @click="bindPlatform(item)">绑定</el-button>
      </div>
    </div>
    <div class="binding-notice" :class="{ warning: !bindingData.length }">
      <span>{{ bindingData.length ? '已绑定账号将作为订单、售后、客服和评价数据来源。' : '当前一级商家账号尚未绑定任何二级电商平台商家账号，请先完成店铺绑定。' }}</span>
    </div>
    <div v-if="bindingData.length" class="bound-shops-card">
      <div class="card-toolbar">
        <h2 class="section-title">已绑定店铺</h2>
        <span class="page-kicker">共 {{ bindingData.length }} 个店铺账号</span>
      </div>
      <el-table v-loading="loading" :data="bindingData" border class="binding-table">
      <el-table-column label="平台" width="170">
        <template #default="{ row }">
          <div class="table-platform">
            <img :src="platformIcon(row.platformCode)" :alt="row.platformName" />
            <span>{{ row.platformName }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column prop="externalShopId" label="店铺ID" min-width="180" />
      <el-table-column prop="shopName" label="店铺名称" min-width="220" />
      <el-table-column prop="accountNo" label="绑定账号" width="160" />
      <el-table-column label="授权状态" width="120">
        <template #default="{ row }">
          <el-tag :type="row.authStatus === 'ACTIVE' ? 'success' : 'warning'">{{ authStatusText(row.authStatus) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="lastSyncedAt" label="最近同步" width="180" />
      <el-table-column label="操作" width="110" fixed="right">
        <template #default="{ row }">
          <el-button link type="danger" @click="unbindPlatform(row)">解绑</el-button>
        </template>
      </el-table-column>
      </el-table>
    </div>
    <div v-if="bindingData.length" class="split-grid">
      <div class="panel sync-panel">
        <div class="card-toolbar">
          <h2 class="section-title">同步任务</h2>
          <span class="page-kicker">订单、售后和评价数据同步</span>
        </div>
        <div v-for="item in syncTaskData" :key="item.id" class="sync-task-card">
          <div>
            <strong>{{ item.taskName }}</strong>
            <div class="sync-time">上次：{{ item.lastRunAt || '-' }}</div>
            <div class="sync-time">下次：{{ item.nextRunAt || '-' }}</div>
          </div>
          <div class="inline-actions">
            <el-tag :type="item.enabled ? 'success' : 'info'">{{ item.enabled ? '已启用' : '已停用' }}</el-tag>
            <el-button link type="primary" :loading="syncingType === item.taskType" @click="runSync(item.taskType)">触发</el-button>
          </div>
        </div>
      </div>
      <div class="panel prepare-panel">
        <div class="card-toolbar">
          <h2 class="section-title">开放平台准备项</h2>
          <span class="page-kicker">真实平台接入前检查</span>
        </div>
        <div v-for="item in platformPrepareSteps" :key="item.title" class="prepare-step" :class="{ done: item.done }">
          <span>{{ item.index }}</span>
          <div>
            <strong>{{ item.title }}</strong>
            <em>{{ item.desc }}</em>
          </div>
        </div>
      </div>
    </div>
    <el-dialog v-model="selfBuiltDialogVisible" :title="`绑定${selectedSelfBuiltPlatform?.name || '自建商城'}账号`" width="460px">
      <el-alert
        :title="selfBuiltDemoHint"
        type="info"
        :closable="false"
        style="margin-bottom: 16px"
      />
      <el-form label-width="88px">
        <el-form-item label="账号">
          <el-input v-model="selfBuiltForm.accountNo" :placeholder="`请输入${selectedSelfBuiltPlatform?.name || '自建商城'}商家账号`" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="selfBuiltForm.password" type="password" show-password placeholder="请输入密码" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="selfBuiltDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="selfBuiltBinding" @click="submitSelfBuiltBind">确认绑定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, watch, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { ElMessageBox } from 'element-plus/es/components/message-box/index'
import { loadSyncTasks, triggerSync } from '../api'
import { syncTasks } from '../data/mock'
import { isDemoMode } from '../utils/auth'
import { clearMerchantBindings, getMerchantBindings, getStoredUser, getTwentyMallMerchantName, removeMerchantBinding, saveMerchantBinding, type MerchantPlatformBinding } from '../utils/auth'
import douyinIcon from '../assets/platforms/douyin.png'
import taobaoIcon from '../assets/platforms/taobao.png'
import pddIcon from '../assets/platforms/pinduoduo.png'
import jdIcon from '../assets/platforms/jd.png'
import twentyMallIcon from '../assets/platforms/twenty-mall.png'
import yuegouMarketIcon from '../assets/platforms/yuegou-market.svg?url'

const bindingData = ref<MerchantPlatformBinding[]>([])
const syncTaskData = ref<typeof syncTasks>(syncTasks)
const loading = ref(false)
const syncingType = ref('')
const selfBuiltDialogVisible = ref(false)
const selfBuiltBinding = ref(false)
const selfBuiltForm = ref({ accountNo: '', password: '' })
const platformOptions = [
  { code: 'DOUYIN', name: '抖音商城', desc: '同步抖店订单与售后', icon: douyinIcon },
  { code: 'TAOBAO', name: '淘宝', desc: '预留淘宝店铺接入', icon: taobaoIcon },
  { code: 'PDD', name: '拼多多', desc: '预留拼多多店铺接入', icon: pddIcon },
  { code: 'JD', name: '京东', desc: '预留京东店铺接入', icon: jdIcon },
  { code: 'TWENTY_MALL', name: '万象商城', desc: '自建数据库模拟电商平台', icon: twentyMallIcon },
  { code: 'YUEGOU_MARKET', name: '悦购集市', desc: '第二个自建数据库模拟电商平台', icon: yuegouMarketIcon }
]
const selectedSelfBuiltPlatform = ref<(typeof platformOptions)[number] | null>(null)
const platformPrepareSteps = [
  { index: 1, title: '准备 App Key', desc: '用于识别开放平台应用身份', done: true },
  { index: 2, title: '配置 App Secret', desc: '用于接口签名和访问令牌换取', done: true },
  { index: 3, title: '设置回调地址', desc: '接收订单、售后和授权状态变更通知', done: true },
  { index: 4, title: '申请真实权限审批', desc: '提交平台审核后才能读取真实店铺数据', done: false }
]
const overviewMetrics = computed(() => [
  {
    label: '已绑定平台',
    value: new Set(bindingData.value.map((item) => item.platformCode)).size,
    description: '当前一级账号已接入的平台'
  },
  {
    label: '已绑定店铺',
    value: bindingData.value.length,
    description: '可同步数据的店铺账号'
  },
  {
    label: '同步任务',
    value: syncTaskData.value.length,
    description: '订单、售后、评价同步任务'
  }
])
const selfBuiltDemoHint = computed(() => {
  if (selectedSelfBuiltPlatform.value?.code === 'YUEGOU_MARKET') {
    return '当前暂无已创建的悦购集市商家账号。请先在数据库中创建该平台的真实商家账号，再在这里绑定。'
  }
  return '商家端演示账号：20230141 / 123456（极光外设旗舰店），20230142 / 123456（黑曜通勤箱包店），22222223 / 123456（晨光数码生活馆），22222224 / 123456（云途箱包旗舰店）'
})

onMounted(async () => {
  if (new URLSearchParams(window.location.search).get('needBind') === '1') {
    ElMessage({ type: 'warning', message: '请先绑定至少一个电商平台商家账号' })
  }
  loadLocalBindings()
})

watch(bindingData, async (value) => {
  if (!value.length) {
    syncTaskData.value = []
    return
  }
  syncTaskData.value = syncTasks
}, { immediate: true })

async function loadLocalBindings() {
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/primary/bindings?primaryAccountNo=${encodeURIComponent(currentPrimaryAccountNo())}&primaryAccountType=MERCHANT&secondaryAccountRole=MERCHANT`)
    const payload = await response.json()
    if (payload.code === '200') {
      const bindings = (payload.data || []).map((item: {
        platformCode?: string
        secondaryAccountNo: string
        platformName: string
        secondaryDisplayName: string
        bindStatus: string
        boundAt: string
      }) => {
        const platformCode = item.platformCode || platformCodeByName(item.platformName)
        return {
          id: Number(item.secondaryAccountNo) || Date.now(),
          platformCode,
          platformName: item.platformName || platformNameByCode(platformCode),
          authStatus: item.bindStatus === '已绑定' ? 'ACTIVE' : 'UNBOUND',
          externalShopId: `${platformCode}_SHOP_${item.secondaryAccountNo}`,
          shopName: item.secondaryDisplayName || getSelfBuiltMerchantName(item.secondaryAccountNo, item.platformName),
          sellerNick: item.secondaryDisplayName || getSelfBuiltMerchantName(item.secondaryAccountNo, item.platformName),
          accountNo: item.secondaryAccountNo,
          lastSyncedAt: item.boundAt
        }
      }) as MerchantPlatformBinding[]
      clearMerchantBindings()
      bindings.forEach((binding) => saveMerchantBinding(binding))
      bindingData.value = bindings
      return
    }
  } catch {
    // Fallback keeps the page usable when the backend is temporarily unavailable.
  }
  bindingData.value = getMerchantBindings()
}

async function runSync(syncType: string) {
  const currentBinding = bindingData.value[0]
  if (!currentBinding) {
    ElMessage({ type: 'warning', message: '请先绑定电商平台商家账号' })
    return
  }
  syncingType.value = syncType
  try {
    if (isDemoMode()) {
      await new Promise((resolve) => window.setTimeout(resolve, 300))
      ElMessage({ type: 'success', message: '演示模式下已模拟触发同步' })
      return
    }
    await triggerSync(currentBinding.id, syncType)
    ElMessage({ type: 'success', message: '同步任务已触发' })
    syncTaskData.value = await loadSyncTasks(currentBinding.id) as typeof syncTasks
  } catch {
    ElMessage({ type: 'warning', message: '后端暂不可用，当前为演示触发' })
  } finally {
    syncingType.value = ''
  }
}

function bindPlatform(item: (typeof platformOptions)[number]) {
  if (isSelfBuiltPlatform(item.code)) {
    selectedSelfBuiltPlatform.value = item
    selfBuiltForm.value = { accountNo: '', password: '' }
    selfBuiltDialogVisible.value = true
    return
  }
  mockAuthorize(item.name)
}

async function submitSelfBuiltBind() {
  const platform = selectedSelfBuiltPlatform.value
  const accountNo = selfBuiltForm.value.accountNo.trim()
  const password = selfBuiltForm.value.password.trim()
  if (!platform) {
    ElMessage({ type: 'warning', message: '请选择要绑定的平台' })
    return
  }
  if (!accountNo || !password) {
    ElMessage({ type: 'warning', message: `请输入${platform.name}账号和密码` })
    return
  }
  selfBuiltBinding.value = true
  try {
    const response = await fetch(`http://localhost:8080${selfBuiltApiPrefix(platform.code)}/bind`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accountNo,
        password,
        role: 'MERCHANT',
        primaryAccountNo: currentPrimaryAccountNo(),
        primaryAccountType: 'MERCHANT',
        primaryDisplayName: currentPrimaryDisplayName()
      })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      ElMessage({ type: 'error', message: payload.message || '账号或密码错误' })
      return
    }
    await loadLocalBindings()
    selfBuiltDialogVisible.value = false
    ElMessage({ type: 'success', message: `${platform.name}商家账号 ${accountNo} 绑定成功` })
  } catch {
    ElMessage({ type: 'error', message: '请先启动后端服务' })
  } finally {
    selfBuiltBinding.value = false
  }
}

function currentPrimaryAccountNo() {
  const user = getStoredUser<{ username?: string; userId?: number }>()
  return user?.username || String(user?.userId || '13338907681')
}

function currentPrimaryDisplayName() {
  const user = getStoredUser<{ nickname?: string; username?: string }>()
  return user?.nickname || user?.username || currentPrimaryAccountNo()
}

async function unbindPlatform(row: MerchantPlatformBinding) {
  try {
    await ElMessageBox.confirm(
      `确定要解绑 ${row.platformName} 店铺 ${row.shopName} 吗？解绑后该店铺数据将不再显示。`,
      '解绑店铺账号',
      {
        confirmButtonText: '确认解绑',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
  } catch {
    return
  }
  if (isSelfBuiltPlatform(row.platformCode) && row.accountNo) {
    try {
      const response = await fetch(`http://localhost:8080${selfBuiltApiPrefix(row.platformCode)}/unbind`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          accountNo: row.accountNo,
          role: 'MERCHANT',
          primaryAccountNo: currentPrimaryAccountNo(),
          primaryAccountType: 'MERCHANT'
        })
      })
      const payload = await response.json()
      if (payload.code !== '200') {
        throw new Error(payload.message || '解绑失败')
      }
    } catch (error) {
      ElMessage({ type: 'error', message: error instanceof Error ? error.message : '后端解绑失败，请确认后端服务已启动' })
      return
    }
  }
  removeMerchantBinding(row.platformCode, row.externalShopId)
  await loadLocalBindings()
  ElMessage({ type: 'success', message: '已解绑' })
}

function authStatusText(status: string) {
  const statusMap: Record<string, string> = {
    ACTIVE: '已授权',
    EXPIRED: '已过期',
    UNBOUND: '未绑定',
    DISABLED: '已停用'
  }
  return statusMap[status] || status
}

function platformBindingCount(code: string) {
  return bindingData.value.filter((item) => item.platformCode === code).length
}

function platformIcon(code: string) {
  return platformOptions.find((item) => item.code === code)?.icon || twentyMallIcon
}

function isSelfBuiltPlatform(code: string) {
  return code === 'TWENTY_MALL' || code === 'YUEGOU_MARKET'
}

function selfBuiltApiPrefix(code: string) {
  return code === 'YUEGOU_MARKET' ? '/api/yuegou-market' : '/api/twenty-mall'
}

function platformCodeByName(platformName = '') {
  return platformName === '悦购集市' ? 'YUEGOU_MARKET' : 'TWENTY_MALL'
}

function platformNameByCode(platformCode = '') {
  return platformCode === 'YUEGOU_MARKET' ? '悦购集市' : '万象商城'
}

function getSelfBuiltMerchantName(accountNo: string, platformName = '万象商城') {
  return platformName === '悦购集市'
    ? `悦购集市商家店铺（${accountNo}）`
    : getTwentyMallMerchantName(accountNo)
}

function mockAuthorize(platformName = '抖音商城', accountNo = '') {
  const codeMap: Record<string, string> = {
    抖音商城: 'DOUYIN',
    淘宝: 'TAOBAO',
    拼多多: 'PDD',
    京东: 'JD',
    '万象商城': 'TWENTY_MALL',
    '悦购集市': 'YUEGOU_MARKET'
  }
  const code = codeMap[platformName] || 'MOCK'
  const binding: MerchantPlatformBinding = {
    id: Date.now(),
    platformCode: code,
    platformName,
    authStatus: 'ACTIVE',
    externalShopId: accountNo ? `${code}_SHOP_${accountNo}` : `${code}_SHOP_DEMO`,
    shopName: accountNo ? getSelfBuiltMerchantName(accountNo, platformName) : `${platformName}模拟店铺`,
    sellerNick: accountNo ? getSelfBuiltMerchantName(accountNo, platformName) : `${platformName}商家`,
    accountNo: accountNo || '模拟授权',
    lastSyncedAt: '2026-06-27 16:20:00'
  }
  saveMerchantBinding(binding)
  loadLocalBindings()
  ElMessage({ type: 'success', message: `${platformName}店铺已完成模拟绑定` })
}
</script>

<style scoped>
.binding-overview {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
  margin-bottom: 16px;
}

.overview-card {
  min-height: 104px;
  padding: 16px 18px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #fff;
}

.overview-card span,
.overview-card em {
  display: block;
}

.overview-card span {
  color: #64748b;
  font-size: 13px;
}

.overview-card strong {
  display: block;
  margin-top: 8px;
  color: #0f172a;
  font-size: 30px;
  line-height: 1;
}

.overview-card em {
  margin-top: 10px;
  color: #64748b;
  font-size: 12px;
  font-style: normal;
}

.platform-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
  margin-bottom: 16px;
}

.platform-card {
  display: grid;
  grid-template-columns: 48px 1fr auto;
  align-items: center;
  gap: 12px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  padding: 14px;
  background: #fff;
  transition: border-color 0.18s ease, background 0.18s ease, transform 0.18s ease;
}

.platform-card:hover {
  border-color: #bfdbfe;
  background: #f8fbff;
  transform: translateY(-1px);
}

.platform-card.bound {
  border-color: #bbf7d0;
  background: #f7fff9;
}

.platform-card.planned {
  background: #fbfcfe;
}

.platform-card img {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  object-fit: cover;
}

.platform-card strong,
.platform-card span,
.platform-title-row {
  display: block;
}

.platform-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.platform-title-row strong {
  color: #0f172a;
  font-size: 16px;
}

.platform-card span {
  margin-top: 4px;
  color: #64748b;
  font-size: 12px;
}

.binding-notice {
  margin-bottom: 16px;
  padding: 12px 14px;
  border: 1px solid #bbf7d0;
  border-radius: 8px;
  background: #f0fdf4;
  color: #16a34a;
  font-size: 14px;
}

.binding-notice.warning {
  border-color: #fde68a;
  background: #fffbeb;
  color: #b45309;
}

.bound-shops-card {
  margin-bottom: 16px;
  padding: 16px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #fff;
}

.card-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 14px;
}

.table-platform {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.table-platform img {
  width: 24px;
  height: 24px;
  border-radius: 6px;
  object-fit: cover;
}

.binding-table :deep(.el-table__header th) {
  background: #f8fafc;
  color: #64748b;
  font-weight: 700;
}

.sync-panel,
.prepare-panel {
  min-height: 300px;
}

.sync-task-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 14px 16px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #f8fafc;
}

.sync-task-card + .sync-task-card {
  margin-top: 10px;
}

.sync-task-card strong {
  color: #0f172a;
}

.sync-time {
  margin-top: 5px;
  color: #64748b;
  font-size: 12px;
}

.prepare-step {
  display: flex;
  gap: 12px;
  padding: 14px 0;
  border-bottom: 1px solid #edf2f7;
}

.prepare-step:last-child {
  border-bottom: none;
}

.prepare-step > span {
  display: inline-flex;
  width: 28px;
  height: 28px;
  flex: 0 0 28px;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #e2e8f0;
  color: #475569;
  font-size: 13px;
  font-weight: 800;
}

.prepare-step.done > span {
  background: #dcfce7;
  color: #16a34a;
}

.prepare-step strong,
.prepare-step em {
  display: block;
}

.prepare-step strong {
  color: #0f172a;
}

.prepare-step em {
  margin-top: 4px;
  color: #64748b;
  font-size: 12px;
  font-style: normal;
}

@media (max-width: 1280px) {
  .platform-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .binding-overview {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}
</style>
