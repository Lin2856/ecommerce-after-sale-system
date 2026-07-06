<template>
  <div class="login-wrap">
    <div class="login-shell">
      <section class="login-brand-panel">
        <div class="brand-head">
          <img class="brand-logo" :src="brandIcon" alt="" />
          <div>
            <h1>商家售后中台</h1>
            <p>统一处理订单、售后、评价与客服消息</p>
          </div>
        </div>

        <div class="brand-visual">
          <img :src="brandIcon" alt="" />
        </div>

        <div class="feature-grid">
          <div class="feature-card">
            <strong>多店铺绑定</strong>
            <span>统一查看已绑定平台账号</span>
          </div>
          <div class="feature-card">
            <strong>售后闭环</strong>
            <span>审核、举证、退款流程联动</span>
          </div>
          <div class="feature-card">
            <strong>客服协同</strong>
            <span>AI 与人工会话无缝切换</span>
          </div>
        </div>
      </section>

      <section class="login-card">
        <div class="form-head">
          <div>
            <span class="form-kicker">MERCHANT LOGIN</span>
            <h2>手机号登录</h2>
            <p>输入手机号与密码进入工作台</p>
          </div>
          <span class="secure-badge">安全登录</span>
        </div>

        <el-form class="login-form" label-position="top" @submit.prevent>
          <el-form-item label="手机号">
            <el-input v-model="phone" size="large" placeholder="请输入手机号" />
          </el-form-item>
          <el-form-item label="密码">
            <el-input v-model="password" size="large" placeholder="请输入密码" type="password" show-password />
          </el-form-item>
          <el-button class="login-submit" type="primary" native-type="button" size="large" :loading="loading" @click="login">
            登录
          </el-button>
        </el-form>

        <div class="login-workbench">
          <strong>商家工作台包含</strong>
          <div>
            <span>待处理售后</span>
            <span>服务动态邮件</span>
            <span>评价异议</span>
            <span>客服操作日志</span>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { clearMerchantBindings, setAuth } from '../utils/auth'
import { clearStaffIdentity } from '../utils/staffAuth'
import { merchantPasswordLogin } from '../api'
import brandIcon from '../assets/brand/fusion-after-sale-icon.png'

const router = useRouter()
const phone = ref('')
const password = ref('')
const loading = ref(false)
async function login() {
  const cleanPhone = phone.value.trim()
  const cleanPassword = password.value.trim()
  if (!cleanPhone) {
    ElMessage({ type: 'warning', message: '请输入手机号' })
    return
  }
  if (!cleanPassword) {
    ElMessage({ type: 'warning', message: '请输入密码' })
    return
  }
  loading.value = true
  try {
    const result = await merchantPasswordLogin(cleanPhone, cleanPassword) as {
      token: string
      user: {
        userId: number
        username: string
        nickname: string
        phone?: string
        avatar?: string
        merchantId?: number | null
        roles: string[]
        loginMode?: string
      }
    }
    setAuth(result.token, result.user)
    clearStaffIdentity()
    if (result.user.username === '13338907682' && localStorage.getItem('merchant_blank_account_initialized:13338907682') !== '1') {
      clearMerchantBindings()
      localStorage.setItem('merchant_blank_account_initialized:13338907682', '1')
    }
    router.push('/platform')
  } catch (error) {
    ElMessage({ type: 'error', message: error instanceof Error ? error.message : '登录失败，请确认后端服务已启动' })
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrap {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 56px 24px;
  background:
    radial-gradient(circle at 30% 20%, rgba(59, 130, 246, 0.14), transparent 32%),
    radial-gradient(circle at 72% 76%, rgba(252, 163, 17, 0.14), transparent 30%),
    linear-gradient(180deg, #f4f8ff 0%, #eef3f9 100%);
  box-sizing: border-box;
}

.login-shell {
  width: min(980px, 100%);
  display: grid;
  grid-template-columns: 1.05fr 0.95fr;
  overflow: hidden;
  border: 1px solid rgba(226, 232, 240, 0.9);
  border-radius: 28px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 30px 80px rgba(15, 23, 42, 0.12);
  backdrop-filter: blur(10px);
}

.login-brand-panel {
  position: relative;
  min-height: 560px;
  padding: 36px;
  overflow: hidden;
  background: linear-gradient(145deg, #ecf6ff 0%, #ffffff 54%, #fff8e8 100%);
}

.login-brand-panel::before {
  content: "";
  position: absolute;
  inset: auto -86px -112px auto;
  width: 300px;
  height: 300px;
  border-radius: 50%;
  background: rgba(31, 122, 224, 0.12);
}

.brand-head {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 16px;
}

.brand-logo {
  width: 64px;
  height: 64px;
  flex-shrink: 0;
  border-radius: 18px;
  box-shadow: 0 14px 28px rgba(31, 122, 224, 0.18);
}

.brand-head h1,
.form-head h2 {
  margin: 0;
  color: #0f172a;
  font-weight: 900;
  letter-spacing: 0;
}

.brand-head h1 {
  font-size: 30px;
}

.brand-head p,
.form-head p {
  margin: 7px 0 0;
  color: #64748b;
  line-height: 1.5;
}

.brand-visual {
  position: relative;
  z-index: 1;
  display: flex;
  justify-content: center;
  margin: 34px 0 28px;
}

.brand-visual img {
  width: min(330px, 82%);
  border-radius: 34px;
  filter: drop-shadow(0 24px 36px rgba(59, 130, 246, 0.18));
}

.feature-grid {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.feature-card {
  min-height: 88px;
  padding: 14px;
  border: 1px solid rgba(226, 232, 240, 0.86);
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.78);
  box-sizing: border-box;
}

.feature-card strong,
.feature-card span {
  display: block;
}

.feature-card strong {
  color: #0f172a;
  font-size: 15px;
}

.feature-card span {
  margin-top: 8px;
  color: #64748b;
  font-size: 12px;
  line-height: 1.45;
}

.login-card {
  width: auto;
  padding: 48px 42px;
  border: 0;
  border-radius: 0;
  background: #fff;
  box-shadow: none;
}

.form-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 28px;
}

.form-kicker {
  display: block;
  margin-bottom: 8px;
  color: #2563eb;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
}

.form-head h2 {
  font-size: 28px;
}

.secure-badge {
  flex-shrink: 0;
  padding: 7px 12px;
  border-radius: 999px;
  background: #ecfdf3;
  color: #16a34a;
  font-size: 13px;
  font-weight: 800;
}

.login-form :deep(.el-form-item) {
  margin-bottom: 18px;
}

.login-form :deep(.el-form-item__label) {
  color: #475569;
  font-weight: 700;
}

.login-form :deep(.el-input__wrapper) {
  border-radius: 12px;
  box-shadow: 0 0 0 1px #dbe5f1 inset;
}

.login-submit {
  width: 100%;
  height: 44px;
  margin-top: 4px;
  border-radius: 12px;
  font-weight: 800;
  box-shadow: 0 12px 24px rgba(37, 99, 235, 0.22);
}

.login-workbench {
  margin-top: 24px;
  padding: 18px;
  border: 1px solid #e7eef8;
  border-radius: 16px;
  background: linear-gradient(180deg, #f8fbff 0%, #ffffff 100%);
}

.login-workbench strong {
  display: block;
  color: #0f172a;
  font-size: 15px;
  font-weight: 900;
}

.login-workbench div {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin-top: 12px;
}

.login-workbench span {
  padding: 10px 12px;
  border-radius: 12px;
  background: #fff;
  color: #475569;
  font-size: 12px;
  font-weight: 800;
}

@media (max-width: 860px) {
  .login-shell {
    grid-template-columns: 1fr;
  }

  .login-brand-panel {
    min-height: auto;
  }

  .feature-grid {
    grid-template-columns: 1fr;
  }

  .login-workbench div {
    grid-template-columns: 1fr;
  }

  .brand-visual img {
    width: 240px;
  }
}
</style>
