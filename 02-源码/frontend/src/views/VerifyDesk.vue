<template>
  <div>
    <h1 class="page-title">核销台</h1>
    <div class="page-sub">学生到店出示取货码，输入 6 位数字核销；取货码错误 3 次锁定该订单 10 分钟，同一取货码并发只允许一次成功</div>

    <div class="panel center">
      <div class="code-box">
        <el-input v-model="code" size="large" maxlength="6" placeholder="请输入 6 位取货码"
                  class="code-input" @keyup.enter="doVerify" />
        <div class="hint">
          <el-radio-group v-model="type" size="small">
            <el-radio-button value="扫码">扫码</el-radio-button>
            <el-radio-button value="取货码">取货码</el-radio-button>
            <el-radio-button value="人工补录">人工补录</el-radio-button>
          </el-radio-group>
          <span class="muted" style="font-size:12.5px" v-if="failCount">连续错误 {{ failCount }} / 3 次</span>
        </div>
        <el-button type="primary" size="large" style="width:220px;margin-top:14px" :loading="loading" @click="doVerify">
          立即核销
        </el-button>
        <div v-if="result" class="result">
          <div class="ok">✓ 核销成功</div>
          <div>{{ result.order_no }}</div>
          <div class="muted" style="font-size:12.5px">{{ result.verifier }}　{{ formatTime(result.verify_time) }}</div>
        </div>
      </div>
      <div class="tips">
        <div><b>核销校验</b>订单须为「待自提」且未超过自提时段结束时间</div>
        <div><b>超时处理</b>时段结束后 2 小时未取，系统自动作废并按临期流程回滚库存</div>
        <div><b>代取规则</b>人工补录必须填写异常说明，核销记录可追溯</div>
      </div>
    </div>

    <div class="panel">
      <h3>最近核销记录 <span class="muted" style="font-size:12px">显示最近 10 条</span></h3>
      <el-table :data="recent" size="small">
        <el-table-column prop="verify_no" label="核销编号" width="150" />
        <el-table-column label="订单" width="150">
          <template #default="{ row }">{{ orderMap[row.order_id]?.order_no || ('#' + row.order_id) }}</template>
        </el-table-column>
        <el-table-column prop="pickup_code" label="取货码" width="96" />
        <el-table-column prop="verifier" label="核销人" width="110" />
        <el-table-column prop="verify_type" label="核销方式" width="100" />
        <el-table-column label="核销时间" width="170">
          <template #default="{ row }">{{ formatTime(row.verify_time) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }"><span class="tag-green">成功</span></template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import request from '../api/request'
import { formatTime } from '../utils/format'

const code = ref('')
const type = ref('取货码')
const loading = ref(false)
const result = ref(null)
const failCount = ref(0)
const records = ref([])
const orders = ref([])
const orderMap = computed(() => Object.fromEntries(orders.value.map((o) => [o.id, o])))
const recent = computed(() => records.value.slice(0, 10))

async function load() {
  const [v, o] = await Promise.all([
    request.get('/api/pickup-verify-record/page', { params: { page: 1, size: 30 } }),
    request.get('/api/pickup-order/page', { params: { page: 1, size: 100 } })
  ])
  records.value = v.data.records || []
  orders.value = o.data.records || []
}

async function doVerify() {
  if (!/^\d{6}$/.test(code.value)) return ElMessage.warning('请输入 6 位数字取货码')
  loading.value = true
  try {
    const res = await request.post('/api/pickup-verify', { pickup_code: code.value, verify_type: type.value })
    if (res.code === 0) {
      result.value = res.data
      failCount.value = 0
      ElMessage.success('核销成功，请交付商品')
      code.value = ''
      load()
    }
  } catch (e) {
    failCount.value += 1
  } finally { loading.value = false }
}

onMounted(load)
</script>

<style scoped>
.center { display: grid; grid-template-columns: 1.1fr 1fr; gap: 24px; align-items: center; padding: 24px; }
.code-box { text-align: center; }
.code-input { max-width: 340px; }
.code-input :deep(input) { font-size: 26px; letter-spacing: 10px; text-align: center; height: 56px; }
.hint { display: flex; justify-content: center; gap: 14px; align-items: center; margin-top: 12px; }
.result { margin-top: 18px; padding: 12px; background: #eef7f3; border-radius: 10px; color: var(--success); }
.result .ok { font-size: 17px; font-weight: 700; }
.tips { display: grid; gap: 10px; font-size: 13px; color: var(--muted); }
.tips div { background: #f7f9f8; border-radius: 10px; padding: 10px 12px; }
.tips b { color: var(--text); display: block; margin-bottom: 2px; }
</style>
