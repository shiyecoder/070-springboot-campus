<template>
  <div class="login">
    <div class="left">
      <div class="brand"><span class="logo">超</span>校园超市 · 线上订货与自提</div>
      <h1>下课不用排队<br />到店直接取货</h1>
      <p class="desc">线上选品、按课表选时段、门店按货架位备货，到店凭 6 位取货码核销，缺货时在线确认替换。</p>
      <div class="bullets">
        <div><b>01</b> 实时库存，售罄自动隐藏</div>
        <div><b>02</b> 时段容量控制，高峰不挤</div>
        <div><b>03</b> 备货进度可查，缺货先沟通</div>
      </div>
      <div class="roles">学生 · 备货员 · 自提点店员 · 门店店长 · 超市运营 · 系统管理员</div>
    </div>
    <div class="right">
      <div class="card">
        <h2>登录</h2>
        <p class="muted" style="margin:0 0 18px;font-size:13px">校内账号登录，按角色进入对应工作台</p>
        <el-form @submit.prevent="submit">
          <el-form-item>
            <el-input v-model="form.username" size="large" placeholder="用户名" :prefix-icon="User" />
          </el-form-item>
          <el-form-item>
            <el-input v-model="form.password" size="large" type="password" placeholder="密码" show-password
                      :prefix-icon="Lock" @keyup.enter="submit" />
          </el-form-item>
          <el-button type="primary" size="large" style="width:100%;margin-top:6px" :loading="loading" @click="submit">
            登 录
          </el-button>
        </el-form>
        <div class="quick">
          <span class="muted" style="font-size:12.5px">演示账号（密码均为 123456）</span>
          <div class="qrow">
            <a v-for="a in accounts" :key="a.u" @click="fill(a)">{{ a.n }}</a>
          </div>
        </div>
        <div class="foot">
          <a @click="$router.push('/portal')">先逛逛学生门户 →</a>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Lock, User } from '@element-plus/icons-vue'
import { useUserStore } from '../store/user'

const router = useRouter()
const store = useUserStore()
const loading = ref(false)
const form = reactive({ username: 'admin', password: '123456' })
const accounts = [
  { u: 'admin', n: '管理员' }, { u: 'operator', n: '超市运营' }, { u: 'manager', n: '门店店长' },
  { u: 'clerk', n: '自提点店员' }, { u: 'picker', n: '备货员' }, { u: 'student', n: '学生' }
]
function fill(a) { form.username = a.u; form.password = '123456' }

async function submit() {
  if (!form.username || !form.password) return ElMessage.warning('请输入用户名和密码')
  loading.value = true
  try {
    await store.login(form.username, form.password)
    ElMessage.success('登录成功')
    const roles = store.profile.roles || ''
    if (roles.includes('student') && !roles.includes('admin')) router.push('/my-orders')
    else router.push('/dashboard')
  } finally { loading.value = false }
}
</script>

<style scoped>
.login { min-height: 100vh; display: flex; }
.left {
  flex: 1.15; background: linear-gradient(150deg, rgba(11,45,38,.94), rgba(22,105,92,.86)),
    url('/login-bg.jpg') center/cover no-repeat; color: #fff; padding: 64px 60px; display: flex; flex-direction: column;
}
.brand { display: flex; align-items: center; gap: 10px; font-weight: 700; font-size: 16px; }
.logo { width: 32px; height: 32px; border-radius: 10px; background: #e0a32e; color: #3b2a05; display: grid; place-items: center; font-size: 15px; }
.left h1 { font-size: 40px; line-height: 1.28; margin: 46px 0 16px; letter-spacing: -1px; }
.desc { color: rgba(255,255,255,.82); font-size: 14.5px; max-width: 460px; line-height: 1.85; }
.bullets { margin-top: 34px; display: grid; gap: 12px; max-width: 430px; }
.bullets div { background: rgba(255,255,255,.1); border: 1px solid rgba(255,255,255,.14); border-radius: 12px; padding: 11px 14px; font-size: 13.5px; display: flex; align-items: center; gap: 10px; }
.bullets b { color: #e0a32e; font-size: 12px; letter-spacing: 1px; }
.roles { margin-top: auto; font-size: 12.5px; color: rgba(255,255,255,.6); letter-spacing: .5px; }
.right { flex: 1; display: grid; place-items: center; background: #f7f9f8; padding: 40px; }
.card { width: 100%; max-width: 400px; background: #fff; border-radius: 18px; padding: 34px 32px 26px; box-shadow: 0 18px 46px rgba(18,49,43,.12); }
.card h2 { margin: 0 0 4px; font-size: 24px; }
.quick { margin-top: 22px; padding-top: 16px; border-top: 1px dashed var(--line); }
.qrow { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 8px; }
.qrow a { font-size: 12.5px; padding: 3px 10px; border-radius: 14px; background: #eef4f2; color: var(--primary); cursor: pointer; }
.qrow a:hover { background: var(--primary); color: #fff; }
.foot { margin-top: 16px; text-align: center; font-size: 12.5px; }
.foot a { color: var(--accent); cursor: pointer; }
@media (max-width: 900px) {
  .login { flex-direction: column; }
  .left { padding: 32px 24px; }
  .left h1 { font-size: 26px; margin: 20px 0 10px; }
  .bullets, .roles { display: none; }
  .right { padding: 24px 18px 36px; }
}
</style>
