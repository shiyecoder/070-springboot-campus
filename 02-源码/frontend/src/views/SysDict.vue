<template>
  <CrudPage :config="config" />
</template>

<script setup>
import CrudPage from '../components/CrudPage.vue'

// 字典管理：状态、分类、类型等枚举统一在此维护，页面下拉从 /api/auth/dict 取，禁止前后端各自硬编码
const config = {
  title: '字典管理',
  sub: '维护业务枚举；页面下拉统一调用字典接口，保证前后端取值一致',
  api: '/api/sys-dict-data',
  addText: '新增字典项',
  titleProp: 'dict_label',
  searchPlaceholder: '字典类型 / 标签 / 值',
  columns: [
    { prop: 'dict_type', label: '字典类型', width: 160 },
    { prop: 'dict_label', label: '标签', width: 150 },
    { prop: 'dict_value', label: '值', width: 130 },
    { prop: 'sort_no', label: '排序', width: 76 },
    { prop: 'status', label: '状态', type: 'status', width: 84, map: { 1: '启用', 0: '停用' } }
  ],
  formFields: [
    { prop: 'dict_type', label: '字典类型', required: true, placeholder: '如 order_status' },
    { prop: 'dict_label', label: '标签', required: true },
    { prop: 'dict_value', label: '值', required: true },
    { prop: 'sort_no', label: '排序', type: 'number', precision: 0, default: 0 },
    { prop: 'status', label: '状态', type: 'select', options: [{ label: '启用', value: 1 }, { label: '停用', value: 0 }] }
  ]
}
</script>
