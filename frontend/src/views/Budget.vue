<template>
  <div>
    <div class="page-title" style="display: flex; justify-content: space-between; align-items: flex-start;">
      <div>
        <h2>预算管理</h2>
        <p>AI 智能预算预测与财务规划</p>
      </div>
      <a-space>
        <a-button @click="runForecast" :loading="forecasting" class="btn-ghost">
          <LineChartOutlined /> 生成预测
        </a-button>
        <a-button type="primary" @click="runBudgetSuggest" :loading="suggesting" class="btn-primary">
          <BulbOutlined /> AI 预算建议
        </a-button>
      </a-space>
    </div>

    <a-row :gutter="20">
      <a-col :span="16">
        <a-card title="预算列表" :bordered="false" style="margin-bottom: 20px;">
          <a-table
            :columns="budgetColumns"
            :data-source="budgets"
            :loading="loading"
            :pagination="{ pageSize: 10, size: 'small', showSizeChanger: false }"
            size="small"
            class="budget-table"
          >
            <template #bodyCell="{ column, text, record }">
              <template v-if="column.key === 'period'">
                <span class="period-text">{{ record.year }} 年 {{ record.month }} 月</span>
              </template>
              <template v-if="column.key === 'category'">
                <a-tag class="category-tag" :class="`cat-${resolveCategoryType(String(text))}`">{{ text }}</a-tag>
              </template>
              <template v-if="column.key === 'planned_amount' || column.key === 'actual_amount' || column.key === 'forecast_amount'">
                <span class="money-text" :class="{ 'money-forecast': column.key === 'forecast_amount' }">
                  ¥{{ Number(text).toLocaleString('zh-CN', { minimumFractionDigits: 2 }) }}
                </span>
              </template>
              <template v-if="column.key === 'variance'">
                <span class="status-chip" :class="`status-${getBudgetStatus(record).type}`">
                  {{ getBudgetStatus(record).label }}
                </span>
              </template>
            </template>

            <template #emptyText>
              <div class="empty-state">
                <WalletOutlined class="empty-icon" />
                <h3>暂无预算数据</h3>
                <p>在右侧添加预算或点击“AI 预算建议”自动生成</p>
              </div>
            </template>
          </a-table>
        </a-card>

        <a-card v-if="forecastResult" title="AI 预测结果" :bordered="false" style="margin-bottom: 20px;">
          <template #extra>
            <a-tag color="blue" style="border-radius: 6px;">AI 生成</a-tag>
          </template>
          <a-alert :message="forecastResult.summary" type="info" show-icon style="margin-bottom: 16px; border-radius: 10px;" />
          <a-table :columns="forecastColumns" :data-source="forecastResult.forecasts" size="small" :pagination="false">
            <template #bodyCell="{ column, text }">
              <template v-if="column.key === 'predicted_amount'">
                <span class="money-text">¥{{ Number(text).toLocaleString('zh-CN', { minimumFractionDigits: 2 }) }}</span>
              </template>
              <template v-if="column.key === 'trend_pct'">
                <div style="display: flex; align-items: center; gap: 4px;">
                  <RiseOutlined v-if="Number(text) >= 0" style="color: #10b981;" />
                  <FallOutlined v-else style="color: #ef4444;" />
                  <span :style="{ color: Number(text) >= 0 ? '#10b981' : '#ef4444', fontWeight: 600 }">
                    {{ Number(text) >= 0 ? '+' : '' }}{{ text }}%
                  </span>
                </div>
              </template>
              <template v-if="column.key === 'category'">
                <a-tag :color="isIncomeCategory(String(text)) ? 'green' : 'red'" style="border-radius: 6px;">{{ text }}</a-tag>
              </template>
            </template>
          </a-table>
        </a-card>

        <a-card v-if="budgetSuggestion" title="AI 预算建议" :bordered="false">
          <template #extra>
            <a-tag color="cyan" style="border-radius: 6px;">AI 生成</a-tag>
          </template>
          <a-alert :message="budgetSuggestion.summary" type="success" show-icon style="margin-bottom: 16px; border-radius: 10px;" />
          <a-table :columns="suggestionColumns" :data-source="budgetSuggestion.suggestions" size="small" :pagination="false">
            <template #bodyCell="{ column, text }">
              <template v-if="column.key === 'historical_avg' || column.key === 'suggested_amount'">
                <span class="money-text">¥{{ Number(text).toLocaleString('zh-CN', { minimumFractionDigits: 2 }) }}</span>
              </template>
            </template>
          </a-table>
        </a-card>
      </a-col>

      <a-col :span="8">
        <a-card title="添加预算" :bordered="false">
          <a-form :model="budgetForm" @finish="handleAddBudget" layout="vertical">
            <a-form-item label="年份">
              <a-input-number v-model:value="budgetForm.year" style="width: 100%;" :min="2020" :max="2030" size="large" />
            </a-form-item>
            <a-form-item label="月份">
              <a-select v-model:value="budgetForm.month" size="large" style="width: 100%;">
                <a-select-option v-for="m in 12" :key="m" :value="m">{{ m }} 月</a-select-option>
              </a-select>
            </a-form-item>
            <a-form-item label="类别">
              <a-input v-model:value="budgetForm.category" placeholder="如：办公费用、市场推广" size="large" />
            </a-form-item>
            <a-form-item label="计划金额">
              <a-input-number v-model:value="budgetForm.planned_amount" style="width: 100%;" :min="0" :precision="2" placeholder="0.00" size="large" />
            </a-form-item>
            <a-button type="primary" html-type="submit" block class="btn-primary" size="large">
              <PlusOutlined /> 添加预算
            </a-button>
          </a-form>
        </a-card>
      </a-col>
    </a-row>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import {
  LineChartOutlined, BulbOutlined, PlusOutlined, WalletOutlined,
  RiseOutlined, FallOutlined,
} from '@ant-design/icons-vue'
import { alertApi } from '@/api/report'
import { aiApi } from '@/api/financial'

const loading = ref(false)
const forecasting = ref(false)
const suggesting = ref(false)
const budgets = ref<any[]>([])
const forecastResult = ref<any>(null)
const budgetSuggestion = ref<any>(null)

const budgetForm = reactive({ year: 2026, month: 1, category: '', planned_amount: 0 })

const budgetColumns = [
  { title: '期间', key: 'period', width: 120 },
  { title: '类别', dataIndex: 'category', key: 'category', width: 120 },
  { title: '计划金额', dataIndex: 'planned_amount', key: 'planned_amount' },
  { title: '实际金额', dataIndex: 'actual_amount', key: 'actual_amount' },
  { title: '预测金额', dataIndex: 'forecast_amount', key: 'forecast_amount' },
  { title: '状态', key: 'variance', width: 80 },
]

const forecastColumns = [
  { title: '月份', dataIndex: 'month', key: 'month' },
  { title: '类别', dataIndex: 'category', key: 'category' },
  { title: '预测金额', dataIndex: 'predicted_amount', key: 'predicted_amount' },
  { title: '趋势', dataIndex: 'trend_pct', key: 'trend_pct' },
]

const suggestionColumns = [
  { title: '类别', dataIndex: 'category', key: 'category' },
  { title: '历史月均', dataIndex: 'historical_avg', key: 'historical_avg' },
  { title: '建议金额', dataIndex: 'suggested_amount', key: 'suggested_amount' },
  { title: '统计月数', dataIndex: 'month_count', key: 'month_count' },
]

function isIncomeCategory(category: string) {
  return /收入|\u93c0\uE48E\u53C6/i.test(category)
}

function resolveCategoryType(category: string) {
  if (isIncomeCategory(category)) return 'income'
  if (/支出|\u93c0\uE488\u56ad\u51fa/i.test(category)) return 'expense'
  return 'other'
}

function getBudgetStatus(record: any): { label: string; type: 'idle' | 'ok' | 'warn' } {
  const planned = Number(record.planned_amount || 0)
  const actual = Number(record.actual_amount || 0)
  if (actual <= 0) return { label: '待执行', type: 'idle' }
  if (planned <= 0) return { label: '有执行待设预算', type: 'warn' }
  if (actual <= planned) return { label: '正常', type: 'ok' }
  return { label: '超支', type: 'warn' }
}

async function loadBudgets() {
  loading.value = true
  try {
    const res = await alertApi.getBudgets()
    budgets.value = res.items
  } catch { /* ignore */ } finally {
    loading.value = false
  }
}

async function handleAddBudget() {
  try {
    await alertApi.createBudget(budgetForm)
    message.success('预算添加成功')
    loadBudgets()
  } catch { message.error('添加失败') }
}

async function runForecast() {
  forecasting.value = true
  try {
    forecastResult.value = await aiApi.forecast(3)
    message.success('预测完成')
  } catch { message.error('预测失败') } finally { forecasting.value = false }
}

async function runBudgetSuggest() {
  suggesting.value = true
  try {
    budgetSuggestion.value = await aiApi.suggestBudget(budgetForm.year, budgetForm.month)
    message.success('预算建议生成完成')
    loadBudgets()
  } catch { message.error('生成建议失败') } finally { suggesting.value = false }
}

onMounted(loadBudgets)
</script>

<style scoped lang="less">
.money-text {
  font-weight: 700;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
  color: var(--text-primary);
  font-feature-settings: "tnum" 1, "lnum" 1;
}

.money-forecast {
  color: #0f766e;
}

.period-text {
  font-weight: 600;
  font-size: 13px;
  color: #0f172a;
}

.budget-table {
  :deep(.ant-table-thead > tr > th) {
    background: #f6f9fd !important;
    color: #334155;
    font-weight: 700;
    font-size: 13px;
    padding: 9px 8px;
    border-bottom: 1px solid #e2e8f0;
  }

  :deep(.ant-table-tbody > tr > td) {
    padding: 9px 8px;
    font-size: 13px;
    border-bottom: 1px solid #edf2f7;
  }

  :deep(.ant-table-tbody > tr:nth-child(even) > td) {
    background: #fbfdff;
  }

  :deep(.ant-pagination) {
    margin: 14px 0 4px;
  }
}

:deep(.ant-card-head) {
  border-bottom: 1px solid #e5edf6;
  background: linear-gradient(180deg, #fbfdff 0%, #f7faff 100%);
}

.category-tag {
  border-radius: 999px !important;
  padding: 1px 8px !important;
  font-size: 12px !important;
  line-height: 18px !important;
  font-weight: 600;
}

.cat-income {
  color: #15803d !important;
  border-color: #86efac !important;
  background: #f0fdf4 !important;
}

.cat-expense {
  color: #dc2626 !important;
  border-color: #fca5a5 !important;
  background: #fef2f2 !important;
}

.cat-other {
  color: #475569 !important;
  border-color: #cbd5e1 !important;
  background: #f8fafc !important;
}

.status-chip {
  display: inline-flex;
  align-items: center;
  padding: 1px 8px;
  border-radius: 999px;
  font-size: 11px;
  line-height: 18px;
  font-weight: 700;
  border: 1px solid transparent;
}

.status-idle {
  color: #64748b;
  border-color: #cbd5e1;
  background: #f8fafc;
}

.status-ok {
  color: #15803d;
  border-color: #86efac;
  background: #f0fdf4;
}

.status-warn {
  color: #b45309;
  border-color: #fcd34d;
  background: #fffbeb;
}
</style>
