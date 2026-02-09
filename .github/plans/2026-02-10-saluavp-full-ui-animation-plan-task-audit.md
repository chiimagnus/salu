# SaluAVP Plan Task Audit Report

- Repo root: `/Users/chii_magnus/Github_OpenSource/salu`
- Target plan: `.github/plans/2026-02-09-saluavp-full-ui-animation-implementation-plan.md`
- Auditor: `plan-task-auditor`
- Scope note: Plan P6/P7 已在计划内标注 `Dropped`（本阶段不做存档/回放）；本报告会把相关 Task 仍列入 TODO，但按“已 Drop”审查其代码/文件一致性。

---

## TODO Board (N=26)

- [ ] Task 1: 建立 AVP 战斗事件消费接口（允许破坏旧 AVP 接口）
- [ ] Task 2: 抽离战斗渲染器，降低 `ImmersiveRootView` 复杂度
- [ ] Task 3: 引入动画队列（先占位，不改交互）
- [ ] Task 4: 抽牌动画（DrawPile -> Hand）
- [ ] Task 5: 出牌动画（Hand -> Enemy / Pile）
- [ ] Task 6: 受击、格挡、死亡反馈
- [ ] Task 7: 回合切换与 HUD 动效
- [ ] Task 8: RunSession 启用多敌人遭遇初始化
- [ ] Task 9: 战斗目标选择交互
- [ ] Task 10: 目标选择边界处理与提示
- [ ] Task 11: Rest 房间交互（休息/升级/对话）
- [ ] Task 12: Shop 房间交互（买卡/买遗物/买消耗/删牌）
- [ ] Task 13: Event 房间交互（选项 + Follow-up）
- [ ] Task 14: Event 触发精英战（followUp.startEliteBattle）
- [ ] Task 15: 统一 AVP 奖励路由模型
- [ ] Task 16: 遗物奖励面板（精英/Boss）
- [ ] Task 17: Boss 章节收束和下一幕衔接
- [ ] Task 18: AVP 快照存储层（RunSnapshot）(Dropped)
- [ ] Task 19: 控制面板 Continue / Save / Reset UI (Dropped)
- [ ] Task 20: 自动保存策略 (Dropped)
- [ ] Task 21: 选择路径记录模型 (Dropped)
- [ ] Task 22: Trace 导出与重放模式（开发向）(Dropped)
- [ ] Task 23: GameCore 相关新增/变更测试补齐
- [ ] Task 24: AVP 手动回归清单固化
- [ ] Task 25: 全量验证与交付前收敛
- [ ] Task 26: 老旧代码清理闸门（每阶段结束必做）

---

## Task-to-File Map (Existence)

- Task 1:
  - OK `SaluNative/SaluAVP/ViewModels/BattlePresentationEvent.swift`
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
  - OK `Tests/GameCoreTests/BattleEventDescriptionTests.swift`
  - OK `Tests/GameCoreTests/BattleEngineFlowEventOrderTests.swift`
- Task 2:
  - OK `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift`
  - OK `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`
  - OK `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- Task 3:
  - OK `SaluNative/SaluAVP/Immersive/BattleAnimationQueue.swift`
  - OK `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`
- Task 4:
  - OK `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`
  - OK `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift`
- Task 5:
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
  - OK `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`
- Task 6:
  - OK `SaluNative/SaluAVP/Immersive/FloatingTextFactory.swift`
  - OK `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift`
  - OK `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`
- Task 7:
  - OK `SaluNative/SaluAVP/Immersive/BattleHUDPanel.swift`
  - OK `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift`
- Task 8:
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Task 9:
  - OK `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
  - OK `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift`
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Task 10:
  - OK `SaluNative/SaluAVP/Immersive/BattleHUDPanel.swift`
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Task 11:
  - OK `SaluNative/SaluAVP/Immersive/RestRoomPanel.swift`
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
  - OK `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- Task 12:
  - OK `SaluNative/SaluAVP/Immersive/ShopRoomPanel.swift`
  - OK `SaluNative/SaluAVP/ViewModels/ShopRoomState.swift`
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Task 13:
  - OK `SaluNative/SaluAVP/Immersive/EventRoomPanel.swift`
  - OK `SaluNative/SaluAVP/ViewModels/EventRoomState.swift`
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
- Task 14:
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
  - OK `SaluNative/SaluAVP/Immersive/EventRoomPanel.swift`
- Task 15:
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
  - OK `SaluNative/SaluAVP/ViewModels/RewardRouteState.swift`
- Task 16:
  - OK `SaluNative/SaluAVP/Immersive/RelicRewardPanel.swift`
  - OK `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- Task 17:
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift`
  - OK `SaluNative/SaluAVP/Immersive/ChapterEndPanel.swift`
- Task 18 (Dropped):
  - MISSING `SaluNative/SaluAVP/Persistence/AVPRunSnapshotStore.swift` (expected dropped)
  - MISSING `SaluNative/SaluAVP/Persistence/AVPDataDirectory.swift` (expected dropped)
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift` (contains no persistence)
- Task 19 (Dropped):
  - OK `SaluNative/SaluAVP/ControlPanel/ControlPanelView.swift` (contains no Continue/Save UI)
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift` (contains no Continue/Save logic)
- Task 20 (Dropped):
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift` (contains no autosave)
- Task 21 (Dropped):
  - MISSING `SaluNative/SaluAVP/ViewModels/RunTrace.swift` (expected dropped)
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift` (contains no trace)
- Task 22 (Dropped):
  - MISSING `SaluNative/SaluAVP/ControlPanel/ReplayPanel.swift` (expected dropped)
  - OK `SaluNative/SaluAVP/ViewModels/RunSession.swift` (contains no replay)
- Task 23:
  - OK `Tests/GameCoreTests/BattleEngineFlowTests.swift`
- Task 24:
  - OK `.github/docs/SaluAVP-手动回归清单.md`
  - OK `.github/plans/Apple Vision Pro 原生 3D 实现（SaluAVP）.md`
- Task 25:
  - OK `README.md`
  - OK `README-en.md`
  - OK `.github/docs/Salu游戏业务说明.md`
- Task 26:
  - OK `.github/docs/SaluAVP-手动回归清单.md`
  - OK `.github/plans/2026-02-09-saluavp-full-ui-animation-implementation-plan.md`

---

## Findings (Open First)

## Finding F-01

- Task: `Task 6: 受击、格挡、死亡反馈`
- Severity: `High`
- Status: `Open`
- Location: `SaluNative/SaluAVP/Immersive/BattleAnimationSystem.swift:245`
- Summary: `damageDealt/blockGained` 的反馈永远打在 `enemyRoot.children.first`，多敌人时会给错目标；并且无法区分“玩家受击”和“某个敌人受击”。
- Risk: 多敌人战斗反馈错误，目标选择的价值被削弱；容易造成“我明明打了 B，但动画/飘字出现在 A”。
- Expected fix: 最小改动下让 hit/block 反馈基于“稳定目标标识”路由到正确实体；不依赖名字字符串匹配（避免双同名敌人歧义）。
- Validation: `swift test --filter GameCoreTests` + `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluAVP -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`
- Resolution evidence: (pending)

## Finding F-02

- Task: `Task 2: 抽离战斗渲染器，降低 ImmersiveRootView 复杂度`
- Severity: `High`
- Status: `Open`
- Location: `SaluNative/SaluAVP/Immersive/BattleSceneRenderer.swift:85`
- Summary: `enemyRoot` 在每次 `render(...)` 都会 `removeFromParent()` 并重建，导致对敌人的 pulse/受击缩放等“持续动画”在下一帧被销毁，表现为抖一下就瞬间复位。
- Risk: 动画系统看似工作，但核心反馈持续时间被帧刷新打断；多敌人时更明显（每帧重建更重，也更丑）。
- Expected fix: 让敌人渲染从“每帧重建”改为“保留实体并增量更新”（按 enemy id 复用、按 alive/selected 状态更新材质/marker），仅在敌人集合变化时增删。
- Validation: `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluAVP -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` + 手动在多敌人战斗里观察受击脉冲持续 0.2s 以上不被重置。
- Resolution evidence: (pending)

## Finding F-03

- Task: `Task 1: 建立 AVP 战斗事件消费接口（允许破坏旧 AVP 接口）`
- Severity: `Medium`
- Status: `Open`
- Location: `SaluNative/SaluAVP/ViewModels/RunSession.swift:966` (see `clearBattleState(preserveSnapshot:)`)
- Summary: `playerWon` 进入 `reward` 路由时，`clearBattleState(preserveSnapshot: true)` 会把 `lastConsumedBattleEventIndex` 重置为 0，导致在奖励界面再次“从头消费一遍 battleEvents”，违反“自上次消费后新增事件”的语义。
- Risk: 奖励界面可能重复触发抽牌/回合等动画队列，表现为随机闪动/噪声；也会让 event bridge 的“增量消费”难以推理。
- Expected fix: `preserveSnapshot == true` 时不要重置 `lastConsumedBattleEventIndex`（或直接推进到 `battleEvents.count`），并明确 reward 界面不回放整场战斗事件。
- Validation: 手动：打一场战斗胜利后进入奖励界面，不再触发“抽牌/回合开始”类动画；并保持后续回到地图正常。
- Resolution evidence: (pending)

## Finding F-04

- Task: `Task 5: 出牌动画（Hand -> Enemy / Pile）`
- Severity: `Medium`
- Status: `Open`
- Location: `SaluNative/SaluAVP/ViewModels/RunSession.swift:788`
- Summary: 出牌动画当前只从手牌飞向牌堆（discard/exhaust），没有“命中目标”的视觉阶段；且 `PlayedCardPresentationContext` 不包含目标实体信息。
- Risk: 出牌缺乏因果链（打到谁），“选目标”与“造成伤害”之间缺少视觉连接，尤其多敌人战斗可读性差。
- Expected fix: 在 AVP 层为 `.played` 事件补足“本次出牌的目标 enemyId（若有）”，动画先飞向目标再落入牌堆；不需要改 GameCore 规则。
- Validation: 手动：多敌人战斗选中目标出牌，卡牌先飞向目标再回收；无目标牌仍飞向牌堆。
- Resolution evidence: (pending)

## Finding F-05

- Task: `Task 18: AVP 快照存储层（RunSnapshot）`
- Severity: `Low`
- Status: `Open`
- Location: `.github/plans/2026-02-09-saluavp-full-ui-animation-implementation-plan.md:367`
- Summary: Plan P6/P7 已标 `Dropped`，但 Task 18/21/22 的文件清单仍指向当前不存在的实现文件，容易误导后续执行者。
- Risk: 执行偏离当前决策；审查时无法快速判断“缺文件是 bug 还是刻意 drop”。 
- Expected fix: 将 Task 18/21/22 标题也明确标注 `Dropped`，并在 Files 段落注明“已回滚/本阶段不执行”。
- Validation: 文档审查即可（无代码验证要求）。
- Resolution evidence: (pending)

---

## Fix Log (Reserved)

> 本节在修复阶段填写：每条 Finding 的改动摘要与对应验证证据。

---

## Validation Log (Reserved)

- (pending)

---

## Current Status

- Findings Open: `F-01..F-05`
- Next step: Apply fixes in priority order (High -> Medium -> Low), then update this report with `Resolved` statuses and validation evidence.
