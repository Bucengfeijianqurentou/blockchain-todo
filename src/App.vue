<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

// ================= 配置区域 =================
const PROXY_PREFIX = "/WeBASE-Front" // 代理前缀
const BASE_URL = `${PROXY_PREFIX}/trans/handle`
const WEB3_URL = `${PROXY_PREFIX}/1/web3/blockNumber` // 获取块高接口

const CONFIG = {
  groupId: 1,
  // ⚠️ 保持你的配置
  contractAddress: "0xbbdc704a67d805db8be2a23884efddc24ff2fc7d", 
  userAddress: "0x86c3cee718a3980875ea1994f3ff88343a708808",     
  contractName: "TodoList"
}

const ABI = [
    {"constant":false,"inputs":[{"name":"_index","type":"uint256"}],"name":"toggleCompleted","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},
    {"constant":true,"inputs":[],"name":"getAll","outputs":[{"components":[{"name":"text","type":"string"},{"name":"completed","type":"bool"}],"name":"","type":"tuple[]"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[{"name":"_index","type":"uint256"}],"name":"get","outputs":[{"name":"","type":"string"},{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":true,"inputs":[],"name":"getCount","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":false,"inputs":[{"name":"_text","type":"string"}],"name":"create","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},
    {"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"todos","outputs":[{"name":"text","type":"string"},{"name":"completed","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},
    {"constant":false,"inputs":[{"name":"_index","type":"uint256"},{"name":"_text","type":"string"}],"name":"updateText","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}
];

// ================= 响应式数据 =================
const todos = ref([])
const inputVal = ref("")
const loading = ref(false)
const currentBlockNumber = ref(0) // 当前块高
const txLogs = ref([]) // 交易日志列表

// ================= 辅助函数 =================
// 缩略显示地址/哈希
const shorten = (str) => {
  if (!str) return ''
  return str.substring(0, 6) + '...' + str.substring(str.length - 4)
}

// 添加日志
const addLog = (type, data) => {
  txLogs.value.unshift({
    id: Date.now(),
    time: new Date().toLocaleTimeString(),
    type: type, // 'TX' (交易) 或 'INFO' (信息)
    hash: data.transactionHash || null,
    block: data.blockNumber || null,
    gas: data.gasUsed || null,
    status: data.status === '0x0' ? 'Success' : 'Fail',
    msg: data.message || ''
  })
}

// ================= 核心交互 =================

// 1. 获取当前块高 (纯 Web3 接口)
const fetchBlockNumber = async () => {
  try {
    const res = await axios.get(WEB3_URL)
    currentBlockNumber.value = res.data
  } catch (e) {
    console.error("获取块高失败", e)
  }
}

const callWeBase = async (funcName, funcParam = []) => {
  loading.value = true
  
  try {
    const payload = {
      reqId: Date.now(),
      groupId: CONFIG.groupId,
      contractName: CONFIG.contractName,
      contractAddress: CONFIG.contractAddress,
      contractAbi: ABI,
      user: CONFIG.userAddress,
      funcName: funcName,
      funcParam: funcParam,
      useAes: false
    }

    const res = await axios.post(BASE_URL, payload)
    
    // 每次交互后刷新块高
    fetchBlockNumber()

    // --- 处理交易回执 (Write 操作) ---
    if (res.data && res.data.status === "0x0") {
      // 记录到右侧日志面板
      addLog('TX', res.data) 
      return res.data
    }
    
    // --- 处理查询结果 (Read 操作) ---
    else if (res.data && res.data.code === 0) {
      return res.data.data
    } 
    else if (Array.isArray(res.data)) {
      return res.data
    }
    
    else {
      console.error("请求异常:", res.data)
      addLog('ERR', { message: res.data.message || 'Unknown Error' })
      return null
    }

  } catch (error) {
    console.error(error)
    addLog('ERR', { message: 'Network Error' })
    return null
  } finally {
    loading.value = false
  }
}

// 2. 获取列表
const loadTasks = async () => {
  const data = await callWeBase("getAll", [])
  if (data && Array.isArray(data) && data.length > 0) {
    let rawContent = data[0]
    let parsedList = []
    if (typeof rawContent === 'string') {
      try { parsedList = JSON.parse(rawContent) } catch (e) { parsedList = [] }
    } else {
      parsedList = rawContent
    }
    todos.value = parsedList.map((item, index) => ({
      index: index,
      text: item[0],
      completed: item[1]
    }))
  } else {
    todos.value = []
  }
}

// 3. 创建任务
const createTask = async () => {
  if (!inputVal.value) return
  const res = await callWeBase("create", [inputVal.value])
  if (res) {
    inputVal.value = ""
    setTimeout(loadTasks, 1000)
  }
}

// 4. 切换状态
const toggleTask = async (index) => {
  const res = await callWeBase("toggleCompleted", [index])
  if (res) {
    setTimeout(loadTasks, 1000)
  }
}

onMounted(() => {
  fetchBlockNumber()
  loadTasks()
})
</script>

<template>
  <div class="dashboard">
    <header class="header">
      <div class="brand">
        <span class="logo">⛓️</span>
        <h1>FISCO BCOS TodoList</h1>
      </div>
      <div class="network-status">
        <span class="indicator"></span>
        <span>Block Height: <strong>{{ currentBlockNumber }}</strong></span>
      </div>
    </header>

    <div class="main-content">
      <div class="panel left-panel">
        <h3>📝 任务管理</h3>
        
        <div class="input-group">
          <input 
            v-model="inputVal" 
            type="text" 
            placeholder="输入新任务..." 
            @keyup.enter="createTask"
          >
          <button @click="createTask" :disabled="loading" class="btn-add">
            {{ loading ? '上链中...' : '添加' }}
          </button>
        </div>

        <ul class="todo-list">
          <li v-for="item in todos" :key="item.index" :class="{ done: item.completed }">
            <div class="todo-content">
              <span class="index">#{{ item.index }}</span>
              <span class="text">{{ item.text }}</span>
            </div>
            <button class="btn-toggle" @click="toggleTask(item.index)">
              {{ item.completed ? '撤销' : '完成' }}
            </button>
          </li>
        </ul>
        
        <div class="empty-tip" v-if="todos.length === 0">
          暂无链上数据
        </div>
      </div>

      <div class="panel right-panel">
        <div class="info-card">
          <h3>👤 账户信息</h3>
          <div class="info-row">
            <span class="label">我的地址:</span>
            <span class="value mono" :title="CONFIG.userAddress">{{ shorten(CONFIG.userAddress) }}</span>
          </div>
          <div class="info-row">
            <span class="label">合约地址:</span>
            <span class="value mono" :title="CONFIG.contractAddress">{{ shorten(CONFIG.contractAddress) }}</span>
          </div>
        </div>

        <div class="logs-area">
          <h3>🧾 交易控制台</h3>
          <div class="logs-container">
            <div v-if="txLogs.length === 0" class="empty-log">暂无交易记录</div>
            
            <div v-for="log in txLogs" :key="log.id" class="log-item" :class="log.type">
              <div class="log-header">
                <span class="time">{{ log.time }}</span>
                <span class="status-badge" :class="log.status">{{ log.status }}</span>
              </div>
              <div class="log-body" v-if="log.hash">
                <div class="log-row"><span>Hash:</span> <span class="mono">{{ shorten(log.hash) }}</span></div>
                <div class="log-row"><span>Block:</span> <span class="highlight">{{ log.block }}</span></div>
                <div class="log-row"><span>Gas:</span> <span class="highlight">{{ log.gas }}</span></div>
              </div>
              <div class="log-body" v-else>
                {{ log.msg }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* 全局重置与变量 */
.dashboard {
  min-height: 100vh;
  background-color: #1a1d21; /* 深灰背景 */
  color: #e0e6ed;
  font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  display: flex;
  flex-direction: column;
}

.mono { font-family: 'Consolas', 'Monaco', monospace; }

/* 顶部导航 */
.header {
  background-color: #263238;
  padding: 0 40px;
  height: 60px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #37474f;
  box-shadow: 0 2px 10px rgba(0,0,0,0.2);
}

.brand { display: flex; align-items: center; gap: 10px; }
.logo { font-size: 24px; }
.header h1 { font-size: 18px; font-weight: 600; margin: 0; color: #82aaff; }

.network-status { 
  display: flex; align-items: center; gap: 8px; font-size: 14px; 
  background: #1e272c; padding: 5px 15px; border-radius: 20px;
}
.indicator { width: 8px; height: 8px; background-color: #00e676; border-radius: 50%; box-shadow: 0 0 8px #00e676; }

/* 主体布局 */
.main-content {
  flex: 1;
  display: grid;
  grid-template-columns: 1.5fr 1fr; /* 左宽右窄 */
  gap: 20px;
  padding: 30px 40px;
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
}

.panel {
  background-color: #263238;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.3);
  display: flex;
  flex-direction: column;
}

.panel h3 { margin-top: 0; margin-bottom: 20px; color: #c3e88d; font-size: 16px; border-bottom: 1px solid #37474f; padding-bottom: 10px;}

/* 左侧样式 */
.input-group { display: flex; gap: 10px; margin-bottom: 20px; }
input {
  flex: 1; padding: 12px; background: #1a1d21; border: 1px solid #37474f; 
  border-radius: 6px; color: white; outline: none; transition: 0.3s;
}
input:focus { border-color: #82aaff; }

.btn-add { background: #82aaff; color: white; border: none; padding: 0 20px; border-radius: 6px; cursor: pointer; font-weight: bold;}
.btn-add:hover { background: #689dff; }
.btn-add:disabled { background: #546e7a; cursor: not-allowed; }

.todo-list { list-style: none; padding: 0; margin: 0; overflow-y: auto; flex: 1; }
.todo-list li {
  background: #303841; margin-bottom: 10px; padding: 15px; border-radius: 8px;
  display: flex; justify-content: space-between; align-items: center;
  border-left: 4px solid #82aaff; transition: all 0.3s;
}
.todo-list li.done { border-left-color: #00e676; opacity: 0.6; }
.todo-list li.done .text { text-decoration: line-through; color: #90a4ae; }

.todo-content { display: flex; gap: 10px; align-items: center; }
.index { font-size: 12px; color: #546e7a; font-weight: bold; }
.text { font-size: 15px; }

.btn-toggle {
  background: transparent; border: 1px solid #546e7a; color: #b0bec5;
  padding: 4px 10px; border-radius: 4px; cursor: pointer; font-size: 12px;
}
.btn-toggle:hover { border-color: #82aaff; color: #82aaff; }

/* 右侧样式 */
.info-card { background: #1e272c; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
.info-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 13px; }
.info-row .label { color: #90a4ae; }
.info-row .value { color: #80cbc4; cursor: pointer; }

.logs-area { flex: 1; display: flex; flex-direction: column; min-height: 300px; }
.logs-container { 
  flex: 1; background: #15171a; border-radius: 8px; padding: 10px; 
  overflow-y: auto; max-height: 400px; font-size: 12px;
}
.empty-log { text-align: center; color: #546e7a; padding-top: 20px; }

.log-item {
  background: #263238; margin-bottom: 8px; padding: 10px; border-radius: 4px;
  border-left: 3px solid #c3e88d; animation: fadeIn 0.5s;
}
.log-item.ERR { border-left-color: #ff5252; }

.log-header { display: flex; justify-content: space-between; margin-bottom: 5px; color: #546e7a; }
.status-badge.Success { color: #00e676; }
.status-badge.Fail { color: #ff5252; }

.log-row { display: flex; gap: 10px; color: #b0bec5; margin-bottom: 2px; }
.log-row span:first-child { min-width: 40px; color: #546e7a; }
.highlight { color: #ffd700; }

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>