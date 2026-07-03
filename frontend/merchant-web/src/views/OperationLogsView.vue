<template>
  <div class="operation-log-page">
    <section class="operation-log-hero">
      <div>
        <h1>操作日志</h1>
        <p>记录客服在售后处理、争议订单、评价异议与知识库维护中的关键操作。</p>
      </div>
      <el-button type="primary" :loading="loading" @click="loadLogs">刷新日志</el-button>
    </section>

    <section class="panel operation-staff-switch">
      <div class="operation-staff-current">
        <el-avatar v-if="confirmedStaff" :size="44" :src="staffAvatar(confirmedStaff.code)" />
        <el-avatar v-else :size="44">未</el-avatar>
        <div>
          <strong>{{ confirmedStaff ? confirmedStaff.name : '未确认客服身份' }}</strong>
          <span>{{ confirmedStaff ? '后续关键操作将以该客服身份写入操作日志' : '请先输入客服秘钥确认当前操作客服' }}</span>
        </div>
      </div>
      <div class="operation-staff-form">
        <el-select v-model="staffForm.code" placeholder="选择客服">
          <el-option v-for="item in staffOptions" :key="item.code" :label="item.name" :value="item.code" />
        </el-select>
        <el-input v-model="staffForm.secret" show-password placeholder="输入客服秘钥" @keyup.enter="switchStaff" />
        <el-button type="primary" @click="switchStaff">{{ confirmedStaff ? '切换客服' : '确认客服' }}</el-button>
        <el-button :disabled="!confirmedStaff" @click="logoutStaff">退出当前客服身份</el-button>
      </div>
    </section>

    <section class="panel operation-log-filter">
      <el-input v-model="keyword" clearable placeholder="搜索操作内容、目标对象或账号" />
      <el-select v-model="staffFilter" placeholder="客服">
        <el-option label="全部客服" value="ALL" />
        <el-option v-for="item in staffOptions" :key="item.code" :label="item.name" :value="item.code" />
      </el-select>
      <el-button @click="resetFilters">重置</el-button>
    </section>

    <section class="panel operation-log-card">
      <el-table :data="filteredLogs" empty-text="暂无操作日志">
        <el-table-column label="客服" width="150">
          <template #default="{ row }">
            <div class="operation-log-staff">
              <el-avatar :size="34" :src="staffAvatar(row.staffCode)" />
              <div>
                <strong>{{ row.staffName }}</strong>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="primaryAccount" label="一级账号" min-width="150" />
        <el-table-column prop="actionName" label="操作" min-width="160" />
        <el-table-column prop="targetType" label="对象类型" width="130" />
        <el-table-column prop="targetId" label="对象编号" min-width="150" />
        <el-table-column prop="detail" label="操作内容" min-width="260" show-overflow-tooltip />
        <el-table-column prop="createdAt" label="操作时间" width="180" />
      </el-table>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { loadOperationLogs } from '../api'
import { getStoredUser } from '../utils/auth'
import { clearStaffIdentity, confirmStaffIdentity, getConfirmedStaff, MERCHANT_STAFFS, type MerchantStaffIdentity } from '../utils/staffAuth'
import staffAAvatar from '../assets/avatars/staff-a.png'
import staffBAvatar from '../assets/avatars/staff-b.png'
import staffCAvatar from '../assets/avatars/staff-c.png'
import staffDAvatar from '../assets/avatars/staff-d.png'

type OperationLog = {
  id: number
  primaryAccount: string
  staffCode: string
  staffName: string
  actionType: string
  actionName: string
  targetType: string
  targetId: string
  detail: string
  createdAt: string
}

const logs = ref<OperationLog[]>([])
const loading = ref(false)
const keyword = ref('')
const staffFilter = ref('ALL')
const staffOptions = MERCHANT_STAFFS
const user = computed(() => getStoredUser<{ username?: string; phone?: string }>())
const confirmedStaff = ref<MerchantStaffIdentity | null>(getConfirmedStaff())
const staffForm = ref({
  code: confirmedStaff.value?.code || 'A',
  secret: ''
})
const staffAvatars: Record<string, string> = {
  A: staffAAvatar,
  B: staffBAvatar,
  C: staffCAvatar,
  D: staffDAvatar
}

const filteredLogs = computed(() => {
  const key = keyword.value.trim().toLowerCase()
  return logs.value.filter((item) => {
    const staffMatched = staffFilter.value === 'ALL' || item.staffCode === staffFilter.value
    const text = [
      item.primaryAccount,
      item.staffName,
      item.actionName,
      item.targetType,
      item.targetId,
      item.detail
    ].join(' ').toLowerCase()
    return staffMatched && (!key || text.includes(key))
  })
})

onMounted(loadLogs)

function resetFilters() {
  keyword.value = ''
  staffFilter.value = 'ALL'
}

function switchStaff() {
  const staff = confirmStaffIdentity(staffForm.value.code, staffForm.value.secret)
  if (!staff) {
    ElMessage({ type: 'error', message: '客服秘钥错误，请重新输入' })
    return
  }
  confirmedStaff.value = staff
  staffForm.value.secret = ''
  ElMessage({ type: 'success', message: `已切换为${staff.name}` })
}

function logoutStaff() {
  clearStaffIdentity()
  confirmedStaff.value = null
  staffForm.value.secret = ''
  ElMessage({ type: 'success', message: '已退出当前客服身份' })
}

function staffAvatar(code: string) {
  return staffAvatars[code] || staffAAvatar
}

async function loadLogs() {
  loading.value = true
  try {
    const primaryAccount = user.value?.username || user.value?.phone || ''
    logs.value = await loadOperationLogs(primaryAccount) as OperationLog[]
  } catch {
    logs.value = []
    ElMessage({ type: 'warning', message: '操作日志暂时无法读取，请确认后端服务和数据库表已启动' })
  } finally {
    loading.value = false
  }
}
</script>
