<template>
  <CrudPage :config="config" ref="page" />
</template>

<script setup>
import { ref } from 'vue'
import CrudPage from '../components/CrudPage.vue'

const page = ref()
// 时段容量：已预约达到容量自动置满；店长可按当日人手临时调整，但不得低于已预约人数
const config = {
  title: '时段配置',
  sub: '按自提点与日期维护自提时段，同一自提点同一天时段不可重叠；容量下调不得低于已预约人数',
  api: '/api/pick-slot',
  addText: '新增时段',
  titleProp: 'slot_no',
  searchPlaceholder: '时段编号',
  actionWidth: 170,
  statusOptions: [{ label: '开放', value: '1' }, { label: '关闭', value: '0' }, { label: '已满', value: '2' }],
  columns: [
    { prop: 'slot_no', label: '时段编号', width: 130 },
    { prop: 'point_id', label: '自提点ID', width: 92 },
    { prop: 'slot_date', label: '日期', type: 'date', width: 110 },
    { prop: 'start_time', label: '开始', width: 88 },
    { prop: 'end_time', label: '结束', width: 88 },
    { prop: 'capacity', label: '容量', width: 74 },
    { prop: 'booked_count', label: '已预约', width: 82 },
    { prop: 'status', label: '状态', type: 'status', width: 88, map: { 1: '开放', 0: '关闭', 2: '已满' } }
  ],
  actions: [
    {
      key: 'adjust', label: '调整容量', drawer: true, qtyKey: 'capacity', numberProp: 'capacity',
      fieldLabel: '新容量', placeholder: '调整原因（不少于 5 个字，例如：今日加派 1 名人手）',
      url: '/api/pick-slot/{id}/adjust', success: '容量已调整',
      summary: (row) => `时段 ${row.slot_date} ${String(row.start_time).slice(0, 5)}-${String(row.end_time).slice(0, 5)}　`
        + `当前容量 ${row.capacity}，已预约 ${row.booked_count}`
    }
  ],
  formFields: [
    { prop: 'slot_no', label: '时段编号', required: true, placeholder: 'SD+yyMMdd+3位序号' },
    { prop: 'point_id', label: '自提点ID', type: 'number', precision: 0, required: true },
    { prop: 'slot_date', label: '日期', type: 'date', required: true },
    { prop: 'start_time', label: '开始时间', type: 'time', required: true },
    { prop: 'end_time', label: '结束时间', type: 'time', required: true },
    { prop: 'capacity', label: '容量', type: 'number', precision: 0, default: 30 },
    { prop: 'status', label: '状态', type: 'select', options: [{ label: '开放', value: 1 }, { label: '关闭', value: 0 }, { label: '已满', value: 2 }] }
  ]
}
</script>
