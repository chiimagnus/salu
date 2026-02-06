# SaluAVP P2 代码审查与遗漏清单（2026-02-06）

目标：按 `.github/plans/2026-02-06-SaluAVP-P2-3D-battle-loop-implementation-plan.md` 的 Task 0–7 逐项对照代码，记录问题并补齐遗漏。

## 对照清单（Tasks → Code）

- ✅ Task 1：`Sources/GameCore/Kernel/StableHash.swift`、`Sources/GameCore/Kernel/SeedDerivation.swift`、`Tests/GameCoreTests/SeedDerivationTests.swift`
- ✅ Task 2：`SaluNative/SaluAVP/ViewModels/RunSession.swift`
- ✅ Task 3：`SaluNative/SaluAVP/Immersive/BattleHUDPanel.swift`、`SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- ✅ Task 4：`SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- ✅ Task 5：`SaluNative/SaluAVP/ControlPanel/ImmersiveSpaceToggleButton.swift`、`SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- ✅ Task 6：`SaluNative/SaluAVP/ViewModels/RunSession.swift`
- ✅ Task 7：`SaluNative/SaluAVP/Immersive/CardRewardPanel.swift`、`SaluNative/SaluAVP/ViewModels/RunSession.swift`、`SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`

## 发现的问题（需处理）

### P2-BUG-001：`BattlePendingInput` 未提供 UI 处理路径

现状：
- `BattleEngine` 可能进入 `pendingInput`（目前只有 `.foresight`），此时引擎会拒绝出牌/结束回合并发出 `invalidAction`。
- `BattleHUDPanel` 仅展示 `Pending: ...`，但没有提供 “选择哪张牌” 的 UI，也没有调用 `submitForesightChoice(index:)`。

影响：
- 一旦玩家拿到/打出会触发 `foresight` 的卡牌，战斗流程可能卡死（无法继续推进）。

建议修复：
- 在 `BattleHUDPanel` 增加一个最小“预知选牌”面板（列出 `options`，按钮选择后调用 `battleEngine.submitForesightChoice(index:)`）。
- 同时在 `RunSession.playCard/endTurn` 中在 `pendingInput != nil` 时直接忽略输入（避免刷屏 invalidAction）。

状态：已修复（见“修复记录”）

### P2-CLEAN-001：`RunSession` 中有未使用的 pending 字段

现状：
- `pendingGoldEarned`、`pendingCardOffer` 只赋值、清空，但不参与任何逻辑（route 已携带同信息）。

影响：
- 不影响功能，但会增加状态复杂度与未来维护成本。

建议：
- 若短期不计划扩展，可移除；若计划扩展（例如显示上一次奖励摘要），则应真正使用并加注释说明用途。

状态：已处理（见“修复记录”）

### P2-UX-001：奖励面板缺少“退出/返回控制面板”的兜底入口

现状：
- `CardRewardPanel` 仅提供选卡与 `Skip`，没有 `Exit`。
- 如果未来奖励面板出现异常（例如 offer 为空、或逻辑出错无法关闭），用户只能重启应用。

建议：
- 给 `CardRewardPanel` 增加一个非侵入的 `Exit`（退出 Immersive 并打开控制面板窗口），或复用已有 HUD anchor 的 `Exit` 入口。

状态：未处理（非阻塞）

## 已补齐的遗漏（修复记录）

- ✅ 2026-02-06：修复 `P2-BUG-001`
  - 增加最小 `foresight` 选牌 UI（BattleHUD）并调用 `RunSession.submitForesightChoice(index:)`
  - 在 `RunSession.playCard/endTurn` 遇到 `pendingInput != nil` 时直接忽略输入，避免刷屏 `invalidAction`
- ✅ 2026-02-06：处理 `P2-CLEAN-001`
  - 移除 `RunSession.pendingGoldEarned/pendingCardOffer`（route 已携带，不再冗余）
