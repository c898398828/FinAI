import axios from 'axios'
import { message } from 'ant-design-vue'
import router from '@/router'

const request = axios.create({
  baseURL: '/api',
  timeout: 30000,
})

request.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

request.interceptors.response.use(
  (response) => response.data,
  (error) => {
    const status = error.response?.status
    const msg = error.response?.data?.detail || '请求失败'

    if (status === 401) {
      localStorage.removeItem('token')
      router.push('/login')
      message.error('登录已过期，请重新登录')
    } else if (status === 403) {
      message.error('无权限执行此操作')
    } else {
      message.error(msg)
    }

    return Promise.reject(error)
  }
)

export default request
