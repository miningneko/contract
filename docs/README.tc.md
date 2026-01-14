# 0xNEKO

<div align="center">

**CPU優化的工作量證明可挖礦ERC20代幣**

[功能特性](#功能特性) • [快速開始](#快速開始) • [API參考](#api參考) • [挖礦指南](#挖礦指南) • [安全性](#安全性)

</div>

---

## 概述

0xNEKO是一個去中心化的可挖礦ERC20代幣，使用新穎的**NekoCycle**工作量證明算法。挖礦過程需要在圖結構中尋找環，邊的生成使用**BranchingHash**——一種資料依賴分支算法，專為CPU挖礦優化。

### 主要亮點

- 🔒 **完全去中心化** - 無管理員金鑰，無擁有者權限
- ⛏️ **CPU優化** - BranchingHash使用資料依賴分支
- 🔗 **鏈綁定** - 解決方案綁定到特定鏈ID和礦工地址
- 📈 **ASERT難度** - 平滑指數難度調整
- 💰 **平滑發行** - 漸進衰減獎勵曲線，帶有尾部發行

---

## 代幣經濟

| 參數 | 值 |
| :--- | :--- |
| **代幣名稱** | 0xNEKO |
| **代幣符號** | 0xNEKO |
| **精度** | 18 |
| **最大供應量** | 1,000,000,000 (10億) |
| **初始獎勵** | ~953.67 NEKO |
| **發行速度因子** | 20 |
| **尾部發行** | 最低0.1 NEKO |
| **目標出塊時間** | 60秒 |

---

## 快速開始

```bash
# 複製儲存庫
git clone https://github.com/miningneko/contract.git
cd contract

# 安裝依賴
npm install

# 編譯合約
npx hardhat compile

# 執行測試
npx hardhat test
```

---

## API參考

### 挖礦函數

| 函數 | 描述 |
| :--- | :--- |
| `mint(nonce, solution)` | 提交挖礦解決方案 |

### 查詢函數

| 函數 | 描述 |
| :--- | :--- |
| `getBlockInfo()` | 一次調用返回所有挖礦資訊 |
| `getChallengeNumber()` | 當前挑戰雜湊 |
| `getMiningTarget()` | 難度目標 |
| `getMiningReward()` | 當前區塊獎勵 |
| `getLocalChallenge(miner, nonce)` | 獲取本地挑戰 |
| `verifySolution(nonce, solution)` | 預驗證解決方案 |
| `computeEdge(root, edgeIndex)` | 計算邊 (u, v) |

---

## 安全性

- ✅ ReentrancyGuard 重入保護
- ✅ CEI 模式
- ✅ 無管理員權限
- ✅ 鏈ID綁定

---

## 授權條款

MIT
