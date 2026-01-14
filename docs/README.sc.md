# 0xNEKO

<div align="center">

**CPU优化的工作量证明可挖矿ERC20代币**

[功能特性](#功能特性) • [快速开始](#快速开始) • [API参考](#api参考) • [挖矿指南](#挖矿指南) • [安全性](#安全性)

</div>

---

## 概述

0xNEKO是一个去中心化的可挖矿ERC20代币，使用新颖的**NekoCycle**工作量证明算法。挖矿过程需要在图结构中寻找环，边的生成使用**BranchingHash**——一种数据依赖分支算法，专为CPU挖矿优化。

### 主要亮点

- 🔒 **完全去中心化** - 无管理员密钥，无所有者权限
- ⛏️ **CPU优化** - BranchingHash使用数据依赖分支
- 🔗 **链绑定** - 解决方案绑定到特定链ID和矿工地址
- 📈 **ASERT难度** - 平滑指数难度调整
- 💰 **平滑发行** - 渐进衰减奖励曲线，带有尾部发行

---

## 代币经济

| 参数 | 值 |
| :--- | :--- |
| **代币名称** | 0xNEKO |
| **代币符号** | 0xNEKO |
| **精度** | 18 |
| **最大供应量** | 1,000,000,000 (10亿) |
| **初始奖励** | ~953.67 NEKO |
| **发行速度因子** | 20 |
| **尾部发行** | 最低0.1 NEKO |
| **目标出块时间** | 60秒 |

---

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/miningneko/contract.git
cd contract

# 安装依赖
npm install

# 编译合约
npx hardhat compile

# 运行测试
npx hardhat test
```

---

## API参考

### 挖矿函数

| 函数 | 描述 |
| :--- | :--- |
| `mint(nonce, solution)` | 提交挖矿解决方案 |

### 查询函数

| 函数 | 描述 |
| :--- | :--- |
| `getBlockInfo()` | 一次调用返回所有挖矿信息 |
| `getChallengeNumber()` | 当前挑战哈希 |
| `getMiningTarget()` | 难度目标 |
| `getMiningReward()` | 当前区块奖励 |
| `getLocalChallenge(miner, nonce)` | 获取本地挑战 |
| `verifySolution(nonce, solution)` | 预验证解决方案 |
| `computeEdge(root, edgeIndex)` | 计算边 (u, v) |

---

## 安全性

- ✅ ReentrancyGuard 重入保护
- ✅ CEI 模式
- ✅ 无管理员权限
- ✅ 链ID绑定

---

## 许可证

MIT
