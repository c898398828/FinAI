<template>
  <a-layout-header class="app-header">
    <div class="header-left">
      <a-breadcrumb>
        <a-breadcrumb-item>
          <router-link to="/" style="color: var(--text-muted);">首页</router-link>
        </a-breadcrumb-item>
        <a-breadcrumb-item>
          <span style="color: var(--text-primary); font-weight: 500;">{{ currentPageName }}</span>
        </a-breadcrumb-item>
      </a-breadcrumb>
    </div>

    <div class="header-right">
      <div class="header-action" @click="$router.push('/alerts')" title="消息通知">
        <a-badge :count="0" :offset="[-2, 2]" :number-style="{ boxShadow: 'none' }">
          <BellOutlined class="header-action-icon" />
        </a-badge>
      </div>

      <div class="header-divider"></div>

      <a-dropdown placement="bottomRight" trigger="click">
        <div class="user-trigger">
          <a-avatar
            :size="40"
            class="user-avatar"
            :class="{ 'avatar-type-image': userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image }"
            :style="userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image ? {} : { background: userStore.avatarConfig.bgColor + ' !important' }"
          >
            <img v-if="userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image" :src="userStore.avatarConfig.image" alt="头像" />
            <template v-else>{{ userStore.userInfo?.username?.charAt(0)?.toUpperCase() || 'U' }}</template>
          </a-avatar>
          <div class="user-info" v-if="userStore.userInfo">
            <span class="user-name">{{ userStore.userInfo.username }}</span>
            <span class="user-role">{{ roleMap[userStore.userInfo.role] || '用户' }}</span>
          </div>
          <DownOutlined class="user-trigger-arrow" />
        </div>
        <template #overlay>
          <a-menu class="user-menu">
            <a-menu-item key="settings" @click="$router.push('/settings')">
              <UserOutlined /> 个人设置
            </a-menu-item>
            <a-menu-divider />
            <a-menu-item key="logout" @click="userStore.logout()" style="color: var(--danger);">
              <LogoutOutlined /> 退出登录
            </a-menu-item>
          </a-menu>
        </template>
      </a-dropdown>
    </div>
  </a-layout-header>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { BellOutlined, DownOutlined, UserOutlined, LogoutOutlined } from '@ant-design/icons-vue'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const route = useRoute()

const roleMap: Record<string, string> = {
  admin: '管理员',
  accountant: '会计',
  viewer: '查看者',
}

const pageNameMap: Record<string, string> = {
  Dashboard: '仪表盘',
  DataImport: '数据导入',
  Reports: '财务报表',
  ReportDetail: '报表详情',
  Alerts: '异常预警',
  Budget: '预算管理',
  AIChat: 'AI 助手',
  CompanyManagement: '企业管理',
  PermissionManagement: '权限管理',
  Settings: '系统设置',
}

const currentPageName = computed(() => pageNameMap[route.name as string] || '仪表盘')
</script>

<style scoped lang="less">
.app-header {
  height: 56px;
  background: #fff !important;
  padding: 0 24px !important;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--border);
  position: sticky;
  top: 0;
  z-index: 9;
  box-shadow: 0 1px 0 0 rgba(0, 0, 0, 0.04);
}

.header-left {
  display: flex;
  align-items: center;
  min-width: 0;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 4px;
}

.header-action {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
  color: var(--text-secondary);

  .header-action-icon {
    font-size: 18px;
  }

  &:hover {
    background: var(--bg-page);
    color: var(--text-primary);
  }
}

.header-divider {
  width: 1px;
  height: 20px;
  background: var(--border);
  margin: 0 12px;
  flex-shrink: 0;
}

.user-trigger {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 10px 6px 12px;
  margin: 0 -4px 0 0;
  border-radius: 10px;
  cursor: pointer;
  transition: background 0.2s, box-shadow 0.2s;

  &:hover {
    background: var(--bg-page);
  }
}

.user-trigger-arrow {
  font-size: 12px;
  color: var(--text-muted);
  margin-left: 2px;
  transition: transform 0.2s;
}

.user-avatar {
  flex-shrink: 0;
  background: var(--primary) !important;
  font-weight: 600;
  font-size: 16px !important;
  overflow: hidden;

  &.avatar-type-image {
    background: transparent !important;
  }

  :deep(img) {
    width: 100% !important;
    height: 100% !important;
    object-fit: cover !important;
    border-radius: 50%;
    display: block;
    vertical-align: top;
  }
}

.user-info {
  display: flex;
  flex-direction: column;
  justify-content: center;
  line-height: 1.35;
  min-width: 0;
  text-align: left;
}

.user-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  letter-spacing: 0.02em;
}

.user-role {
  font-size: 12px;
  color: var(--text-muted);
  margin-top: 0;
}

.user-menu {
  border-radius: 10px !important;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1) !important;
  padding: 6px !important;
  min-width: 160px;

  :deep(.ant-dropdown-menu-item) {
    border-radius: 8px;
    padding: 10px 14px;
    font-size: 14px;
  }
}
</style>
