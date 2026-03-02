<template>
  <a-layout-sider
    v-model:collapsed="collapsed"
    :trigger="null"
    collapsible
    :width="230"
    :collapsed-width="68"
    class="app-sider"
  >
    <div class="sider-logo">
      <div class="logo-icon">
        <svg width="28" height="28" viewBox="0 0 28 28" fill="none">
          <rect width="28" height="28" rx="7" fill="url(#logo-grad)"/>
          <path d="M8 10h12M8 14h8M8 18h10" stroke="#fff" stroke-width="2" stroke-linecap="round"/>
          <defs><linearGradient id="logo-grad" x1="0" y1="0" x2="28" y2="28"><stop stop-color="#2dd4bf"/><stop offset="1" stop-color="#0d9488"/></linearGradient></defs>
        </svg>
      </div>
      <transition name="fade">
        <div v-if="!collapsed" class="logo-text">
          <span class="logo-title">F-AI</span>
          <span class="logo-subtitle">财务助理</span>
        </div>
      </transition>
    </div>

    <div class="nav-section">
      <div class="nav-label" v-if="!collapsed">主导航</div>
      <a-menu
        theme="dark"
        mode="inline"
        :selectedKeys="selectedKeys"
        :defaultOpenKeys="['OrganizationMenu']"
        class="custom-menu"
      >
        <a-menu-item key="Dashboard" @click="$router.push('/')">
          <template #icon><DashboardOutlined /></template>
          <span>仪表盘</span>
        </a-menu-item>
        <a-menu-item key="DataImport" @click="$router.push('/data-import')">
          <template #icon><CloudUploadOutlined /></template>
          <span>数据导入</span>
        </a-menu-item>
        <a-menu-item key="Reports" @click="$router.push('/reports')">
          <template #icon><BarChartOutlined /></template>
          <span>财务报表</span>
        </a-menu-item>
        <a-menu-item key="Alerts" @click="$router.push('/alerts')">
          <template #icon><ThunderboltOutlined /></template>
          <span>异常预警</span>
        </a-menu-item>
        <a-menu-item key="Budget" @click="$router.push('/budget')">
          <template #icon><WalletOutlined /></template>
          <span>预算管理</span>
        </a-menu-item>
        <a-menu-item key="AIChat" @click="$router.push('/ai-chat')">
          <template #icon><RobotOutlined /></template>
          <span>AI 助手</span>
        </a-menu-item>

        <template v-if="canManageEnterprise">
          <div class="nav-label nav-label-inner" v-if="!collapsed">组织</div>
          <a-sub-menu key="OrganizationMenu">
            <template #icon><ApartmentOutlined /></template>
            <template #title>组织</template>
            <a-menu-item key="CompanyManagement" @click="$router.push('/company')">
              <template #icon><TeamOutlined /></template>
              <span>企业管理</span>
            </a-menu-item>
            <a-menu-item key="PermissionManagement" @click="$router.push('/permissions')">
              <template #icon><SafetyCertificateOutlined /></template>
              <span>权限管理</span>
            </a-menu-item>
          </a-sub-menu>
        </template>

        <div class="nav-label nav-label-inner" v-if="!collapsed">系统</div>
        <a-menu-item key="Settings" @click="$router.push('/settings')">
          <template #icon><SettingOutlined /></template>
          <span>系统设置</span>
        </a-menu-item>
      </a-menu>
    </div>

    <div class="sider-footer" :class="{ 'sider-footer-collapsed': collapsed }" @click="collapsed = !collapsed">
      <a-tooltip v-if="collapsed" title="展开菜单" placement="right">
        <span class="sider-footer-inner"><MenuUnfoldOutlined /></span>
      </a-tooltip>
      <template v-else>
        <MenuFoldOutlined />
        <span class="sider-footer-text">收起菜单</span>
      </template>
    </div>
  </a-layout-sider>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import {
  DashboardOutlined,
  CloudUploadOutlined,
  BarChartOutlined,
  ThunderboltOutlined,
  WalletOutlined,
  RobotOutlined,
  ApartmentOutlined,
  TeamOutlined,
  SafetyCertificateOutlined,
  SettingOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
} from '@ant-design/icons-vue'

const collapsed = ref(false)
const route = useRoute()
const userStore = useUserStore()
const selectedKeys = computed(() => [route.name as string])
const canManageEnterprise = computed(
  () => !!(userStore.userInfo?.company_super_admin || userStore.userInfo?.role === 'admin')
)
</script>

<style scoped lang="less">
.app-sider {
  background: linear-gradient(180deg, #1a1a2e 0%, #16213e 100%) !important;
  box-shadow: 2px 0 12px rgba(0, 0, 0, 0.12);
  position: relative;
  z-index: 10;

  :deep(.ant-layout-sider-children) {
    display: flex;
    flex-direction: column;
    height: 100vh;
  }
}

.sider-logo {
  height: 60px;
  display: flex;
  align-items: center;
  padding: 0 18px;
  gap: 10px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  flex-shrink: 0;

  .logo-icon {
    flex-shrink: 0;
    display: flex;
  }

  .logo-text {
    display: flex;
    flex-direction: column;
    line-height: 1.2;
  }

  .logo-title {
    font-size: 17px;
    font-weight: 700;
    color: #fff;
    letter-spacing: 0.5px;
  }

  .logo-subtitle {
    font-size: 11px;
    color: rgba(255, 255, 255, 0.4);
    letter-spacing: 1px;
  }
}

.nav-section {
  flex: 1;
  overflow-y: auto;
  padding: 8px 0;
}

.nav-label {
  padding: 18px 22px 6px;
  font-size: 11px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.25);
  text-transform: uppercase;
  letter-spacing: 1px;
}

.nav-label-inner {
  padding-top: 20px;
}

.custom-menu {
  background: transparent !important;
  border: none;

  :deep(.ant-menu-item),
  :deep(.ant-menu-submenu-title) {
    height: 42px;
    line-height: 42px;
    margin: 2px 10px !important;
    padding: 0 14px !important;
    border-radius: 8px !important;
    color: rgba(255, 255, 255, 0.55);
    font-size: 14px;
    transition: all 0.2s ease;

    &:hover {
      color: #fff;
      background: rgba(255, 255, 255, 0.06) !important;
    }

    .anticon {
      font-size: 17px;
    }
  }

  :deep(.ant-menu-item-selected) {
    background: rgba(13, 148, 136, 0.2) !important;
    color: #2dd4bf;
    font-weight: 500;
  }

  :deep(.ant-menu-sub) {
    background: transparent !important;
  }
}

.sider-footer {
  padding: 14px 18px;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  color: rgba(255, 255, 255, 0.35);
  cursor: pointer;
  display: flex;
  align-items: center;
  transition: color 0.2s;
  flex-shrink: 0;

  .sider-footer-inner {
    display: inline-flex;
    align-items: center;
    justify-content: center;
  }

  .sider-footer-text {
    margin-left: 10px;
    font-size: 13px;
  }

  &:hover {
    color: rgba(255, 255, 255, 0.7);
  }

  &.sider-footer-collapsed {
    padding: 14px 0;
    justify-content: center;
  }
}
</style>
