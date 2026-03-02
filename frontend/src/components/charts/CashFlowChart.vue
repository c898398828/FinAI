<template>
  <div ref="chartRef" :style="{ width: '100%', height: height }"></div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import * as echarts from 'echarts'

const props = defineProps<{
  data: { months: string[]; inflow: number[]; outflow: number[] }
  height?: string
}>()

const chartRef = ref<HTMLElement>()
let chart: echarts.ECharts | null = null

function renderChart() {
  if (!chartRef.value || !props.data) return
  if (!chart) {
    chart = echarts.init(chartRef.value)
  }
  chart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['流入', '流出'] },
    xAxis: { type: 'category', data: props.data.months },
    yAxis: { type: 'value', axisLabel: { formatter: '¥{value}' } },
    series: [
      {
        name: '流入',
        type: 'bar',
        data: props.data.inflow,
        itemStyle: { color: '#52c41a' },
      },
      {
        name: '流出',
        type: 'bar',
        data: props.data.outflow,
        itemStyle: { color: '#ff4d4f' },
      },
    ],
    grid: { left: 60, right: 20, top: 40, bottom: 30 },
  })
}

onMounted(renderChart)
watch(() => props.data, renderChart, { deep: true })
</script>
