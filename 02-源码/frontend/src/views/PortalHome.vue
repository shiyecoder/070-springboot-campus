<template>
  <div class="home">
    <section class="hero">
      <div class="hl">
        <div class="tag">校内自提 · 免排队</div>
        <h1>线上下单，按课表选时段<br />下课直接来取</h1>
        <p>实时库存、按时段备货，到店报 6 位取货码即可。缺货会先征求你的意见，不擅自换货。</p>
        <div class="hact">
          <el-button type="primary" size="large" round @click="scrollToGoods">开始选品</el-button>
          <el-button size="large" round @click="$router.push('/my-orders')">我的订单</el-button>
        </div>
      </div>
      <div class="hr">
        <div class="ptcard">
          <div class="muted" style="font-size:12.5px">当前自提点</div>
          <el-select v-model="pointId" style="width:100%" @change="onPoint">
            <el-option v-for="p in points" :key="p.id" :label="p.name" :value="p.id" />
          </el-select>
          <div class="muted" style="font-size:12px;margin-top:8px">{{ curPoint.location_desc }}</div>
          <div class="muted" style="font-size:12px">营业 {{ formatClock(curPoint.open_time) }}-{{ formatClock(curPoint.close_time) }}　{{ curPoint.contact_name }}</div>
        </div>
        <div class="notice" v-for="n in notices.slice(0, 2)" :key="n.id">
          <span class="tag-orange">公告</span> {{ n.title }}
        </div>
      </div>
    </section>

    <section ref="goodsRef" class="goods">
      <div class="gtop">
        <h2>今日推荐</h2>
        <div class="cats">
          <a :class="{ on: !cat }" @click="setCat('')">全部</a>
          <a v-for="c in cats" :key="c" :class="{ on: cat === c }" @click="setCat(c)">{{ c }}</a>
        </div>
      </div>
      <div class="grid">
        <div v-for="g in goods" :key="g.id" class="card">
          <div class="thumb" @click="$router.push('/portal/goods/' + g.id)">
            <img :src="g.image" :alt="g.name" loading="lazy" />
            <span v-if="g.is_cold" class="cold">冷藏</span>
            <span v-if="g.sold_out" class="sold">已售罄</span>
          </div>
          <div class="cbody">
            <div class="cname" @click="$router.push('/portal/goods/' + g.id)">{{ g.name }}</div>
            <div class="muted" style="font-size:12px">{{ g.spec }}　{{ g.category_code }}</div>
            <div class="cfoot">
              <span class="price">{{ formatMoney(g.sale_price) }}</span>
              <el-button v-if="!g.sold_out" size="small" type="primary" round @click="add(g)">加入</el-button>
              <span v-else class="muted" style="font-size:12px">补货中</span>
            </div>
          </div>
        </div>
      </div>
      <div v-if="!goods.length" class="empty-tip">该分类暂无在售商品</div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import request from '../api/request'
import { useCartStore } from '../store/cart'
import { formatClock, formatMoney } from '../utils/format'

const cart = useCartStore()
const points = ref([])
const pointId = ref(null)
const curPoint = ref({})
const goods = ref([])
const cats = ref([])
const notices = ref([])
const cat = ref('')
const goodsRef = ref()

async function load() {
  const res = await request.get('/api/portal/home', { params: { point_id: pointId.value || undefined, category: cat.value || undefined } })
  points.value = res.data.points || []
  if (!pointId.value && points.value.length) { pointId.value = res.data.point_id; cart.setPoint(pointId.value) }
  curPoint.value = points.value.find((p) => p.id === pointId.value) || points.value[0] || {}
  goods.value = res.data.goods || []
  cats.value = (res.data.categories || []).map((c) => c.code)
  notices.value = res.data.notices || []
}

function onPoint(v) { cart.setPoint(v); load() }
function setCat(c) { cat.value = c; load() }
function scrollToGoods() { goodsRef.value?.scrollIntoView({ behavior: 'smooth' }) }
function add(g) {
  cart.add(g, 1)
  ElMessage.success('已加入购物车')
}

onMounted(load)
</script>

<style scoped>
.hero {
  background: linear-gradient(120deg, #12312b, #16695c 62%, #2f8a76);
  border-radius: 16px; color: #fff; padding: 34px 36px; display: grid; grid-template-columns: 1.35fr 1fr;
  gap: 26px; align-items: center; margin-bottom: 22px; position: relative; overflow: hidden;
}
.hero::after { content: ''; position: absolute; right: -60px; top: -60px; width: 260px; height: 260px; border-radius: 50%; background: rgba(224,163,46,.16); }
.tag { display: inline-block; background: rgba(224,163,46,.9); color: #3b2a05; font-size: 12px; padding: 3px 12px; border-radius: 12px; margin-bottom: 12px; }
.hero h1 { font-size: 30px; line-height: 1.35; margin: 0 0 10px; letter-spacing: -0.5px; }
.hero p { color: rgba(255,255,255,.85); font-size: 13.5px; line-height: 1.8; max-width: 420px; }
.hact { margin-top: 18px; display: flex; gap: 10px; }
.ptcard { background: #fff; border-radius: 12px; padding: 14px; color: var(--text); }
.notice { background: rgba(255,255,255,.12); border-radius: 10px; padding: 9px 12px; font-size: 12.5px; margin-top: 10px; color: #fff; }
.gtop { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.gtop h2 { font-size: 18px; margin: 0; }
.cats { display: flex; gap: 18px; font-size: 13.5px; color: var(--muted); flex-wrap: wrap; }
.cats a { cursor: pointer; padding-bottom: 2px; border-bottom: 2px solid transparent; }
.cats a.on { color: var(--primary); border-color: var(--primary); font-weight: 600; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(196px, 1fr)); gap: 14px; }
.card { background: #fff; border-radius: 12px; overflow: hidden; box-shadow: var(--shadow); transition: transform .16s, box-shadow .16s; }
.card:hover { transform: translateY(-3px); box-shadow: 0 10px 22px rgba(18,49,43,.12); }
.thumb { position: relative; height: 132px; background: #eef2f0; cursor: pointer; }
.thumb img { width: 100%; height: 100%; object-fit: cover; display: block; }
.cold { position: absolute; left: 8px; top: 8px; background: rgba(22,105,92,.9); color: #fff; font-size: 11px; padding: 1px 7px; border-radius: 8px; }
.sold { position: absolute; inset: 0; background: rgba(31,41,51,.45); color: #fff; display: grid; place-items: center; font-size: 13px; }
.cbody { padding: 10px 12px 12px; }
.cname { font-size: 13.5px; font-weight: 600; cursor: pointer; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.cfoot { display: flex; align-items: center; justify-content: space-between; margin-top: 8px; }
</style>
