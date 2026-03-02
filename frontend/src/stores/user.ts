import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import { authApi } from '@/api/auth'
import router from '@/router'

interface UserInfo {
  id: number
  username: string
  email: string
  role: string
  company_id: number | null
  company_super_admin: boolean
  is_active: boolean
}

export interface AvatarConfig {
  type: 'letter' | 'image'
  bgColor: string
  image: string
}

// 字体选项：系统字体 + 3个本地自定义字体
const FONT_OPTIONS = [
  { label: '系统默认', value: 'system-default', preview: "'PingFang SC', 'Microsoft YaHei', sans-serif" },
  { label: '锐字水柱体', value: 'font-shuizhu', preview: "'锐字水柱体', sans-serif" },
  { label: '新蒂金钟体', value: 'font-jinzhong', preview: "'新蒂金钟体', sans-serif" },
  { label: '新蒂雪山体', value: 'font-xueshan', preview: "'新蒂雪山体', sans-serif" },
]

// 头像背景色
const AVATAR_COLORS = [
  '#0d9488', '#2563eb', '#7c3aed', '#db2777', '#ea580c',
  '#16a34a', '#ca8a04', '#475569', '#dc2626', '#0891b2',
]

// 预设头像图片文件名（对应 assets/avatars/ 下的文件，如 a1.png, b1.png）
export const AVATAR_IMAGE_NAMES: string[] = [
  ...Array.from({ length: 10 }, (_, i) => `a${i + 1}.png`),
  ...Array.from({ length: 8 }, (_, i) => `b${i + 1}.png`),
]

export { FONT_OPTIONS, AVATAR_COLORS }

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref<UserInfo | null>(null)

  // 字体 key（如 'system-default', 'font-shuizhu'）
  const fontKey = ref(localStorage.getItem('pref_font_key') || 'system-default')

  // 头像配置
  const avatarConfig = ref<AvatarConfig>(
    JSON.parse(localStorage.getItem('pref_avatar') || JSON.stringify({ type: 'letter', bgColor: '#0d9488', image: '' }))
  )

  // 应用字体 class 到 document
  function applyFont(key: string) {
    const root = document.documentElement
    // 移除所有字体 class
    FONT_OPTIONS.forEach(f => root.classList.remove(f.value))
    if (key !== 'system-default') {
      root.classList.add(key)
    }
  }

  watch(fontKey, (val) => {
    localStorage.setItem('pref_font_key', val)
    applyFont(val)
  }, { immediate: true })

  watch(avatarConfig, (val) => {
    localStorage.setItem('pref_avatar', JSON.stringify(val))
  }, { deep: true })

  function setFont(key: string) {
    fontKey.value = key
    applyFont(key) // 立即应用，避免仅依赖 watch 时序
  }

  function setAvatar(config: Partial<AvatarConfig>) {
    avatarConfig.value = { ...avatarConfig.value, ...config }
  }

  async function login(username: string, password: string) {
    const res = await authApi.login({ username, password })
    token.value = res.access_token
    localStorage.setItem('token', res.access_token)
    await fetchUserInfo()
  }

  async function fetchUserInfo() {
    try {
      const res = await authApi.getMe()
      userInfo.value = res
    } catch {
      logout()
    }
  }

  function logout() {
    token.value = ''
    userInfo.value = null
    localStorage.removeItem('token')
    router.push('/login')
  }

  return { token, userInfo, fontKey, avatarConfig, login, fetchUserInfo, logout, setFont, setAvatar }
})
