<template>
  <CrudPage :config="config" />
</template>

<script setup>
import CrudPage from '../components/CrudPage.vue'

// 操作日志：关键写操作留痕（取消、挂起、核销、规则修改），只读展示
const config = {
  title: '操作日志',
  sub: '记录取消、挂起、核销、规则修改等关键写操作，含操作人、时间与内容',
  api: '/api/sys-oper-log',
  titleProp: 'biz_no',
  searchPlaceholder: '模块 / 单号 / 内容',
  editText: false,
  actionWidth: 80,
  columns: [
    { prop: 'module', label: '模块', width: 120 },
    { prop: 'oper_type', label: '操作类型', width: 110 },
    { prop: 'biz_no', label: '业务单号', width: 160 },
    { prop: 'content', label: '操作内容', minWidth: 260 },
    { prop: 'oper_name', label: '操作人', width: 110 },
    { prop: 'oper_time', label: '操作时间', type: 'datetime', width: 170 },
    { prop: 'ip', label: 'IP', width: 120 }
  ],
  actions: []
}
</script>
