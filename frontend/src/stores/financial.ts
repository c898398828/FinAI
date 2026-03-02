import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useFinancialStore = defineStore('financial', () => {
  const summary = ref<any>(null)
  const records = ref<any[]>([])
  const totalRecords = ref(0)

  function setSummary(data: any) {
    summary.value = data
  }

  function setRecords(data: any[], total: number) {
    records.value = data
    totalRecords.value = total
  }

  return { summary, records, totalRecords, setSummary, setRecords }
})
