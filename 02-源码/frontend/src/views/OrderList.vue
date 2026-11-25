<template>
  <div>
    <h1 class="page-title">订单管理</h1>
    <div class="page-sub">全部自提订单按状态流转，取消需在下单后 30 分钟内且订单仍为待备货；点击单号查看明细与流转记录</div>
    <div class="filters">
      <el-input v-model="q.keyword" placeholder="订单号 / 取货码" clearable @keyup.enter="load" />
      <el-select v-model="q.status" placeholder="全部状态" clearable>
        <el-option v-for="s in STATUS" :key="s" :label="s" :value="s" />
      </el-select>
      <el-select v-model="q.point" placeholder="全部自提点" clearable>
        <el-option v-for="p in points" :key="p.id" :label="p.name" :value="String(p.id)" />
      </el-select>
      <el-button type="primary" @click="load">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <span class="muted" style="margin-left:auto;font-size:13px">共 {{ total }} 单</span>
    </div>

    <div class="panel" style="padding:0 0 6px">
      <el-table :data="rows" v-loading="loading" style="width:100%">
        <el-table-column prop="order_no" label="订单号" min-width="150">
          <template #default="{ row }"><a class="link" @click="openDetail(row)">{{ row.order_no }}</a></template>
        </el-table-column>
        <el-table-column prop="pickup_code" label="取货码" width="96">
          <template #default="{ row }"><b style="letter-spacing:1px">{{ row.pickup_code }}</b></template>
        </el-table-column>
        <el-table-column label="学生" width="110">
          <template #default="{ row }">{{ userMap[row.student_id] || ('学生#' + row.student_id) }}</template>
        </el-table-column>
        <el-table-column label="自提点" min-width="170">
          <template #default="{ row }">{{ pointMap[row.point_id] || ('自提点#' + row.point_id) }}</template>
        </el-table-column>
        <el-table-column label="金额" width="100">
          <template #default="{ row }"><span class="price">{{ formatMoney(row.pay_amount) }}</span></template>
        </el-table-column>
        <el-table-column label="下单时间" width="160">
          <template #default="{ row }">{{ formatTime(row.order_time) }}</template>
        </el-table-column>
        <el-table-column label="备货完成" width="160">
          <template #default="{ row }">{{ row.ready_time ? formatTime(row.ready_time) : '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="98">
          <template #default="{ row }"><span :class="statusClass(row.status)">{{ row.status }}</span></template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="openDetail(row)">查看</el-button>
            <el-button v-if="row.status === '待备货'" link type="danger" size="small" @click="cancel(row)">取消</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div style="display:flex;justify-content:flex-end;padding:12px 16px 4px">
        <el-pagination v-model:current-page="q.page" v-model:page-size="q.size" :total="total"
                       :page-sizes="[10, 20, 50]" layout="total, sizes, prev, pager, next" @change="load" />
      </div>
    </div>

    <el-drawer v-model="drawer" :title="'订单 ' + (cur.order_no || '')" size="560px">
      <div class="panel" style="box-shadow:none;background:#f7f9f8">
        <div style="display:flex;justify-content:space-between;align-items:center">
          <div>
            <div class="muted" style="font-size:12.5px">{{ pointMap[cur.point_id] }}　取货码 <b>{{ cur.pickup_code }}</b></div>
            <div style="font-size:17px;font-weight:700;margin-top:2px">{{ userMap[cur.student_id] }} 的自提订单</div>
          </div>
          <span :class="statusClass(cur.status)">{{ cur.status }}</span>
        </div>
        <div class="muted" style="font-size:12.5px;margin-top:6px">
          下单 {{ formatTime(cur.order_time) }}　备货完成 {{ cur.ready_time ? formatTime(cur.ready_time) : '未完成' }}
        </div>
      </div>
      <h3 style="font-size:14px;margin:4px 0 8px">商品明细</h3>
      <el-table :data="items" size="small">
        <el-table-column label="商品" min-width="170">
          <template #default="{ row }">{{ goodsMap[row.goods_id] || ('商品#' + row.goods_id) }}</template>
        </el-table-column>
        <el-table-column prop="qty" label="数量" width="64" />
        <el-table-column label="单价" width="84">
          <template #default="{ row }">{{ formatMoney(row.price) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <span :class="row.out_of_stock ? 'tag-red' : 'tag-green'">{{ row.out_of_stock ? '缺货' : '正常' }}</span>
          </template>
        </el-table-column>
      </el-table>
      <div style="display:flex;justify-content:space-between;margin-top:12px;font-size:13px">
        <span class="muted">商品金额 {{ formatMoney(cur.goods_amount) }}</span>
        <span>实付 <b class="price">{{ formatMoney(cur.pay_amount) }}</b></span>
      </div>
      <div v-if="cur.cancel_reason" class="panel" style="box-shadow:none;background:#fdf3f4;margin-top:12px">
        <div class="muted" style="font-size:12.5px">取消/作废原因</div>
        <div style="font-size:13px">{{ cur.cancel_reason }}</div>
      </div>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../api/request'
import { formatMoney, formatTime, statusClass } from '../utils/format'

const STATUS = ['待备货', '备货中', '待自提', '已核销', '已取消', '超时作废']
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const drawer = ref(false)
const cur = ref({})
const items = ref([])
const points = ref([])
const pointMap = ref({})
const userMap = ref({})
const goodsMap = ref({})
const q = reactive({ page: 1, size: 10, keyword: '', status: '', point: '' })

async function load() {
  loading.value = true
  try {
    let url = `/api/pickup-order/page?page=${q.page}&size=${q.size}`
    if (q.keyword) url += `&keyword=${encodeURIComponent(q.keyword)}`
    if (q.status) url += `&status=${encodeURIComponent(q.status)}`
    const res = await request.get(url)
    let list = res.data.records || []
    if (q.point) list = list.filter((r) => String(r.point_id) === q.point)
    rows.value = list
    total.value = q.point ? list.length : res.data.total
  } finally { loading.value = false }
}
function reset() { q.keyword = ''; q.status = ''; q.point = ''; q.page = 1; load() }

async function openDetail(row) {
  cur.value = row
  const res = await request.get(`/api/pickup-order/${row.id}`)
  cur.value = { ...row, ...res.data }
  const its = await request.get('/api/order-item/page', { params: { page: 1, size: 50 } })
  items.value = (its.data.records || []).filter((i) => i.order_id === row.id)
  drawer.value = true
}

async function cancel(row) {
  const { value } = await ElMessageBox.prompt('取消原因（不少于 2 个字）', '取消订单', {
    confirmButtonText: '确认取消', cancelButtonText: '再想想', inputPlaceholder: '例如：临时改选其他时段'
  })
  const res = await request.post(`/api/pickup-order/${row.id}/cancel`, { reason: value })
  if (res.code === 0) { ElMessage.success('已取消，库存与时段名额已释放'); load() }
}

onMounted(async () => {
  await load()
  const [p, u, g] = await Promise.all([
    request.get('/api/pickup-point/page', { params: { page: 1, size: 50 } }),
    request.get('/api/sys-user/page', { params: { page: 1, size: 50 } }),
    request.get('/api/shop-goods/page', { params: { page: 1, size: 100 } })
  ])
  points.value = p.data.records || []
  pointMap.value = Object.fromEntries((p.data.records || []).map((x) => [x.id, x.name]))
  userMap.value = Object.fromEntries((u.data.records || []).map((x) => [x.id, x.real_name]))
  goodsMap.value = Object.fromEntries((g.data.records || []).map((x) => [x.id, x.name]))
})
</script>

<style scoped>
.link { color: var(--primary); cursor: pointer; font-weight: 600; }
</style>
