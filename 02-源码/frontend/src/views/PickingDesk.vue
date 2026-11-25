<template>
  <div>
    <h1 class="page-title">备货工作台</h1>
    <div class="page-sub">左侧领取任务，右侧按货架位分组拣货；每行一个大号数量步进器，实备少于应备须先发起缺货替换</div>

    <div class="desk">
      <div class="panel queue">
        <h3>待领取任务 <span class="muted" style="font-size:12px">{{ todo.length }} 单</span></h3>
        <div v-if="!todo.length" class="empty-tip">当前没有待领取任务</div>
        <div v-for="t in todo" :key="t.id" class="task" :class="{ on: cur.id === t.id }" @click="pick(t)">
          <div class="tl">
            <b>{{ t.task_no }}</b>
            <span :class="t.status === '备货中' ? 'tag-orange' : 'tag-gray'">{{ t.status }}</span>
          </div>
          <div class="muted" style="font-size:12px">订单 {{ orderMap[t.order_id]?.order_no || '-' }}　应备 {{ t.plan_qty }} 件</div>
          <div class="muted" style="font-size:12px">货架 {{ t.shelf_list }}</div>
        </div>
        <div class="my">
          <h3 style="margin-top:14px">我的进行中</h3>
          <div v-for="t in mine" :key="t.id" class="task" :class="{ on: cur.id === t.id }" @click="pick(t)">
            <div class="tl"><b>{{ t.task_no }}</b><span class="tag-orange">{{ t.status }}</span></div>
            <div class="muted" style="font-size:12px">已拣 {{ t.real_qty }} / 应备 {{ t.plan_qty }} 件</div>
          </div>
        </div>
      </div>

      <div class="panel list">
        <h3>
          <span>拣货清单 {{ cur.task_no ? '· ' + cur.task_no : '' }}</span>
          <span v-if="cur.id" class="muted" style="font-size:12px">取货码 {{ orderMap[cur.order_id]?.pickup_code }}</span>
        </h3>
        <div v-if="!cur.id" class="empty-tip">从左侧选择一个任务开始拣货</div>
        <template v-else>
          <div class="orderbar">
            <div>
              <b>{{ orderMap[cur.order_id]?.order_no }}</b>
              <span class="muted" style="margin-left:10px;font-size:12.5px">
                {{ pointMap[orderMap[cur.order_id]?.point_id] }}　{{ slotText(cur.order_id) }}
              </span>
            </div>
            <div>
              <el-button v-if="cur.status === '待领取'" type="primary" @click="claim">领取任务</el-button>
              <el-button v-if="cur.status === '备货中'" @click="hangup">挂起</el-button>
              <el-button v-if="cur.status === '备货中'" type="success" @click="finish">备货完成</el-button>
            </div>
          </div>

          <div v-for="g in groups" :key="g.shelf" class="shelf">
            <div class="shelf-h"><span class="step-num">{{ g.shelf.slice(0, 1) }}</span>货架位 {{ g.shelf }}</div>
            <div v-for="it in g.items" :key="it.id" class="pick-row">
              <img class="img-box" :src="it.image" alt="" />
              <div class="pi">
                <b>{{ it.name }}</b>
                <div class="muted" style="font-size:12px">{{ it.spec }}　单价 {{ formatMoney(it.price) }}
                  <span v-if="it.is_cold" class="tag-orange" style="margin-left:6px">冷藏优先</span>
                </div>
              </div>
              <div class="pq">
                <el-input-number v-model="qty[it.id]" :min="0" :max="it.qty" size="large" />
                <span class="muted" style="font-size:12px">应拣 {{ it.qty }} 件</span>
              </div>
              <el-button link type="danger" size="small" @click="openReplace(it, g.shelf)">缺货</el-button>
            </div>
          </div>

          <div class="summary">
            <span>应备 <b>{{ cur.plan_qty }}</b> 件　实拣 <b style="color:var(--primary)">{{ realTotal }}</b> 件</span>
            <span v-if="realTotal < cur.plan_qty" class="tag-orange">差 {{ cur.plan_qty - realTotal }} 件，需先发起缺货替换</span>
          </div>
        </template>
      </div>
    </div>

    <el-dialog v-model="repVisible" title="发起缺货替换" width="560px">
      <div class="panel" style="box-shadow:none;background:#f7f9f8">
        <div class="muted" style="font-size:12.5px">原商品</div>
        <div style="font-weight:600">{{ repItem.name }}　{{ repItem.spec }}　应拣 {{ repItem.qty }} 件</div>
      </div>
      <el-form label-width="100px">
        <el-form-item label="替换数量">
          <el-input-number v-model="rep.qty" :min="1" :max="repItem.qty || 1" />
        </el-form-item>
        <el-form-item label="替换商品">
          <el-select v-model="rep.replace_goods_id" clearable placeholder="留空表示直接退款" style="width:100%">
            <el-option v-for="g in sameCategory" :key="g.id" :label="`${g.name} ${g.spec}　${formatMoney(g.sale_price)}　库存${g.stock_qty}`" :value="g.id" />
          </el-select>
        </el-form-item>
        <div class="muted" style="font-size:12.5px;padding-left:100px">
          同订单最多发起 2 次替换，第 3 次只能整单退款；学生 10 分钟内未确认视为拒绝
        </div>
      </el-form>
      <template #footer>
        <el-button @click="repVisible = false">取消</el-button>
        <el-button type="primary" @click="submitReplace">提交替换</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../api/request'
import { formatMoney } from '../utils/format'

const tasks = ref([])
const cur = ref({})
const items = ref([])
const qty = reactive({})
const goods = ref([])
const orders = ref([])
const points = ref([])
const slots = ref([])
const repVisible = ref(false)
const repItem = ref({})
const rep = reactive({ qty: 1, replace_goods_id: null })

const todo = computed(() => tasks.value.filter((t) => t.status === '待领取'))
const mine = computed(() => tasks.value.filter((t) => t.status === '备货中'))
const orderMap = computed(() => Object.fromEntries(orders.value.map((o) => [o.id, o])))
const pointMap = computed(() => Object.fromEntries(points.value.map((p) => [p.id, p.name])))
const goodsMap = computed(() => Object.fromEntries(goods.value.map((g) => [g.id, g])))
const realTotal = computed(() => items.value.reduce((a, it) => a + (qty[it.id] || 0), 0))
const groups = computed(() => {
  const map = {}
  for (const it of items.value) {
    const g = goodsMap.value[it.goods_id] || {}
    const shelf = g.shelf_code || '未分配'
    ;(map[shelf] = map[shelf] || []).push({ ...it, name: g.name, spec: g.spec, image: g.image,
      is_cold: g.is_cold, stock_qty: g.stock_qty })
  }
  return Object.keys(map).sort().map((shelf) => ({ shelf, items: map[shelf] }))
})
const sameCategory = computed(() => {
  const origin = goodsMap.value[repItem.value.goods_id] || {}
  return goods.value.filter((g) => g.category_code === origin.category_code && g.id !== origin.id && g.status === 1)
})

function slotText(orderId) {
  const o = orderMap.value[orderId]
  const s = slots.value.find((x) => x.id === o?.slot_id)
  return s ? `${s.slot_date} ${String(s.start_time).slice(0, 5)}-${String(s.end_time).slice(0, 5)}` : ''
}

async function load() {
  const res = await request.get('/api/picking-task/page', { params: { page: 1, size: 50 } })
  tasks.value = (res.data.records || []).filter((t) => t.status === '待领取' || t.status === '备货中')
}

async function pick(t) {
  cur.value = t
  const res = await request.get('/api/order-item/page', { params: { page: 1, size: 100 } })
  items.value = (res.data.records || []).filter((i) => i.order_id === t.order_id)
  items.value.forEach((i) => { qty[i.id] = i.qty })
}

async function claim() {
  const res = await request.post(`/api/picking-task/${cur.value.id}/claim`)
  if (res.code === 0) { ElMessage.success('已领取，开始计时'); await load(); cur.value = tasks.value.find((t) => t.id === cur.value.id) || {} }
}

async function hangup() {
  const { value } = await ElMessageBox.prompt('挂起原因（不少于 5 个字）', '挂起任务', { inputPlaceholder: '例如：货架补货中，等待 10 分钟' })
  const res = await request.post(`/api/picking-task/${cur.value.id}/hangup`, { reason: value })
  if (res.code === 0) { ElMessage.success('已挂起'); await load(); cur.value = {}; items.value = [] }
}

async function finish() {
  const res = await request.post(`/api/picking-task/${cur.value.id}/finish`, { real_qty: realTotal.value })
  if (res.code === 0) {
    ElMessage.success('备货完成，已通知学生取货')
    await load(); cur.value = {}; items.value = []
  }
}

function openReplace(item) {
  repItem.value = item
  rep.qty = 1
  rep.replace_goods_id = null
  repVisible.value = true
}

async function submitReplace() {
  const res = await request.post(`/api/pickup-order/${cur.value.order_id}/replace`, {
    origin_goods_id: repItem.value.goods_id,
    replace_goods_id: rep.replace_goods_id,
    qty: rep.qty
  })
  if (res.code === 0) {
    ElMessage.success('替换请求已推送学生，10 分钟内确认')
    repVisible.value = false
    qty[repItem.value.id] = 0
  }
}

onMounted(async () => {
  await load()
  const [o, g, p, s] = await Promise.all([
    request.get('/api/pickup-order/page', { params: { page: 1, size: 100 } }),
    request.get('/api/shop-goods/page', { params: { page: 1, size: 100 } }),
    request.get('/api/pickup-point/page', { params: { page: 1, size: 20 } }),
    request.get('/api/pick-slot/page', { params: { page: 1, size: 100 } })
  ])
  orders.value = o.data.records || []
  goods.value = g.data.records || []
  points.value = p.data.records || []
  slots.value = s.data.records || []
})
</script>

<style scoped>
.desk { display: grid; grid-template-columns: 320px 1fr; gap: 14px; align-items: start; }
.queue { max-height: calc(100vh - 190px); overflow: auto; }
.task { border: 1px solid var(--line); border-radius: 10px; padding: 9px 11px; margin-bottom: 8px; cursor: pointer; }
.task.on { border-color: var(--primary); background: #eff7f5; }
.task .tl { display: flex; justify-content: space-between; align-items: center; font-size: 13px; }
.orderbar { display: flex; align-items: center; justify-content: space-between; padding: 8px 12px; background: #f7f9f8; border-radius: 10px; margin-bottom: 12px; }
.shelf { margin-bottom: 12px; }
.shelf-h { font-size: 13px; font-weight: 600; color: var(--primary); margin-bottom: 6px; }
.pick-row { display: flex; align-items: center; gap: 12px; padding: 8px 10px; border-bottom: 1px dashed var(--line); }
.pi { flex: 1; min-width: 0; }
.pq { display: flex; flex-direction: column; align-items: center; gap: 2px; }
.summary { display: flex; gap: 18px; align-items: center; padding: 10px 12px; background: #f7f9f8; border-radius: 10px; font-size: 13.5px; }
</style>
