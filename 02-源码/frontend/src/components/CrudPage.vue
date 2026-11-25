<template>
  <div>
    <h1 class="page-title">{{ config.title }}</h1>
    <div class="page-sub">{{ config.sub }}</div>
    <div class="filters">
      <el-input v-model="query.keyword" :placeholder="config.searchPlaceholder || '输入编号或名称搜索'" clearable
                @keyup.enter="load" />
      <el-select v-if="config.statusOptions" v-model="query.status" placeholder="全部状态" clearable>
        <el-option v-for="s in config.statusOptions" :key="s.value || s" :label="s.label || s" :value="s.value || s" />
      </el-select>
      <el-select v-if="config.extraFilter" v-model="query.extra" :placeholder="config.extraFilter.placeholder" clearable>
        <el-option v-for="o in config.extraFilter.options" :key="o.value" :label="o.label" :value="o.value" />
      </el-select>
      <el-button type="primary" @click="load">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <el-button v-if="config.addText" type="success" style="margin-left:auto" @click="openForm()">{{ config.addText }}</el-button>
    </div>
    <div class="panel" style="padding:0 0 6px">
      <el-table :data="rows" v-loading="loading" style="width:100%" row-key="id">
        <el-table-column v-for="c in config.columns" :key="c.prop" :prop="c.prop" :label="c.label"
                         :min-width="c.width || 110" :fixed="c.fixed" show-overflow-tooltip>
          <template #default="{ row }">
            <template v-if="c.type === 'image'">
              <img class="img-box" :src="row[c.prop] || ''" alt="" />
            </template>
            <template v-else-if="c.type === 'goods'">
              <div style="display:flex;gap:10px;align-items:center">
                <img class="img-box" :src="row.image || ''" alt="" />
                <div>
                  <b>{{ row[c.prop] }}</b>
                  <div class="muted" style="font-size:12px">{{ row.spec }}　{{ row.shelf_code }}</div>
                </div>
              </div>
            </template>
            <template v-else-if="c.type === 'status'">
              <span :class="statusClass(row[c.prop])">{{ statusText(row[c.prop], c.map) }}</span>
            </template>
            <template v-else-if="c.type === 'money'"><span class="price">{{ formatMoney(row[c.prop]) }}</span></template>
            <template v-else-if="c.type === 'date'">{{ formatDate(row[c.prop]) }}</template>
            <template v-else-if="c.type === 'datetime'">{{ formatTime(row[c.prop]) }}</template>
            <template v-else-if="c.type === 'mask'">{{ maskPhone(row[c.prop]) }}</template>
            <template v-else-if="c.type === 'bool'">
              <span :class="row[c.prop] ? 'tag-orange' : 'tag-gray'">{{ row[c.prop] ? '冷藏' : '常温' }}</span>
            </template>
            <template v-else>{{ row[c.prop] ?? '-' }}</template>
          </template>
        </el-table-column>
        <el-table-column label="操作" :width="config.actionWidth || 200" fixed="right">
          <template #default="{ row }">
            <el-button v-for="a in visibleActions(row)" :key="a.key" link :type="a.type || 'primary'" size="small"
                       @click="runAction(a, row)">{{ a.label }}</el-button>
            <el-button v-if="config.editText !== false" link type="primary" size="small" @click="openForm(row)">编辑</el-button>
            <el-button v-if="config.deleteText" link type="danger" size="small" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 16px 4px">
        <span class="muted" style="font-size:13px">共 {{ total }} 条　每页 {{ query.size }} 条</span>
        <el-pagination v-model:current-page="query.page" v-model:page-size="query.size" :total="total"
                       :page-sizes="[10, 20, 50]" layout="sizes, prev, pager, next" @change="load" />
      </div>
    </div>

    <el-dialog v-model="formVisible" :title="(form.id ? '编辑' : (config.addText || '新增'))" width="640px">
      <el-form label-width="110px">
        <el-form-item v-for="f in config.formFields || []" :key="f.prop" :label="f.label" :required="f.required">
          <el-select v-if="f.type === 'select'" v-model="form[f.prop]" style="width:100%">
            <el-option v-for="o in f.options" :key="o.value || o" :label="o.label || o" :value="o.value || o" />
          </el-select>
          <el-input-number v-else-if="f.type === 'number'" v-model="form[f.prop]" :precision="f.precision ?? 2"
                           :step="f.step || 1" style="width:100%" />
          <el-input v-else-if="f.type === 'textarea'" v-model="form[f.prop]" type="textarea" :rows="3" />
          <el-date-picker v-else-if="f.type === 'date'" v-model="form[f.prop]" type="date"
                          value-format="YYYY-MM-DD" style="width:100%" />
          <el-date-picker v-else-if="f.type === 'datetime'" v-model="form[f.prop]" type="datetime"
                          value-format="YYYY-MM-DD HH:mm:ss" style="width:100%" />
          <el-time-picker v-else-if="f.type === 'time'" v-model="form[f.prop]" value-format="HH:mm:ss" style="width:100%" />
          <el-switch v-else-if="f.type === 'switch'" v-model="form[f.prop]" :active-value="1" :inactive-value="0" />
          <el-input v-else v-model="form[f.prop]" :placeholder="f.placeholder || ''" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>

    <!-- 通用「填写原因 + 提交动作」抽屉，取消/挂起/修正类操作共用 -->
    <el-drawer v-model="actVisible" :title="actTitle" size="480px">
      <div v-if="current.id" class="panel" style="box-shadow:none;background:#f7f9f8">
        <div class="muted" style="font-size:12.5px">{{ actSummary }}</div>
      </div>
      <el-form label-width="90px">
        <el-form-item v-if="actForm.number !== undefined" :label="actField.label" required>
          <el-input-number v-model="actForm.number" :min="0" :max="999" style="width:100%" />
        </el-form-item>
        <el-form-item :label="actField.label" :required="actField.required">
          <el-input v-model="actForm.reason" type="textarea" :rows="3" :placeholder="actField.placeholder" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="actVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAct">确认</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../api/request'
import { formatDate, formatMoney, formatTime, maskPhone, statusClass, statusText } from '../utils/format'

const props = defineProps({ config: { type: Object, required: true } })
const emit = defineEmits(['refresh'])

const rows = ref([])
const total = ref(0)
const loading = ref(false)
const query = reactive({ page: 1, size: 10, keyword: '', status: '', extra: '' })
const formVisible = ref(false)
const form = reactive({})
const current = ref({})
const actVisible = ref(false)
const actTitle = ref('')
const actSummary = ref('')
const actAction = ref(null)
const actField = reactive({ label: '原因', placeholder: '请填写原因（不少于 5 个字）', required: true })
const actForm = reactive({ reason: '', number: undefined })

async function load() {
  loading.value = true
  try {
    const params = { page: query.page, size: query.size, keyword: query.keyword || undefined, status: query.status || undefined }
    if (props.config.extraFilter && query.extra) params[props.config.extraFilter.key] = query.extra
    const res = await request.get(props.config.api + '/page', { params })
    rows.value = res.data.records || []
    total.value = res.data.total || 0
  } finally { loading.value = false }
}
function reset() {
  query.keyword = ''; query.status = ''; query.extra = ''; query.page = 1; load()
}

// when 支持字符串表达式（便于纯配置声明），也兼容函数
function cond(a, row) {
  if (!a.when) return true
  if (typeof a.when === 'function') return a.when(row)
  try { return new Function('row', a.when)(row) } catch (e) { return true }
}
function visibleActions(row) {
  return (props.config.actions || []).filter((a) => cond(a, row))
}

async function runAction(a, row) {
  current.value = row
  if (a.drawer) {
    actAction.value = a
    actTitle.value = a.label
    actSummary.value = a.summary ? a.summary(row) : (row[props.config.titleProp || 'name'] || row.id)
    actField.label = a.fieldLabel || '原因'
    actField.placeholder = a.placeholder || '请填写原因（不少于 5 个字）'
    actField.required = a.reasonRequired !== false
    actForm.reason = ''
    actForm.number = a.numberProp ? Number(row[a.numberProp] ?? 0) : undefined
    actVisible.value = true
    return
  }
  if (a.confirm) {
    await ElMessageBox.confirm(a.confirmText || ('确定执行「' + a.label + '」吗？'), '操作确认',
      { type: 'warning', confirmButtonText: '确认', cancelButtonText: '取消' })
  }
  const url = a.url.replace('{id}', row.id)
  const method = (a.method || 'POST').toLowerCase()
  const res = await request[method](url, a.body ? a.body(row) : {})
  if (res.code === 0) {
    ElMessage.success(a.success || '操作成功')
    load(); emit('refresh')
  }
}

async function submitAct() {
  const a = actAction.value
  if (!a) return
  if (actField.required && actForm.reason.trim().length < 5) {
    return ElMessage.warning('原因不少于 5 个字')
  }
  const payload = {}
  if (actForm.number !== undefined) payload[a.qtyKey || 'manual_qty'] = actForm.number
  payload[a.reasonKey || 'reason'] = actForm.reason
  const res = await request[(a.method || 'POST').toLowerCase()](a.url.replace('{id}', current.value.id), payload)
  if (res.code === 0) {
    ElMessage.success(a.success || '操作成功')
    actVisible.value = false
    load(); emit('refresh')
  }
}

function openForm(row) {
  Object.keys(form).forEach((k) => delete form[k])
  if (row) Object.assign(form, JSON.parse(JSON.stringify(row)))
  else (props.config.formFields || []).forEach((f) => { form[f.prop] = f.default ?? (f.type === 'number' ? 0 : '') })
  formVisible.value = true
}

async function submit() {
  const payload = { ...form }
  if (payload.id) await request.put(`${props.config.api}/${payload.id}`, payload)
  else await request.post(props.config.api, payload)
  ElMessage.success('保存成功')
  formVisible.value = false
  load()
}

async function remove(row) {
  await ElMessageBox.confirm('删除后列表不再显示，确定继续？', '删除确认',
    { type: 'warning', confirmButtonText: '确认', cancelButtonText: '取消' })
  await request.delete(`${props.config.api}/${row.id}`)
  ElMessage.success('已删除')
  load()
}

defineExpose({ load })
onMounted(load)
</script>
