export function formatMoney(value: number): string {
  return `¥${value.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
}

export function formatDate(date: string): string {
  return new Date(date).toLocaleDateString('zh-CN')
}

export function formatDateTime(date: string): string {
  return new Date(date).toLocaleString('zh-CN')
}

export const categoryOptions = [
  { value: '收入', label: '收入' },
  { value: '支出', label: '支出' },
  { value: '资产', label: '资产' },
  { value: '负债', label: '负债' },
]

export const reportTypeOptions = [
  { value: 'profit_loss', label: '利润表' },
  { value: 'balance_sheet', label: '资产负债表' },
  { value: 'cash_flow', label: '现金流量表' },
]

export const severityMap: Record<string, { color: string; text: string }> = {
  low: { color: 'blue', text: '低' },
  medium: { color: 'orange', text: '中' },
  high: { color: 'red', text: '高' },
}
