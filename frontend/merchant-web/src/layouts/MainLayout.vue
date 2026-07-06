<template>
  <el-container class="app-shell">
    <el-aside width="236px" class="sidebar">
      <div class="brand">
        <img class="brand-logo" :src="sidebarBrandIcon" alt="" />
        <div>
          <strong>商家售后中台</strong>
          <span>融合电商服务工作台</span>
        </div>
      </div>
      <el-menu :default-active="$route.path" class="nav-menu">
        <el-menu-item v-for="item in navItems" :key="item.path" :index="item.path" @click="goNav(item.path)">
          <component :is="item.icon" class="nav-icon" />
          <span>{{ item.label }}</span>
        </el-menu-item>
      </el-menu>
      <div class="sidebar-account">
        <el-dropdown trigger="click" placement="top-start">
          <button class="sidebar-avatar-button" type="button">
            <el-avatar v-if="userAvatar" :size="42" :src="userAvatar" />
            <el-avatar v-else :size="42">{{ avatarText }}</el-avatar>
            <span class="sidebar-account-text">
              <strong>{{ displayName }}</strong>
              <em>查看账号信息</em>
            </span>
          </button>
          <template #dropdown>
            <div class="account-popover">
              <div class="account-head">
                <el-avatar v-if="userAvatar" :size="46" :src="userAvatar" />
                <el-avatar v-else :size="46">{{ avatarText }}</el-avatar>
                <div>
                  <strong>{{ displayName }}</strong>
                  <span>{{ accountNo }}</span>
                </div>
              </div>
              <div class="account-line">
                <span>登录状态</span>
                <em>{{ isDemoMode ? '演示模式' : '真实登录' }}</em>
              </div>
              <div class="account-line">
                <span>绑定店铺</span>
                <em>{{ bindingCount }} 个</em>
              </div>
              <button class="account-edit-button" type="button" @click="openProfileDialog">编辑头像和名称</button>
              <button class="logout-menu-button" type="button" @click="logout">退出登录</button>
            </div>
          </template>
        </el-dropdown>
      </div>
    </el-aside>
    <el-container>
      <el-main v-if="staffReady" class="main">
        <router-view />
      </el-main>
      <el-main v-else class="main staff-gate-main">
        <div class="staff-gate-placeholder">
          <strong>正在确认客服身份</strong>
          <span>完成身份确认后即可进入商家端工作台</span>
        </div>
      </el-main>
    </el-container>
    <el-dialog
      v-model="staffDialogVisible"
      title="确认客服身份"
      width="560px"
      class="staff-identity-dialog"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      :show-close="false"
      append-to-body
    >
      <div class="staff-dialog-head">
        <el-avatar :size="58" :src="staffAvatar(staffForm.code)" />
        <div>
          <strong>请选择当前操作客服</strong>
          <span>登录一级账号后必须确认客服身份，后续售后处理、评价异议、知识库维护等操作会写入对应客服日志。</span>
        </div>
      </div>
      <div class="staff-option-grid">
        <button
          v-for="item in staffOptions"
          :key="item.code"
          class="staff-option"
          :class="{ active: staffForm.code === item.code }"
          type="button"
          @click="staffForm.code = item.code"
        >
          <el-avatar :size="42" :src="staffAvatar(item.code)" />
          <span>{{ item.name }}</span>
        </button>
      </div>
      <el-form class="staff-confirm-form" label-position="top">
        <el-form-item label="客服秘钥">
          <el-input
            v-model="staffForm.secret"
            show-password
            placeholder="请输入当前客服秘钥"
            size="large"
            @keyup.enter="confirmStaff"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="logout">退出登录</el-button>
        <el-button type="primary" :loading="staffConfirming" @click="confirmStaff">确认并进入商家端</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="profileDialogVisible" title="编辑商家账号信息" width="520px">
      <el-form label-width="84px">
        <el-form-item label="头像">
          <div class="avatar-editor">
            <el-avatar v-if="profileForm.avatar" :size="64" :src="profileForm.avatar" />
            <el-avatar v-else :size="64">{{ profileForm.displayName.slice(0, 1) || '商' }}</el-avatar>
            <el-button @click="triggerAvatarInput">选择头像</el-button>
            <input ref="avatarInputRef" class="hidden-file" type="file" accept="image/*" @change="onAvatarChange" />
          </div>
        </el-form-item>
        <el-form-item label="名称">
          <el-input v-model="profileForm.displayName" maxlength="32" placeholder="请输入商家端一级账号名称" />
        </el-form-item>
        <el-form-item label="账号">
          <el-input :model-value="accountNo" disabled />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="profileDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="profileSaving" @click="savePrimaryProfile">保存</el-button>
      </template>
    </el-dialog>
  </el-container>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { BarChart3, BookOpen, Bot, ChartNoAxesCombined, ClipboardList, Headphones, RefreshCcw, Store } from 'lucide-vue-next'
import { clearAuth, getMerchantBindings, getStoredUser, getToken, USER_KEY } from '../utils/auth'
import { clearStaffIdentity, getConfirmedStaff, MERCHANT_STAFFS, saveConfirmedStaff, type MerchantStaffIdentity } from '../utils/staffAuth'
import { confirmMerchantStaffIdentity } from '../api'
import sidebarBrandIcon from '../assets/brand/fusion-after-sale-icon.png'
import staffAAvatar from '../assets/avatars/staff-a.png'
import staffBAvatar from '../assets/avatars/staff-b.png'
import staffCAvatar from '../assets/avatars/staff-c.png'
import staffDAvatar from '../assets/avatars/staff-d.png'

const route = useRoute()
const router = useRouter()
const profile = ref({
  accountNo: '',
  displayName: '',
  avatar: ''
})
const profileDialogVisible = ref(false)
const profileSaving = ref(false)
const staffDialogVisible = ref(false)
const staffConfirming = ref(false)
const confirmedStaff = ref<MerchantStaffIdentity | null>(getConfirmedStaff())
const staffOptions = MERCHANT_STAFFS
const staffForm = ref({
  code: confirmedStaff.value?.code || 'A',
  secret: ''
})
const avatarInputRef = ref<HTMLInputElement | null>(null)
const profileForm = ref({
  displayName: '',
  avatar: ''
})
const navItems = [
  { path: '/dashboard', label: '工作台', icon: BarChart3 },
  { path: '/platform', label: '店铺绑定', icon: Store },
  { path: '/after-sales', label: '售后处理', icon: RefreshCcw },
  { path: '/conversations', label: '实时客服', icon: Headphones },
  { path: '/reviews', label: '评价分析', icon: Bot },
  { path: '/statistics', label: '统计分析', icon: ChartNoAxesCombined },
  { path: '/knowledge', label: '知识库', icon: BookOpen },
  { path: '/operation-logs', label: '操作日志', icon: ClipboardList }
]
const staffAvatars: Record<string, string> = {
  A: staffAAvatar,
  B: staffBAvatar,
  C: staffCAvatar,
  D: staffDAvatar
}

const isDemoMode = computed(() => getToken() === 'demo-token')
const bindingCount = ref(getMerchantBindings().length)
const user = computed(() => getStoredUser<{ nickname?: string; username?: string; avatar?: string; phone?: string }>())
const displayName = computed(() => profile.value.displayName || user.value?.nickname || user.value?.username || '商家账号')
const accountNo = computed(() => profile.value.accountNo || user.value?.username || user.value?.phone || '未读取账号')
const userAvatar = computed(() => profile.value.avatar || user.value?.avatar || '')
const avatarText = computed(() => {
  return (displayName.value || accountNo.value || '商').slice(0, 1)
})
const staffReady = computed(() => Boolean(confirmedStaff.value))

watch(
  () => route.fullPath,
  () => {
    bindingCount.value = getMerchantBindings().length
    loadPrimaryProfile()
  },
  { immediate: true }
)

onMounted(() => {
  loadPrimaryProfile()
  window.addEventListener('merchant-staff-required', openStaffDialog)
  ensureStaffDialog()
})

onUnmounted(() => {
  window.removeEventListener('merchant-staff-required', openStaffDialog)
})

function logout() {
  clearStaffIdentity()
  clearAuth()
  router.push('/login')
}

function openStaffDialog() {
  staffDialogVisible.value = true
}

function ensureStaffDialog() {
  confirmedStaff.value = getConfirmedStaff()
  staffDialogVisible.value = !confirmedStaff.value
}

function staffAvatar(code: string) {
  return staffAvatars[code] || staffAAvatar
}

async function confirmStaff() {
  const secret = staffForm.value.secret.trim()
  if (!secret) {
    ElMessage({ type: 'warning', message: '请输入客服秘钥' })
    return
  }
  const currentAccountNo = accountNo.value
  if (!currentAccountNo || currentAccountNo === '未读取账号') {
    ElMessage({ type: 'warning', message: '未读取到商家一级账号，请重新登录' })
    return
  }
  staffConfirming.value = true
  try {
    const staff = await confirmMerchantStaffIdentity(currentAccountNo, staffForm.value.code, secret) as MerchantStaffIdentity
    const confirmed = saveConfirmedStaff(staff)
    confirmedStaff.value = confirmed
    staffForm.value.secret = ''
    staffDialogVisible.value = false
    ElMessage({ type: 'success', message: `已确认为${confirmed.name}` })
  } catch (error) {
    ElMessage({ type: 'error', message: error instanceof Error ? error.message : '客服秘钥错误，请重新输入' })
  } finally {
    staffConfirming.value = false
  }
}

async function loadPrimaryProfile() {
  const currentAccountNo = user.value?.username || user.value?.phone || ''
  if (!currentAccountNo) {
    return
  }
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/primary/profile?accountNo=${encodeURIComponent(currentAccountNo)}&accountType=MERCHANT`)
    const payload = await response.json()
    if (payload.code === '200' && payload.data) {
      profile.value = {
        accountNo: payload.data.accountNo || currentAccountNo,
        displayName: payload.data.displayName || currentAccountNo,
        avatar: payload.data.avatar || ''
      }
    }
  } catch {
    profile.value = {
      accountNo: currentAccountNo,
      displayName: user.value?.nickname || currentAccountNo,
      avatar: user.value?.avatar || ''
    }
  }
}

function openProfileDialog() {
  profileForm.value = {
    displayName: displayName.value,
    avatar: userAvatar.value
  }
  profileDialogVisible.value = true
}

function triggerAvatarInput() {
  avatarInputRef.value?.click()
}

function onAvatarChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = () => {
    profileForm.value.avatar = String(reader.result || '')
  }
  reader.readAsDataURL(file)
  input.value = ''
}

async function savePrimaryProfile() {
  const nextName = profileForm.value.displayName.trim()
  if (!nextName) {
    ElMessage({ type: 'warning', message: '请输入名称' })
    return
  }
  profileSaving.value = true
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/primary/profile', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accountNo: accountNo.value,
        accountType: 'MERCHANT',
        displayName: nextName,
        avatar: profileForm.value.avatar
      })
    })
    const payload = await response.json()
    if (payload.code !== '200' || !payload.data) {
      ElMessage({ type: 'error', message: payload.message || '资料保存失败' })
      return
    }
    profile.value = {
      accountNo: payload.data.accountNo || accountNo.value,
      displayName: payload.data.displayName || nextName,
      avatar: payload.data.avatar || ''
    }
    const currentUser = user.value || {}
    localStorage.setItem(USER_KEY, JSON.stringify({
      ...currentUser,
      nickname: profile.value.displayName,
      avatar: profile.value.avatar
    }))
    window.dispatchEvent(new Event('merchant-profile-updated'))
    profileDialogVisible.value = false
    ElMessage({ type: 'success', message: '账号信息已保存' })
  } catch {
    ElMessage({ type: 'error', message: '资料保存失败，请确认后端服务已启动' })
  } finally {
    profileSaving.value = false
  }
}

function goNav(path: string) {
  bindingCount.value = getMerchantBindings().length
  if (path !== '/platform' && bindingCount.value <= 0) {
    ElMessage({ type: 'warning', message: '需要绑定至少一个电商平台商家账号才能进入该页面' })
    router.push('/platform')
    return
  }
  router.push(path)
}
</script>

<style scoped>
.staff-gate-main {
  display: grid;
  min-height: 100vh;
  place-items: center;
  background: #f6f8fb;
}

.staff-gate-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  color: #64748b;
  font-weight: 700;
}

.staff-gate-placeholder strong {
  color: #0f172a;
  font-size: 18px;
}

:global(.staff-identity-dialog .el-dialog) {
  border-radius: 8px;
}

.staff-dialog-head {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 4px 2px 18px;
  border-bottom: 1px solid #edf2f7;
}

.staff-dialog-head strong,
.staff-dialog-head span {
  display: block;
}

.staff-dialog-head strong {
  color: #0f172a;
  font-size: 20px;
  font-weight: 900;
}

.staff-dialog-head span {
  margin-top: 6px;
  color: #64748b;
  font-size: 13px;
  line-height: 1.6;
}

.staff-option-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
  margin: 18px 0;
}

.staff-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 14px 10px;
  border: 1px solid #dbe3ef;
  border-radius: 8px;
  background: #fff;
  color: #334155;
  cursor: pointer;
  font-size: 13px;
  font-weight: 800;
  transition: border-color 0.18s ease, box-shadow 0.18s ease, background 0.18s ease;
}

.staff-option.active {
  border-color: #2563eb;
  background: #eff6ff;
  box-shadow: 0 10px 24px rgba(37, 99, 235, 0.12);
  color: #1d4ed8;
}

.staff-confirm-form {
  margin-top: 2px;
}
</style>
