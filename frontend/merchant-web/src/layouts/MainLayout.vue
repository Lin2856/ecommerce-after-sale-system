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
  </el-container>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { BarChart3, BookOpen, Bot, ChartNoAxesCombined, Headphones, RefreshCcw, Store } from 'lucide-vue-next'
import { clearAuth, getMerchantBindings, getStoredUser, getToken } from '../utils/auth'
import sidebarBrandIcon from '../assets/brand/fusion-after-sale-icon.png'

const route = useRoute()
const router = useRouter()
const profile = ref({
  accountNo: '',
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
  { path: '/knowledge', label: '知识库', icon: BookOpen }
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

onMounted(loadPrimaryProfile)

function logout() {
  clearAuth()
  router.push('/login')
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
