<template>
  <div>
    <h1 class="page-title">预测看板 · 备货建议</h1>
    <div class="page-sub">
      五因素加权测算（历史同段销量 30% · 课程标签 20% · 天气 15% · 促销 20% · 商品周转 15%）
      当前规则版本 v{{ ruleVersion }}
    </div>

    <div class="filters">
      <el-select v-model="pointId" placeholder="选择自提点" style="width:220px" @change="load">
        <el-option v-for="p in points" :key="p.id" :label="p.name" :value="p.id" />
      </el-select>
      <el-date-picker v-model="date" type="date" value-format="YYYY-MM-DD" placeholder="预测日期" @change="load" />
      <el-button type="primary" @click="load(true)">重新计算</el-button>
      <el-button @click="ruleVisible = true">规则配置</el-button>
      <span class="muted" style="margin-left:auto;font-size:13px">
        采纳率 {{ stats.adopt_rate ?? 0 }}%　人工修正率 {{ stats.manual_rate ?? 0 }}%
      </span>
    </div>

    <div class="row-3">
      <div class="panel" style="padding:14px">
        <h3>各时段建议备货量与高峰等级</h3>
        <el-table :data="items" size="small" max-height="440" @row-click="openDetail">
          <el-table-column label="时段" width="118">
            <template #default="{ row }">{{ formatClock(row.start_time) }}-{{ formatClock(row.end_time) }}</template>
          </el-table-column>
          <el-table-column label="等级" width="70">
            <template #default="{ row }"><span :class="'level-' + row.level">{{ row.level }}</span></template>
          </el-table-column>
          <el-table-column prop="suggest_qty" label="建议备货" width="92">
            <template #default="{ row }"><b style="color:var(--primary)">{{ row.suggest_qty }}</b> 件</template>
          </el-table-column>
          <el-table-column label="评分" width="72">
            <template #default="{ row }">{{ row.score }}</template>
          </el-table-column>
          <el-table-column label="置信度" width="96">
            <template #default="{ row }">
              <span :class="row.confidence < 60 ? 'tag-orange' : 'tag-green'">{{ row.confidence }}%</span>
            </template>
          </el-table-column>
          <el-table-column label="容量/已约" width="96">
            <template #default="{ row }">{{ row.booked_count }}/{{ row.capacity }}</template>
          </el-table-column>
          <el-table-column label="操作" width="96">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click.stop="openAdjust(row)">人工修正</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <div class="panel" style="padding:14px">
        <h3>高峰时段建议</h3>
        <div v-if="!top.length" class="empty-tip">暂无数据</div>
        <div v-for="t in top" :key="t.slot_id" class="topcard">
          <div class="th"><span :class="'level-' + t.level">{{ t.level }}</span>
            <b>{{ formatClock(t.start_time) }}-{{ formatClock(t.end_time) }}</b>
            <span class="muted" style="font-size:12px">建议 {{ t.suggest_qty }} 件</span>
          </div>
          <div class="drv" v-for="d in t.drivers.slice(0, 3)" :key="d.name">
            <span>{{ d.name }}（权重 {{ d.weight }}%）</span>
            <el-progress :percentage="Math.min(100, Number(d.value))" :stroke-width="6" :show-text="false" />
          </div>
          <div class="advice">{{ t.advice }}</div>
        </div>
      </div>
    </div>

    <!-- 计算留痕详情 -->
    <el-drawer v-model="detailVisible" title="计算结果与留痕" size="540px">
      <div class="panel" style="box-shadow:none;background:#f7f9f8">
        <div class="muted" style="font-size:12.5px">
          {{ detail.slot_date }} {{ formatClock(detail.start_time) }}　规则版本 v{{ cur?.rule_version }}
        </div>
        <div style="font-size:17px;font-weight:700;margin:4px 0">
          建议备货 {{ cur?.suggest_qty }} 件　<span :class="'level-' + cur?.level">{{ cur?.level }}</span>
        </div>
        <div class="muted" style="font-size:12.5px">
          高峰评分 {{ cur?.score }}　置信度 {{ cur?.confidence }}%
          <span v-if="cur?.conservative" class="tag-orange" style="margin-left:6px">置信度低于 60%，已按保守值备货</span>
        </div>
      </div>
      <h3 style="font-size:14px;margin:10px 0 6px">输入快照（可追溯）</h3>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="历史同段销量">{{ cur?.base_qty }} 件</el-descriptions-item>
        <el-descriptions-item label="课程表标签">{{ cur?.course_tag }}</el-descriptions-item>
        <el-descriptions-item label="天气">{{ cur?.weather }}</el-descriptions-item>
        <el-descriptions-item label="规则版本">v{{ cur?.rule_version }}</el-descriptions-item>
      </el-descriptions>
      <h3 style="font-size:14px;margin:14px 0 6px">各因素得分</h3>
      <div v-for="d in (cur?.drivers || [])" :key="d.name" class="dl">
        <span>{{ d.name }}</span>
        <el-progress :percentage="Math.min(100, Number(d.value))" :stroke-width="8" />
        <span class="muted" style="font-size:12px">权重 {{ d.weight }}%</span>
      </div>
      <h3 style="font-size:14px;margin:14px 0 6px">未满足条件与可改进项</h3>
      <div class="panel" style="box-shadow:none;background:#fbf7ec;font-size:12.5px;line-height:1.9">
        <div v-if="Number(cur?.confidence) < 60">· 样本周数不足 4 周，置信度偏低，建议人工复核后再备货</div>
        <div v-if="cur?.course_tag === '常规'">· 该时段未命中课程表标签，可按 1.0 系数处理</div>
        <div v-if="cur?.weather === '晴天'">· 天气为默认值，建议运营按当日实况维护</div>
        <div v-if="!cur?.manual_flag">· 尚无人工修正记录，可直接采纳建议量</div>
      </div>
      <div v-if="cur?.manual_flag" class="panel" style="box-shadow:none;background:#eef7f3">
        <div style="font-size:13px">人工修正：{{ cur.manual_qty }} 件</div>
        <div class="muted" style="font-size:12.5px">{{ cur.manual_reason }}　{{ cur.manual_by }}　{{ formatTime(cur.manual_time) }}</div>
        <div class="muted" style="font-size:12px;margin-top:4px">原始计算结果 {{ cur.suggest_qty }} 件已保留，未被覆盖</div>
      </div>
    </el-drawer>

    <!-- 人工修正 -->
    <el-dialog v-model="adjustVisible" title="人工修正备货量" width="480px">
      <div class="panel" style="box-shadow:none;background:#f7f9f8">
        <div class="muted" style="font-size:12.5px">系统建议 {{ adjustRow.suggest_qty }} 件（{{ adjustRow.level }} 级）</div>
        <div style="font-size:13px">修正后建议量将用于备货单，原始结果保留可追溯</div>
      </div>
      <el-form label-width="100px">
        <el-form-item label="修正备货量"><el-input-number v-model="adjustQty" :min="0" :max="500" style="width:100%" /></el-form-item>
        <el-form-item label="修正原因" required>
          <el-input v-model="adjustReason" type="textarea" :rows="3" placeholder="不少于 5 个字，例如：当日社团活动，客流预计翻倍" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="adjustVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAdjust">确认修正</el-button>
      </template>
    </el-dialog>

    <!-- 规则配置 -->
    <el-dialog v-model="ruleVisible" title="预测规则配置" width="560px">
      <div class="panel" style="box-shadow:none;background:#fbf7ec;font-size:12.5px">
        五项权重合计必须等于 100%，保存后版本号 +1 并记录生效时间；已生成的历史计算不受影响。
      </div>
      <el-form label-width="130px">
        <el-form-item v-for="w in WEIGHTS" :key="w.key" :label="w.label">
          <el-input-number v-model="ruleForm[w.key]" :min="0" :max="100" :step="5" style="width:180px" />
          <span class="muted" style="margin-left:10px">%</span>
        </el-form-item>
        <el-form-item label="权重合计">
          <b :style="{ color: totalWeight === 100 ? 'var(--success)' : 'var(--danger)' }">{{ totalWeight }}%</b>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="ruleVisible = false">取消</el-button>
        <el-button type="primary" @click="saveRule">保存并生成新版本</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import request from '../api/request'
import { formatClock, formatTime } from '../utils/format'

const items = ref([])
const points = ref([])
const pointId = ref(null)
const date = ref(null)
const ruleVersion = ref(1)
const stats = ref({})
const detailVisible = ref(false)
const adjustVisible = ref(false)
const ruleVisible = ref(false)
const cur = ref({})
const detail = ref({})
const adjustRow = ref({})
const adjustQty = ref(0)
const adjustReason = ref('')
const WEIGHTS = [
  { key: 'w_history', label: '历史同段销量' }, { key: 'w_course', label: '课程表标签' },
  { key: 'w_weather', label: '天气因素' }, { key: 'w_promo', label: '促销活动' },
  { key: 'w_turnover', label: '商品周转' }
]
const ruleForm = reactive({ w_history: 30, w_course: 20, w_weather: 15, w_promo: 20, w_turnover: 15 })
const totalWeight = computed(() => WEIGHTS.reduce((a, w) => a + Number(ruleForm[w.key] || 0), 0))
const top = computed(() => [...items.value].sort((a, b) => b.score - a.score).slice(0, 3))

async function load(recalc = false) {
  const params = { recalc }
  if (pointId.value) params.point_id = pointId.value
  if (date.value) params.date = date.value
  const res = await request.get('/api/stocks/forecast', { params })
  items.value = res.data.items || []
  ruleVersion.value = res.data.rule_version
  if (recalc) ElMessage.success('已按当前规则重新计算并写入留痕')
  const s = await request.get('/api/forecast/stats')
  stats.value = s.data || {}
}

function openDetail(row) {
  cur.value = row
  detail.value = row
  detailVisible.value = true
}

function openAdjust(row) {
  adjustRow.value = row
  adjustQty.value = row.suggest_qty
  adjustReason.value = ''
  adjustVisible.value = true
}

async function submitAdjust() {
  if (adjustReason.value.trim().length < 5) return ElMessage.warning('修正原因不少于 5 个字')
  const res = await request.post(`/api/forecast/${adjustRow.value.calc_id}/adjust`,
    { manual_qty: adjustQty.value, reason: adjustReason.value })
  if (res.code === 0) {
    ElMessage.success('已修正，原始计算结果保留')
    adjustVisible.value = false
    load()
  }
}

async function saveRule() {
  if (totalWeight.value !== 100) return ElMessage.warning('五项权重合计必须等于 100%')
  const res = await request.put('/api/forecast/rules', { ...ruleForm, remark: '看板权重调整' })
  if (res.code === 0) {
    ElMessage.success(`已生成规则版本 v${res.data.rule_version}，仅影响新计算`)
    ruleVisible.value = false
    load(true)
  }
}

onMounted(async () => {
  const p = await request.get('/api/pickup-point/page', { params: { page: 1, size: 20 } })
  points.value = p.data.records || []
  if (points.value.length) pointId.value = points.value[0].id
  await load()
})
</script>

<style scoped>
.topcard { border: 1px solid var(--line); border-radius: 10px; padding: 10px 12px; margin-bottom: 10px; }
.th { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; }
.drv { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; align-items: center; font-size: 12px; color: var(--muted); margin-bottom: 4px; }
.advice { background: #f7f9f8; border-radius: 8px; padding: 6px 8px; font-size: 12.5px; margin-top: 6px; }
.dl { display: grid; grid-template-columns: 100px 1fr 70px; gap: 10px; align-items: center; font-size: 12.5px; margin-bottom: 6px; }
</style>
