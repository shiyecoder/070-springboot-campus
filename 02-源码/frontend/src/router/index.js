import { createRouter, createWebHashHistory } from 'vue-router'

/**
 * 路由表：后台管理（AdminLayout，6 类角色共用）+ 学生门户（PortalLayout）两套骨架。
 * 后台菜单本身由后端按角色动态下发，这里只负责路径与组件映射。
 */
const routes = [
  { path: '/login', component: () => import('../views/Login.vue'), meta: { public: true } },
  {
    path: '/',
    component: () => import('../layouts/AdminLayout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '经营看板' } },
      { path: 'goods', component: () => import('../views/GoodsList.vue'), meta: { title: '商品管理' } },
      { path: 'point', component: () => import('../views/PointList.vue'), meta: { title: '自提点管理' } },
      { path: 'slot', component: () => import('../views/SlotList.vue'), meta: { title: '时段配置' } },
      { path: 'order', component: () => import('../views/OrderList.vue'), meta: { title: '订单管理' } },
      { path: 'picking', component: () => import('../views/PickingDesk.vue'), meta: { title: '备货工作台' } },
      { path: 'verify', component: () => import('../views/VerifyDesk.vue'), meta: { title: '核销台' } },
      { path: 'replace', component: () => import('../views/ReplaceList.vue'), meta: { title: '缺货替换' } },
      { path: 'forecast', component: () => import('../views/ForecastBoard.vue'), meta: { title: '预测看板' } },
      { path: 'my-orders', component: () => import('../views/MyOrders.vue'), meta: { title: '我的订单' } },
      { path: 'profile', component: () => import('../views/Profile.vue'), meta: { title: '个人中心' } },
      { path: 'system/user', component: () => import('../views/SysUser.vue'), meta: { title: '用户管理' } },
      { path: 'system/role', component: () => import('../views/SysRole.vue'), meta: { title: '角色管理' } },
      { path: 'system/menu', component: () => import('../views/SysMenu.vue'), meta: { title: '菜单管理' } },
      { path: 'system/dict', component: () => import('../views/SysDict.vue'), meta: { title: '字典管理' } },
      { path: 'system/log', component: () => import('../views/SysLog.vue'), meta: { title: '操作日志' } }
    ]
  },
  {
    path: '/portal', component: () => import('../layouts/PortalLayout.vue'), children: [
      { path: '', component: () => import('../views/PortalHome.vue'), meta: { public: true } },
      { path: 'goods/:id', component: () => import('../views/PortalGoods.vue'), meta: { public: true } },
      { path: 'order', component: () => import('../views/OrderCreate.vue'), meta: { public: true } }
    ]
  }
]

const router = createRouter({ history: createWebHashHistory(), routes })

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('cm_token')
  if (to.meta.public) return next()
  if (!token) return next('/login')
  next()
})

export default router
