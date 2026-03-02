<template>
  <div class="login-page">
    <div class="login-bg">
      <div class="bg-shape shape-1"></div>
      <div class="bg-shape shape-2"></div>
      <div class="bg-shape shape-3"></div>
    </div>

    <div class="login-container">
      <!-- Left: Branding -->
      <div class="login-branding">
        <div class="brand-content">
          <div class="brand-logo">
            <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
              <rect width="48" height="48" rx="14" fill="url(#lg)"/>
              <path d="M14 18h20M14 24h14M14 30h17" stroke="#fff" stroke-width="2.5" stroke-linecap="round"/>
              <defs><linearGradient id="lg" x1="0" y1="0" x2="48" y2="48"><stop stop-color="#2dd4bf"/><stop offset="1" stop-color="#0d9488"/></linearGradient></defs>
            </svg>
          </div>
          <h1>F-AI</h1>
          <p class="brand-tagline">智能财务助理平台</p>
          <div class="brand-features">
            <div class="feature-item">
              <div class="feature-dot"></div>
              <span>AI 智能异常检测与预警</span>
            </div>
            <div class="feature-item">
              <div class="feature-dot"></div>
              <span>自动生成专业财务报表</span>
            </div>
            <div class="feature-item">
              <div class="feature-dot"></div>
              <span>数据驱动的预算预测</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Login Form -->
      <div class="login-form-wrapper">
        <div class="login-form-inner">
          <div class="form-header">
            <h2>欢迎回来</h2>
            <p>请登录您的账号</p>
          </div>

          <a-form :model="form" @finish="handleLogin" layout="vertical" class="login-form">
            <a-form-item name="username" :rules="[{ required: true, message: '请输入用户名' }]">
              <a-input
                v-model:value="form.username"
                size="large"
                placeholder="用户名"
                class="form-input"
              >
                <template #prefix><UserOutlined style="color: var(--text-muted);" /></template>
              </a-input>
            </a-form-item>

            <a-form-item name="password" :rules="[{ required: true, message: '请输入密码' }]">
              <a-input-password
                v-model:value="form.password"
                size="large"
                placeholder="密码"
                class="form-input"
              >
                <template #prefix><LockOutlined style="color: var(--text-muted);" /></template>
              </a-input-password>
            </a-form-item>

            <a-form-item>
              <a-button type="primary" html-type="submit" size="large" block :loading="loading" class="btn-primary login-btn">
                登录
              </a-button>
            </a-form-item>
          </a-form>

          <div class="form-footer">
            还没有账号？<router-link to="/register" class="link-primary">立即注册</router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { UserOutlined, LockOutlined } from '@ant-design/icons-vue'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const loading = ref(false)
const form = reactive({ username: '', password: '' })

async function handleLogin() {
  loading.value = true
  try {
    await userStore.login(form.username, form.password)
    message.success('登录成功')
    router.push('/')
  } catch {
    message.error('用户名或密码错误')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped lang="less">
.login-page {
  min-height: 100vh;
  position: relative;
  overflow: hidden;
  background: #f8f9fb;
}

.login-bg {
  position: absolute;
  inset: 0;
  overflow: hidden;

  .bg-shape {
    position: absolute;
    border-radius: 50%;
    filter: blur(80px);
    opacity: 0.4;
  }

  .shape-1 {
    width: 450px; height: 450px;
    background: #99f6e4;
    top: -120px; right: -80px;
  }
  .shape-2 {
    width: 350px; height: 350px;
    background: #a7f3d0;
    bottom: -80px; left: -40px;
  }
  .shape-3 {
    width: 250px; height: 250px;
    background: #fde68a;
    top: 45%; left: 35%;
  }
}

.login-container {
  position: relative;
  z-index: 1;
  display: flex;
  min-height: 100vh;
}

.login-branding {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
}

.brand-content {
  max-width: 380px;
  color: #fff;

  h1 {
    font-size: 40px;
    font-weight: 800;
    margin: 20px 0 8px;
    letter-spacing: 1px;
  }

  .brand-tagline {
    font-size: 15px;
    color: rgba(255, 255, 255, 0.6);
    margin-bottom: 44px;
  }
}

.brand-features {
  display: flex;
  flex-direction: column;
  gap: 18px;

  .feature-item {
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 14px;
    color: rgba(255, 255, 255, 0.8);
  }

  .feature-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #2dd4bf;
    flex-shrink: 0;
  }
}

.login-form-wrapper {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px;
}

.login-form-inner {
  width: 100%;
  max-width: 360px;
}

.form-header {
  margin-bottom: 32px;

  h2 {
    font-size: 26px;
    font-weight: 700;
    color: var(--text-primary);
    margin: 0 0 6px;
  }

  p {
    font-size: 14px;
    color: var(--text-secondary);
    margin: 0;
  }
}

.form-input {
  height: 46px !important;
  border-radius: 8px !important;
  font-size: 14px;

  :deep(.ant-input) {
    height: 46px;
  }
}

.login-btn {
  height: 46px !important;
  font-size: 15px !important;
  border-radius: 8px !important;
  margin-top: 8px;
}

.form-footer {
  text-align: center;
  margin-top: 20px;
  font-size: 14px;
  color: var(--text-secondary);

  .link-primary {
    color: var(--primary);
    font-weight: 600;
    text-decoration: none;

    &:hover {
      text-decoration: underline;
    }
  }
}
</style>
