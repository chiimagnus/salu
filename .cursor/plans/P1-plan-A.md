# P1 Plan A：战斗后奖励系统（卡牌 3 选 1 + 入牌组）

> 目标：让 Run 具备“战斗胜利 → 奖励 → 牌组成长”的核心循环（可复现）。

## 1. 需求与约束

- **触发时机**：普通战斗/精英战斗胜利后（Boss 房间暂不接入，后续在遗物掉落阶段做）
- **奖励内容**：3 张卡牌（`CardID`）供选择；允许跳过
- **可复现性**：固定 `--seed` + 相同路线选择 → 奖励一致
- **PDD 约束**：
  - GameCore 只做“奖励生成/规则”，不做 I/O、不依赖 Foundation
  - UI 展示从 `CardRegistry` 取 `name/rulesText/cost/type/rarity`
- **存档一致性**：选择奖励后，deck 变化必须被写入 `RunSnapshot`（目前节点完成后自动保存）

## 2. 架构设计

### 2.1 GameCore（新增 Rewards 域）

新增目录：`Sources/GameCore/Rewards/`

核心类型（建议）：

- `RewardContext`：
  - `seed: UInt64`
  - `floor: Int`
  - `currentRow: Int`
  - `roomType: RoomType`（battle/elite）
  - （可选）战斗统计摘要：用于未来做“奖励权重/稀有度提升”

- `CardRewardOffer`：
  - `choices: [CardID]`（长度 3，去重）
  - `canSkip: Bool = true`

- `CardPool`：
  - 从 `CardRegistry` 过滤可奖励卡（初期策略：`rarity != .starter`）
  - （后续扩展）按稀有度权重、按已有卡去重/限制重复

- `RewardGenerator`（纯函数/静态方法）：
  - `generateCardReward(context: RewardContext, rng: inout SeededRNG) -> CardRewardOffer`

### 2.2 GameCLI（新增 RewardScreen）

新增文件：`Sources/GameCLI/Screens/RewardScreen.swift`

UI 行为：

- 展示标题：“🎁 战斗奖励”
- 逐条展示 3 个选项：
  - `[1] 卡名  ◆cost  typeIcon  rulesText`
- 输入：
  - `1~3` 选择加入牌组
  - `0` 跳过
  - `q` 跳过并返回（与其他界面一致）
- **EOF 处理**：`readLine() == nil` → 默认跳过（保证脚本测试不会卡死）

### 2.3 与房间流程的接入点

修改：

- `BattleRoomHandler` / `EliteRoomHandler`
  - 在 `engine.state.playerWon == true` 分支：
    1) 生成奖励（基于可复现 rng）
    2) 展示 `RewardScreen` 获取选择
    3) 若选择卡牌：创建 `Card` 实例并 append 到 `runState.deck`
    4) `runState.completeCurrentNode()`（保持现有语义）

### 2.4 可复现 RNG 策略（建议）

为避免引入“全局 run-level rng 状态”的大改动，P1 用**局部种子派生**：

- `rewardSeed = runState.seed ^ UInt64(runState.currentRow) ^ 0xA11CE`（示例）
- 普通战斗与精英战斗可加不同常量区分
- 用 `SeededRNG(seed: rewardSeed)` 生成 3 张卡（确保同路径同结果）

> 后续 P5 事件/商店更复杂时，再引入 run-level RNG state 进入 `RunSnapshot`。

## 3. 卡牌实例 ID 生成策略（必须稳定）

当前 `Card` 需要 `id: String`（instanceId）。P1 新增卡需要生成新 id：

- 规则：`"<cardId.rawValue>_<n>"`
- `n` 的求法：扫描当前 deck 中同 `cardId.rawValue + "_"` 前缀的最大序号 + 1
- 该策略在存档/继续冒险后仍稳定（因为 deck 持久化保存了 instanceId）

## 4. 测试策略

### 4.1 更新现有脚本的兼容性

奖励界面会插入到战斗胜利后，脚本若遇到 EOF 应默认跳过，因此不应导致卡死。

### 4.2 新增测试脚本：`test_reward.sh`

放置：`.cursor/Scripts/tests/test_reward.sh`，并在 `test_game.sh` 加入 `reward` 子命令。

测试思路（推荐）：

- 设置 `SALU_DATA_DIR` 到临时目录
- 跑一局：开始冒险 → 起点 → 第一场战斗（给足够多的出牌输入确保胜利）→ 奖励选 1 → `q` 回主菜单 → 退出
- 断言：`$SALU_DATA_DIR/run_save.json` 存在且 deck 数量从 13 变为 14

## 5. 验收标准

- [ ] 普通战斗胜利后出现奖励界面（可跳过）
- [ ] 选择卡牌后 deck +1，存档后继续冒险 deck 仍保留
- [ ] 固定 seed 下奖励可复现（同一路径）
- [ ] `./.cursor/Scripts/test_game.sh all` 通过


