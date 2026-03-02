<template>
  <div class="permission-page">
    <div class="page-title">
      <h2>权限管理</h2>
      <p>统一管理菜单可见范围与成员用户权限</p>
    </div>

    <a-row :gutter="16" class="summary-row">
      <a-col :span="8">
        <a-card :bordered="false" class="summary-card summary-card--menu">
          <div class="summary-label">菜单项数量</div>
          <div class="summary-value">{{ menuPermissions.length }}</div>
        </a-card>
      </a-col>
      <a-col :span="8">
        <a-card :bordered="false" class="summary-card summary-card--member">
          <div class="summary-label">成员用户数</div>
          <div class="summary-value">{{ members.length }}</div>
        </a-card>
      </a-col>
      <a-col :span="8">
        <a-card :bordered="false" class="summary-card summary-card--enabled">
          <div class="summary-label">启用菜单权限</div>
          <div class="summary-value">{{ enabledMenuCount }}</div>
        </a-card>
      </a-col>
    </a-row>

    <a-card :bordered="false" class="permission-card">
      <a-tabs v-model:activeKey="activeTab" class="permission-tabs">
        <a-tab-pane key="menu" tab="菜单权限">
          <div class="tab-head">
            <p>配置不同角色可访问的菜单范围</p>
            <a-button type="primary" class="btn-primary" @click="saveMenuPermissions">保存菜单权限</a-button>
          </div>

          <a-table :data-source="menuPermissions" :columns="menuColumns" row-key="key" :pagination="false">
            <template #bodyCell="{ column, record }">
              <template v-if="column.key === 'roles'">
                <a-checkbox-group v-model:value="record.roles" :options="roleOptions" />
              </template>
              <template v-else-if="column.key === 'enabled'">
                <a-switch v-model:checked="record.enabled" checked-children="开" un-checked-children="关" />
              </template>
            </template>
          </a-table>
        </a-tab-pane>

        <a-tab-pane key="member" tab="成员用户权限">
          <div class="tab-head">
            <p>配置成员的菜单权限和数据权限范围</p>
            <a-button type="primary" class="btn-primary" @click="saveMemberPermissions">保存用户权限</a-button>
          </div>

          <a-table :data-source="members" :columns="memberColumns" row-key="id" :loading="loadingMembers">
            <template #bodyCell="{ column, record }">
              <template v-if="column.key === 'menu_scope'">
                <a-select v-model:value="memberPermissionMap[record.id].menuScope" style="width: 180px" :disabled="record.company_super_admin">
                  <a-select-option value="all">全部菜单</a-select-option>
                  <a-select-option value="basic">基础菜单</a-select-option>
                  <a-select-option value="finance_only">仅财务菜单</a-select-option>
                </a-select>
              </template>
              <template v-else-if="column.key === 'data_scope'">
                <a-select v-model:value="memberPermissionMap[record.id].dataScope" style="width: 180px" :disabled="record.company_super_admin">
                  <a-select-option value="all_company">全企业数据</a-select-option>
                  <a-select-option value="department">部门数据</a-select-option>
                  <a-select-option value="self">仅本人数据</a-select-option>
                </a-select>
              </template>
            </template>
          </a-table>
        </a-tab-pane>
      </a-tabs>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { message } from 'ant-design-vue'
import { userApi } from '@/api/user'

interface MemberItem {
  id: number
  username: string
  email: string
  role: string
  company_super_admin: boolean
  is_active: boolean
}

interface MenuPermissionItem {
  key: string
  menu: string
  route: string
  roles: string[]
  enabled: boolean
}

const activeTab = ref('menu')
const loadingMembers = ref(false)
const members = ref<MemberItem[]>([])

const menuPermissions = ref<MenuPermissionItem[]>([
  { key: 'dashboard', menu: '仪表盘', route: '/', roles: ['admin', 'accountant', 'viewer'], enabled: true },
  { key: 'data-import', menu: '数据导入', route: '/data-import', roles: ['admin', 'accountant'], enabled: true },
  { key: 'reports', menu: '财务报表', route: '/reports', roles: ['admin', 'accountant', 'viewer'], enabled: true },
  { key: 'budget', menu: '预算管理', route: '/budget', roles: ['admin', 'accountant'], enabled: true },
  { key: 'alerts', menu: '异常预警', route: '/alerts', roles: ['admin'], enabled: true },
  { key: 'ai-chat', menu: 'AI 助手', route: '/ai-chat', roles: ['admin', 'accountant'], enabled: true },
  { key: 'organization', menu: '组织管理', route: '/company,/permissions', roles: ['admin'], enabled: true },
])

const memberPermissionMap = reactive<Record<number, { menuScope: string; dataScope: string }>>({})

const roleOptions = [
  { label: '企业管理员', value: 'admin' },
  { label: '会计', value: 'accountant' },
  { label: '查看者', value: 'viewer' },
]

const menuColumns = [
  { title: '菜单名称', dataIndex: 'menu', key: 'menu', width: 220 },
  { title: '路由', dataIndex: 'route', key: 'route', width: 240 },
  { title: '可访问角色', key: 'roles' },
  { title: '启用', key: 'enabled', width: 120 },
]

const memberColumns = [
  { title: '成员', dataIndex: 'username', key: 'username', width: 160 },
  { title: '邮箱', dataIndex: 'email', key: 'email' },
  { title: '角色', dataIndex: 'role', key: 'role', width: 120 },
  { title: '菜单权限', key: 'menu_scope', width: 220 },
  { title: '数据权限', key: 'data_scope', width: 220 },
]

const enabledMenuCount = computed(() => menuPermissions.value.filter((x) => x.enabled).length)

function initMemberPermissions() {
  members.value.forEach((m) => {
    if (!memberPermissionMap[m.id]) {
      memberPermissionMap[m.id] = {
        menuScope: m.role === 'admin' ? 'all' : 'basic',
        dataScope: m.role === 'viewer' ? 'self' : 'department',
      }
    }
  })
}

async function loadMembers() {
  loadingMembers.value = true
  try {
    const data = await userApi.getCompanyMembers()
    members.value = (data || []) as MemberItem[]
    initMemberPermissions()
  } catch {
    members.value = []
  } finally {
    loadingMembers.value = false
  }
}

function saveMenuPermissions() {
  message.success('菜单权限已保存')
}

function saveMemberPermissions() {
  message.success('成员用户权限已保存')
}

onMounted(loadMembers)
</script>

<style scoped lang="less">
.permission-page {
  .summary-row {
    margin-bottom: 16px;
  }

  .summary-card {
    border: 1px solid #e7edf6 !important;
    border-radius: 14px !important;
    min-height: 108px;
    background: #fff;
  }

  .summary-label {
    color: #64748b;
    font-size: 13px;
    margin-bottom: 6px;
  }

  .summary-value {
    color: #0f172a;
    font-size: 32px;
    line-height: 1.1;
    font-weight: 700;
  }

  .summary-card--menu { background: linear-gradient(180deg, #ffffff 0%, #f3fbf9 100%); }
  .summary-card--member { background: linear-gradient(180deg, #ffffff 0%, #f4f7ff 100%); }
  .summary-card--enabled { background: linear-gradient(180deg, #ffffff 0%, #fff8ed 100%); }

  .permission-card {
    border: 1px solid #e7edf6 !important;
    border-radius: 16px !important;
  }

  .tab-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 14px;

    p {
      margin: 0;
      color: #64748b;
      font-size: 13px;
    }
  }

  :deep(.ant-tabs-tab) {
    font-weight: 600;
  }

  :deep(.ant-checkbox-wrapper) {
    margin-right: 14px;
  }
}
</style>
