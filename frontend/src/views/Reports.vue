<template>
  <div>
    <div class="page-title" style="display: flex; justify-content: space-between; align-items: flex-start;">
      <div>
        <h2>财务报表</h2>
        <p>自动生成与管理财务报表</p>
      </div>
      <a-button type="primary" class="btn-primary" @click="showGenerateModal = true">
        <PlusOutlined /> 生成报表
      </a-button>
    </div>

    <a-card :bordered="false">
      <a-table
        :columns="columns"
        :data-source="reports"
        :loading="loading"
        :pagination="pagination"
        @change="handleTableChange"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'title'">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div class="report-icon" :style="{ background: typeStyleMap[record.report_type]?.bg }">
                <component :is="typeStyleMap[record.report_type]?.icon" :style="{ color: typeStyleMap[record.report_type]?.color }" />
              </div>
              <div>
                <div style="font-weight: 500; color: var(--text-primary);">{{ record.title }}</div>
                <div style="font-size: 12px; color: var(--text-muted);">{{ record.period_start }} ~ {{ record.period_end }}</div>
              </div>
            </div>
          </template>
          <template v-if="column.key === 'report_type'">
            <a-tag :color="typeStyleMap[record.report_type]?.tag" style="border-radius: 6px;">
              {{ typeNameMap[record.report_type] }}
            </a-tag>
          </template>
          <template v-if="column.key === 'created_at'">
            <span style="color: var(--text-secondary); font-size: 13px;">{{ formatDateTime(record.created_at) }}</span>
          </template>
          <template v-if="column.key === 'action'">
            <a-button type="link" @click="$router.push(`/reports/${record.id}`)">
              查看详情 <RightOutlined />
            </a-button>
          </template>
        </template>

        <template #emptyText>
          <div class="empty-state">
            <BarChartOutlined class="empty-icon" />
            <h3>暂无报表</h3>
            <p>点击"生成报表"创建您的第一份财务报表</p>
          </div>
        </template>
      </a-table>
    </a-card>

    <!-- Generate Modal -->
    <a-modal
      v-model:open="showGenerateModal"
      title="生成财务报表"
      @ok="handleGenerate"
      :confirm-loading="generating"
      ok-text="生成"
      cancel-text="取消"
      :width="480"
    >
      <a-form layout="vertical" style="margin-top: 16px;">
        <a-form-item label="报表类型">
          <a-select v-model:value="generateForm.report_type" size="large">
            <a-select-option value="profit_loss">
              <div style="display: flex; align-items: center; gap: 8px;">
                <BarChartOutlined style="color: #0d9488;" /> 利润表
              </div>
            </a-select-option>
            <a-select-option value="balance_sheet">
              <div style="display: flex; align-items: center; gap: 8px;">
                <PieChartOutlined style="color: #10b981;" /> 资产负债表
              </div>
            </a-select-option>
            <a-select-option value="cash_flow">
              <div style="display: flex; align-items: center; gap: 8px;">
                <LineChartOutlined style="color: #f59e0b;" /> 现金流量表
              </div>
            </a-select-option>
          </a-select>
        </a-form-item>
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="起始日期">
              <a-date-picker v-model:value="generateForm.period_start" style="width: 100%;" size="large" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="结束日期">
              <a-date-picker v-model:value="generateForm.period_end" style="width: 100%;" size="large" />
            </a-form-item>
          </a-col>
        </a-row>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, h } from 'vue'
import { message } from 'ant-design-vue'
import { PlusOutlined, RightOutlined, BarChartOutlined, PieChartOutlined, LineChartOutlined } from '@ant-design/icons-vue'
import dayjs from 'dayjs'
import { reportApi } from '@/api/report'
import { formatDateTime } from '@/utils/format'

const loading = ref(false)
const generating = ref(false)
const showGenerateModal = ref(false)
const reports = ref<any[]>([])
const pagination = reactive({ current: 1, pageSize: 10, total: 0 })

const typeNameMap: Record<string, string> = {
  profit_loss: '利润表',
  balance_sheet: '资产负债表',
  cash_flow: '现金流量表',
}

const typeStyleMap: Record<string, any> = {
  profit_loss: { tag: 'cyan', bg: '#f0fdfa', color: '#0d9488', icon: BarChartOutlined },
  balance_sheet: { tag: 'green', bg: '#ecfdf5', color: '#10b981', icon: PieChartOutlined },
  cash_flow: { tag: 'orange', bg: '#fffbeb', color: '#f59e0b', icon: LineChartOutlined },
}

const generateForm = reactive({
  report_type: 'profit_loss',
  period_start: null as any,
  period_end: null as any,
})

const columns = [
  { title: '报表名称', key: 'title', ellipsis: true },
  { title: '类型', dataIndex: 'report_type', key: 'report_type', width: 130 },
  { title: '生成时间', dataIndex: 'created_at', key: 'created_at', width: 180 },
  { title: '操作', key: 'action', width: 140, align: 'right' as const },
]

async function loadReports() {
  loading.value = true
  try {
    const skip = (pagination.current - 1) * pagination.pageSize
    const res = await reportApi.getList({ skip, limit: pagination.pageSize })
    reports.value = res.items
    pagination.total = res.total
  } catch { /* ignore */ } finally {
    loading.value = false
  }
}

async function handleGenerate() {
  if (!generateForm.period_start || !generateForm.period_end) {
    message.warning('请选择起止日期')
    return
  }
  generating.value = true
  try {
    await reportApi.generate({
      report_type: generateForm.report_type,
      period_start: dayjs(generateForm.period_start).format('YYYY-MM-DD'),
      period_end: dayjs(generateForm.period_end).format('YYYY-MM-DD'),
    })
    message.success('报表生成成功')
    showGenerateModal.value = false
    loadReports()
  } catch {
    message.error('报表生成失败')
  } finally {
    generating.value = false
  }
}

function handleTableChange(pag: any) {
  pagination.current = pag.current
  loadReports()
}

onMounted(loadReports)
</script>

<style scoped lang="less">
.report-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}
</style>
