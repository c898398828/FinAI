import request from './request'

export const financialApi = {
  uploadFile(file: File) {
    const formData = new FormData()
    formData.append('file', file)
    return request.post('/financial/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
  },
  getRecords(params?: { category?: string; start_date?: string; end_date?: string; skip?: number; limit?: number }) {
    return request.get('/financial/records', { params })
  },
  addRecord(data: any) {
    return request.post('/financial/records', data)
  },
  getSummary(params?: { start_date?: string; end_date?: string }) {
    return request.get('/financial/summary', { params })
  },
  getTrend(params?: { start_date?: string; end_date?: string; period?: 'month' | 'quarter' }) {
    return request.get('/financial/trend', { params })
  },
  getCashflow(params?: { start_date?: string; end_date?: string; period?: 'month' | 'quarter' }) {
    return request.get('/financial/cashflow', { params })
  },
  getDashboard() {
    return request.get('/financial/summary')
  },
  downloadTemplate() {
    const token = localStorage.getItem('token')
    return fetch('/api/financial/template', {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }).then(async (res) => {
      if (!res.ok) throw new Error('下载失败')
      const blob = await res.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = 'financial_import_template.xlsx'
      a.click()
      URL.revokeObjectURL(url)
    })
  },
}

export const aiApi = {
  detectAnomalies() {
    return request.post('/ai/anomaly-detect')
  },
  forecast(months_ahead: number = 3, persist: boolean = true) {
    return request.post(`/ai/forecast?months_ahead=${months_ahead}&persist=${persist}`)
  },
  suggestBudget(year?: number, month?: number) {
    const params = new URLSearchParams()
    if (year) params.append('year', String(year))
    if (month) params.append('month', String(month))
    return request.post(`/ai/budget-suggest?${params.toString()}`)
  },
  getDashboardInsights() {
    return request.get('/ai/dashboard-insights')
  },
  chat(message: string, history?: { role: string; content: string }[]) {
    return request.post('/ai/chat', { message, history })
  },
  /** 流式对话 — 返回原生 Response，调用方自行读取 SSE */
  chatStream(message: string, history?: { role: string; content: string }[]) {
    const token = localStorage.getItem('token')
    return fetch('/api/ai/chat/stream', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify({ message, history }),
    })
  },
  analyzeReport(report_data: any, report_type: string) {
    return request.post('/ai/analyze-report', { report_data, report_type })
  },
  getConfig() {
    return request.get('/ai/config')
  },
  saveConfig(data: { api_key?: string; base_url?: string; model?: string }) {
    return request.put('/ai/config', data)
  },
  testConnection() {
    return request.post('/ai/config/test')
  },
}
