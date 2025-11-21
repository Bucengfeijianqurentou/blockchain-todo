# blockchain-todo

这是一个基于 Vue 3 + Vite 的简单链上 TodoList 前端示例，演示如何通过 WeBASE-Front（或类似网关）与 FISCO-BCOS 智能合约进行交互。本项目包含一个 UI 原型和与链上 TodoList 合约交互的示例逻辑。

**主要用途**
- **前端示例**: 演示如何调用合约的读写接口（查询任务、创建任务、切换完成状态）。
- **WeBASE-Front 网关示例**: 通过代理路径示例展示与 `trans/handle` 和 web3 接口的交互方式。

**技术栈**
- **框架**: Vue 3
- **构建工具**: Vite
- **HTTP 客户端**: axios

**文件结构（关键文件）**
- `src/App.vue`: 核心 UI 与链交互逻辑（配置、ABI、调用函数）。
- `src/main.js`: Vue 应用入口。
- `contracts/TodoList.sol`: 合约源码（示例）。
- `index.html`, `public/`: 静态入口与资源。
- `package.json`: 脚本与依赖。

**快速开始**

1. 安装依赖（推荐 Node 版本见 `package.json` 中 `engines`，本项目要求 Node >= 20）:

```
npm install
```

2. 启动开发服务器:

```
npm run dev
```

3. 构建生产包:

```
npm run build
```

4. 预览构建产物:

```
npm run preview
```

**关键配置说明（在 `src/App.vue`）**
- **代理前缀**: `PROXY_PREFIX`（默认 `/WeBASE-Front`），用于在开发环境通过本地代理转发到 WeBASE-Front。若不使用代理，可将 `BASE_URL`、`WEB3_URL` 指向你的网关完整地址。
- **接口地址**:
  - `BASE_URL = `${PROXY_PREFIX}/trans/handle`` — 用于发送合约读/写请求（示例为 WeBASE-Front 的交易处理接口）。
  - `WEB3_URL = `${PROXY_PREFIX}/1/web3/blockNumber`` — 获取当前块高的示例接口。
- **合约配置（CONFIG）**: 包含 `groupId`、`contractAddress`、`userAddress`、`contractName`，请替换为你自己的链与合约信息。
- **ABI**: 前端内置了调用合约需要的 ABI（在 `src/App.vue` 中的 `ABI` 常量），用于构造调用负载。

**合约交互（核心逻辑）说明**
- `callWeBase(funcName, funcParam)`: 通用的调用包装，发送 POST 到 `BASE_URL`，并根据响应区分读（query）与写（transaction）操作。
  - 写操作（Write）：当返回 `res.data.status === '0x0'` 时表示上链交易已返回回执，示例会把交易信息记录到右侧日志面板。
  - 读操作（Read）：当返回 `res.data.code === 0` 或返回数组时，函数会解析并把结果返回给调用者。
- `loadTasks()`: 调用合约的 `getAll` 并解析链上任务列表，渲染到页面。
- `createTask()` / `toggleTask(index)`: 分别封装了任务创建和切换完成状态的写操作，写成功后会在短延迟后重新拉取列表。

**开发与调试提示**
- 若你使用 Vite 的代理（开发阶段），在 `vite.config.js` 中将 `/WeBASE-Front` 转发到真实的 WeBASE-Front 地址。
- 常见无数据场景：确保 `CONFIG.contractAddress` 与链上部署的合约地址一致，且 `groupId` 与网关配置匹配。
- 网络错误：前端会在 `callWeBase` 捕获网络错误并在日志面板显示 `Network Error`，请检查网关或代理配置。

**部署**
- 构建后将 `dist` 目录上传到任意静态托管（例如 GitHub Pages、Nginx、静态文件 CDN 等）。若后端与前端分离，确保生产环境中 `BASE_URL`/`WEB3_URL` 指向可访问的 WeBASE-Front 或自建网关接口。

**扩展建议 / 下一步**
- 支持用户钱包签名：目前示例使用后端网关直接发送交易，若需要支持客户端签名，可接入 Web3 钱包或自定义签名流程。
- 更完善的错误处理与 UX：对交易状态（pending / mined / failed）进行更细粒度的显示与轮询。
- 单元测试：为关键函数（例如 `callWeBase`、数据解析）添加自动化测试。

**许可证**
- 本仓库示例代码可按需要修改并在项目中使用。若要添加开源许可证，请在仓库根目录添加合适的 `LICENSE` 文件。

如需我代为：
- 更新 `CONFIG` 为你的真实合约地址并启动一次完整演示；或
- 配置 `vite.config.js` 代理并本地验证与 WeBASE-Front 的联通性。

如果你希望我现在执行其中任一步（如替换配置、启动本地 dev），告诉我你要我做哪一步即可。
