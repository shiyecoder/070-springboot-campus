<template>
  <div class="shell">
    <aside class="side">
      <div class="brand"><span class="dot">超</span>校园超市</div>
      <el-menu :default-active="route.path" router background-color="#12312B" text-color="#BFD4CE"
               active-text-color="#FFFFFF" :collapse="false" class="menu">
        <template v-for="m in topMenus" :key="m.id">
          <el-sub-menu v-if="m.children && m.children.length" :index="'p' + m.id">
            <template #title><span class="mi">{{ short(m.menu_name) }}</span></template>
            <el-menu-item v-for="c in m.children" :key="c.id" :index="c.path">{{ c.menu_name }}</el-menu-item>
          </el-sub-menu>
          <el-menu-item v-else :index="m.path"><span class="mi">{{ short(m.menu_name) }}</span></el-menu-item>
        </template>
      </el-menu>
    </aside>
    <div class="main">
      <header class="top">
        <div class="crumb">校园超市 / <b>{{ route.meta.title || '经营看板' }}</b></div>
        <div class="top-right">
          <el-popover placement="bottom-end" :width="320" trigger="click">
            <template #reference>
              <el-badge :value="unread" :hidden="!unread" class="bell">
                <el-icon :size="18"><Bell /></el-icon>
              </el-badge>
            </template>
            <div style="max-height:280px;overflow:auto">
              <div v-for="m in messages" :key="m.id" style="padding:8px 4px;border-bottom:1px solid #f0f2f4">
                <div style="font-size:13px;font-weight:600">{{ m.title }}</div>
                <div class="muted" style="font-size:12px">{{ m.content }}</div>
                <div class="muted" style="font-size:11px">{{ formatTime(m.create_time) }}</div>
              </div>
              <div v-if="!messages.length" class="empty-tip" style="padding:16px 0">暂无消息</div>
            </div>
          </el-popover>
          <el-button link @click="$router.push('/portal')">学生门户</el-button>
          <el-dropdown @command="onCommand">
            <span class="who">
              <span class="avatar"><img v-if="profile.avatar" :src="profile.avatar" alt="" /><template v-else>超</template></span>
              {{ profile.real_name || profile.username }} · {{ roleName }}
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人中心</el-dropdown-item>
                <el-dropdown-item command="portal">学生门户</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>
      <div class="body"><router-view /></div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '../store/user'
import request from '../api/request'
import { formatTime } from '../utils/format'

const route = useRoute()
const router = useRouter()
const store = useUserStore()
const unread = ref(0)
const messages = ref([])
const profile = computed(() => store.profile)
const roleName = computed(() => (store.profile.role_names || [])[0] || '用户')

// 菜单由后端按角色动态下发，前端不写死；菜单管理项在侧栏隐藏（需求硬性第 12 条）
const topMenus = computed(() => {
  const list = (store.menus || []).filter((m) => m.path !== '/system/menu')
  const roots = list.filter((m) => !m.parent_id || m.parent_id === 0)
  return roots.map((r) => ({ ...r, children: list.filter((c) => c.parent_id === r.id) }))
    .filter((m) => m.children.length || m.path)
})

const ICON = {
  经营看板: '▤', 商品管理: '▣', 自提点管理: '⌖', 时段配置: '◷', 订单管理: '≡',
  备货工作台: '☑', 核销台: '◎', 缺货替换: '⇄', 预测看板: '◈', 系统管理: '⚙',
  我的订单: '▦', 个人中心: '☺'
}
const short = (n) => (ICON[n] || '•') + '  ' + n

async function loadMessages() {
  try {
    const res = await request.get('/api/sys-message/mine')
    unread.value = res.data.unread || 0
    messages.value = res.data.list || []
  } catch (e) { unread.value = 0 }
}

onMounted(async () => {
  if (!store.menus.length) await store.loadMenus()
  loadMessages()
})

function onCommand(c) {
  if (c === 'logout') { store.logout(); router.push('/login') }
  if (c === 'profile') router.push('/profile')
  if (c === 'portal') window.open('/#/portal', '_blank')
}
</script>

<style scoped>
.shell { display: flex; min-height: 100vh; }
.side { width: 220px; flex: 0 0 220px; background: #12312b; display: flex; flex-direction: column; }
.brand { height: 56px; display: flex; align-items: center; gap: 10px; padding: 0 18px; background: #0d2621; color: #fff; font-weight: 700; letter-spacing: .5px; }
.brand .dot { width: 26px; height: 26px; border-radius: 8px; background: linear-gradient(135deg, #3d9683, #e0a32e); display: grid; place-items: center; font-size: 13px; }
.menu { border-right: none; flex: 1; padding: 6px; }
.menu :deep(.el-menu-item), .menu :deep(.el-sub-menu__title) { height: 40px; line-height: 40px; font-size: 13.5px; border-radius: 8px; margin-bottom: 2px; }
.menu :deep(.el-menu-item.is-active) { background: #16695c !important; font-weight: 600; }
.main { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.top { height: 56px; background: #fff; border-bottom: 1px solid var(--line); display: flex; align-items: center; justify-content: space-between; padding: 0 24px; }
.crumb { color: var(--muted); font-size: 13px; }
.crumb b { color: var(--text); }
.top-right { display: flex; align-items: center; gap: 18px; }
.who { display: flex; align-items: center; gap: 8px; font-size: 13px; cursor: pointer; }
.avatar { width: 30px; height: 30px; border-radius: 50%; overflow: hidden; background: linear-gradient(135deg, #3d9683, #16695c); color: #fff; display: grid; place-items: center; font-size: 12px; }
.avatar img { width: 100%; height: 100%; object-fit: cover; }
.body { padding: 18px 24px 30px; flex: 1; overflow: auto; }
</style>
