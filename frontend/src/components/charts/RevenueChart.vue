<template>
  <div ref="chartRef" :style="{ width: '100%', height: height }"></div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import * as echarts from 'echarts'

const props = defineProps<{
  data: { months: string[]; values: number[] }
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
    tooltip: { trigger: 'axis', formatter: '{b}<br/>收入: ¥{c}' },
    xAxis: { type: 'category', data: props.data.months },
    yAxis: { type: 'value', axisLabel: { formatter: '¥{value}' } },
    series: [{
      name: '收入',
      type: 'line',
      data: props.data.values,
      smooth: true,
      areaStyle: { opacity: 0.3 },
      itemStyle: { color: '#52c41a' },
    }],
    grid: { left: 60, right: 20, top: 20, bottom: 30 },
  })
}

onMounted(renderChart)
watch(() => props.data, renderChart, { deep: true })
</script>
