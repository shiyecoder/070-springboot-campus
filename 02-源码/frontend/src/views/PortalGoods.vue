<template>
  <div v-if="g.id">
    <el-button link @click="$router.push('/portal')" style="margin-bottom:12px">← 返回商品列表</el-button>
    <div class="panel detail">
      <img class="main" :src="g.image" :alt="g.name" />
      <div class="info">
        <h1>{{ g.name }}</h1>
        <div class="muted" style="font-size:13px">{{ g.category_code }}　{{ g.spec }}　货架位 {{ g.shelf_code }}</div>
        <div class="pricebig">{{ formatMoney(g.sale_price) }}</div>
        <div class="meta">
          <span :class="g.is_cold ? 'tag-orange' : 'tag-gray'">{{ g.is_cold ? '冷藏商品' : '常温商品' }}</span>
          <span :class="g.sold_out ? 'tag-red' : 'tag-green'">{{ g.sold_out ? '已售罄' : '在售' }}</span>
          <span class="tag-blue" v-if="g.limit_qty > 0">单日限购 {{ g.limit_qty }} 件</span>
          <span class="tag-gray" v-else>不限购</span>
        </div>
        <div class="buy">
          <el-input-number v-model="qty" :min="1" :max="g.limit_qty > 0 ? g.limit_qty : 99" />
          <el-button type="primary" size="large" :disabled="g.sold_out" @click="add">加入购物车</el-button>
          <el-button size="large" :disabled="g.sold_out" @click="buyNow">立即选时段</el-button>
        </div>
        <div class="tip">冷藏商品备货时优先拣选；库存低于 5 件自动转售罄并从门户隐藏。</div>
      </div>
    </div>

    <h2 style="font-size:16px;margin:18px 0 10px">同类推荐</h2>
    <div class="grid">
      <div v-for="r in g.related || []" :key="r.id" class="rcard" @click="$router.push('/portal/goods/' + r.id)">
        <img :src="r.image" :alt="r.name" />
        <div style="padding:8px 10px">
          <div style="font-size:13px;font-weight:600">{{ r.name }}</div>
          <div class="price" style="font-size:13px">{{ formatMoney(r.sale_price) }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import request from '../api/request'
import { useCartStore } from '../store/cart'
import { formatMoney } from '../utils/format'

const route = useRoute()
const router = useRouter()
const cart = useCartStore()
const g = ref({})
const qty = ref(1)

async function load() {
  const res = await request.get(`/api/portal/goods/${route.params.id}`)
  g.value = res.data
}
function add() {
  cart.add(g.value, qty.value)
  ElMessage.success('已加入购物车')
}
function buyNow() {
  cart.add(g.value, qty.value)
  router.push('/portal/order')
}
onMounted(load)
</script>

<style scoped>
.detail { display: grid; grid-template-columns: 380px 1fr; gap: 26px; }
.main { width: 100%; height: 290px; object-fit: cover; border-radius: 12px; background: #eef2f0; }
.info h1 { font-size: 22px; margin: 0 0 6px; }
.pricebig { font-size: 30px; font-weight: 700; color: var(--accent); margin: 12px 0 10px; }
.meta { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 18px; }
.buy { display: flex; gap: 10px; align-items: center; }
.tip { margin-top: 16px; font-size: 12.5px; color: var(--muted); background: #f7f9f8; padding: 9px 12px; border-radius: 8px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(168px, 1fr)); gap: 12px; }
.rcard { background: #fff; border-radius: 12px; overflow: hidden; box-shadow: var(--shadow); cursor: pointer; }
.rcard img { width: 100%; height: 108px; object-fit: cover; display: block; }
</style>
