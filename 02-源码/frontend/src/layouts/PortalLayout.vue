<template>
  <div class="portal">
    <header class="phead">
      <div class="pbrand" @click="$router.push('/portal')"><span class="dot">超</span>校园超市 · 线上下单到店自提</div>
      <nav class="pnav">
        <a @click="$router.push('/portal')">今日推荐</a>
        <a @click="$router.push('/portal')">全部分类</a>
        <a v-if="store.token" @click="$router.push('/my-orders')">我的订单</a>
        <a v-if="!store.token" @click="$router.push('/login')">登录</a>
        <a v-else @click="logout">退出</a>
      </nav>
    </header>
    <div class="pbody"><router-view /></div>
    <div class="cart-bar" v-if="cart.count">
      <div class="cbi">
        <span class="cnum">{{ cart.count }}</span>
        <span>件商品　合计 <b class="price">¥{{ cart.amount.toFixed(2) }}</b></span>
      </div>
      <el-button type="primary" round @click="$router.push('/portal/order')">去选时段下单</el-button>
    </div>
    <footer class="pfoot">校园超市线上订货与自提系统 · 仅支持到店自提，不接入在线支付与收银硬件</footer>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useUserStore } from '../store/user'
import { useCartStore } from '../store/cart'
const store = useUserStore()
const cart = useCartStore()
const router = useRouter()
function logout() { store.logout(); router.push('/portal') }
</script>

<style scoped>
.portal { background: #f7f9f8; min-height: 100vh; display: flex; flex-direction: column; padding-bottom: 60px; }
.phead { height: 62px; background: #fff; border-bottom: 1px solid var(--line); display: flex; align-items: center; justify-content: space-between; padding: 0 40px; position: sticky; top: 0; z-index: 9; }
.pbrand { display: flex; align-items: center; gap: 10px; font-weight: 700; font-size: 17px; color: var(--primary); cursor: pointer; }
.pbrand .dot { width: 30px; height: 30px; border-radius: 9px; background: linear-gradient(135deg, #16695c, #e0a32e); color: #fff; display: grid; place-items: center; font-size: 14px; }
.pnav { display: flex; gap: 26px; font-size: 14px; color: var(--muted); }
.pnav a { cursor: pointer; }
.pnav a:hover { color: var(--primary); }
.pbody { flex: 1; max-width: 1180px; width: 100%; margin: 0 auto; padding: 20px 24px 30px; }
.pfoot { text-align: center; color: #93a09b; font-size: 12px; padding: 18px 0; border-top: 1px solid #ecefed; }
.cart-bar {
  position: fixed; left: 50%; transform: translateX(-50%); bottom: 16px; width: min(860px, 92vw);
  background: #12312b; color: #fff; border-radius: 28px; height: 54px; display: flex; align-items: center;
  justify-content: space-between; padding: 0 14px 0 22px; box-shadow: 0 10px 24px rgba(18,49,43,.28); z-index: 20;
}
.cbi { display: flex; align-items: center; gap: 12px; font-size: 13.5px; }
.cnum { background: var(--accent); color: #3b2a05; border-radius: 50%; width: 22px; height: 22px; display: grid; place-items: center; font-weight: 700; font-size: 12px; }
</style>
