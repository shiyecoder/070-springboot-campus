import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 多通道并行：端口由启动参数覆盖，默认 5172；所有 /api 与 /uploads 代理到本通道后端 8082
export default defineConfig({
  plugins: [vue()],
  server: {
    host: '127.0.0.1',
    port: Number(process.env.PORT || 5172),
    proxy: {
      '/api': { target: 'http://127.0.0.1:8082', changeOrigin: true },
      '/uploads': { target: 'http://127.0.0.1:8082', changeOrigin: true }
    }
  },
  build: { outDir: 'dist', chunkSizeWarningLimit: 1600 }
})
