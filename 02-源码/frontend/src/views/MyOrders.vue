<template>
  <div>
    <h1 class="page-title">我的订单</h1>
    <div class="page-sub">下单后 30 分钟内可自助取消；备货完成会推送取货提醒，到店报取货码即可</div>
    <el-tabs v-model="tab" @tab-change="load">
      <el-tab-pane label="全部" name="" />
      <el-tab-pane label="进行中" name="active" />
      <el-tab-pane label="已核销" name="已核销" />
      <el-tab-pane label="已取消/作废" name="closed" />
    </el-tabs>

    <div v-if="!rows.length" class="panel empty-tip">还没有订单，去门户挑几件吧</div>
    <div v-for="o in rows" :key="o.id" class="panel order">
      <div class="ohead">
        <div>
          <b>{{ o.order_no }}</b>
          <span class="muted" style="font-size:12.5px;margin-left:10px">{{ formatTime(o.order_time) }}</span>
        </div>
        <span :class="statusClass(o.status)">{{ o.status }}</span>
      </div>
      <div class="obody">
        <div class="ocode">
          <div class="muted" style="font-size:12px">取货码</div>
          <div class="code">{{ o.pickup_code }}</div>
        </div>
        <div class="oinfo">
          <div>{{ pointMap[o.point_id] }}　{{ slotMap[o.slot_id] }}</div>
          <div class="muted" style="font-size:12.5px">
            共 {{ itemCount[o.id] || 0 }} 件　实付 <b class="price">{{ formatMoney(o.pay_amount) }}</b>
          </div>
          <div v-if="o.cancel_reason" class="muted" style="font-size:12.5px">原因：{{ o.cancel_reason }}</div>
        </div>
        <div class="oact">
          <el-button v-if="o.status === '待备货'" size="small" @click="cancel(o)">取消订单</el-button>
          <el-button v-if="o.status === '待自提'" size="small" type="primary" @click="tip">取货提醒</el-button>
          <el-button v-if="o.status === '已核销'" size="small" @click="tip">申请售后</el-button>
        </div>
      </div>
      <div v-if="pendingReplace[o.id]" class="rep">
        <div>
          <span class="tag-orange">缺货待确认</span>
          替换为 {{ pendingReplace[o.id].replace_goods_id ? goodsMap[pendingReplace[o.id].replace_goods_id] : '直接退款' }}
          ，差价 {{ formatMoney(pendingReplace[o.id].diff_amount) }}，10 分钟内不确认视为拒绝
        </div>
        <div>
          <el-button size="small" type="primary" @click="confirmReplace(pendingReplace[o.id], true)">接受</el-button>
          <el-button size="small" @click="confirmReplace(pendingReplace[o.id], false)">拒绝退款</el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../api/request'
import { formatMoney, formatTime, statusClass } from '../utils/format'

const tab = ref('')
const orders = ref([])
const items = ref([])
const replaces = ref([])
const points = ref([])
const slots = ref([])
const goods = ref([])
const profile = ref({})

const pointMap = computed(() => Object.fromEntries(points.value.map((p) => [p.id, p.name])))
const goodsMap = computed(() => Object.fromEntries(goods.value.map((g) => [g.id, g.name])))
const slotMap = computed(() => Object.fromEntries(slots.value.map((s) => [s.id,
  `${s.slot_date} ${String(s.start_time).slice(0, 5)}-${String(s.end_time).slice(0, 5)}`])))
const itemCount = computed(() => {
  const m = {}
  items.value.forEach((i) => { m[i.order_id] = (m[i.order_id] || 0) + i.qty })
  return m
})
const pendingReplace = computed(() => {
  const m = {}
  replaces.value.filter((r) => r.status === '待确认').forEach((r) => { m[r.order_id] = r })
  return m
})
const rows = computed(() => {
  const mine = orders.value.filter((o) => o.student_id === profile.value.id)
  if (tab.value === 'active') return mine.filter((o) => ['待备货', '备货中', '待自提'].includes(o.status))
  if (tab.value === 'closed') return mine.filter((o) => ['已取消', '超时作废'].includes(o.status))
  if (tab.value) return mine.filter((o) => o.status === tab.value)
  return mine
})

async function load() {
  const [o, i, r] = await Promise.all([
    request.get('/api/pickup-order/page', { params: { page: 1, size: 100 } }),
    request.get('/api/order-item/page', { params: { page: 1, size: 300 } }),
    request.get('/api/shortage-replace/page', { params: { page: 1, size: 100 } })
  ])
  orders.value = o.data.records || []
  items.value = i.data.records || []
  replaces.value = r.data.records || []
}

async function cancel(o) {
  const { value } = await ElMessageBox.prompt('取消原因（不少于 2 个字）', '取消订单',
    { confirmButtonText: '确认取消', cancelButtonText: '再想想', inputPlaceholder: '例如：课程调整不需要了' })
  const res = await request.post(`/api/pickup-order/${o.id}/cancel`, { reason: value })
  if (res.code === 0) { ElMessage.success('已取消，库存与名额已释放'); load() }
}

async function confirmReplace(r, accept) {
  const res = await request.post(`/api/shortage-replace/${r.id}/confirm`, { accept })
  if (res.code === 0) { ElMessage.success(accept ? '已接受替换' : '已拒绝，订单整单退款'); load() }
}

function tip() { ElMessage.info('该功能在演示环境中仅展示入口，售后窗口为核销后 24 小时') }

onMounted(async () => {
  const info = await request.get('/api/auth/info')
  profile.value = { ...info.data, id: info.data.id }
  await load()
  const [p, s, g] = await Promise.all([
    request.get('/api/pickup-point/page', { params: { page: 1, size: 20 } }),
    request.get('/api/pick-slot/page', { params: { page: 1, size: 100 } }),
    request.get('/api/shop-goods/page', { params: { page: 1, size: 100 } })
  ])
  points.value = p.data.records || []
  slots.value = s.data.records || []
  goods.value = g.data.records || []
})
</script>

<style scoped>
.order { padding: 14px 16px; }
.ohead { display: flex; justify-content: space-between; align-items: center; padding-bottom: 10px; border-bottom: 1px solid var(--line); }
.obody { display: grid; grid-template-columns: 150px 1fr 160px; gap: 16px; align-items: center; padding-top: 10px; }
.code { font-size: 24px; font-weight: 700; letter-spacing: 4px; color: var(--primary); }
.oact { text-align: right; }
.rep { margin-top: 10px; background: #fbf7ec; border-radius: 10px; padding: 10px 12px; display: flex; justify-content: space-between; align-items: center; font-size: 12.5px; gap: 12px; }
</style>
