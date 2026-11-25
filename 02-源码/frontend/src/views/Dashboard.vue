<template>
  <div class="dash">
    <div class="head">
      <div>
        <h1 class="page-title">校园超市经营看板</h1>
        <div class="page-sub" style="margin:0">数据每 15 分钟刷新　·　统计口径：自提订单与核销记录　·　截止 {{ now }}</div>
      </div>
      <div class="hbtns">
        <el-radio-group v-model="range" size="small" @change="loadTrend">
          <el-radio-button :value="7">最近7天</el-radio-button>
          <el-radio-button :value="30">最近30天</el-radio-button>
        </el-radio-group>
        <el-button size="small" @click="loadAll">刷新</el-button>
      </div>
    </div>

    <div class="kpi-grid">
      <div class="kpi"><div class="t">今日自提订单数</div><div class="v">{{ k.today_orders ?? 0 }}</div>
        <div class="d">已核销 {{ k.today_done ?? 0 }} 单</div></div>
      <div class="kpi"><div class="t">自提完成率</div><div class="v">{{ k.complete_rate ?? 0 }}%</div>
        <div class="d">全量订单 {{ k.total_orders ?? 0 }} 单</div></div>
      <div class="kpi acc"><div class="t">平均备货时长</div><div class="v">{{ k.avg_ready_min ?? 0 }} 分</div>
        <div class="d">目标 ≤ 15 分钟</div></div>
      <div class="kpi acc"><div class="t">超时作废单数</div><div class="v">{{ k.timeout_orders ?? 0 }}</div>
        <div class="d">时段结束 2 小时未取</div></div>
      <div class="kpi"><div class="t">缺货替换率</div><div class="v">{{ k.replace_rate ?? 0 }}%</div>
        <div class="d">替换单 / 总订单</div></div>
      <div class="kpi"><div class="t">时段容量利用率</div><div class="v">{{ k.capacity_use ?? 0 }}%</div>
        <div class="d">已预约 / 总容量</div></div>
      <div class="kpi"><div class="t">预测准确率</div><div class="v">{{ k.forecast_accuracy ?? 0 }}%</div>
        <div class="d">未人工修正占比</div></div>
      <div class="kpi acc"><div class="t">高峰平均排队人数</div><div class="v">{{ k.queue_avg ?? 0 }} 人</div>
        <div class="d">按自提点服务上限估算</div></div>
    </div>

    <div class="row-3">
      <div class="panel">
        <h3>近 {{ range }} 天订单量与自提完成率</h3>
        <div ref="trendRef" class="chart" style="height:148px"></div>
      </div>
      <div class="panel">
        <h3>商品分类销量占比</h3>
        <div ref="catRef" class="chart" style="height:148px"></div>
      </div>
    </div>

    <div class="row-3">
      <div class="panel">
        <h3>一周各时段订单密度热力图</h3>
        <div ref="heatRef" class="chart" style="height:144px"></div>
      </div>
      <div class="panel">
        <h3>各自提点平均备货时长</h3>
        <div ref="durRef" class="chart" style="height:144px"></div>
      </div>
    </div>

    <div class="row-2">
      <div class="panel">
        <h3>预测备货量与实际销量对比</h3>
        <div ref="cmpRef" class="chart" style="height:109px"></div>
      </div>
      <div class="panel">
        <h3>超时作废 / 取消原因占比</h3>
        <div ref="reasonRef" class="chart" style="height:109px"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import * as echarts from 'echarts'
import request from '../api/request'
import { formatTime } from '../utils/format'

const k = ref({})
const range = ref(7)
const now = ref(formatTime(new Date()))
const trendRef = ref(); const catRef = ref(); const heatRef = ref()
const durRef = ref(); const cmpRef = ref(); const reasonRef = ref()
let charts = []

function make(el, option) {
  const c = echarts.init(el)
  c.setOption(option)
  charts.push(c)
  return c
}
const PALETTE = ['#16695C', '#3D9683', '#E0A32E', '#7FB5A8', '#B9C7C2', '#9A6B11']

async function loadKpi() {
  const res = await request.get('/api/dashboard/overview')
  k.value = res.data || {}
}

async function loadTrend() {
  charts.forEach((c) => c.dispose()); charts = []
  const [trend, cat, heat, dur, cmp, reason] = await Promise.all([
    request.get('/api/dashboard/trend', { params: { days: range.value } }),
    request.get('/api/dashboard/category'),
    request.get('/api/dashboard/hour-heatmap'),
    request.get('/api/dashboard/point-duration'),
    request.get('/api/dashboard/forecast-compare'),
    request.get('/api/dashboard/timeout-reason')
  ])
  const t = trend.data || []
  make(trendRef.value, {
    color: PALETTE, tooltip: { trigger: 'axis' }, legend: { right: 0, top: 0, itemHeight: 6, textStyle: { fontSize: 11 } },
    grid: { left: 34, right: 34, top: 32, bottom: 22 },
    xAxis: { type: 'category', data: t.map((i) => i.date), axisLine: { lineStyle: { color: '#dfe4e2' } }, axisLabel: { fontSize: 10.5 } },
    yAxis: [{ type: 'value', splitLine: { lineStyle: { color: '#f0f2f4' } }, axisLabel: { fontSize: 10.5 } },
            { type: 'value', max: 100, splitLine: { show: false }, axisLabel: { fontSize: 10.5, formatter: '{value}%' } }],
    series: [
      { name: '订单量', type: 'line', smooth: true, symbolSize: 5, data: t.map((i) => i.orders), areaStyle: { opacity: .12 } },
      { name: '完成率', type: 'line', yAxisIndex: 1, smooth: true, symbolSize: 5, data: t.map((i) => i.rate), lineStyle: { type: 'dashed' } }
    ]
  })
  const c = cat.data || []
  make(catRef.value, {
    color: PALETTE, tooltip: { trigger: 'item' },
    legend: { orient: 'vertical', right: 0, top: 'center', itemHeight: 6, textStyle: { fontSize: 10.5 } },
    series: [{ type: 'pie', radius: ['48%', '70%'], center: ['36%', '52%'], label: { show: false },
      data: c.map((i) => ({ name: i.name, value: i.value })) }]
  })
  const h = heat.data || { items: [], days: [], hours: [] }
  make(heatRef.value, {
    tooltip: { formatter: (p) => `${h.days[p.value[1]]} ${h.hours[p.value[0]]}:00　订单 ${p.value[2]}` },
    grid: { left: 44, right: 12, top: 10, bottom: 42 },
    xAxis: { type: 'category', data: h.hours.map((x) => x + ':00'), splitArea: { show: true }, axisLabel: { fontSize: 9.5, interval: 1 } },
    yAxis: { type: 'category', data: h.days, splitArea: { show: true }, axisLabel: { fontSize: 10.5 } },
    visualMap: { min: 0, max: h.max || 1, calculable: false, orient: 'horizontal', left: 'center', bottom: 0,
      itemHeight: 60, itemWidth: 8, textStyle: { fontSize: 10 }, inRange: { color: ['#eef4f2', '#8fc0b3', '#16695c'] } },
    series: [{ type: 'heatmap', data: h.items.map((i) => [i.x, i.y, i.value]), label: { show: false },
      emphasis: { itemStyle: { shadowBlur: 6, shadowColor: 'rgba(0,0,0,.2)' } } }]
  })
  const d = dur.data || []
  make(durRef.value, {
    color: ['#3D9683'], tooltip: { trigger: 'axis' }, grid: { left: 96, right: 30, top: 10, bottom: 18 },
    xAxis: { type: 'value', splitLine: { lineStyle: { color: '#f0f2f4' } }, axisLabel: { fontSize: 10 } },
    yAxis: { type: 'category', data: d.map((i) => i.name.slice(0, 9)), axisLabel: { fontSize: 10.5 } },
    series: [{ type: 'bar', barWidth: 12, data: d.map((i) => i.minutes), itemStyle: { borderRadius: [0, 6, 6, 0] },
      label: { show: true, position: 'right', fontSize: 10, formatter: '{c} 分' } }]
  })
  const m = cmp.data || []
  make(cmpRef.value, {
    color: ['#16695C', '#E0A32E'], tooltip: { trigger: 'axis' }, legend: { right: 0, top: 0, itemHeight: 6, textStyle: { fontSize: 11 } },
    grid: { left: 34, right: 12, top: 28, bottom: 20 },
    xAxis: { type: 'category', data: m.map((i) => i.slot), axisLabel: { fontSize: 10 } },
    yAxis: { type: 'value', splitLine: { lineStyle: { color: '#f0f2f4' } }, axisLabel: { fontSize: 10 } },
    series: [{ name: '建议备货', type: 'bar', barWidth: 12, data: m.map((i) => i.forecast), itemStyle: { borderRadius: [4, 4, 0, 0] } },
             { name: '实际销量', type: 'bar', barWidth: 12, data: m.map((i) => i.actual), itemStyle: { borderRadius: [4, 4, 0, 0] } }]
  })
  const rs = reason.data || []
  make(reasonRef.value, {
    color: ['#B02A37', '#E0A32E', '#3D9683', '#7FB5A8'], tooltip: { trigger: 'item' },
    legend: { orient: 'vertical', right: 0, top: 'center', itemHeight: 6, textStyle: { fontSize: 10 } },
    series: [{ type: 'pie', radius: '66%', center: ['34%', '52%'], label: { show: false },
      data: rs.map((i) => ({ name: String(i.name).slice(0, 12), value: i.value })) }]
  })
}

async function loadAll() {
  now.value = formatTime(new Date())
  await loadKpi()
  await loadTrend()
}
function onResize() { charts.forEach((c) => c.resize()) }

onMounted(() => { loadAll(); window.addEventListener('resize', onResize) })
onBeforeUnmount(() => { window.removeEventListener('resize', onResize); charts.forEach((c) => c.dispose()) })
</script>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 8px; }
.head .page-title { font-size: 18px; }
.head .page-sub { font-size: 12px; }
.hbtns { display: flex; gap: 8px; align-items: center; }
.dash .panel { margin-bottom: 10px; padding: 10px 12px 6px; }
.dash .panel h3 { font-size: 13px; margin-bottom: 2px; }
.dash .kpi-grid { gap: 10px; margin-bottom: 10px; }
.dash .kpi { padding: 7px 11px; }
.dash .kpi .t { font-size: 12px; }
.dash .kpi .v { font-size: 19px; margin-top: 0; }
.dash .kpi .d { font-size: 11px; margin-top: 0; }
.dash { padding-bottom: 0; }
</style>
