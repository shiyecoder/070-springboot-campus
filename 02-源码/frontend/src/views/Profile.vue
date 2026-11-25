<template>
  <div>
    <h1 class="page-title">个人中心</h1>
    <div class="page-sub">维护个人资料、上传头像（右上角同步显示）与修改登录密码</div>
    <div class="row-2">
      <div class="panel">
        <h3>基本资料</h3>
        <div class="avatar-row">
          <el-upload :show-file-list="false" :http-request="uploadAvatar" accept="image/*">
            <div class="avatar">
              <img v-if="form.avatar" :src="form.avatar" alt="" />
              <span v-else>上传</span>
            </div>
          </el-upload>
          <div>
            <div style="font-weight:600">{{ form.real_name }}　<span class="muted" style="font-size:12.5px">{{ form.username }}</span></div>
            <div class="muted" style="font-size:12.5px">{{ roleNames }}　{{ form.dept_name }}</div>
            <div class="muted" style="font-size:12px">点击左侧头像上传，支持 jpg/png，≤5MB</div>
          </div>
        </div>
        <el-form label-width="90px" style="margin-top:14px">
          <el-form-item label="姓名"><el-input v-model="form.real_name" /></el-form-item>
          <el-form-item label="手机号"><el-input v-model="form.phone" maxlength="11" /></el-form-item>
          <el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item>
          <el-button type="primary" @click="saveProfile">保存资料</el-button>
        </el-form>
      </div>
      <div class="panel">
        <h3>修改密码</h3>
        <el-form label-width="90px">
          <el-form-item label="原密码"><el-input v-model="pwd.old_password" type="password" show-password /></el-form-item>
          <el-form-item label="新密码"><el-input v-model="pwd.new_password" type="password" show-password /></el-form-item>
          <el-form-item label="确认新密码"><el-input v-model="pwd.confirm" type="password" show-password /></el-form-item>
          <el-button type="primary" @click="savePwd">修改密码</el-button>
        </el-form>
        <div class="panel" style="box-shadow:none;background:#f7f9f8;margin-top:16px;font-size:12.5px">
          <div class="muted">角色权限按「菜单 + 按钮 + 数据范围」三层控制，个人中心对所有角色开放。</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import request from '../api/request'
import { useUserStore } from '../store/user'

const store = useUserStore()
const form = reactive({ id: null, username: '', real_name: '', phone: '', email: '', avatar: '', dept_name: '' })
const pwd = reactive({ old_password: '', new_password: '', confirm: '' })
const roles = ref([])
const roleNames = computed(() => roles.value.map((r) => r.role_name).join(' / '))

async function load() {
  const res = await request.get('/api/auth/info')
  Object.assign(form, res.data)
  roles.value = res.data.roles || []
}

async function uploadAvatar(opt) {
  const fd = new FormData()
  fd.append('file', opt.file)
  fd.append('bizType', 'avatar')
  const res = await request.post('/api/file/upload', fd, { headers: { 'Content-Type': 'multipart/form-data' } })
  if (res.code === 0) {
    form.avatar = res.data.filePath
    await request.put('/api/auth/profile', { avatar: res.data.filePath })
    await store.refreshProfile()
    ElMessage.success('头像已更新，右上角同步显示')
    load()
  }
}

async function saveProfile() {
  await request.put('/api/auth/profile', { real_name: form.real_name, phone: form.phone, email: form.email })
  await store.refreshProfile()
  ElMessage.success('资料已保存')
}

async function savePwd() {
  if (!pwd.old_password || !pwd.new_password) return ElMessage.warning('请填写原密码与新密码')
  if (pwd.new_password !== pwd.confirm) return ElMessage.warning('两次输入的新密码不一致')
  await request.put('/api/auth/profile', { old_password: pwd.old_password, new_password: pwd.new_password })
  ElMessage.success('密码已修改')
  pwd.old_password = ''; pwd.new_password = ''; pwd.confirm = ''
}

onMounted(load)
</script>

<style scoped>
.avatar-row { display: flex; gap: 16px; align-items: center; }
.avatar { width: 78px; height: 78px; border-radius: 50%; overflow: hidden; background: #eef4f2; color: var(--primary); display: grid; place-items: center; font-size: 12px; cursor: pointer; }
.avatar img { width: 100%; height: 100%; object-fit: cover; }
</style>
