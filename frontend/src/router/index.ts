import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/stores/user'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { public: true },
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/Register.vue'),
    meta: { public: true },
  },
  {
    path: '/',
    component: () => import('@/components/layout/AppLayout.vue'),
    children: [
      { path: '', name: 'Dashboard', component: () => import('@/views/Dashboard.vue') },
      { path: 'data-import', name: 'DataImport', component: () => import('@/views/DataImport.vue') },
      { path: 'reports', name: 'Reports', component: () => import('@/views/Reports.vue') },
      { path: 'reports/:id', name: 'ReportDetail', component: () => import('@/views/ReportDetail.vue') },
      { path: 'alerts', name: 'Alerts', component: () => import('@/views/Alerts.vue') },
      { path: 'budget', name: 'Budget', component: () => import('@/views/Budget.vue') },
      { path: 'ai-chat', name: 'AIChat', component: () => import('@/views/AIChat.vue') },
      {
        path: 'company',
        name: 'CompanyManagement',
        component: () => import('@/views/CompanyManagement.vue'),
        meta: { requiresEnterpriseManage: true },
      },
      {
        path: 'permissions',
        name: 'PermissionManagement',
        component: () => import('@/views/PermissionManagement.vue'),
        meta: { requiresEnterpriseManage: true },
      },
      { path: 'settings', name: 'Settings', component: () => import('@/views/Settings.vue') },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to, _from, next) => {
  const token = localStorage.getItem('token')
  if (!to.meta.public && !token) {
    return next('/login')
  }

  const userStore = useUserStore()
  if (token && !userStore.userInfo) {
    await userStore.fetchUserInfo()
  }

  if (to.meta.requiresEnterpriseManage) {
    const canManageEnterprise = !!(
      userStore.userInfo?.company_super_admin || userStore.userInfo?.role === 'admin'
    )
    if (!canManageEnterprise) {
      return next('/')
    }
  }

  next()
})

export default router
