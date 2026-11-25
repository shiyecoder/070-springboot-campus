<template>
  <CrudPage :config="config" />
</template>

<script setup>
import CrudPage from '../components/CrudPage.vue'

// 菜单管理：目录 M / 菜单 C / 按钮 B 三级，按钮权限以 perms 标识下发给前端
const config = {
  title: '菜单管理',
  sub: '维护目录、菜单与按钮三级权限；按钮权限标识 perms 与后端写接口校验一一对应',
  api: '/api/sys-menu',
  addText: '新增菜单',
  titleProp: 'menu_name',
  searchPlaceholder: '菜单名 / 路径 / 权限标识',
  editText: false,
  columns: [
    { prop: 'menu_name', label: '菜单名称', width: 160 },
    { prop: 'parent_id', label: '上级ID', width: 84 },
    { prop: 'type', label: '类型', width: 72 },
    { prop: 'path', label: '路由路径', width: 170 },
    { prop: 'component', label: '组件', width: 150 },
    { prop: 'perms', label: '权限标识', width: 150 },
    { prop: 'sort_no', label: '排序', width: 70 },
    { prop: 'visible', label: '可见', width: 70 }
  ],
  formFields: [
    { prop: 'parent_id', label: '上级ID', type: 'number', precision: 0, default: 0 },
    { prop: 'menu_name', label: '菜单名称', required: true },
    { prop: 'type', label: '类型', type: 'select', options: [{ label: '目录 M', value: 'M' }, { label: '菜单 C', value: 'C' }, { label: '按钮 B', value: 'B' }] },
    { prop: 'path', label: '路由路径' },
    { prop: 'component', label: '组件名' },
    { prop: 'perms', label: '权限标识' },
    { prop: 'sort_no', label: '排序', type: 'number', precision: 0, default: 0 },
    { prop: 'visible', label: '可见', type: 'switch' }
  ]
}
</script>
