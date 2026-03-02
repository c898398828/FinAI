<template>
  <div class="company-page">
    <div class="page-title company-header">
      <div class="company-header__intro">
        <span class="company-kicker">Team Workspace</span>
        <h2>企业管理</h2>
        <p>超级管理员与企业管理员可邀请成员、管理权限与移除成员</p>
      </div>
      <a-space :size="10" wrap class="company-action-space">
        <a-button v-if="isSuperAdmin" class="btn-ghost toolbar-btn" @click="openTransferModal">
          转移超级管理员
        </a-button>

        <a-popconfirm
          v-if="isSuperAdmin"
          title="确认解散企业？该操作将清空企业相关数据且不可恢复。"
          ok-text="确认解散"
          cancel-text="取消"
          @confirm="handleDissolveCompany"
        >
          <a-button danger class="toolbar-btn toolbar-btn--danger" :loading="dissolving">
            解散企业
          </a-button>
        </a-popconfirm>

        <a-button
          v-if="isEnterpriseManager"
          type="primary"
          class="btn-primary toolbar-btn company-action-space__primary"
          @click="inviteModalOpen = true"
        >
          邀请成员
        </a-button>

        <a-button class="btn-ghost toolbar-btn" :loading="loading" @click="loadMembers">
          刷新列表
        </a-button>
      </a-space>
    </div>

    <a-row :gutter="16" style="margin-bottom: 16px;">
      <a-col :span="8">
        <a-card :bordered="false" class="company-stat-card company-stat-card--members">
          <div class="stat-head">
            <span class="stat-dot"></span>
            <span class="stat-mini-label">成员规模</span>
          </div>
          <div class="stat-value">{{ members.length }}</div>
          <div class="stat-label">企业成员总数</div>
        </a-card>
      </a-col>
      <a-col :span="8">
        <a-card :bordered="false" class="company-stat-card company-stat-card--admins">
          <div class="stat-head">
            <span class="stat-dot"></span>
            <span class="stat-mini-label">权限核心</span>
          </div>
          <div class="stat-value">{{ adminCount }}</div>
          <div class="stat-label">管理员数量</div>
        </a-card>
      </a-col>
      <a-col :span="8">
        <a-card :bordered="false" class="company-stat-card company-stat-card--company">
          <div class="stat-head">
            <span class="stat-dot"></span>
            <span class="stat-mini-label">企业标识</span>
          </div>
          <div class="stat-value">{{ userStore.userInfo?.company_id || '--' }}</div>
          <div class="stat-label">当前企业 ID</div>
        </a-card>
      </a-col>
    </a-row>

    <a-card :bordered="false" class="company-table-card">
      <div class="table-head">
        <h3>成员列表</h3>
        <span>共 {{ members.length }} 人</span>
      </div>
      <a-table :columns="columns" :data-source="members" :loading="loading" row-key="id">
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'role'">
            <a-space>
              <template v-if="canManageRole(record)">
                <a-select
                  :value="record.role"
                  size="small"
                  style="width: 112px"
                  :loading="updatingRoleUserId === record.id"
                  @change="(val) => handleChangeRole(record, val)"
                >
                  <a-select-option
                    v-for="opt in roleOptionsFor(record)"
                    :key="opt.value"
                    :value="opt.value"
                  >
                    {{ opt.label }}
                  </a-select-option>
                </a-select>
              </template>
              <template v-else>
                <a-tag :color="roleTagMap[record.role] || 'default'" style="border-radius: 6px;">
                  {{ roleMap[record.role] || record.role }}
                </a-tag>
              </template>
              <a-tag v-if="record.company_super_admin" color="gold" style="border-radius: 6px;">
                超级管理员
              </a-tag>
            </a-space>
          </template>

          <template v-if="column.key === 'status'">
            <a-badge :status="record.is_active ? 'success' : 'error'" :text="record.is_active ? '正常' : '禁用'" />
          </template>

          <template v-if="column.key === 'created_at'">
            <span style="color: var(--text-secondary);">{{ formatDateTime(record.created_at) }}</span>
          </template>

          <template v-if="column.key === 'action'">
            <a-popconfirm
              v-if="canRemove(record)"
              :title="record.id === userStore.userInfo?.id ? '确认退出当前企业？' : '确认移除该成员？'"
              ok-text="确认"
              cancel-text="取消"
              @confirm="handleRemove(record)"
            >
              <a-button type="link" danger>
                {{ record.id === userStore.userInfo?.id ? '退出企业' : '移除成员' }}
              </a-button>
            </a-popconfirm>
            <a-button v-else type="link" danger disabled>
              {{ record.id === userStore.userInfo?.id ? '退出企业' : '移除成员' }}
            </a-button>
          </template>
        </template>

        <template #emptyText>
          <div class="empty-state">
            <h3>暂无成员数据</h3>
            <p>当前账号可能尚未加入企业</p>
          </div>
        </template>
      </a-table>
    </a-card>

    <a-modal
      v-model:open="transferModalOpen"
      wrap-class-name="company-modal-wrap company-modal-wrap--transfer"
      title="转移超级管理员"
      ok-text="确认转移"
      cancel-text="取消"
      :confirm-loading="transferring"
      @ok="handleTransferSuperAdmin"
    >
      <a-form layout="vertical" class="company-modal-form">
        <a-form-item label="目标成员">
          <a-select v-model:value="transferTargetUserId" placeholder="请选择要转移的成员">
            <a-select-option v-for="m in transferCandidates" :key="m.id" :value="m.id">
              {{ m.username }}（{{ m.email }}）
            </a-select-option>
          </a-select>
        </a-form-item>
      </a-form>
    </a-modal>

    <a-modal
      v-model:open="inviteModalOpen"
      wrap-class-name="company-modal-wrap company-modal-wrap--invite"
      title="邀请企业成员"
      ok-text="发送邀请"
      cancel-text="取消"
      :confirm-loading="inviting"
      @ok="handleInvite"
    >
      <a-form layout="vertical" class="company-modal-form">
        <a-form-item label="用户名（可选）">
          <a-input v-model:value="inviteForm.username" placeholder="输入已注册用户名" />
        </a-form-item>
        <a-form-item label="邮箱（可选）">
          <a-input v-model:value="inviteForm.email" placeholder="输入已注册邮箱" />
        </a-form-item>
        <a-form-item label="加入后角色">
          <a-select v-model:value="inviteForm.role">
            <a-select-option value="viewer">查看者</a-select-option>
            <a-select-option value="accountant">会计</a-select-option>
            <a-select-option v-if="isSuperAdmin" value="admin">企业管理员</a-select-option>
          </a-select>
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { message } from 'ant-design-vue'
import { useRouter } from 'vue-router'
import { userApi } from '@/api/user'
import { useUserStore } from '@/stores/user'
import { formatDateTime } from '@/utils/format'

interface MemberItem {
  id: number
  username: string
  email: string
  role: string
  company_id: number | null
  company_super_admin: boolean
  is_active: boolean
  created_at: string
}

const userStore = useUserStore()
const router = useRouter()
const loading = ref(false)
const inviting = ref(false)
const transferring = ref(false)
const dissolving = ref(false)
const updatingRoleUserId = ref<number | null>(null)
const inviteModalOpen = ref(false)
const transferModalOpen = ref(false)
const members = ref<MemberItem[]>([])
const inviteForm = ref({ username: '', email: '', role: 'viewer' })
const transferTargetUserId = ref<number | undefined>(undefined)

const roleMap: Record<string, string> = {
  admin: '企业管理员',
  accountant: '会计',
  viewer: '查看者',
}

const roleTagMap: Record<string, string> = {
  admin: 'red',
  accountant: 'blue',
  viewer: 'default',
}

const isSuperAdmin = computed(() => !!userStore.userInfo?.company_super_admin)
const isEnterpriseManager = computed(() => isSuperAdmin.value || userStore.userInfo?.role === 'admin')
const adminCount = computed(() => members.value.filter((x) => x.role === 'admin').length)
const transferCandidates = computed(() =>
  members.value.filter((m) => m.id !== userStore.userInfo?.id && m.is_active)
)

const columns = [
  { title: '成员', dataIndex: 'username', key: 'username', width: 160 },
  { title: '邮箱', dataIndex: 'email', key: 'email' },
  { title: '角色', dataIndex: 'role', key: 'role', width: 220 },
  { title: '状态', key: 'status', width: 100 },
  { title: '加入时间', dataIndex: 'created_at', key: 'created_at', width: 180 },
  { title: '操作', key: 'action', width: 120, align: 'right' as const },
]

function canRemove(record: MemberItem) {
  const currentUser = userStore.userInfo
  if (!currentUser) return false

  // 自己可退出企业（超级管理员除外）
  if (record.id === currentUser.id) return !record.company_super_admin

  // 超级管理员：可移除除超级管理员外的成员
  if (currentUser.company_super_admin) return !record.company_super_admin

  // 管理员：不可移除超级管理员和管理员，只可移除普通成员
  if (currentUser.role === 'admin') return !record.company_super_admin

  // 其他成员：不可移除他人
  return false
}

function canManageRole(record: MemberItem) {
  const currentUser = userStore.userInfo
  if (!currentUser) return false
  if (!isEnterpriseManager.value) return false
  if (record.company_super_admin) return false
  if (record.id === currentUser.id) return false
  if (!isSuperAdmin.value && record.role === 'admin') return false
  return true
}

function roleOptionsFor(record: MemberItem) {
  const base = [
    { value: 'viewer', label: '查看者' },
    { value: 'accountant', label: '会计' },
  ]
  if (isSuperAdmin.value && !record.company_super_admin) {
    base.unshift({ value: 'admin', label: '企业管理员' })
  }
  return base
}

function openTransferModal() {
  transferTargetUserId.value = undefined
  transferModalOpen.value = true
}

async function loadMembers() {
  loading.value = true
  try {
    const data = await userApi.getCompanyMembers()
    members.value = data || []
  } catch {
    members.value = []
  } finally {
    loading.value = false
  }
}

async function handleRemove(record: MemberItem) {
  try {
    await userApi.removeCompanyMember(record.id)
    if (record.id === userStore.userInfo?.id) {
      message.success('已退出企业')
      await userStore.fetchUserInfo()
    } else {
      message.success('成员已移除')
    }
    await loadMembers()
  } catch {
    message.error('操作失败')
  }
}

async function handleChangeRole(record: MemberItem, role: string) {
  if (!canManageRole(record)) return
  if (record.role === role) return
  updatingRoleUserId.value = record.id
  try {
    await userApi.setCompanyMemberRole(record.id, role as 'admin' | 'accountant' | 'viewer')
    message.success('成员权限已更新')
    await loadMembers()
  } catch {
    message.error('权限更新失败')
  } finally {
    updatingRoleUserId.value = null
  }
}

async function handleInvite() {
  const username = inviteForm.value.username.trim()
  const email = inviteForm.value.email.trim()
  if (!username && !email) {
    message.warning('请至少填写用户名或邮箱')
    return
  }

  inviting.value = true
  try {
    await userApi.inviteCompanyMember({
      username: username || undefined,
      email: email || undefined,
      role: inviteForm.value.role,
    })
    message.success('邀请成功')
    inviteModalOpen.value = false
    inviteForm.value = { username: '', email: '', role: 'viewer' }
    await loadMembers()
  } catch {
    message.error('邀请失败')
  } finally {
    inviting.value = false
  }
}

async function handleTransferSuperAdmin() {
  if (!transferTargetUserId.value) {
    message.warning('请选择目标成员')
    return
  }

  transferring.value = true
  try {
    await userApi.transferSuperAdmin(transferTargetUserId.value)
    message.success('超级管理员已转移')
    transferModalOpen.value = false
    await Promise.all([userStore.fetchUserInfo(), loadMembers()])
  } catch {
    message.error('转移失败')
  } finally {
    transferring.value = false
  }
}

async function handleDissolveCompany() {
  dissolving.value = true
  try {
    await userApi.dissolveCompany()
    message.success('企业已解散')
    await userStore.fetchUserInfo()
    router.push('/settings')
  } catch {
    message.error('解散失败')
  } finally {
    dissolving.value = false
  }
}

onMounted(loadMembers)
</script>

<style scoped lang="less">
.company-page {
  position: relative;
}

.company-page::before {
  content: '';
  position: absolute;
  inset: -10px -8px auto -8px;
  height: 210px;
  background:
    radial-gradient(circle at 18% 12%, rgba(13, 148, 136, 0.12), transparent 44%),
    radial-gradient(circle at 86% 26%, rgba(37, 99, 235, 0.12), transparent 42%);
  pointer-events: none;
  z-index: 0;
}

.company-header {
  position: relative;
  z-index: 1;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.company-header__intro {
  min-width: 0;
}

.company-kicker {
  display: inline-block;
  margin-bottom: 8px;
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #0f766e;
  background: #dffaf7;
  border: 1px solid #b3efe7;
}

.company-header__intro h2 {
  margin-bottom: 6px !important;
}

.company-header__intro p {
  max-width: 520px;
}

.company-action-space {
  justify-content: flex-end;
  padding: 12px;
  border: 1px solid rgba(148, 163, 184, 0.28);
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.22);
  backdrop-filter: blur(2px);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.35);
}

.company-action-space :deep(.ant-space-item) {
  display: inline-flex;
}

.toolbar-btn {
  height: 40px !important;
  border-radius: 12px !important;
  font-weight: 600 !important;
  padding-inline: 16px !important;
}

.toolbar-btn--danger {
  background: #fff5f5 !important;
  border-color: #ef4444 !important;
  color: #dc2626 !important;
}

.toolbar-btn--danger:hover {
  background: #fee2e2 !important;
  border-color: #dc2626 !important;
  color: #b91c1c !important;
}

.company-action-space__primary {
  box-shadow: 0 10px 18px rgba(13, 148, 136, 0.28) !important;
}

.company-stat-card {
  position: relative;
  overflow: hidden;
  min-height: 124px;
  border: 1px solid #e8eef7 !important;
  box-shadow: 0 10px 26px rgba(10, 30, 70, 0.06) !important;
}

.company-stat-card::after {
  content: '';
  position: absolute;
  right: -28px;
  top: -28px;
  width: 96px;
  height: 96px;
  border-radius: 50%;
  opacity: 0.18;
}

.company-stat-card--members {
  background: linear-gradient(165deg, #ffffff 0%, #f3fbf9 100%) !important;
}

.company-stat-card--members::after {
  background: #14b8a6;
}

.company-stat-card--admins {
  background: linear-gradient(165deg, #ffffff 0%, #f8f7ff 100%) !important;
}

.company-stat-card--admins::after {
  background: #6366f1;
}

.company-stat-card--company {
  background: linear-gradient(165deg, #ffffff 0%, #f3f8ff 100%) !important;
}

.company-stat-card--company::after {
  background: #3b82f6;
}

.stat-head {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
}

.stat-dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: #14b8a6;
  box-shadow: 0 0 0 4px rgba(20, 184, 166, 0.15);
}

.company-stat-card--admins .stat-dot {
  background: #6366f1;
  box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.16);
}

.company-stat-card--company .stat-dot {
  background: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.16);
}

.stat-mini-label {
  font-size: 12px;
  color: #64748b;
  font-weight: 600;
  letter-spacing: 0.02em;
}

.company-table-card {
  border: 1px solid #e8eef7 !important;
  border-radius: 16px !important;
  overflow: hidden;
}

.table-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding: 0 4px;
}

.table-head h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.table-head span {
  font-size: 13px;
  color: #64748b;
  background: #f2f6fd;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  padding: 4px 10px;
}

.company-table-card :deep(.ant-table-thead > tr > th) {
  background: #f6f9fe !important;
  color: #334155 !important;
  font-size: 13px;
  font-weight: 600;
}

.company-table-card :deep(.ant-table-tbody > tr > td) {
  padding-top: 14px;
  padding-bottom: 14px;
}

.company-table-card :deep(.ant-table-tbody > tr:hover > td) {
  background: #f8fbff !important;
}

.stat-value {
  font-size: 36px;
  line-height: 1.1;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: 0.02em;
}

.stat-label {
  margin-top: 6px;
  font-size: 13px;
  color: #64748b;
}

@media (max-width: 1200px) {
  .company-page::before {
    height: 180px;
  }

  .company-header {
    flex-direction: column;
    align-items: stretch;
  }

  .company-action-space {
    width: 100%;
    justify-content: flex-start;
  }

  .stat-value {
    font-size: 30px;
  }
}

@media (max-width: 768px) {
  .table-head {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
}

:deep(.company-modal-wrap .ant-modal) {
  width: min(640px, calc(100vw - 32px)) !important;
}

:deep(.company-modal-wrap .ant-modal-content) {
  border-radius: 18px;
  border: 1px solid #e7edf6;
  box-shadow: 0 18px 42px rgba(15, 23, 42, 0.16);
  overflow: hidden;
}

:deep(.company-modal-wrap .ant-modal-header) {
  padding: 20px 24px 14px;
  background:
    linear-gradient(180deg, #ffffff 0%, #fbfdff 100%),
    radial-gradient(circle at 0% 0%, rgba(20, 184, 166, 0.08), transparent 40%);
  border-bottom: 1px solid #edf2f8;
}

:deep(.company-modal-wrap .ant-modal-title) {
  font-size: 24px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: 0.01em;
}

:deep(.company-modal-wrap .ant-modal-close) {
  top: 14px;
  right: 14px;
  width: 34px;
  height: 34px;
  border-radius: 10px;
  color: #64748b;
}

:deep(.company-modal-wrap .ant-modal-close:hover) {
  background: #f1f5f9;
  color: #334155;
}

:deep(.company-modal-wrap .ant-modal-body) {
  padding: 20px 24px 8px;
}

:deep(.company-modal-wrap .ant-modal-footer) {
  margin-top: 0;
  padding: 14px 24px 20px;
  border-top: 1px solid #edf2f8;
  background: linear-gradient(180deg, #fbfdff 0%, #f8fbff 100%);
}

:deep(.company-modal-wrap .ant-modal-footer .ant-btn) {
  height: 40px;
  border-radius: 12px;
  font-weight: 600;
  padding-inline: 18px;
}

:deep(.company-modal-wrap .ant-modal-footer .ant-btn-default) {
  border-color: #d4dde8;
  color: #475569;
  background: #ffffff;
}

:deep(.company-modal-wrap .ant-modal-footer .ant-btn-primary) {
  border: none;
  background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%);
  box-shadow: 0 10px 18px rgba(13, 148, 136, 0.28);
}

:deep(.company-modal-wrap .ant-modal-footer .ant-btn-primary:hover) {
  background: linear-gradient(135deg, #0f766e 0%, #115e59 100%);
}

:deep(.company-modal-form .ant-form-item) {
  margin-bottom: 18px;
}

:deep(.company-modal-form .ant-form-item-label > label) {
  color: #334155;
  font-weight: 600;
}

:deep(.company-modal-form .ant-input),
:deep(.company-modal-form .ant-select-selector) {
  min-height: 44px !important;
  border-radius: 12px !important;
  border-color: #d6dfeb !important;
  background: #fcfdff !important;
  transition: all 0.2s ease;
}

:deep(.company-modal-form .ant-input:hover),
:deep(.company-modal-form .ant-select:hover .ant-select-selector) {
  border-color: #8bb7e8 !important;
  background: #ffffff !important;
}

:deep(.company-modal-form .ant-input:focus),
:deep(.company-modal-form .ant-input-focused),
:deep(.company-modal-form .ant-select-focused .ant-select-selector) {
  border-color: #14b8a6 !important;
  box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.14) !important;
  background: #ffffff !important;
}
</style>

<style lang="less">
.company-modal-wrap .ant-modal {
  width: min(640px, calc(100vw - 32px)) !important;
}

.company-modal-wrap .ant-modal-content {
  border-radius: 18px;
  border: 1px solid #e7edf6;
  box-shadow: 0 18px 42px rgba(15, 23, 42, 0.16);
  overflow: hidden;
}

.company-modal-wrap .ant-modal-header {
  padding: 20px 24px 14px;
  background:
    linear-gradient(180deg, #ffffff 0%, #fbfdff 100%),
    radial-gradient(circle at 0% 0%, rgba(20, 184, 166, 0.08), transparent 40%);
  border-bottom: 1px solid #edf2f8;
}

.company-modal-wrap .ant-modal-title {
  font-size: 24px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: 0.01em;
}

.company-modal-wrap .ant-modal-close {
  top: 14px;
  right: 14px;
  width: 34px;
  height: 34px;
  border-radius: 10px;
  color: #64748b;
}

.company-modal-wrap .ant-modal-close:hover {
  background: #f1f5f9;
  color: #334155;
}

.company-modal-wrap .ant-modal-body {
  padding: 20px 24px 8px;
}

.company-modal-wrap .ant-modal-footer {
  margin-top: 0;
  padding: 14px 24px 20px;
  border-top: 1px solid #edf2f8;
  background: linear-gradient(180deg, #fbfdff 0%, #f8fbff 100%);
}

.company-modal-wrap .ant-modal-footer .ant-btn {
  height: 40px;
  border-radius: 12px;
  font-weight: 600;
  padding-inline: 18px;
}

.company-modal-wrap .ant-modal-footer .ant-btn-default {
  border-color: #d4dde8;
  color: #475569;
  background: #ffffff;
}

.company-modal-wrap .ant-modal-footer .ant-btn-primary {
  border: none;
  background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%);
  box-shadow: 0 10px 18px rgba(13, 148, 136, 0.28);
}

.company-modal-wrap .ant-modal-footer .ant-btn-primary:hover {
  background: linear-gradient(135deg, #0f766e 0%, #115e59 100%);
}

.company-modal-wrap .company-modal-form .ant-form-item {
  margin-bottom: 18px;
}

.company-modal-wrap .company-modal-form .ant-form-item-label > label {
  color: #334155;
  font-weight: 600;
}

.company-modal-wrap .company-modal-form .ant-input,
.company-modal-wrap .company-modal-form .ant-select-selector {
  min-height: 44px !important;
  border-radius: 12px !important;
  border-color: #d6dfeb !important;
  background: #fcfdff !important;
  transition: all 0.2s ease;
}

.company-modal-wrap .company-modal-form .ant-input:hover,
.company-modal-wrap .company-modal-form .ant-select:hover .ant-select-selector {
  border-color: #8bb7e8 !important;
  background: #ffffff !important;
}

.company-modal-wrap .company-modal-form .ant-input:focus,
.company-modal-wrap .company-modal-form .ant-input-focused,
.company-modal-wrap .company-modal-form .ant-select-focused .ant-select-selector {
  border-color: #14b8a6 !important;
  box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.14) !important;
  background: #ffffff !important;
}
</style>
