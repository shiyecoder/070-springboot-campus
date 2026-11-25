<template>
  <CrudPage :config="config" />
</template>

<script setup>
import CrudPage from '../components/CrudPage.vue'

const config = {
  title: '自提点管理',
  sub: '维护校内自提点的位置、营业时段与服务能力，前台电话按脱敏展示',
  api: '/api/pickup-point',
  addText: '新增自提点',
  titleProp: 'name',
  searchPlaceholder: '编号 / 名称',
  statusOptions: [{ label: '启用', value: '1' }, { label: '停用', value: '0' }],
  columns: [
    { prop: 'image', label: '照片', type: 'image', width: 96 },
    { prop: 'name', label: '自提点', width: 190 },
    { prop: 'point_no', label: '编号', width: 92 },
    { prop: 'location_desc', label: '位置说明', width: 260 },
    { prop: 'open_time', label: '营业开始', width: 96 },
    { prop: 'close_time', label: '营业结束', width: 96 },
    { prop: 'contact_name', label: '联系人', width: 80 },
    { prop: 'contact_phone', label: '联系电话', type: 'mask', width: 120 },
    { prop: 'serve_limit', label: '同时服务', width: 90 },
    { prop: 'status', label: '状态', type: 'status', width: 84, map: { 1: '启用', 0: '停用' } }
  ],
  formFields: [
    { prop: 'name', label: '自提点名称', required: true },
    { prop: 'location_desc', label: '位置说明', required: true, placeholder: '楼层与门口，不接地图' },
    { prop: 'open_time', label: '营业开始', type: 'time' },
    { prop: 'close_time', label: '营业结束', type: 'time' },
    { prop: 'contact_name', label: '联系人', required: true },
    { prop: 'contact_phone', label: '联系电话', required: true },
    { prop: 'serve_limit', label: '同时服务人数', type: 'number', precision: 0, default: 5 },
    { prop: 'status', label: '状态', type: 'select', options: [{ label: '启用', value: 1 }, { label: '停用', value: 0 }] }
  ]
}
</script>
