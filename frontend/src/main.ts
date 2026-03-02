import { createApp } from 'vue'
import { createPinia } from 'pinia'
import Antd from 'ant-design-vue'
import App from './App.vue'
import router from './router'
import './styles/global.less'

// 启动时立即应用全局字体（不依赖 store 挂载时机）
function applyInitialFont() {
  const key = localStorage.getItem('pref_font_key') || 'system-default'
  const root = document.documentElement
  ;['font-shuizhu', 'font-jinzhong', 'font-xueshan'].forEach((c) => root.classList.remove(c))
  if (key !== 'system-default') root.classList.add(key)
}
applyInitialFont()

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.use(Antd)
app.mount('#app')
