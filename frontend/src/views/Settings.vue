<template>
  <div>
    <div class="page-title">
      <h2>系统设置</h2>
      <p>个人信息与企业管理</p>
    </div>

    <a-row :gutter="24">
      <a-col :span="12">
        <a-card :bordered="false">
          <template #title>
            <div style="display: flex; align-items: center; gap: 8px;">
              <UserOutlined /> 个人信息
            </div>
          </template>

          <div class="profile-header" v-if="userStore.userInfo">
            <a-avatar
              :size="72"
              class="profile-avatar"
              :class="{ 'avatar-type-image': userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image }"
              :style="userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image ? {} : { background: userStore.avatarConfig.bgColor + ' !important' }"
            >
              <img
                v-if="userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image"
                :src="userStore.avatarConfig.image"
                alt="头像"
              />
              <span v-else>{{ userStore.userInfo.username?.charAt(0)?.toUpperCase() }}</span>
            </a-avatar>
            <div class="profile-meta">
              <h3>{{ userStore.userInfo.username }}</h3>
              <a-tag :color="roleTagMap[userStore.userInfo.role]" style="border-radius: 6px;">
                {{ roleMap[userStore.userInfo.role] }}
              </a-tag>
            </div>
          </div>

          <a-divider style="margin: 20px 0;" />

          <div class="info-list" v-if="userStore.userInfo">
            <div class="info-row">
              <span class="info-label"><MailOutlined /> 邮箱</span>
              <span class="info-value">{{ userStore.userInfo.email }}</span>
            </div>
            <div class="info-row">
              <span class="info-label"><SafetyOutlined /> 账号状态</span>
              <a-badge :status="userStore.userInfo.is_active ? 'success' : 'error'" :text="userStore.userInfo.is_active ? '正常' : '已禁用'" />
            </div>
            <div class="info-row">
              <span class="info-label"><TeamOutlined /> 企业 ID</span>
              <span class="info-value">{{ userStore.userInfo.company_id || '未绑定' }}</span>
            </div>
          </div>
        </a-card>

        <a-card :bordered="false" style="margin-top: 20px;">
          <template #title>
            <div style="display: flex; align-items: center; gap: 8px;">
              <UserOutlined /> 头像设置
            </div>
          </template>
          <div class="avatar-config">
            <div class="avatar-preview-wrap">
              <a-avatar
                :size="64"
                class="preview-avatar"
                :class="{ 'avatar-type-image': userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image }"
                :style="userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image ? {} : { background: userStore.avatarConfig.bgColor + ' !important' }"
              >
                <img
                  v-if="userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image"
                  :src="userStore.avatarConfig.image"
                  alt="头像"
                />
                <span v-else>{{ userStore.userInfo?.username?.charAt(0)?.toUpperCase() || 'U' }}</span>
              </a-avatar>
              <span class="preview-label">预览</span>
            </div>

            <a-radio-group v-model:value="userStore.avatarConfig.type" @change="onAvatarTypeChange" style="margin-bottom: 16px;">
              <a-radio value="letter">首字母</a-radio>
              <a-radio value="image">图片</a-radio>
            </a-radio-group>

            <template v-if="userStore.avatarConfig.type === 'letter'">
              <div class="config-label">背景色</div>
              <div class="avatar-colors">
                <span
                  v-for="c in AVATAR_COLORS"
                  :key="c"
                  class="color-dot"
                  :class="{ active: userStore.avatarConfig.bgColor === c }"
                  :style="{ background: c }"
                  @click="userStore.setAvatar({ bgColor: c })"
                />
              </div>
            </template>

            <template v-else>
              <div class="config-label">选择头像（资源路径：`src/assets/icon`）</div>
              <div class="avatar-grid" v-if="avatarImageUrls.length">
                <div
                  v-for="(url, idx) in avatarImageUrls"
                  :key="idx"
                  class="avatar-cell"
                  :class="{ active: userStore.avatarConfig.image === url }"
                  @click="userStore.setAvatar({ type: 'image', image: url })"
                >
                  <img :src="url" alt="" />
                </div>
              </div>
              <div v-else class="avatar-empty-hint">
                请在 <code>frontend/src/assets/icon</code> 目录放置头像图片（如 <code>a1.png ~ a10.png</code>）。
              </div>
            </template>
          </div>
        </a-card>

        <a-card :bordered="false" style="margin-top: 20px;">
          <template #title>
            <div style="display: flex; align-items: center; gap: 8px;">
              <FontSizeOutlined /> 系统字体
            </div>
          </template>
          <div class="font-config">
            <div class="config-label">字体资源路径：<code>frontend/src/assets/fonts</code></div>
            <a-radio-group v-model:value="fontKeyModel" class="font-options">
              <a-radio
                v-for="opt in FONT_OPTIONS"
                :key="opt.value"
                :value="opt.value"
                class="font-option"
              >
                <span :style="{ fontFamily: opt.value === 'system-default' ? undefined : opt.preview }">{{ opt.label }}</span>
              </a-radio>
            </a-radio-group>
          </div>
        </a-card>
      </a-col>

      <a-col :span="12">
        <a-card :bordered="false" v-if="!userStore.userInfo?.company_id">
          <template #title>
            <div style="display: flex; align-items: center; gap: 8px;">
              <BankOutlined /> 创建企业
            </div>
          </template>

          <div class="create-company-hint">
            <div class="hint-icon">
              <BankOutlined />
            </div>
            <p>创建企业后，才能使用财务管理相关功能。</p>
          </div>

          <a-form :model="companyForm" @finish="handleCreateCompany" layout="vertical" style="margin-top: 20px;">
            <a-form-item label="企业名称" :rules="[{ required: true, message: '请输入企业名称' }]">
              <a-input v-model:value="companyForm.name" placeholder="请输入企业名称" size="large" />
            </a-form-item>

            <a-form-item label="所属行业">
              <a-select v-model:value="companyForm.industry" placeholder="选择行业" size="large" allow-clear>
                <a-select-option value="制造业">制造业</a-select-option>
                <a-select-option value="服务业">服务业</a-select-option>
                <a-select-option value="零售业">零售业</a-select-option>
                <a-select-option value="科技">科技</a-select-option>
                <a-select-option value="教育">教育</a-select-option>
                <a-select-option value="医疗">医疗</a-select-option>
                <a-select-option value="金融">金融</a-select-option>
                <a-select-option value="其他">其他</a-select-option>
              </a-select>
            </a-form-item>

            <a-button type="primary" html-type="submit" :loading="creating" block class="btn-primary" size="large">
              <PlusOutlined /> 创建企业
            </a-button>
          </a-form>

          <div class="company-action-row">
            <span>已有企业 ID？</span>
            <a-button type="link" @click="openJoinCompanyModal">加入企业</a-button>
          </div>
        </a-card>

        <a-card :bordered="false" v-else>
          <template #title>
            <div style="display: flex; align-items: center; gap: 8px;">
              <BankOutlined /> 企业信息
            </div>
          </template>

          <div class="company-success">
            <div class="success-icon">
              <CheckCircleOutlined />
            </div>
            <h3>企业已绑定</h3>
            <p>企业 ID: {{ userStore.userInfo?.company_id }}</p>
          </div>
        </a-card>

        <a-card :bordered="false" style="margin-top: 20px;">
          <template #title>
            <div style="display: flex; align-items: center; gap: 8px;">
              <ApiOutlined /> AI API 配置
            </div>
          </template>

          <a-form :model="aiConfigForm" layout="vertical" @finish="handleSaveAiConfig">
            <a-form-item label="API Base URL">
              <a-input v-model:value="aiConfigForm.base_url" placeholder="例如 https://api.openai.com/v1" />
            </a-form-item>
            <a-form-item label="API Key">
              <a-input-password v-model:value="aiConfigForm.api_key" placeholder="留空则不修改已保存的 Key" autocomplete="off" />
            </a-form-item>
            <a-form-item label="模型">
              <a-input v-model:value="aiConfigForm.model" placeholder="例如 gpt-4.1、gpt-4o-mini" />
            </a-form-item>
            <div style="display: flex; gap: 8px;">
              <a-button type="primary" html-type="submit" :loading="aiConfigSaving">保存配置</a-button>
              <a-button @click="handleTestAiConnection" :loading="aiConfigTesting">测试连接</a-button>
            </div>
          </a-form>
        </a-card>

        <a-card :bordered="false" style="margin-top: 20px;">
          <template #title>
            <div style="display: flex; align-items: center; gap: 8px;">
              <InfoCircleOutlined /> 关于系统
            </div>
          </template>
          <div class="about-list">
            <div class="about-row">
              <span>系统版本</span>
              <a-tag style="border-radius: 6px;">v1.0.0</a-tag>
            </div>
            <div class="about-row">
              <span>前端框架</span>
              <span style="color: var(--text-secondary);">Vue 3 + Ant Design Vue</span>
            </div>
            <div class="about-row">
              <span>后端框架</span>
              <span style="color: var(--text-secondary);">Python FastAPI</span>
            </div>
            <div class="about-row">
              <span>AI 引擎</span>
              <span style="color: var(--text-secondary);">LLM API</span>
            </div>
          </div>
        </a-card>
      </a-col>
    </a-row>

    <a-modal
      v-model:open="joinModalOpen"
      wrap-class-name="join-company-modal"
      title="加入企业"
      ok-text="加入"
      cancel-text="取消"
      :confirm-loading="joining"
      @ok="handleJoinCompany"
    >
      <div class="join-modal-body">
        <div class="join-modal-tip">
          <span class="join-modal-tip__icon">i</span>
          <div class="join-modal-tip__content">
            <span class="join-modal-tip__title">快速加入企业</span>
            <span class="join-modal-tip__desc">输入 9 位企业 ID，即可加入对应企业。</span>
          </div>
        </div>
      </div>
      <a-form layout="vertical" class="join-modal-form">
        <a-form-item label="企业 ID（9 位数字）">
          <a-input
            v-model:value="joinForm.company_id"
            placeholder="请输入 9 位企业 ID"
            maxlength="9"
            size="large"
            @input="onJoinCompanyIdInput"
          />
          <div class="join-modal-meta">
            <span>仅支持数字</span>
            <span>{{ joinForm.company_id.length }}/9</span>
          </div>
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import {
  UserOutlined, MailOutlined, SafetyOutlined, TeamOutlined,
  BankOutlined, PlusOutlined, CheckCircleOutlined, InfoCircleOutlined,
  FontSizeOutlined, ApiOutlined,
} from '@ant-design/icons-vue'
import { useUserStore } from '@/stores/user'
import { authApi } from '@/api/auth'
import { aiApi } from '@/api/financial'
import { FONT_OPTIONS, AVATAR_COLORS } from '@/stores/user'

const userStore = useUserStore()
const creating = ref(false)
const joining = ref(false)
const joinModalOpen = ref(false)

const avatarImageUrls = Object.values(
  import.meta.glob<{ default: string }>('@/assets/icon/*.{png,jpg,jpeg,webp}', { eager: true, import: 'default' })
) as string[]

const roleMap: Record<string, string> = { admin: '企业管理员', accountant: '会计', viewer: '查看者' }
const roleTagMap: Record<string, string> = { admin: 'red', accountant: 'blue', viewer: 'default' }

const companyForm = reactive({ name: '', industry: undefined as string | undefined })
const joinForm = reactive({ company_id: '' })

const aiConfigForm = reactive({ base_url: '', api_key: '', model: '' })
const aiConfigSaving = ref(false)
const aiConfigTesting = ref(false)

function onAvatarTypeChange() {
  if (userStore.avatarConfig.type === 'letter') {
    userStore.setAvatar({ image: '' })
  }
}

const fontKeyModel = computed({
  get: () => userStore.fontKey,
  set: (val: string) => { if (val) userStore.setFont(val) },
})

async function loadAiConfig() {
  try {
    const res = await aiApi.getConfig()
    const data = res?.data ?? res
    aiConfigForm.base_url = data?.base_url ?? ''
    aiConfigForm.model = data?.model ?? ''
    aiConfigForm.api_key = ''
  } catch {
    // AI 配置接口可选，忽略加载错误
  }
}

async function handleSaveAiConfig() {
  aiConfigSaving.value = true
  try {
    await aiApi.saveConfig({
      base_url: aiConfigForm.base_url || undefined,
      api_key: aiConfigForm.api_key || undefined,
      model: aiConfigForm.model || undefined,
    })
    message.success('AI 配置已保存')
    aiConfigForm.api_key = ''
  } catch {
    message.error('保存失败')
  } finally {
    aiConfigSaving.value = false
  }
}

async function handleTestAiConnection() {
  aiConfigTesting.value = true
  try {
    const res: any = await aiApi.testConnection()
    const ok = Boolean(res?.success)
    const msg = res?.message || (ok ? '连接成功' : '连接失败')
    const model = res?.model ? `（模型: ${res.model}）` : ''
    const latency = Number.isFinite(res?.latency_ms) ? `，耗时 ${res.latency_ms}ms` : ''

    if (ok) {
      message.success(`${msg}${model}${latency}`)
    } else {
      message.error(`${msg}${model}${latency}`)
    }
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '连接失败')
  } finally {
    aiConfigTesting.value = false
  }
}

async function handleCreateCompany() {
  creating.value = true
  try {
    await authApi.createCompany({ name: companyForm.name, industry: companyForm.industry })
    message.success('企业创建成功')
    await userStore.fetchUserInfo()
  } catch {
    message.error('创建失败')
  } finally {
    creating.value = false
  }
}

function openJoinCompanyModal() {
  joinForm.company_id = ''
  joinModalOpen.value = true
}

function onJoinCompanyIdInput() {
  joinForm.company_id = joinForm.company_id.replace(/\D/g, '').slice(0, 9)
}

async function handleJoinCompany() {
  const companyId = joinForm.company_id.trim()
  if (!/^\d{9}$/.test(companyId)) {
    message.warning('请输入 9 位数字企业 ID')
    return
  }

  joining.value = true
  try {
    await authApi.joinCompany({ company_id: Number(companyId) })
    message.success('加入企业成功')
    joinModalOpen.value = false
    await userStore.fetchUserInfo()
  } catch {
    message.error('加入企业失败')
  } finally {
    joining.value = false
  }
}

onMounted(loadAiConfig)
</script>

<style scoped lang="less">
.profile-header {
  display: flex;
  align-items: center;
  gap: 20px;
}

.profile-avatar {
  font-size: 28px !important;
  font-weight: 700;
  &:not(.avatar-type-image) { background: linear-gradient(135deg, #0d9488, #2dd4bf) !important; }
  &.avatar-type-image { background: transparent !important; }
  img { width: 100%; height: 100%; object-fit: cover; border-radius: 50%; }
}

.profile-meta {
  h3 {
    font-size: 20px;
    font-weight: 700;
    color: var(--text-primary);
    margin: 0 0 6px;
  }
}

.info-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;

  .info-label {
    font-size: 14px;
    color: var(--text-secondary);
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .info-value {
    font-size: 14px;
    font-weight: 500;
    color: var(--text-primary);
  }
}

.create-company-hint {
  text-align: center;
  padding: 16px 0;

  .hint-icon {
    width: 64px;
    height: 64px;
    border-radius: 16px;
    background: var(--primary-bg);
    color: var(--primary);
    font-size: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 12px;
  }

  p {
    font-size: 14px;
    color: var(--text-secondary);
    margin: 0;
  }
}

.company-action-row {
  margin-top: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  color: var(--text-secondary);
}

.company-success {
  text-align: center;
  padding: 32px 0;

  .success-icon {
    font-size: 56px;
    color: #10b981;
    margin-bottom: 12px;
  }

  h3 {
    font-size: 18px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 4px;
  }

  p {
    font-size: 14px;
    color: var(--text-muted);
    margin: 0;
  }
}

.about-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.about-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  color: var(--text-primary);
}

.avatar-config {
  .avatar-preview-wrap {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;

    .preview-avatar {
      font-size: 24px !important;
      font-weight: 700;
      &:not(.avatar-type-image) { background: var(--primary) !important; }
      &.avatar-type-image { background: transparent !important; }
      img { width: 100%; height: 100%; object-fit: cover; border-radius: 50%; }
    }

    .preview-label {
      font-size: 13px;
      color: var(--text-muted);
    }
  }

  .config-label {
    font-size: 13px;
    color: var(--text-secondary);
    margin-bottom: 8px;
  }

  .avatar-colors {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
  }

  .color-dot {
    width: 28px;
    height: 28px;
    border-radius: 50%;
    cursor: pointer;
    border: 2px solid transparent;

    &.active {
      border-color: var(--primary);
      box-shadow: 0 0 0 2px var(--primary-light);
    }
  }

  .avatar-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(48px, 1fr));
    gap: 10px;
  }

  .avatar-cell {
    width: 48px;
    height: 48px;
    border-radius: 8px;
    overflow: hidden;
    cursor: pointer;
    border: 2px solid transparent;

    &.active {
      border-color: var(--primary);
    }

    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  }

  .avatar-empty-hint {
    font-size: 13px;
    color: var(--text-muted);

    code {
      background: var(--bg-secondary);
      padding: 2px 6px;
      border-radius: 4px;
    }
  }
}

.font-config {
  .config-label {
    font-size: 13px;
    color: var(--text-secondary);
    margin-bottom: 12px;
  }

  .font-options {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .font-option {
    display: block;
  }
}

.join-modal-body {
  margin-bottom: 8px;
}

.join-modal-tip {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 9px;
  border-radius: 14px;
  border: 1px solid rgba(147, 197, 253, 0.75);
  background:
    linear-gradient(135deg, rgba(255, 255, 255, 0.82) 0%, rgba(239, 246, 255, 0.88) 48%, rgba(219, 234, 254, 0.85) 100%);
  box-shadow:
    0 8px 22px rgba(30, 64, 175, 0.12),
    inset 0 1px 0 rgba(255, 255, 255, 0.65);
  backdrop-filter: blur(4px);
  padding: 11px 12px;
}

.join-modal-tip::after {
  content: '';
  position: absolute;
  left: 20px;
  bottom: -6px;
  width: 10px;
  height: 10px;
  background: #edf4ff;
  border-left: 1px solid rgba(147, 197, 253, 0.75);
  border-bottom: 1px solid rgba(147, 197, 253, 0.75);
  transform: rotate(-45deg);
}

.join-modal-tip__icon {
  width: 22px;
  height: 22px;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(165deg, #3b82f6 0%, #1d4ed8 100%);
  color: #ffffff;
  font-size: 12px;
  font-weight: 700;
  line-height: 1;
  margin-top: 1px;
  box-shadow: 0 6px 14px rgba(37, 99, 235, 0.3);
}

.join-modal-tip__content {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.join-modal-tip__title {
  color: #1e40af;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 0.01em;
  line-height: 1.2;
}

.join-modal-tip__desc {
  color: #334155;
  font-size: 12px;
  line-height: 1.35;
}

.join-modal-meta {
  margin-top: 8px;
  display: flex;
  justify-content: space-between;
  color: #64748b;
  font-size: 12px;
}

:deep(.join-company-modal .ant-modal-content) {
  border-radius: 16px;
  border: 1px solid #e6edf7;
  box-shadow: 0 16px 42px rgba(15, 23, 42, 0.16);
  overflow: hidden;
}

:deep(.join-company-modal .ant-modal-header) {
  padding: 18px 20px 12px;
  border-bottom: 1px solid #edf2f7;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
}

:deep(.join-company-modal .ant-modal-title) {
  font-size: 22px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: 0.01em;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
}

:deep(.join-company-modal .ant-modal-body) {
  padding: 16px 20px 8px;
}

:deep(.join-company-modal .join-modal-form .ant-form-item-label > label) {
  color: #334155;
  font-weight: 600;
}

:deep(.join-company-modal .join-modal-form .ant-input) {
  border-radius: 12px;
  border-color: #d7dfeb;
  background: linear-gradient(180deg, #ffffff 0%, #fcfdff 100%);
  font-variant-numeric: tabular-nums;
  font-size: 17px;
  font-weight: 600;
  letter-spacing: 0.08em;
  transition: all 0.2s ease;
}

:deep(.join-company-modal .join-modal-form .ant-input:hover) {
  border-color: #60a5fa;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.08);
}

:deep(.join-company-modal .join-modal-form .ant-input:focus),
:deep(.join-company-modal .join-modal-form .ant-input-focused) {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.16);
}

:deep(.join-company-modal .ant-modal-footer .ant-btn-primary) {
  border: none;
  background: linear-gradient(145deg, #3b82f6 0%, #2563eb 100%);
  box-shadow: 0 8px 16px rgba(37, 99, 235, 0.3);
}

:deep(.join-company-modal .ant-modal-footer .ant-btn-primary:hover) {
  background: linear-gradient(145deg, #2563eb 0%, #1d4ed8 100%);
  box-shadow: 0 10px 20px rgba(37, 99, 235, 0.34);
}

:deep(.join-company-modal .ant-modal-footer) {
  border-top: 1px solid #edf2f7;
  padding: 12px 20px 18px;
}

:deep(.join-company-modal .ant-modal-footer .ant-btn) {
  height: 38px;
  border-radius: 10px;
  font-weight: 600;
  padding-inline: 18px;
}
</style>
