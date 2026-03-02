<template>
  <div ref="chartRef" :style="{ width: '100%', height: height }"></div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import * as echarts from 'echarts'

const props = defineProps<{
  data: { categories: string[]; values: number[] }
  height?: string
}>()

const chartRef = ref<HTMLElement>()
let chart: echarts.ECharts | null = null

function renderChart() {
  if (!chartRef.value || !props.data) return
  if (!chart) {
    chart = echarts.init(chartRef.value)
  }
  const pieData = props.data.categories.map((name, i) => ({
    name,
    value: props.data.values[i],
  }))
  chart.setOption({
    tooltip: { trigger: 'item', formatter: '{b}: ¥{c} ({d}%)' },
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      data: pieData,
      emphasis: {
        itemStyle: { shadowBlur: 10, shadowOffsetX: 0, shadowColor: 'rgba(0,0,0,0.5)' },
      },
      label: { formatter: '{b}\n¥{c}' },
    }],
  })
}

onMounted(renderChart)
watch(() => props.data, renderChart, { deep: true })
</script>
