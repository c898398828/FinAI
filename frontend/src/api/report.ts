import request from './request'

export const reportApi = {
  generate(data: { report_type: string; period_start: string; period_end: string }) {
    return request.post('/reports/generate', data)
  },
  getList(params?: { skip?: number; limit?: number }) {
    return request.get('/reports/', { params })
  },
  getDetail(id: number) {
    return request.get(`/reports/${id}`)
  },
  exportDetail(id: number) {
    const token = localStorage.getItem('token')
    return fetch(`/api/reports/${id}/export`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }).then(async (res) => {
      if (!res.ok) {
        const err = await res.text().catch(() => '')
        throw new Error(err || '导出失败')
      }
      const blob = await res.blob()
      const disposition = res.headers.get('content-disposition') || ''
      const match = disposition.match(/filename=\"?([^\";]+)\"?/)
      const filename = match?.[1] || `report_${id}.xlsx`
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      a.click()
      URL.revokeObjectURL(url)
    })
  },
}

export const alertApi = {
  getList(params?: { is_read?: boolean; skip?: number; limit?: number }) {
    return request.get('/alerts/', { params })
  },
  markRead(id: number) {
    return request.put(`/alerts/${id}/read`)
  },
  getBudgets(params?: { year?: number; skip?: number; limit?: number }) {
    return request.get('/alerts/budgets', { params })
  },
  createBudget(data: { year: number; month: number; category: string; planned_amount: number }) {
    return request.post('/alerts/budgets', data)
  },
}
