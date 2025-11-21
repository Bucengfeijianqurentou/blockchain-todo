import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  // --- 核心配置开始 ---
  server: {
    proxy: {
      // 当代码请求 /WeBASE-Front 开头的地址时
      '/WeBASE-Front': {
        target: 'http://192.168.174.137:5002', // 转发给你的服务器
        changeOrigin: true, // 允许跨域
        // 也就是把 http://localhost:5173/WeBASE-Front/...
        // 变成 http://192.168.174.137:5002/WeBASE-Front/...
      }
    }
  }
  // --- 核心配置结束 ---
})