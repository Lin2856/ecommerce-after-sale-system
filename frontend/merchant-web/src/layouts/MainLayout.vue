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
      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
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
import { clearStaffIdentity } from '../utils/staffAuth'
import sidebarBrandIcon from '../assets/brand/fusion-after-sale-icon.png'

const route = useRoute()
const router = useRouter()
const profile = ref({
  accountNo: '',
  displayName: '',
  avatar: ''
})
const profileDialogVisible = ref(false)
const profileSaving = ref(false)
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

const isDemoMode = computed(() => getToken() === 'demo-token')
const bindingCount = ref(getMerchantBindings().length)
const user = computed(() => getStoredUser<{ nickname?: string; username?: string; avatar?: string; phone?: string }>())
const displayName = computed(() => profile.value.displayName || user.value?.nickname || user.value?.username || '商家账号')
const accountNo = computed(() => profile.value.accountNo || user.value?.username || user.value?.phone || '未读取账号')
const userAvatar = computed(() => profile.value.avatar || user.value?.avatar || '')
const avatarText = computed(() => {
  return (displayName.value || accountNo.value || '商').slice(0, 1)
})

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
  ElMessage({ type: 'warning', message: '请先在操作日志页面输入客服秘钥确认当前客服' })
  router.push('/operation-logs')
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
