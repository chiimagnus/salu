# Backlog 全量实现 - Plan A（按优先级 P1~P7）- 2026-01-04

> 目标：把目前“已具备主干闭环（地图/房间/战斗/存档/历史）”的 Salu，推进到具备《杀戮尖塔》核心成长循环（奖励/商店/升级/遗物/事件/多敌人/内容扩展）的版本。  
> 约束：遵守现有的**协议驱动开发（PDD）**架构（Definition + Registry + ID + Effect 管线），并确保**可复现性**（所有随机来自注入的 `SeededRNG`）。

## 0. 现状基线（已完成）

- 结构：GameCore（逻辑）/ GameCLI（表现）模块分离
- 框架：Cards/Status/Enemies/Relics 均已协议化 + registry 化
- Run：地图（Act1）+ 房间 handler 流程 + HP 跨战斗保持
- I/O：History/Save 已隔离在 GameCLI，并支持 `SALU_DATA_DIR`
- 测试：`swift test` 可通过

## 1. 总体优先级策略

优先做“玩家体验闭环”，再做大规模架构改动：

1) **成长循环**：战斗后奖励（卡牌）→ 金币/商店 → 休息升级 → 遗物掉落 → 事件  
2) **战斗复杂度提升**：多敌人 + 目标选择（架构级）  
3) **内容扩展**：Act2、更多敌人/精英/Boss/卡牌/遗物

每完成一个 Px：必须执行一次验证（至少 `build + all tests`）。

---

## P1：战斗后奖励系统（卡牌 3 选 1 + 入牌组）⭐⭐⭐ ✅ 已完成（基础版）

### 目标

- 战斗胜利后进入奖励界面：显示 3 张卡 → 选择 1 张加入 `RunState.deck` 或跳过
- 奖励必须可复现：同 seed + 同路径选择 → 奖励一致

### 设计要点（PDD 对齐）

- GameCore 提供**奖励生成**（纯逻辑）：输入 `RewardContext` + rng → 输出 `RewardOffer`
- GameCLI 仅负责 UI 展示与输入，把结果回写 `RunState`

### 当前实现落点

- `Sources/GameCore/Rewards/`
- `Sources/GameCLI/Screens/RewardScreen.swift`
- `Sources/GameCLI/Rooms/Handlers/BattleRoomHandler.swift`
- `Sources/GameCLI/Rooms/Handlers/EliteRoomHandler.swift`
- `Tests/GameCoreTests/RewardGeneratorTests.swift`
- `Tests/GameCLIUITests/GameCLIRewardUITests.swift`

### 实施步骤（建议顺序）

1. GameCore 新增 `Rewards/` 模块：
   - `RewardContext`：包含 seed、row、roomType、（可选）战斗结果摘要
   - `RewardOffer`：`[CardID]`（去重）+ 允许跳过
   - `CardPool`：从 `CardRegistry` 里筛选可奖励卡（排除 starter、排除已拥有过多重复等策略先简单）
2. GameCLI 新增 `Screens/RewardScreen.swift`（中文 UI）
3. 在 `BattleRoomHandler` / `EliteRoomHandler`：胜利后插入奖励流程（在 `completeCurrentNode()` 前完成 deck 修改）
4. 测试：
   - 新增 Swift XCTest：
     - Unit：`Tests/GameCoreTests/RewardGeneratorTests.swift`
     - CLI UI：`Tests/GameCLIUITests/GameCLIRewardUITests.swift`

### 验收标准

- 战斗胜利后一定出现奖励界面（可跳过）
- 选择卡牌后 deck 数量 +1，且存档后继续冒险仍保留
- 可复现（固定 seed 下奖励稳定）

### 可选优化（建议在 P2 后再做）

- 按 `CardDefinition.rarity` 做稀有度权重
- 避免重复（除 offer 内去重外，进一步降低 deck 内已存在卡的出现频率）
- 跳过奖励给少量金币（依赖 RunState.gold）

### 验证

- P1 完成后必须验证通过：`swift test`

---

## P2：金币系统 + 商店（买卡/删卡）⭐⭐⭐ ✅ 已完成（基础版）

### 目标

- RunState 增加金币
- 战斗胜利给金币
- 地图增加 shop 节点（RoomType.shop），并可在商店购买卡牌/删除卡牌

### 实施步骤

1. GameCore：`RunState` 增加 `gold`；定义 `ShopItem/ShopInventory/Pricing`
2. Map：`RoomType` 增加 `.shop`；`MapGenerator.decideRoomType` 增加商店分布策略（保持可复现）
3. GameCLI：
   - `ShopRoomHandler` + 注册到 `RoomHandlerRegistry`
   - `ShopScreen`：购买卡牌（从 CardPool 抽商品）/删除卡牌
4. 测试：
   - 新增 Swift XCTest：
     - Unit：商店定价/库存生成的可复现性与规则断言
     - CLI UI：覆盖“进入商店 → 购买/删牌 → 存档变化”的黑盒流程（断言以存档 JSON 为主）

### 验收标准

- 商店节点可生成且可进入
- 购买/删牌会正确修改金币与 deck

### 验证

- `swift test`

---

## P3：休息点升级卡牌（利用 upgradedId）⭐⭐ ✅ 已完成

### 目标

- 休息点提供 2 个选项：回血 / 升级卡牌
- 升级将某张卡的 `cardId` 替换为 `upgradedId`

### 实施步骤

1. GameCore：提供纯函数/方法升级逻辑（输入 deck + index → 输出新 deck / 就地替换）
2. GameCLI：扩展 `MapScreen.showRestOptions`，加入“升级卡牌”流程与卡牌选择 UI（中文）
3. 测试：
   - Unit：升级规则（`upgradedId` 替换、仅可升级项可选）
   - CLI UI：覆盖“进入休息点 → 升级卡牌 → 存档 deck.cardId 变化”的黑盒流程

### 验收标准

- 可升级卡只显示可升级项；升级后 cardId 变化正确

### 验证

- `swift test`

---

## P4：遗物掉落与展示（精英/Boss）⭐⭐⭐ ✅ 已完成

### 目标

- 精英胜利：掉落 1 个遗物（随机或可选）
- Boss 胜利：Boss 遗物（可选，后续可扩展）
- 战斗/地图界面显示已持有遗物（至少 icon + 名称）

### 实施步骤

1. GameCore：新增 `RelicPool`（基于 `RelicRegistry`，排除 starter/已拥有）
2. GameCLI：
   - `RelicRewardScreen`（中文 UI）
   - Elite/Boss handler 胜利后接入掉落流程，更新 `RunState.relicManager`
3. 测试：
   - 新增 Swift XCTest：
     - Unit：遗物掉落的可复现性与排除规则（不重复、排除 starter/已拥有）
     - CLI UI：覆盖“精英胜利 → 遗物获得 → 后续触发生效”的黑盒流程（断言以存档/关键字段为主）

### 验收标准

- 遗物可获得且效果生效；存档后仍保留

### 验证

- `swift test`

---

## P5：事件房间（Event）+ RunEffect ⭐⭐⭐⭐

### 目标

- 地图生成 event 节点
- 事件房间提供多选项，并对 RunState 产生影响（金币/卡牌/遗物/HP 等）

### 实施步骤（建议）

1. GameCore：
   - 定义 `RunEffect`（Run 维度效果）
   - 定义 `EventDefinition` + `EventRegistry` + `EventPool`
2. GameCLI：`EventScreen` + `EventRoomHandler` 接入
3. 测试：新增 Swift XCTest（固定 seed，事件选择后 RunState 变化可断言/可复现）

### 验收标准

- 事件节点可生成；事件选择可复现；影响正确落到 RunState

### 验证

- `swift test`

---

## P6：多敌人战斗 + 目标选择 ⭐⭐⭐⭐⭐（架构级）

### 目标

- BattleState 支持多个敌人；卡牌效果支持选择目标
- UI 支持选择目标（例如输入 `cardIndex targetIndex`）

### 风险

- 会涉及 `BattleState`、`BattleEngine`、`BattleEffect`、`BattleScreen` 的大范围重构

### 验收标准

- 支持至少 2 个敌人同时战斗；可正确指定目标并结算

### 验证

- `swift test`

---

## P7：内容扩展（Act2/更多卡牌/敌人/精英/Boss）⭐⭐⭐

### 目标

- 扩充卡牌、敌人、遗物数量
- 至少提供 1 个“真正的 Boss 定义”（独特技能循环）
- 为 Act2 引入新的地图生成策略（继续沿用 MapGenerating 扩展点）

### 验证

- `swift test`
