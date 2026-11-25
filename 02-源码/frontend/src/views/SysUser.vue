<template>
  <CrudPage :config="config" />
</template>

<script setup>
import CrudPage from '../components/CrudPage.vue'

// 用户管理：管理员维护账号、组织与状态，密码由后端 BCrypt 存储
const config = {
  title: '用户管理',
  sub: '维护登录账号、所属组织与启用状态；密码使用 BCrypt 存储，接口不返回明文',
  api: '/api/sys-user',
  addText: '新增用户',
  titleProp: 'username',
  searchPlaceholder: '账号 / 姓名 / 手机号',
  statusOptions: [{ label: '启用', value: '1' }, { label: '停用', value: '0' }],
  columns: [
    { prop: 'avatar', label: '头像', type: 'image', width: 92 },
    { prop: 'username', label: '账号', width: 120 },
    { prop: 'real_name', label: '姓名', width: 100 },
    { prop: 'dept_name', label: '所属组织', width: 160 },
    { prop: 'phone', label: '手机号', type: 'mask', width: 130 },
    { prop: 'credit_score', label: '信用分', width: 86 },
    { prop: 'status', label: '状态', type: 'status', width: 84, map: { 1: '启用', 0: '停用' } },
    { prop: 'create_time', label: '创建时间', type: 'datetime', width: 160 }
  ],
  formFields: [
    { prop: 'username', label: '登录账号', required: true },
    { prop: 'password', label: '初始密码', placeholder: '留空则不修改（BCrypt 存储）' },
    { prop: 'real_name', label: '姓名', required: true },
    { prop: 'dept_name', label: '所属组织' },
    { prop: 'phone', label: '手机号' },
    { prop: 'email', label: '邮箱' },
    { prop: 'status', label: '状态', type: 'select', options: [{ label: '启用', value: 1 }, { label: '停用', value: 0 }] }
  ]
}
</script>
