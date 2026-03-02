<template>
  <div>
    <div class="page-title" style="display: flex; justify-content: space-between; align-items: flex-start;">
      <div>
        <h2>异常预警</h2>
        <p>AI 智能检测财务数据异常</p>
      </div>
      <a-button type="primary" :loading="analyzing" @click="runAnalysis" class="btn-primary">
        <ThunderboltOutlined /> 运行异常检测
      </a-button>
    </div>

    <!-- Analysis Result -->
    <a-card v-if="analysisResult" style="margin-bottom: 20px; border-left: 4px solid;" :bordered="false"
      :style="{ borderLeftColor: analysisResult.anomalies.length > 0 ? '#f59e0b' : '#10b981' }">
      <div style="display: flex; align-items: center; gap: 12px;">
        <a-avatar :size="44" :style="{ background: analysisResult.anomalies.length > 0 ? '#fffbeb' : '#ecfdf5' }">
          <template #icon>
            <CheckCircleOutlined v-if="!analysisResult.anomalies.length" style="color: #10b981;" />
            <WarningOutlined v-else style="color: #f59e0b;" />
          </template>
        </a-avatar>
        <div>
          <div style="font-weight: 600; font-size: 15px; color: var(--text-primary);">{{ analysisResult.summary }}</div>
          <div style="font-size: 13px; color: var(--text-muted);">最近一次检测完成</div>
        </div>
      </div>
    </a-card>

    <!-- Tabs: Unread / All -->
    <a-card :bordered="false">
      <a-tabs v-model:activeKey="activeTab">
        <a-tab-pane key="unread">
          <template #tab>
            <a-badge :count="unreadAlerts.length" :offset="[10, -2]" :number-style="{ fontSize: '11px' }">
              未读预警
            </a-badge>
          </template>

          <div v-if="unreadAlerts.length === 0" class="empty-state">
            <CheckCircleOutlined class="empty-icon" style="color: #10b981; opacity: 0.5;" />
            <h3>暂无未读预警</h3>
            <p>所有预警已处理完毕</p>
          </div>

          <div class="alert-list" v-else>
            <div class="alert-item" v-for="item in unreadAlerts" :key="item.id">
              <div class="alert-severity" :class="`severity-${item.severity}`">
                <WarningOutlined />
              </div>
              <div class="alert-body">
                <div class="alert-header">
                  <a-tag :color="severityMap[item.severity]?.color" style="border-radius: 6px; font-size: 11px;">
                    {{ severityMap[item.severity]?.text }}
                  </a-tag>
                  <span class="alert-type">{{ item.alert_type }}</span>
                  <span class="alert-time">{{ formatDateTime(item.created_at) }}</span>
                </div>
                <div class="alert-message">{{ item.message }}</div>
              </div>
              <a-button size="small" @click="markAsRead(item.id)" class="btn-ghost">
                标记已读
              </a-button>
            </div>
          </div>
        </a-tab-pane>

        <a-tab-pane key="all" tab="全部预警">
          <a-table :columns="alertColumns" :data-source="allAlerts" :loading="loading" size="small">
            <template #bodyCell="{ column, record }">
              <template v-if="column.key === 'severity'">
                <a-tag :color="severityMap[record.severity]?.color" style="border-radius: 6px;">
                  {{ severityMap[record.severity]?.text }}
                </a-tag>
              </template>
              <template v-if="column.key === 'is_read'">
                <a-badge :status="record.is_read ? 'default' : 'processing'" :text="record.is_read ? '已读' : '未读'" />
              </template>
              <template v-if="column.key === 'created_at'">
                <span style="font-size: 13px; color: var(--text-muted);">{{ formatDateTime(record.created_at) }}</span>
              </template>
            </template>

            <template #emptyText>
              <div class="empty-state">
                <ThunderboltOutlined class="empty-icon" />
                <h3>暂无预警记录</h3>
                <p>点击"运行异常检测"开始分析财务数据</p>
              </div>
            </template>
          </a-table>
        </a-tab-pane>
      </a-tabs>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { ThunderboltOutlined, WarningOutlined, CheckCircleOutlined } from '@ant-design/icons-vue'
import { alertApi } from '@/api/report'
import { aiApi } from '@/api/financial'
import { severityMap, formatDateTime } from '@/utils/format'

const loading = ref(false)
const analyzing = ref(false)
const activeTab = ref('unread')
const unreadAlerts = ref<any[]>([])
const allAlerts = ref<any[]>([])
const analysisResult = ref<any>(null)

const alertColumns = [
  { title: '类型', dataIndex: 'alert_type', key: 'alert_type', width: 120 },
  { title: '严重程度', dataIndex: 'severity', key: 'severity', width: 100 },
  { title: '消息', dataIndex: 'message', key: 'message', ellipsis: true },
  { title: '状态', dataIndex: 'is_read', key: 'is_read', width: 90 },
  { title: '时间', dataIndex: 'created_at', key: 'created_at', width: 170 },
]

async function loadAlerts() {
  loading.value = true
  try {
    const [unread, all] = await Promise.all([
      alertApi.getList({ is_read: false }),
      alertApi.getList(),
    ])
    unreadAlerts.value = unread.items
    allAlerts.value = all.items
  } catch { /* ignore */ } finally {
    loading.value = false
  }
}

async function runAnalysis() {
  analyzing.value = true
  try {
    analysisResult.value = await aiApi.detectAnomalies()
    message.success('异常检测完成')
    loadAlerts()
  } catch {
    message.error('异常检测失败')
  } finally {
    analyzing.value = false
  }
}

async function markAsRead(id: number) {
  try {
    await alertApi.markRead(id)
    loadAlerts()
  } catch {
    message.error('操作失败')
  }
}

onMounted(loadAlerts)
</script>

<style scoped lang="less">
.alert-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.alert-item {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 16px 20px;
  background: #fafbfc;
  border-radius: var(--radius);
  border: 1px solid var(--border);
  transition: all 0.2s;

  &:hover {
    background: #fff;
    box-shadow: var(--shadow-sm);
  }
}

.alert-severity {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;

  &.severity-high {
    background: var(--danger-bg);
    color: var(--danger);
  }
  &.severity-medium {
    background: var(--warning-bg);
    color: var(--warning);
  }
  &.severity-low {
    background: #eff6ff;
    color: #3b82f6;
  }
}

.alert-body {
  flex: 1;
  min-width: 0;
}

.alert-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.alert-type {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
}

.alert-time {
  font-size: 12px;
  color: var(--text-muted);
  margin-left: auto;
}

.alert-message {
  font-size: 14px;
  color: var(--text-secondary);
  line-height: 1.5;
}
</style>
