# SaluAVP P2：3D 战斗闭环（同一个 ImmersiveSpace）实施计划

> 执行方式：建议使用 `executing-plans` 分批实现与验收（每批次都跑一次 `xcodebuild` 回归）。

**Goal（目标）:** 在 `SaluAVP` 的同一个 `ImmersiveSpace` 内打通战斗闭环：从地图进入战斗 → 3D 敌人 + 3D 手牌交互出牌 → 敌人回合 → 胜负结算 → 回到地图继续推进（或 run over）。

**Non-goals（非目标）:**
- 不做“甩牌/投掷命中敌人”的手势（先记录为后续增强）。
- 不做多敌人（先记录为后续扩展）；本阶段只支持单敌人（`BattleEngine` 会自动解析 `targetEnemyIndex == nil` 的目标）。
- 不做完整 VFX/动画/资产管线；敌人与卡牌先用占位几何体，后续替换为真实 3D 资源。
- 不做存档持久化（P3 再做）。

**Approach（方案）:**
- `RunSession` 扩展战斗路由与 `BattleEngine` 生命周期：进入战斗节点时创建引擎并 `startBattle()`；玩家交互转换为 `PlayerAction`；战斗结束后用 `RunState.updateFromBattle(playerHP:)` + `completeCurrentNode()` 推进冒险并回到地图。
- `ImmersiveRootView` 在同一个 `RealityView` 中按 `route` 切换渲染层：`mapLayer` ↔ `battleLayer`（地图隐藏/移除）。
- 手牌使用 RealityKit `ModelEntity`（3D 卡牌）呈现并可点选出牌；目标先按“单敌人自动目标”走通流程（后续再扩展到“拖拽/甩牌命中 + 多敌人目标”）。
- 可复现性：战斗 seed 由（run seed + floor + nodeId）稳定派生，禁止使用 `hashValue`（非稳定）。

**Acceptance（验收）:**
- `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluAVP -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` 通过。
- Simulator：从地图进入战斗（单敌人）后能通过点选 3D 卡牌进行出牌、结束回合，直至胜/负；胜利后回地图继续推进；失败后进入 run over。
- 同 seed + 同节点选择路径：每次进入同一节点战斗的敌人类型/初始 HP 可复现（由派生 seed 决定）。
- Immersive 期间控制面板窗口默认隐藏（避免“初始页面挡视线”），但在 Immersive 内提供 `Panel/Exit` 入口可随时返回。
  - Update：按反馈移除 `Panel`，仅保留 `Exit`（退出 Immersive 并打开控制面板窗口）。

---

## Plan A（主方案）

### P2.0：记录 deferred（避免遗忘/范围漂移）

### ✅Task 0: 把“甩牌命中”和“多敌人”记录为后续里程碑

**Files:**
-Create: `.github/plans/2026-02-06-SaluAVP-P2-3D-battle-loop-implementation-plan.md`

**Step 1: 记录后续增强点（本文件末尾的 Backlog）**

**Step 2:（可选）在主计划 `.github/plans/Apple Vision Pro 原生 3D 实现（SaluAVP）.md` 的 P2 段落补一行“已选择：3D 卡牌（RealityKit）/ 单敌人 MVP / 甩牌与多敌人 deferred”。**

Verify: 无（文档变更）。

---

### P2.1：稳定派生 seed（可测试，避免 UI 层随意拼）

### ✅Task 1: 在 GameCore 增加稳定字符串哈希 + seed 派生工具

**Files:**
-Create: `Sources/GameCore/Kernel/StableHash.swift`
-Create: `Sources/GameCore/Kernel/SeedDerivation.swift`
-Test: `Tests/GameCoreTests/SeedDerivationTests.swift`

**Step 1: 写失败测试**
- 覆盖：同输入多次结果一致；不同 nodeId 结果不同；不使用 `hashValue`。

Run: `swift test --filter GameCoreTests.SeedDerivationTests`
Expected: FAIL（类型/函数不存在）

**Step 2: 写最小实现让测试通过**
- `StableHash.fnv1a64(_:)`：对 `String.utf8` 做 FNV-1a 64-bit。
- `SeedDerivation.battleSeed(runSeed:floor:nodeId:)`：`runSeed ^ fnv1a64(nodeId) &+ UInt64(floor) &* 1_000_000_000`（或其它简单可复现组合；保持 64-bit 溢出语义）。

Run: `swift test --filter GameCoreTests.SeedDerivationTests`
Expected: PASS

**Step 3: 回归 GameCore**
Run: `swift test --filter GameCoreTests`
Expected: PASS

---

### P2.2：RunSession 增加战斗路由与引擎生命周期

### ✅Task 2: 扩展 RunSession 支持 `.battle` route + BattleEngine

**Files:**
-Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 增加 route 与状态**
- `RunSession.Route` 新增：`case battle(nodeId: String, roomType: RoomType)`
- 新增可观察状态：
  - `var battleEngine: BattleEngine?`
  - `var battleNodeId: String?`（可选，用于断言与回溯）
  - `var battleError: String?`（可选）

**Step 2: 进入节点时分流**
- `selectAccessibleNode(_:)`：
  - 若 `node.roomType` 是 `.battle/.elite/.boss`：创建战斗并 `route = .battle(...)`
  - 否则维持现有 `route = .room(...)`

**Step 3: 创建单敌人 BattleEngine（可复现）**
- 从 `runState` 取：`player`、`deck`、`relicManager`
- 用 `SeedDerivation.battleSeed(runSeed:floor:nodeId:)` 得到 battle seed
- 用 `SeededRNG(seed:)` 从对应 Act 的 `ActXEncounterPool.randomWeak(rng:)` 选一次遭遇
- **MVP：只取 `encounter.enemyIds.first!` 生成 1 个敌人**
  - 敌人用 `createEnemy(enemyId:instanceIndex:rng:)`，`instanceIndex = 0`
- 初始化 `BattleEngine(player:enemies:deck:relicManager:seed:)` 并 `startBattle()`

**Step 4: 暴露最小交互 API**
- `playCard(handIndex:)`：包装 `battleEngine?.handleAction(.playCard(handIndex: handIndex, targetEnemyIndex: nil))`
- `endTurn()`：包装 `battleEngine?.handleAction(.endTurn)`
- `isBattleOver/won`：从 `engine.state.isOver` + `engine.state.playerWon` 读

**Step 5: 结束战斗并回到地图**
- 胜利：`runState.updateFromBattle(playerHP: engine.state.player.currentHP)` → `runState.completeCurrentNode()` → `battleEngine = nil` → `route = .map`
- 失败：`runState.updateFromBattle(...)`（会把 run 置为 over）→ `battleEngine = nil` → `route = .runOver(...)`

Verify: `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluAVP -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`

---

### P2.3：Battle HUD（先可用/可调试，后再美化）

### ✅Task 3: 添加 Battle HUD Attachment（End Turn + 状态展示）

**Files:**
-Create: `SaluNative/SaluAVP/Immersive/BattleHUDPanel.swift`
-Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`

**Step 1: 新建 `BattleHUDPanel`（SwiftUI）**
- 展示：玩家 HP、能量、回合数、手牌数量
- 按钮：`End Turn`
- （可选）展示：最近若干条 `BattleEvent` 文本（用于快速定位流程）
- UX 小改（来自截图反馈）：
  - HUD 缩小，默认收起日志（`Log` 按钮展开）
  - 提供 `Exit`（退出 Immersive 并打开控制面板窗口）

**Step 2: 在 `ImmersiveRootView` 中新增 attachment**
- 仅当 `route == .battle` 时显示
- 放置：用 `BillboardComponent()` 让面板面向用户；位置固定在视野右上角附近（head anchor 偏移）

Verify: `xcodebuild ... build`

---

### P2.4：3D 战斗场景渲染（单敌人 + 3D 手牌）

### ✅Task 4: 在 ImmersiveRootView 增加 `battleLayer` 并按 route 切换

**Files:**
-Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`

**Step 1: battle layer 基础结构**
- `mapRoot` 下新增 `battleLayer`（命名例如 `battleLayer`）
- `route == .battle`：`mapLayer.isEnabled = false`、`battleLayer.isEnabled = true`
- `route == .map/.room/.runOver`：反向切换

**Step 2: 渲染单敌人（占位体）**
- 从 `runSession.battleEngine?.state.enemies.first` 读数据
- 用 `ModelEntity`（球/胶囊/盒子）占位，并在实体 `name` 中写入稳定前缀（例如 `enemy:0`）
- 材质/颜色按敌人类型简单区分（后续替换为真实模型）
  - Note：当前实现使用 `Sphere`（`MeshResource.generateCapsule` 在目标 SDK 不可用）

**Step 3: 渲染 3D 手牌（占位卡牌）**
- 将“手牌 anchor”绑定到头部（建议：`AnchorEntity(.head)` + 固定 offset），实现“像拿在眼前的一叠牌”
- 为每张 `engine.state.hand` 创建 `ModelEntity`（薄盒子），弧形/扇形排布
- `entity.name = "card:<handIndex>"`，并加 `CollisionComponent` + `InputTargetComponent`
- 外观：可打出（能量足够）高亮；不可打出变暗
  - UX 小改（来自截图反馈）：修正扇形朝向（圆心朝向用户），并让外侧卡牌略靠近用户

**Step 4: 交互：点选卡牌出牌**
- `SpatialTapGesture().targetedToAnyEntity()`：
  - 命中 `card:<idx>` 且 `route == .battle` → `runSession.playCard(handIndex: idx)`
- 出牌后 UI 更新应由 `RealityView update` 重新渲染手牌（以 `engine.state.hand` 为源）

**Step 5: 战斗结束检测与自动回收**
- 每次出牌/结束回合后：
  - 若 `engine.state.isOver == true`：调用 `RunSession` 的“结算并回地图/RunOver”逻辑

Verify:
- `xcodebuild ... build`
- Simulator 手动验收：进入战斗后点几张牌 → `End Turn` → 直到战斗结束

---

### P2.5：从地图房间接入战斗（用户路径）

### ✅Task 5: 房间面板对 battle 节点的行为对齐

**Files:**
-Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`

**Step 1: battle 节点进入方式**
- 建议：点选 battle 节点后 **直接进入 `.battle`**（不先进入 `.room`），减少多一步点击
- 若保留 `.room`：则 `RoomPanel` 对 battle 类型显示 `Enter Battle`（而不是 `Complete`）

**Step 2: run over 的 UI**
- `route == .runOver` 时：HUD/面板提供 `New Run` 与 `Close`（回控制面板）即可
  - Note：当前实现中 `Close` 会退出 Immersive 并打开控制面板窗口

Verify: Simulator 手动走通 “地图 → 战斗 → 回地图/RunOver”

---

### P2.6：战斗胜利最小奖励（Gold only）

### ✅Task 6: 战斗胜利发放可复现金币奖励（不做卡牌选择）

**Files:**
-Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 在战斗胜利分支生成 `RewardContext` 并累加金币**
- 使用 `GoldRewardStrategy.generateGoldReward(context:)`
- `currentRow` 使用 `RunState.currentRow`（在 `completeCurrentNode()` 之前读取，保持与该节点一致）

Verify:
- `xcodebuild ... build`
- Simulator：赢一场战斗后 `run.gold` 增加（MapHUD/ControlPanel 可见）

---

## Backlog（已记录，后续增强）

### B1：甩牌 / 投掷命中敌人（真机增强 + Simulator 退化）
- 真机：抓起 3D 卡牌 → 释放时根据速度/方向投射 → 命中敌人触发出牌动画与结算
- Simulator：拖拽卡牌 → 放到敌人身上判定命中（命中后播放飞行动画）
- 需要引入：
  - “抓取/拖拽”手势（targeted drag）
  - 命中判定（碰撞体 + 接触回调或射线检测）
  - 卡牌回收与失败落点处理

### B2：多敌人（2–3 敌人）与目标选择
- 敌人布局：战斗场景内左右排布
- 目标选择：
  - 点选敌人锁定目标；或拖拽/投掷命中指定敌人
  - `PlayerAction.playCard(targetEnemyIndex: selectedIndex)`
- 注意：`BattleEngine` 在多敌人时对 `.singleEnemy` 卡牌要求显式目标（否则会报 “该牌需要选择目标”）

### B3：真实 3D 模型资产（RealityKitContent）
- 将敌人与卡牌外观替换为 `.usdz/.reality` 资产
- 需要：资源加载失败降级为占位几何体，避免沉浸空间白屏
