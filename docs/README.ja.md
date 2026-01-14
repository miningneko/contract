# 0xNEKO

<div align="center">

**CPU最適化されたProof-of-Workマイニング可能なERC20トークン**

[機能](#機能) • [クイックスタート](#クイックスタート) • [APIリファレンス](#apiリファレンス) • [マイニングガイド](#マイニングガイド) • [セキュリティ](#セキュリティ)

</div>

---

## 概要

0xNEKOは、新しい**NekoCycle** Proof-of-Workアルゴリズムを使用する分散型マイニング可能ERC20トークンです。マイニングプロセスはグラフ構造内でサイクルを見つけることを含み、エッジ生成にはCPUマイニング向けに最適化されたデータ依存分岐アルゴリズム**BranchingHash**を使用します。

### 主な特徴

- 🔒 **完全分散型** - 管理者キーなし、オーナー権限なし
- ⛏️ **CPU最適化** - BranchingHashはデータ依存分岐を使用
- 🔗 **チェーンバインド** - ソリューションは特定のチェーンIDとマイナーアドレスに紐付け
- 📈 **ASERT難易度** - スムーズな指数難易度調整
- 💰 **スムーズエミッション** - テールエミッション付きの緩やかな減衰報酬曲線

---

## トークンエコノミクス

| パラメータ | 値 |
| :--- | :--- |
| **トークン名** | 0xNEKO |
| **シンボル** | 0xNEKO |
| **小数点以下桁数** | 18 |
| **最大供給量** | 1,000,000,000 (10億) |
| **初期報酬** | ~953.67 NEKO |
| **エミッション速度係数** | 20 |
| **テールエミッション** | 最小0.1 NEKO |
| **目標ブロック時間** | 60秒 |

---

## 機能

### NekoCycle Proof-of-Work

マイニングアルゴリズムは、`_branchingHash()`関数で生成されるエッジを持つ二部グラフで**42長のサイクル**を見つける必要があります。

### ASERT難易度調整

| パラメータ | 値 | 説明 |
| :--- | :--- | :--- |
| 半減期 | 2,880ブロック | 目標レートで約2日 |
| 目標ブロック時間 | 60秒 | ブロック間1分 |
| アンカー更新 | 100ブロックごと | 計算ドリフト防止 |

### スムーズエミッション曲線

```
報酬 = (最大供給量 - ミント済み量) >> エミッション速度係数
```

---

## クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/your-repo/0xneko.git
cd 0xneko

# 依存関係をインストール
npm install

# コントラクトをコンパイル
npx hardhat compile

# テストを実行
npx hardhat test

# デプロイ
npx hardhat run scripts/deploy.js --network hardhat
```

---

## APIリファレンス

### マイニング関数

#### `mint(uint256 nonce, uint256[] calldata solution)`
有効なマイニングソリューションを提出してトークンをミント。

### クエリ関数

| 関数 | 説明 |
| :--- | :--- |
| `getBlockInfo()` | 1回の呼び出しで全マイニング情報を返す |
| `getChallengeNumber()` | 現在のチャレンジハッシュ |
| `getMiningTarget()` | 難易度ターゲット |
| `getMiningReward()` | 現在のブロック報酬 |
| `getLocalChallenge(miner, nonce)` | ローカルチャレンジを取得 |
| `verifySolution(nonce, solution)` | ソリューションを事前検証 |
| `computeEdge(root, edgeIndex)` | エッジ (u, v) を計算 |
| `getDifficulty()` | 人間が読める難易度 |
| `getDifficultyInfo()` | ASERTパラメータ |
| `getEconomicsInfo()` | トークンエコノミクス情報 |
| `getNetworkStats()` | ネットワークハッシュレート推定 |
| `getConstants()` | プロトコル定数 |

---

## マイニングガイド

```
1. 現在のチャレンジを取得: getChallengeNumber()
2. ローカルチャレンジを生成: hash(challenge, miner, nonce, chainid)
3. computeEdge()でグラフエッジを構築
4. グラフ内で42サイクルを見つける
5. ソリューションハッシュ < ターゲットを検証
6. 提出: mint(nonce, solution)
```

---

## Gasコスト

| 操作 | Gas |
| :--- | ---: |
| **コントラクトデプロイ** | ~1,390,000 |
| **完全Mintトランザクション** | ~250,000 |

---

## セキュリティ

| 保護 | 実装 |
| :--- | :--- |
| **リエントランシー** | OpenZeppelin ReentrancyGuard |
| **CEIパターン** | _mint()前に状態更新 |
| **オーバーフロー保護** | ASERTはunchecked+事前検証使用 |
| **チェーンバインド** | ソリューションにblock.chainidを含む |
| **管理者なし** | 完全分散型 |

---

## ライセンス

MIT
