<template>
  <div>
    <h1 class="page-title">确认订单 · 选择自提时段</h1>
    <div class="page-sub">同一学生在同一时段只允许一个进行中订单；下单后 30 分钟内可自助取消，库存与名额同步释放</div>

    <div v-if="!cart.items.length" class="panel empty-tip">
      购物车还是空的，<a style="color:var(--primary)" @click="$router.push('/portal')">去挑几件</a>
    </div>

    <template v-else>
      <div class="row-3">
        <div>
          <div class="panel">
            <h3>商品清单 <span class="muted" style="font-size:12px">{{ cart.count }} 件</span></h3>
            <div v-for="it in cart.items" :key="it.id" class="line">
              <img class="img-box" :src="it.image" alt="" />
              <div style="flex:1">
                <b>{{ it.name }}</b>
                <div class="muted" style="font-size:12px">{{ it.spec }}　{{ formatMoney(it.sale_price) }}</div>
              </div>
              <el-input-number v-model="it.qty" :min="1" :max="99" size="small" @change="cart.setQty(it.id, it.qty)" />
              <span class="price" style="width:88px;text-align:right">{{ formatMoney(it.qty * it.sale_price) }}</span>
              <el-button link type="danger" size="small" @click="cart.remove(it.id)">移除</el-button>
            </div>
          </div>

          <div class="panel">
            <h3>自提点</h3>
            <el-radio-group v-model="pointId" @change="loadSlots">
              <el-radio v-for="p in points" :key="p.id" :value="p.id" border style="margin-bottom:8px">
                <b>{{ p.name }}</b>
                <span class="muted" style="font-size:12px;margin-left:8px">{{ p.location_desc }}</span>
              </el-radio>
            </el-radio-group>
          </div>

          <div class="panel">
            <h3>自提时段 <span class="muted" style="font-size:12px">按日期分组，容量已满置灰</span></h3>
            <div v-for="g in slotGroups" :key="g.date" class="sgroup">
              <div class="sdate">{{ g.label }}　<span class="muted" style="font-size:12px">{{ g.date }}</span></div>
              <div>
                <div v-for="s in g.slots" :key="s.id" class="slot-pill"
                     :class="{ active: slotId === s.id, disabled: s.status !== 1 || s.booked_count >= s.capacity }"
                     @click="chooseSlot(s)">
                  <b>{{ formatClock(s.start_time) }}-{{ formatClock(s.end_time) }}</b>
                  <span>{{ s.status !== 1 || s.booked_count >= s.capacity ? '已满' : '剩 ' + (s.capacity - s.booked_count) + ' 位' }}</span>
                </div>
              </div>
            </div>
            <div v-if="!slotGroups.length" class="empty-tip">该自提点暂无可选时段</div>
          </div>
        </div>

        <div class="panel settle">
          <h3>结算</h3>
          <div class="srow"><span class="muted">商品金额</span><span>{{ formatMoney(cart.amount) }}</span></div>
          <div class="srow"><span class="muted">优惠</span><span>- ¥0.00</span></div>
          <div class="srow"><span class="muted">自提方式</span><span>到店自提（不接入在线支付）</span></div>
          <div class="srow total"><span>合计</span><span class="price">{{ formatMoney(cart.amount) }}</span></div>
          <div class="muted" style="font-size:12px;margin:10px 0 12px">
            下单即锁定库存并占用时段名额，30 分钟内可取消；超过时段结束 2 小时未取自动作废。
          </div>
          <el-button type="primary" size="large" style="width:100%" :loading="loading" @click="submit">
            提交订单
          </el-button>
          <div v-if="!store.token" class="muted" style="font-size:12px;margin-top:8px;text-align:center">
            提交前需 <a style="color:var(--primary)" @click="$router.push('/login')">登录校内账号</a>
          </div>
        </div>
      </div>
    </template>

    <el-dialog v-model="okVisible" title="下单成功" width="420px" :close-on-click-modal="false">
      <div style="text-align:center;padding:8px 0 4px">
        <div style="font-size:13px;color:var(--muted)">取货码</div>
        <div class="code">{{ result.pickup_code }}</div>
        <div class="muted" style="font-size:12.5px">订单 {{ result.order_no }}　实付 {{ formatMoney(result.pay_amount) }}</div>
      </div>
      <template #footer>
        <el-button @click="goOrders">查看我的订单</el-button>
        <el-button type="primary" @click="goHome">继续选购</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import request from '../api/request'
import { useCartStore } from '../store/cart'
import { useUserStore } from '../store/user'
import { formatClock, formatMoney } from '../utils/format'

const router = useRouter()
const cart = useCartStore()
const store = useUserStore()
const points = ref([])
const slots = ref([])
const pointId = ref(null)
const slotId = ref(null)
const loading = ref(false)
const okVisible = ref(false)
const result = ref({})

const WEEK = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
const slotGroups = computed(() => {
  const map = {}
  for (const s of slots.value) {
    if (s.status === 0) continue
    ;(map[s.slot_date] = map[s.slot_date] || []).push(s)
  }
  return Object.keys(map).sort().map((d) => {
    const dt = new Date(d.replace(/-/g, '/'))
    const today = new Date(); today.setHours(0, 0, 0, 0)
    const diff = Math.round((dt - today) / 86400000)
    const label = diff === 0 ? '今天' : diff === 1 ? '明天' : WEEK[dt.getDay()]
    return { date: d, label, slots: map[d] }
  })
})

async function loadSlots() {
  slotId.value = null
  const res = await request.get('/api/portal/home', { params: { point_id: pointId.value } })
  points.value = res.data.points || []
  slots.value = res.data.slots || []
  cart.setPoint(pointId.value)
}

function chooseSlot(s) {
  if (s.status !== 1 || s.booked_count >= s.capacity) {
    return ElMessage.warning('该时段已满，请选择其他时段')
  }
  slotId.value = s.id
}

async function submit() {
  if (!store.token) { ElMessage.warning('请先登录校内账号'); return router.push('/login') }
  if (!cart.items.length) return ElMessage.warning('购物车为空')
  if (!slotId.value) return ElMessage.warning('请选择自提时段')
  loading.value = true
  try {
    const res = await request.post('/api/pickup-order/create', {
      point_id: pointId.value,
      slot_id: slotId.value,
      items: cart.items.map((i) => ({ goods_id: i.id, qty: i.qty }))
    })
    if (res.code === 0) {
      result.value = res.data
      okVisible.value = true
      cart.clear()
    }
  } finally { loading.value = false }
}

function goOrders() { okVisible.value = false; router.push('/my-orders') }
function goHome() { okVisible.value = false; router.push('/portal') }

onMounted(async () => {
  const res = await request.get('/api/portal/home', { params: { point_id: cart.pointId || undefined } })
  points.value = res.data.points || []
  pointId.value = cart.pointId || res.data.point_id
  slots.value = res.data.slots || []
})
</script>

<style scoped>
.line { display: flex; align-items: center; gap: 12px; padding: 9px 0; border-bottom: 1px dashed var(--line); }
.sgroup { margin-bottom: 14px; }
.sdate { font-size: 13px; font-weight: 600; margin-bottom: 8px; }
.settle { align-self: start; position: sticky; top: 80px; }
.srow { display: flex; justify-content: space-between; font-size: 13px; padding: 5px 0; }
.srow.total { border-top: 1px solid var(--line); margin-top: 8px; padding-top: 10px; font-size: 15px; font-weight: 700; }
.code { font-size: 38px; font-weight: 700; letter-spacing: 8px; color: var(--primary); margin: 6px 0; }
</style>
