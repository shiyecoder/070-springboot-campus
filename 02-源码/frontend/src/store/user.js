import { defineStore } from 'pinia'
import request from '../api/request'

// 用户状态：token、资料、角色、菜单、按钮权限
export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('cm_token') || '',
    profile: JSON.parse(localStorage.getItem('cm_profile') || '{}'),
    menus: JSON.parse(localStorage.getItem('cm_menus') || '[]'),
    perms: JSON.parse(localStorage.getItem('cm_perms') || '[]')
  }),
  getters: {
    roles: (s) => (s.profile.roles || '').split(',').filter(Boolean),
    isAdmin: (s) => (s.profile.roles || '').includes('admin'),
    isBuyer: (s) => (s.profile.roles || '') === 'buyer',
    isFarmer: (s) => (s.profile.roles || '').includes('farmer')
  },
  actions: {
    async login(username, password) {
      const res = await request.post('/api/auth/login', { username, password })
      this.token = res.data.token
      this.profile = res.data
      localStorage.setItem('cm_token', this.token)
      localStorage.setItem('cm_profile', JSON.stringify(this.profile))
      await this.loadMenus()
      return res.data
    },
    async loadMenus() {
      const res = await request.get('/api/auth/menus')
      this.menus = res.data.menus || []
      this.perms = res.data.perms || []
      localStorage.setItem('cm_menus', JSON.stringify(this.menus))
      localStorage.setItem('cm_perms', JSON.stringify(this.perms))
    },
    async refreshProfile() {
      const res = await request.get('/api/auth/info')
      this.profile = { ...this.profile, ...res.data, roles: (res.data.roles || []).map((r) => r.role_code).join(',') }
      localStorage.setItem('cm_profile', JSON.stringify(this.profile))
    },
    logout() {
      this.token = ''
      this.profile = {}
      this.menus = []
      this.perms = []
      localStorage.removeItem('cm_token')
      localStorage.removeItem('cm_profile')
      localStorage.removeItem('cm_menus')
      localStorage.removeItem('cm_perms')
    },
    can(perm) {
      return this.perms.includes(perm)
    }
  }
})
