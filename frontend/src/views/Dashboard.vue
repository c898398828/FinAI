<template>
  <div class="dashboard-page">
    <div class="page-title">
      <h2>仪表盘</h2>
      <p>财务数据概览与趋势分析</p>
    </div>

    <a-row :gutter="20" style="margin-bottom: 20px;">
      <a-col :span="6">
        <a-card class="stat-card stat-income" :bordered="false">
          <div class="stat-icon"><RiseOutlined /></div>
          <a-statistic title="总收入" :value="summary.total_income" :precision="2" prefix="¥" />
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card class="stat-card stat-expense" :bordered="false">
          <div class="stat-icon"><FallOutlined /></div>
          <a-statistic title="总支出" :value="summary.total_expense" :precision="2" prefix="¥" />
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card class="stat-card stat-profit" :bordered="false">
          <div class="stat-icon"><TrophyOutlined /></div>
          <a-statistic title="净利润" :value="summary.net_profit" :precision="2" prefix="¥" />
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card class="stat-card stat-asset" :bordered="false">
          <div class="stat-icon"><BankOutlined /></div>
          <a-statistic title="总资产" :value="summary.total_assets" :precision="2" prefix="¥" />
        </a-card>
      </a-col>
    </a-row>

    <a-row :gutter="20" style="margin-bottom: 20px;">
      <a-col :span="14">
        <a-card title="收入趋势">
          <template #extra>
            <a-radio-group v-model:value="chartPeriod" size="small" button-style="solid">
              <a-radio-button value="month">月度</a-radio-button>
              <a-radio-button value="quarter">季度</a-radio-button>
            </a-radio-group>
          </template>
          <RevenueChart :data="revenueData" height="320px" />
        </a-card>
      </a-col>
      <a-col :span="10">
        <a-card title="支出分布">
          <ExpenseChart :data="expenseData" height="320px" />
        </a-card>
      </a-col>
    </a-row>

    <a-row :gutter="20">
      <a-col :span="24">
        <a-card title="现金流分析">
          <CashFlowChart :data="cashFlowData" height="280px" />
        </a-card>
      </a-col>
    </a-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref, watch } from 'vue'
import { BankOutlined, FallOutlined, RiseOutlined, TrophyOutlined } from '@ant-design/icons-vue'
import { financialApi } from '@/api/financial'
import RevenueChart from '@/components/charts/RevenueChart.vue'
import ExpenseChart from '@/components/charts/ExpenseChart.vue'
import CashFlowChart from '@/components/charts/CashFlowChart.vue'

type Period = 'month' | 'quarter'

const chartPeriod = ref<Period>('month')

const summary = reactive({
  total_income: 0,
  total_expense: 0,
  net_profit: 0,
  total_assets: 0,
  total_liabilities: 0,
  category_breakdown: {} as Record<string, number>,
})

const revenueData = ref({ months: ['暂无数据'], values: [0] })
const expenseData = ref({ categories: ['暂无数据'], values: [0] })
const cashFlowData = ref({ months: ['暂无数据'], inflow: [0], outflow: [0] })

function isExpenseCategory(category: string) {
  return /支出|\u93c0\uE488\u56ad\u51fa/i.test(category)
}

function parseExpenseFromBreakdown(breakdown: Record<string, number>) {
  const categories: string[] = []
  const values: number[] = []
  Object.entries(breakdown).forEach(([key, val]) => {
    const [category, ...rest] = key.split('-')
    if (!category || !isExpenseCategory(category)) return
    categories.push(rest.join('-') || category)
    values.push(Number(val) || 0)
  })
  return { categories, values }
}

async function loadSummary() {
  const res = await financialApi.getSummary()
  Object.assign(summary, res)
  const parsed = parseExpenseFromBreakdown(res?.category_breakdown || {})
  expenseData.value = parsed.categories.length > 0 ? parsed : { categories: ['暂无数据'], values: [0] }
}

async function loadTrendAndCashflow() {
  const [trendRes, cashRes] = await Promise.allSettled([
    financialApi.getTrend({ period: chartPeriod.value }),
    financialApi.getCashflow({ period: chartPeriod.value }),
  ])

  if (trendRes.status === 'fulfilled' && trendRes.value?.periods?.length) {
    revenueData.value = {
      months: trendRes.value.periods,
      values: trendRes.value.income || [],
    }
  } else {
    revenueData.value = { months: ['暂无数据'], values: [0] }
  }

  if (cashRes.status === 'fulfilled' && cashRes.value?.periods?.length) {
    cashFlowData.value = {
      months: cashRes.value.periods,
      inflow: cashRes.value.inflow || [],
      outflow: cashRes.value.outflow || [],
    }
  } else {
    cashFlowData.value = { months: ['暂无数据'], inflow: [0], outflow: [0] }
  }
}

onMounted(async () => {
  await Promise.all([loadSummary(), loadTrendAndCashflow()])
})

watch(chartPeriod, () => {
  loadTrendAndCashflow()
})
</script>

<style scoped lang="less">
.dashboard-page {
  .page-title {
    margin-bottom: 16px;
  }
}

.stat-card {
  border-radius: 12px !important;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.06) !important;
}

.stat-icon {
  font-size: 18px;
  margin-bottom: 8px;
}

.stat-income .stat-icon {
  color: #16a34a;
}

.stat-expense .stat-icon {
  color: #dc2626;
}

.stat-profit .stat-icon {
  color: #f59e0b;
}

.stat-asset .stat-icon {
  color: #0ea5e9;
}
</style>
