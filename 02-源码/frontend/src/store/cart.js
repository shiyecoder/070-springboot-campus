import { defineStore } from 'pinia'

/** 购物车：门户选品与下单页共用，存 localStorage 防止刷新丢失 */
export const useCartStore = defineStore('cart', {
  state: () => ({
    items: JSON.parse(localStorage.getItem('cm_cart') || '[]'),
    pointId: Number(localStorage.getItem('cm_point') || 0)
  }),
  getters: {
    count: (s) => s.items.reduce((a, b) => a + b.qty, 0),
    amount: (s) => s.items.reduce((a, b) => a + b.qty * Number(b.sale_price), 0)
  },
  actions: {
    persist() {
      localStorage.setItem('cm_cart', JSON.stringify(this.items))
      localStorage.setItem('cm_point', String(this.pointId))
    },
    add(goods, qty = 1) {
      const hit = this.items.find((i) => i.id === goods.id)
      if (hit) hit.qty = Math.min(99, hit.qty + qty)
      else this.items.push({ id: goods.id, name: goods.name, spec: goods.spec, sale_price: goods.sale_price, image: goods.image, qty })
      this.persist()
    },
    setQty(id, qty) {
      const hit = this.items.find((i) => i.id === id)
      if (hit) hit.qty = Math.max(1, Math.min(99, qty))
      this.persist()
    },
    remove(id) {
      this.items = this.items.filter((i) => i.id !== id)
      this.persist()
    },
    clear() {
      this.items = []
      this.persist()
    },
    setPoint(id) {
      this.pointId = id
      this.persist()
    }
  }
})
