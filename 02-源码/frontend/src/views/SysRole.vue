<template>
  <div>
    <h1 class="page-title">角色管理</h1>
    <div class="page-sub">维护角色与数据范围（本人/本部门/全部），并为角色分配菜单与按钮权限</div>
    <div class="filters">
      <el-button type="success" @click="openForm()">新增角色</el-button>
      <span class="muted" style="margin-left:auto;font-size:13px">共 {{ rows.length }} 个角色</span>
    </div>
    <div class="panel" style="padding:0 0 6px">
      <el-table :data="rows" v-loading="loading">
        <el-table-column prop="role_name" label="角色名称" width="150" />
        <el-table-column prop="role_code" label="角色编码" width="130" />
        <el-table-column label="数据范围" width="130">
          <template #default="{ row }">
            <span class="tag-blue">{{ SCOPE[row.data_scope] || row.data_scope }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="说明" min-width="200" />
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <span :class="row.status === 1 ? 'tag-green' : 'tag-gray'">{{ row.status === 1 ? '启用' : '停用' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="openMenus(row)">分配菜单</el-button>
            <el-button link type="primary" size="small" @click="openForm(row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <el-dialog v-model="formVisible" :title="form.id ? '编辑角色' : '新增角色'" width="520px">
      <el-form label-width="100px">
        <el-form-item label="角色名称" required><el-input v-model="form.role_name" /></el-form-item>
        <el-form-item label="角色编码" required><el-input v-model="form.role_code" placeholder="如 manager" /></el-form-item>
        <el-form-item label="数据范围">
          <el-select v-model="form.data_scope" style="width:100%">
            <el-option label="本人" value="SELF" />
            <el-option label="本部门" value="DEPT" />
            <el-option label="全部" value="ALL" />
          </el-select>
        </el-form-item>
        <el-form-item label="说明"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>

    <el-drawer v-model="menuVisible" :title="'为「' + (cur.role_name || '') + '」分配菜单'" size="520px">
      <div class="muted" style="font-size:12.5px;margin-bottom:10px">
        勾选后该角色登录即可见对应菜单；按钮权限以 perms 标识下发，前端隐藏按钮同时后端会复核。
      </div>
      <el-tree ref="treeRef" :data="tree" show-checkbox node-key="id" :props="{ label: 'menu_name', children: 'children' }"
               default-expand-all style="font-size:13px" />
      <template #footer>
        <el-button @click="menuVisible = false">取消</el-button>
        <el-button type="primary" @click="saveMenus">保存授权</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import request from '../api/request'

const SCOPE = { SELF: '本人', DEPT: '本部门', ALL: '全部' }
const rows = ref([])
const loading = ref(false)
const formVisible = ref(false)
const menuVisible = ref(false)
const tree = ref([])
const treeRef = ref()
const cur = ref({})
const form = reactive({ id: null, role_name: '', role_code: '', data_scope: 'SELF', remark: '', status: 1 })

async function load() {
  loading.value = true
  try {
    const res = await request.get('/api/sys-role/page', { params: { page: 1, size: 50 } })
    rows.value = res.data.records || []
  } finally { loading.value = false }
}

function openForm(row) {
  Object.assign(form, row ? JSON.parse(JSON.stringify(row)) : { id: null, role_name: '', role_code: '', data_scope: 'SELF', remark: '', status: 1 })
  formVisible.value = true
}

async function submit() {
  if (!form.role_name || !form.role_code) return ElMessage.warning('角色名称与编码必填')
  if (form.id) await request.put(`/api/sys-role/${form.id}`, form)
  else await request.post('/api/sys-role', form)
  ElMessage.success('保存成功')
  formVisible.value = false
  load()
}

async function openMenus(row) {
  cur.value = row
  const all = await request.get('/api/sys-menu/page', { params: { page: 1, size: 200 } })
  const list = (all.data.records || []).filter((m) => m.id !== 13) // 菜单管理自身不在授权树里展示
  const roots = list.filter((m) => !m.parent_id || m.parent_id === 0)
  tree.value = roots.map((r) => ({ ...r, children: list.filter((c) => c.parent_id === r.id) }))
  const mine = await request.get(`/api/role/${row.id}/menus`)
  menuVisible.value = true
  setTimeout(() => {
    const ids = mine.data || []
    treeRef.value?.setCheckedKeys(ids.filter((id) => list.some((m) => m.id === id)))
  }, 120)
}

async function saveMenus() {
  const checked = treeRef.value.getCheckedKeys()
  const half = treeRef.value.getHalfCheckedKeys()
  const res = await request.put(`/api/role/${cur.value.id}/menus`, { menu_ids: [...checked, ...half] })
  if (res.code === 0) {
    ElMessage.success('授权已保存，该角色下次登录生效')
    menuVisible.value = false
  }
}

onMounted(load)
</script>
