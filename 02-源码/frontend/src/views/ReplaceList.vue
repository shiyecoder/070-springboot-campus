<template>
  <div>
    <h1 class="page-title">缺货替换</h1>
    <div class="page-sub">备货发现缺货时发起替换，学生 10 分钟内确认；同一订单最多 2 次替换，第 3 次只能整单退款</div>
    <div class="filters">
      <el-select v-model="status" placeholder="全部状态" clearable @change="load">
        <el-option v-for="s in STATUS" :key="s" :label="s" :value="s" />
      </el-select>
      <el-button type="primary" @click="load">刷新</el-button>
      <span class="muted" style="margin-left:auto;font-size:13px">共 {{ rows.length }} 条</span>
    </div>
    <div class="panel" style="padding:0 0 6px">
      <el-table :data="rows" v-loading="loading">
        <el-table-column prop="replace_no" label="替换单号" width="150" />
        <el-table-column label="订单" width="150">
          <template #default="{ row }">{{ orderMap[row.order_id]?.order_no || ('#' + row.order_id) }}</template>
        </el-table-column>
        <el-table-column label="原商品" min-width="180">
          <template #default="{ row }">{{ goodsMap[row.origin_goods_id]?.name || '-' }}</template>
        </el-table-column>
        <el-table-column label="替换为" min-width="180">
          <template #default="{ row }">
            <span v-if="row.replace_goods_id">{{ goodsMap[row.replace_goods_id]?.name }}</span>
            <span v-else class="tag-gray">直接退款</span>
          </template>
        </el-table-column>
        <el-table-column prop="qty" label="数量" width="70" />
        <el-table-column label="差价" width="100">
          <template #default="{ row }">
            <span :class="Number(row.diff_amount) > 0 ? 'price' : 'muted'">{{ formatMoney(row.diff_amount) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }"><span :class="statusClass(row.status)">{{ row.status }}</span></template>
        </el-table-column>
        <el-table-column label="发起时间" width="170">
          <template #default="{ row }">{{ formatTime(row.create_time) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="170" fixed="right">
          <template #default="{ row }">
            <template v-if="row.status === '待确认'">
              <el-button link type="primary" size="small" @click="confirm(row, true)">接受</el-button>
              <el-button link type="danger" size="small" @click="confirm(row, false)">拒绝退款</el-button>
            </template>
            <span v-else class="muted" style="font-size:12px">{{ row.confirm_time ? formatTime(row.confirm_time) : '-' }}</span>
          </template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../api/request'
import { formatMoney, formatTime, statusClass } from '../utils/format'

const STATUS = ['待确认', '已接受', '已拒绝', '已退款']
const rows = ref([])
const loading = ref(false)
const status = ref('')
const orders = ref([])
const goods = ref([])
const orderMap = computed(() => Object.fromEntries(orders.value.map((o) => [o.id, o])))
const goodsMap = computed(() => Object.fromEntries(goods.value.map((g) => [g.id, g])))

async function load() {
  loading.value = true
  try {
    const res = await request.get('/api/shortage-replace/page', { params: { page: 1, size: 50, status: status.value || undefined } })
    rows.value = res.data.records || []
  } finally { loading.value = false }
}

async function confirm(row, accept) {
  await ElMessageBox.confirm(
    accept ? '确认接受替换？差价将按规则补付或退差' : '拒绝后整单退款，库存与时段名额同步释放',
    '替换确认', { type: 'warning', confirmButtonText: '确认', cancelButtonText: '取消' })
  const res = await request.post(`/api/shortage-replace/${row.id}/confirm`, { accept })
  if (res.code === 0) { ElMessage.success(accept ? '已接受替换' : '已拒绝并整单退款'); load() }
}

onMounted(async () => {
  await load()
  const [o, g] = await Promise.all([
    request.get('/api/pickup-order/page', { params: { page: 1, size: 100 } }),
    request.get('/api/shop-goods/page', { params: { page: 1, size: 100 } })
  ])
  orders.value = o.data.records || []
  goods.value = g.data.records || []
})
</script>
