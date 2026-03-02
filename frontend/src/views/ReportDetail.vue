<template>
  <div class="report-detail-page">
    <div class="page-title detail-head">
      <div class="head-left">
        <a-button shape="circle" @click="$router.push('/reports')" class="btn-ghost">
          <ArrowLeftOutlined />
        </a-button>
        <div>
          <h2>{{ report?.title || '报表详情' }}</h2>
          <p>查看报表详细数据</p>
        </div>
      </div>
      <a-button type="primary" class="btn-primary" :loading="exporting" :disabled="!report" @click="handleExport">
        <DownloadOutlined />
        导出报表
      </a-button>
    </div>

    <a-spin :spinning="loading">
      <template v-if="report">
        <a-card :bordered="false" style="margin-bottom: 20px;">
          <div class="report-meta-grid">
            <div class="meta-card">
              <div class="meta-label">
                <FileTextOutlined />
                报表类型
              </div>
              <a-tag :color="typeColorMap[report.report_type]" class="meta-type-tag">
                {{ typeNameMap[report.report_type] || report.report_type }}
              </a-tag>
            </div>
            <div class="meta-card">
              <div class="meta-label">
                <CalendarOutlined />
                开始日期
              </div>
              <div class="meta-value">{{ report.period_start }}</div>
            </div>
            <div class="meta-card">
              <div class="meta-label">
                <CalendarOutlined />
                结束日期
              </div>
              <div class="meta-value">{{ report.period_end }}</div>
            </div>
          </div>
        </a-card>

        <a-card v-if="analysisSummary" :bordered="false" style="margin-bottom: 20px;" class="ai-analysis-card">
          <template #title>
            <div style="display: flex; align-items: center; gap: 8px;">
              <BulbOutlined style="color: var(--primary);" />
              AI 智能分析
              <a-tag color="cyan" style="border-radius: 6px;">AI</a-tag>
            </div>
          </template>
          <a-alert :message="analysisSummary" type="info" show-icon style="border-radius: 8px;" />
        </a-card>

        <template v-if="reportDataRows.length">
          <div class="summary-grid" v-if="summaryItems.length">
            <a-card v-for="item in summaryItems" :key="item.key" :title="item.key" :bordered="false" class="summary-card">
              <div class="summary-number-card">
                <div class="summary-value" :class="{ 'text-success': item.value >= 0, 'text-danger': item.value < 0 }">
                  ¥{{ item.value.toLocaleString('zh-CN', { minimumFractionDigits: 2 }) }}
                </div>
              </div>
            </a-card>
          </div>

          <div class="detail-grid" v-if="detailItems.length">
            <a-card v-for="item in detailItems" :key="item.key" :title="item.key" :bordered="false" class="detail-card">
              <div class="detail-list">
                <div class="detail-row" v-for="row in item.rows" :key="row.name">
                  <span class="detail-name">{{ row.name }}</span>
                  <span class="detail-amount">¥{{ row.value.toLocaleString('zh-CN', { minimumFractionDigits: 2 }) }}</span>
                </div>
                <div class="detail-row detail-total" v-if="item.rows.length > 1">
                  <span class="detail-name">合计</span>
                  <span class="detail-amount">
                    ¥{{ item.rows.reduce((s, r) => s + r.value, 0).toLocaleString('zh-CN', { minimumFractionDigits: 2 }) }}
                  </span>
                </div>
              </div>
            </a-card>
          </div>
        </template>
      </template>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { message } from 'ant-design-vue'
import { ArrowLeftOutlined, BulbOutlined, CalendarOutlined, DownloadOutlined, FileTextOutlined } from '@ant-design/icons-vue'
import { reportApi } from '@/api/report'

const route = useRoute()
const loading = ref(false)
const exporting = ref(false)
const report = ref<any>(null)

const typeNameMap: Record<string, string> = {
  profit_loss: '利润表',
  balance_sheet: '资产负债表',
  cash_flow: '现金流量表',
}

const typeColorMap: Record<string, string> = {
  profit_loss: 'cyan',
  balance_sheet: 'green',
  cash_flow: 'orange',
}

const analysisSummary = computed(() => {
  const data = report.value?.data_json || {}
  const aiKey = Object.keys(data).find((k) => /AI|ai/.test(k))
  if (!aiKey) return ''
  const ai = data[aiKey]
  if (!ai || typeof ai !== 'object') return ''
  const summaryKey = Object.keys(ai).find((k) => /摘要|summary/i.test(k))
  if (!summaryKey) return ''
  return String(ai[summaryKey] || '')
})

const reportDataRows = computed(() => {
  const data = report.value?.data_json || {}
  return Object.entries(data)
    .filter(([k]) => !/AI|ai/.test(k))
    .map(([key, value]) => {
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        const rows = Object.entries(value as Record<string, any>).map(([name, v]) => ({
          name,
          value: Number(v || 0),
        }))
        return { key, isObject: true, rows }
      }
      return { key, isObject: false, value: Number(value || 0) }
    })
})

const summaryItems = computed(() => reportDataRows.value.filter((item: any) => !item.isObject))
const detailItems = computed(() => reportDataRows.value.filter((item: any) => item.isObject))

async function handleExport() {
  if (!report.value) return
  exporting.value = true
  try {
    await reportApi.exportDetail(Number(route.params.id))
    message.success('报表导出成功')
  } catch {
    message.error('报表导出失败')
  } finally {
    exporting.value = false
  }
}

onMounted(async () => {
  loading.value = true
  try {
    report.value = await reportApi.getDetail(Number(route.params.id))
  } finally {
    loading.value = false
  }
})
</script>

<style scoped lang="less">
.detail-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.head-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.report-meta-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.meta-card {
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 14px 16px;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  min-height: 84px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.meta-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.5px;
  color: var(--text-muted);
}

.meta-value {
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 0.2px;
  color: var(--text-primary);
  font-variant-numeric: tabular-nums;
}

.meta-type-tag {
  border-radius: 999px;
  font-size: 13px;
  padding: 3px 12px;
  width: fit-content;
  margin: 0;
}

.ai-analysis-card {
  border-left: 4px solid var(--primary) !important;
}

.summary-number-card {
  text-align: center;
  padding: 16px 0 10px;
}

.summary-value {
  font-size: 46px;
  font-weight: 700;
  letter-spacing: -0.5px;
}

.text-success {
  color: #10b981;
}

.text-danger {
  color: #ef4444;
}

.detail-list {
  display: flex;
  flex-direction: column;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f1f5f9;
}

.detail-name {
  font-size: 14px;
  color: var(--text-secondary);
}

.detail-amount {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  font-variant-numeric: tabular-nums;
}

.detail-total {
  border-top: 2px solid var(--border);
  border-bottom: none;
  margin-top: 4px;
  padding-top: 14px;

  .detail-name {
    font-weight: 600;
    color: var(--text-primary);
  }

  .detail-amount {
    font-size: 16px;
    color: var(--primary);
  }
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}

.summary-card {
  border: 1px solid #dbe4f0;
  border-radius: 14px;
  overflow: hidden;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.detail-card {
  border: 1px solid #dbe4f0;
  border-radius: 14px;
  overflow: hidden;
}

@media (max-width: 1200px) {
  .report-meta-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .detail-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .detail-head {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .report-meta-grid {
    grid-template-columns: 1fr;
  }

  .summary-grid {
    grid-template-columns: 1fr;
  }

  .summary-value {
    font-size: 38px;
  }
}
</style>
