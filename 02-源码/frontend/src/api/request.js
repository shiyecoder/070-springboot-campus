import axios from 'axios'
import { ElMessage } from 'element-plus'

// 统一 axios 封装：自动带 token、统一错误码提示、4010 跳登录
const request = axios.create({ baseURL: '', timeout: 20000 })

request.interceptors.request.use((cfg) => {
  const token = localStorage.getItem('cm_token')
  if (token) cfg.headers.Authorization = `Bearer ${token}`
  return cfg
})

request.interceptors.response.use(
  (res) => {
    const d = res.data
    if (d && typeof d.code !== 'undefined' && d.code !== 0) {
      if (d.code === 4010) {
        localStorage.removeItem('cm_token')
        if (location.hash !== '#/login') location.hash = '#/login'
      }
      ElMessage.error(d.message || '操作失败')
      return Promise.reject(d)
    }
    return d
  },
  (err) => {
    ElMessage.error(err.message || '网络异常')
    return Promise.reject(err)
  }
)

export default request
