/**
 * 全系统统一的时间、金额、状态格式化函数。
 * 所有页面必须调用这里（需求硬性第 9 条），禁止各页自写格式化逻辑。
 */
export function formatTime(v, fmt = 'YYYY-MM-DD HH:mm:ss') {
  if (!v) return '-'
  const d = typeof v === 'string' ? new Date(v.replace(/-/g, '/').replace('T', ' ')) : new Date(v)
  if (isNaN(d.getTime())) return String(v)
  const p = (n) => String(n).padStart(2, '0')
  return fmt
    .replace('YYYY', d.getFullYear())
    .replace('MM', p(d.getMonth() + 1))
    .replace('DD', p(d.getDate()))
    .replace('HH', p(d.getHours()))
    .replace('mm', p(d.getMinutes()))
    .replace('ss', p(d.getSeconds()))
}

export function formatDate(v) {
  return formatTime(v, 'YYYY-MM-DD')
}

export function formatClock(v) {
  return v ? String(v).slice(0, 5) : '-'
}

export function formatMoney(v, digits = 2) {
  if (v === null || v === undefined || v === '') return '-'
  const n = Number(v)
  if (isNaN(n)) return '-'
  return '¥' + n.toFixed(digits).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

/** 手机号脱敏：138****0001（需求 6.3.2 前台脱敏） */
export function maskPhone(v) {
  if (!v) return '-'
  return String(v).replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
}

/** 状态 -> 标签样式。状态不只靠颜色表达，标签内始终有中文（需求 10.2） */
export const STATUS_STYLE = {
  在售: 'tag-green', 待自提: 'tag-blue', 已完成: 'tag-green', 已核销: 'tag-green', 已接受: 'tag-green',
  开放: 'tag-green', 正常: 'tag-green', 启用: 'tag-green', 已退款: 'tag-blue',
  待备货: 'tag-orange', 备货中: 'tag-orange', 待领取: 'tag-orange', 待确认: 'tag-orange',
  已挂起: 'tag-orange', 已满: 'tag-orange', 冷藏: 'tag-orange',
  超时作废: 'tag-red', 已拒绝: 'tag-red', 已售罄: 'tag-red', 已下架: 'tag-gray',
  已取消: 'tag-gray', 关闭: 'tag-gray', 停用: 'tag-gray', 常温: 'tag-gray'
}

export function statusClass(s) {
  if (s === 1) return 'tag-green'
  if (s === 0) return 'tag-gray'
  if (s === 2) return 'tag-red'
  return STATUS_STYLE[s] || 'tag-gray'
}

/** 数值型状态码翻译成中文，前端展示永远不出现裸数字 */
const MAP = {
  1: '在售', 0: '已下架', 2: '已售罄'
}
export function statusText(v, map) {
  if (v === null || v === undefined || v === '') return '-'
  if (typeof v === 'string') return v
  const m = map || MAP
  return m[v] ?? String(v)
}
