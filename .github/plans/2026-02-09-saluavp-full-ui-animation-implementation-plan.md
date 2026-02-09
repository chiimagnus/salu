# SaluAVP XR/3D 原生破坏性重构实施计划

> 执行方式：建议使用 `executing-plans` 按批次实现与验收。

**Goal（目标）:** 以 XR 原生、3D 原生为唯一方向，对 `SaluAVP` 做破坏性重构：完整补齐战斗动画、目标选择、多敌人、房间 UI（休息/商店/事件）、奖励链路（含精英/Boss 遗物）、存档 Continue 与回放观测，并在每个阶段及时删除老旧实现与兼容层。

**Non-goals（非目标）:** 不做写实资产管线重建；不引入网络同步；不修改 `GameCore` 既有规则语义；不把 `RealityKit` 代码抽到 `Sources/`；不保留旧 AVP UI/路由 API 的向后兼容桥接。

**Approach（方案）:**  
1) 先建立“状态推进（GameCore）”与“表现驱动（AVP）”之间的事件桥接层，替换当前 `ImmersiveRootView` 大一统渲染。  
2) 优先做可复现、可验证的动画闭环（抽牌、出牌、受击、死亡、牌堆变化），并直接移除旧静态重建路径。  
3) 房间、奖励、存档、回放全部用新路由与新面板实现，不做旧路由兼容。  
4) 每个阶段必须包含“实现 + 删除老代码 + 验证”三连动作，禁止新旧双轨长期并存。

**Acceptance（验收）:**  
1) 战斗可见“抽牌→出牌→命中/格挡→入弃牌/消耗堆”的连续动画。  
2) 支持多敌人并可明确选目标；`.singleEnemy` 卡在多敌人战斗中可稳定落点。  
3) 休息、商店、事件三类房间在 AVP 可完成完整交互并正确推进 `RunState`。  
4) 精英/Boss 胜利后奖励链路与 CLI 业务一致（金币/卡牌/遗物）。  
5) 2D 控制面板支持 Continue（从快照恢复）与自动保存。  
6) 可导出一局关键选择路径并用于重放验证。  
7) 旧 AVP 占位逻辑被删除（无旧 room panel 占位完成路径、无旧 battle 静态分支）。  
8) 修改 `SaluNative/**` 后 `xcodebuild` 可通过；修改 `Sources/**` 后 `swift test` 可通过。

---

## 重构硬约束（本计划强制）

1) 不向后兼容旧 AVP 表现层 API：允许重命名 `RunSession.Route`、面板组件、渲染入口。  
2) 不保留“兼容桥接层”超过一个任务周期：新实现落地的同批次必须删除旧实现。  
3) 禁止新旧双轨渲染：同一能力只保留一条主路径。  
4) 2D Window 仅承担控制面板与调试入口；核心玩法必须在 Immersive 3D 中完成。  
5) 存档兼容策略仅保证 `GameCore.RunSnapshot` 语义，不保证旧 AVP 私有结构可读。  

---

## Brainstorming 方案结论

### 方案 A（推荐）：事件桥接 + 分层渲染
- 核心：在 `RunSession` 上提供战斗“增量事件流”，`Immersive` 只消费事件并驱动动画系统。
- 优点：可测试性高；动画与规则解耦；后续扩展多敌人/甩牌更稳。
- 风险：需要先做一轮结构改造（短期开发速度略慢）。

### 方案 B：继续在 `ImmersiveRootView` 里增量打补丁
- 核心：维持现有单文件渲染，直接塞动画和房间逻辑。
- 优点：前两周看起来改动快。
- 风险：复杂度迅速失控，后续多人协作和回归风险高。

### 方案 C：先做房间 UI，再回头补动画
- 核心：业务闭环优先，表现层后置。
- 优点：更快覆盖地图全流程。
- 风险：后续动画接入要返工（状态切换点已固化）。

**推荐采用：方案 A（Plan A）**

---

## Plan A（主方案）

### P1（最高优先级）：战斗表现基础层（事件桥接 + 动画骨架）

### ✅Task 1: 建立 AVP 战斗事件消费接口（允许破坏旧 AVP 接口）
**Files:**
- Create: `SaluNative/SaluAVP/ViewModels/BattlePresentationEvent.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- `RunSession` 可返回“自上次消费后的新增 `BattleEvent` 列表”。
- 不重复消费旧事件。

**Step 2: 最小实现**
- 在 `RunSession` 内维护 `lastConsumedBattleEventIndex`。
- 提供 `consumeNewBattleEvents() -> [BattleEvent]`。
- 删除旧的直接 UI 轮询依赖路径（若有）。

**Step 3: 测试覆盖**
- Modify: `Tests/GameCoreTests/BattleEventDescriptionTests.swift`（补充事件序列稳定性断言）
- Create: `Tests/GameCoreTests/BattleEngineFlowEventOrderTests.swift`（验证关键事件顺序）

**Step 4: 验证**
- Run: `swift test --filter GameCoreTests/BattleEngineFlowEventOrderTests`

**Step 5: 小步回归**
- Run: `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluAVP -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`
- Run: `rg -n \"battleState.*直接驱动视图重建|legacy|deprecated\" SaluNative/SaluAVP`

### ✅Task 2: 抽离战斗渲染器，降低 `ImmersiveRootView` 复杂度
**Files:**
- Create: `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift`
- Create: `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`

**Step 1: 最小验收**
- `ImmersiveRootView` 不再直接持有大段 battle 实体构建细节。
- battle 渲染入口统一到 `BattleSceneRenderer.render(...)`。

**Step 2: 最小实现**
- 迁移 `renderBattle/renderPiles/renderPeek/clearBattle` 逻辑。
- 同批删除 `ImmersiveRootView` 内已迁移的旧 battle 渲染代码，不保留 fallback。

**Step 3: 测试覆盖**
- 以构建和手动冒烟为主（SaluAVP 无现成单测 target）。

**Step 4: 验证**
- Run: `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluAVP -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`
- Manual: 新开一局进入战斗，确认地图/战斗切换、出牌、回合结束可用。

### ❎Task 3: 引入动画队列（先占位，不改交互）
**Files:**
- Create: `SaluNative/SaluAVP/Immersive/BattleAnimationQueue.swift`
- Modify: `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`

**Step 1: 最小验收**
- 可将 `BattleEvent` 转成动画任务并顺序执行（先支持日志输出级别）。

**Step 2: 最小实现**
- 定义 `AnimationJob`（draw/play/hit/die/pileUpdate）。
- 定义去重规则（同帧多事件合并）。
- 移除“状态变更即瞬时替换实体”的旧策略入口。

**Step 3: 验证**
- Run: `xcodebuild ... build`
- Manual: 打一回合，确认动画任务在控制台可见且顺序正确。

---

### P2：战斗动画闭环（抽牌/打牌/受击/死亡）

### ✅Task 4: 抽牌动画（DrawPile -> Hand）
**Files:**
- Modify: `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`
- Modify: `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift`

**Step 1: 最小验收**
- 每次 `.drew` 事件触发可见卡牌飞入手牌扇形目标位。

**Step 2: 最小实现**
- 用临时卡实体从 draw pile 位置 `move(to:)` 到手牌槽位。
- 结束后销毁临时实体并刷新手牌实体。

**Step 3: 验证**
- Manual: 连续抽牌与洗牌后抽牌，动画不丢帧、不重影。

### ✅Task 5: 出牌动画（Hand -> Enemy / Pile）
**Files:**
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Modify: `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`

**Step 1: 最小验收**
- 点牌后先播卡牌飞行动画，再落地到弃牌/消耗堆表现。

**Step 2: 最小实现**
- `RunSession.playCard` 前后记录出牌实体索引与结果事件。
- 根据 `.played` + 卡类型决定终点（discard/exhaust）。

**Step 3: 验证**
- Manual: 普通卡与消耗性卡各打 3 次，路径正确。

### ✅Task 6: 受击、格挡、死亡反馈
**Files:**
- Create: `SaluNative/SaluAVP/Immersive/FloatingTextFactory.swift`
- Modify: `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift`
- Modify: `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`

**Step 1: 最小验收**
- `.damageDealt` 有浮字和受击闪烁。
- `.blockGained`、`blocked > 0` 有区分反馈。
- `.entityDied` 有死亡动画与实体淡出。

**Step 2: 最小实现**
- 用 `UnlitMaterial` 颜色闪烁 + 缩放脉冲。
- 浮字固定生命周期并自动回收。

**Step 3: 验证**
- Manual: 触发高伤、被格挡、击杀三种情形。

### ✅Task 7: 回合切换与 HUD 动效
**Files:**
- Modify: `SaluNative/SaluAVP/Immersive/BattleHUDPanel.swift`
- Modify: `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`

**Step 1: 最小验收**
- `turnStarted/turnEnded` 有轻量过场提示。
- 能量变化有可视化过渡。

**Step 2: 最小实现**
- HUD 显示最近一条“回合状态条”。
- 能量文本/图标做简短动画。
- 删除旧 HUD 中仅文本瞬时刷新的重复状态块。

**Step 3: 验证**
- Manual: 连续 3 回合确认提示稳定、无遮挡主交互。

---

### P3：多敌人与目标选择（战斗可玩性补齐）

### ✅Task 8: RunSession 启用多敌人遭遇初始化
**Files:**
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- `battle` 路由可创建 2-3 敌人战斗，不再只取 `first`。

**Step 2: 最小实现**
- `startBattle` 对 `.battle` 使用 `EnemyEncounter.enemyIds` 全量创建实体。
- 删除单敌人 `first` 兜底路径。

**Step 3: 验证**
- Manual: Act1/Act2 各进入 5 次普通战斗，出现多敌人场景。

### Task 9: 战斗目标选择交互
**Files:**
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- Modify: `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 点击敌人可锁定目标并有高亮。
- 出牌时可将 `targetEnemyIndex` 传入 `PlayerAction.playCard`。

**Step 2: 最小实现**
- 新增 `selectedEnemyIndex` 状态。
- 当牌 `targeting == .singleEnemy` 且多敌人时，要求目标已选。

**Step 3: 验证**
- Manual: 多敌人时攻击牌可定向命中，非目标牌不受影响。

### ✅Task 10: 目标选择边界处理与提示
**Files:**
- Modify: `SaluNative/SaluAVP/Immersive/BattleHUDPanel.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 目标死亡后自动清空锁定。
- 无目标出牌失败时给出用户可读提示。

**Step 2: 最小实现**
- 在 battle state 更新后校验 `selectedEnemyIndex` 有效性。
- HUD 显示“需要选择目标”。

**Step 3: 验证**
- Manual: 锁定敌人后其死亡，再打单体牌，提示正确。

---

### ✅P4：房间 UI 闭环（Rest / Shop / Event）

### ✅Task 11: Rest 房间交互（休息/升级/对话）
**Files:**
- Create: `SaluNative/SaluAVP/Immersive/RestRoomPanel.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`

**Step 1: 最小验收**
- 可执行休息回血。
- 可选择可升级卡并升级。

**Step 2: 最小实现**
- 在 AVP 侧封装 rest 操作接口（调用 `runState.restAtNode/upgradeCard`）。
- 删除 `RoomPanel` 中旧的统一 `Complete` 占位入口（rest 路径）。

**Step 3: 验证**
- Manual: 进入休息点完成“休息”与“升级”各一次。

### ✅Task 12: Shop 房间交互（买卡/买遗物/买消耗/删牌）
**Files:**
- Create: `SaluNative/SaluAVP/Immersive/ShopRoomPanel.swift`
- Create: `SaluNative/SaluAVP/ViewModels/ShopRoomState.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 商店库存可生成并展示价格。
- 四类交易可正确改动 `RunState` 并处理金币不足。

**Step 2: 最小实现**
- 复用 `GameCore` 的 `ShopContext/ShopInventory/ShopPricing`。
- 对外暴露按钮动作：buyCard/buyRelic/buyConsumable/removeCard。
- 删除旧 room 占位流程在 shop 路径的分支。

**Step 3: 验证**
- Manual: 每类交易至少执行一次；金币不足路径触发一次。

### ✅Task 13: Event 房间交互（选项 + Follow-up）
**Files:**
- Create: `SaluNative/SaluAVP/Immersive/EventRoomPanel.swift`
- Create: `SaluNative/SaluAVP/ViewModels/EventRoomState.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 事件可生成并展示选项。
- 选择后可应用 `RunEffect` 并展示结果摘要。

**Step 2: 最小实现**
- 复用 `EventContext/EventGenerator`。
- 支持 `followUp.chooseUpgradeableCard`。
- 删除旧 room 占位流程在 event 路径的分支。

**Step 3: 验证**
- Manual: 触发 3 个不同事件，验证数值和牌组变化。

### ✅Task 14: Event 触发精英战（followUp.startEliteBattle）
**Files:**
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Modify: `SaluNative/SaluAVP/Immersive/EventRoomPanel.swift`

**Step 1: 最小验收**
- 事件可跳转到指定精英战并在胜负后回收正确路由。

**Step 2: 最小实现**
- 新增事件来源 battle 上下文（用于结算返回事件结果页或 run over）。

**Step 3: 验证**
- Manual: 触发一次事件精英战并完成胜利链路。

---

### ✅P5：奖励链路一致性（尤其精英/Boss 遗物）

### ✅Task 15: 统一 AVP 奖励路由模型
**Files:**
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Create: `SaluNative/SaluAVP/ViewModels/RewardRouteState.swift`

**Step 1: 最小验收**
- 奖励路由支持“金币 + 卡牌 + 遗物”组合。

**Step 2: 最小实现**
- 将当前 `.cardReward(...)` 扩展为组合奖励结构。
- 清理旧奖励路由字段与已废弃面板状态。

**Step 3: 验证**
- Manual: 普通战、精英战、Boss 战分别走一遍奖励。

### ✅Task 16: 遗物奖励面板（精英/Boss）
**Files:**
- Create: `SaluNative/SaluAVP/Immersive/RelicRewardPanel.swift`
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`

**Step 1: 最小验收**
- 可选择遗物或跳过；结果正确写入 `runState.relicManager`。

**Step 2: 最小实现**
- HUD attachment 增加 relic reward 面板。

**Step 3: 验证**
- Manual: 精英和 Boss 奖励各测一次选择与跳过。

### ✅Task 17: Boss 章节收束和下一幕衔接
**Files:**
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Create: `SaluNative/SaluAVP/Immersive/ChapterEndPanel.swift`

**Step 1: 最小验收**
- Boss 胜利后有章节收束文本；非最终幕进入下一幕地图。

**Step 2: 最小实现**
- 对齐 `GameCore.RunState.completeCurrentNode()` 的 multi-act 逻辑。

**Step 3: 验证**
- Manual: 至少通关一幕并进入下一幕。

---

### ✅P6：存档与 Continue（控制面板能力补齐）

### ✅Task 18: AVP 快照存储层（RunSnapshot）
**Files:**
- Create: `SaluNative/SaluAVP/Persistence/AVPRunSnapshotStore.swift`
- Create: `SaluNative/SaluAVP/Persistence/AVPDataDirectory.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 可保存/读取/删除当前 run 快照。

**Step 2: 最小实现**
- 使用 `RunSnapshot` + JSON 文件持久化（以当前实现为准，不额外维护旧 AVP 私有格式兼容）。

**Step 3: 验证**
- Manual: 新开 run -> 保存 -> 关闭重开 -> Continue 恢复。

### ✅Task 19: 控制面板 Continue / Save / Reset UI
**Files:**
- Modify: `SaluNative/SaluAVP/ControlPanel/ControlPanelView.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 控制面板出现 Continue 和 Save 状态提示。

**Step 2: 最小实现**
- 增加按钮和错误提示；无存档时禁用 Continue。

**Step 3: 验证**
- Manual: 有存档和无存档两条路径。

### ✅Task 20: 自动保存策略
**Files:**
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 关键节点自动保存：进入房间、战斗结算、奖励确认后。

**Step 2: 最小实现**
- 封装 `autosaveIfNeeded()`，失败仅记录错误不阻塞流程。

**Step 3: 验证**
- Manual: 强制关闭 App 后恢复到最近关键节点。

---

### P7：可观测性与回放（Determinism + Replay）

### Task 21: 选择路径记录模型
**Files:**
- Create: `SaluNative/SaluAVP/ViewModels/RunTrace.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 记录节点选择、出牌、目标、奖励选择等关键动作。

**Step 2: 最小实现**
- `RunSession` 在各入口动作追加 trace entry。

**Step 3: 验证**
- Manual: 完成 1 场战斗后导出 trace，内容完整。

### Task 22: Trace 导出与重放模式（开发向）
**Files:**
- Create: `SaluNative/SaluAVP/ControlPanel/ReplayPanel.swift`
- Modify: `SaluNative/SaluAVP/ViewModels/RunSession.swift`

**Step 1: 最小验收**
- 可加载 trace 并按步回放到同结果（允许表现差异）。

**Step 2: 最小实现**
- 仅实现开发模式 replay（UI 可简化）。

**Step 3: 验证**
- Manual: 同 seed + trace 重放 2 次，比较关键状态一致。

---

### P8：测试、回归与文档收口

### Task 23: GameCore 相关新增/变更测试补齐
**Files:**
- Modify: `Tests/GameCoreTests/BattleEngineFlowTests.swift`
- Create: `Tests/GameCoreTests/BattleSeedAndEncounterParityTests.swift`
- Create: `Tests/GameCoreTests/RunSnapshotCodableRoundTripTests.swift`

**Step 1: 最小验收**
- 新增逻辑（多敌人目标、奖励链路、快照读写）有单测覆盖。

**Step 2: 验证**
- Run: `swift test --filter GameCoreTests`

### Task 24: AVP 手动回归清单固化
**Files:**
- Create: `.github/docs/SaluAVP-手动回归清单.md`
- Modify: `.github/plans/Apple Vision Pro 原生 3D 实现（SaluAVP）.md`

**Step 1: 最小验收**
- 覆盖地图、战斗动画、多敌人、房间、奖励、存档、重放七大路径。

**Step 2: 验证**
- Run: `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluAVP -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`
- Manual: 按回归文档逐条走查并记录结果。

### Task 25: 全量验证与交付前收敛
**Files:**
- Modify: `README.md`
- Modify: `README-en.md`
- Modify: `.github/docs/Salu游戏业务说明.md`

**Step 1: 最小验收**
- 文档与现状一致；命令可执行；无明显死链。
- 不存在未引用的旧 AVP 视图/状态/兼容桥接代码。

**Step 2: 验证**
- Run: `swift test`
- Run: `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluAVP -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`
- Run: `rg -n \"legacy|deprecated|TODO_COMPAT|oldRoute|oldPanel\" SaluNative/SaluAVP`

### Task 26: 老旧代码清理闸门（每阶段结束必做）
**Files:**
- Modify: `.github/docs/SaluAVP-手动回归清单.md`
- Modify: `.github/plans/2026-02-09-saluavp-full-ui-animation-implementation-plan.md`

**Step 1: 最小验收**
- 每个阶段明确“删除了什么旧代码、为何可删、如何验证无回归”。

**Step 2: 最小实现**
- 在阶段验收记录中追加“Removed Legacy”小节。
- 若发现无法删除的遗留分支，必须在当阶段内继续拆任务清理，不允许延期到“未来某次”。

**Step 3: 验证**
- Manual: 逐阶段检查回归清单包含删除记录。

---

## 分阶段回归策略

1) 完成 P1-P2 后：重点战斗回归  
- `xcodebuild ... build`  
- 手动：开局 3 场战斗，验证抽牌/打牌/受击/死亡动画。

2) 完成 P3-P5 后：重点业务闭环回归  
- `swift test --filter GameCoreTests`  
- 手动：普通/精英/Boss 各 1 场，验证奖励一致性。

3) 完成 P6-P8 后：交付回归  
- `swift test`  
- `xcodebuild ... build`  
- 手动：新开局、Continue、重放导入全链路。

---

## 不确定项（执行前建议确认）

1) 已确认：本轮不纳入“甩牌/投掷命中（B1）”，留在后续迭代。  
2) 事件房间中的“文本演出深度”目标（仅功能可用 vs 有完整剧情排版和动效）。  
3) 存档策略是否只保留“单槽自动保存”，还是支持多槽（多槽会显著增加 UI 与管理复杂度）。  
