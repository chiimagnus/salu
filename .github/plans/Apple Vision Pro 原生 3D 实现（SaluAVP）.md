---
title: Apple Vision Pro 原生 3D 实现（SaluAVP）
date: 2026-01-29
updated: 2026-01-31
architecture: visionOS-only App + Immersive-first (RealityKit)
target: SaluAVP
---

# Plan AVP：Apple Vision Pro（visionOS）原生 3D 实现（SaluAVP）

## 0. 概览

### 背景与定位

- `SaluAVP` 是仓库内的 **visionOS-only** 原生 App Target：以 **ImmersiveSpace + RealityKit（原生 3D）** 为主。
- 2D Window 仅承担“控制面板”：入口 / seed / 存档选择 / 设置 / 历史等，不承载主战斗体验。
- 逻辑与内容 **仅复用 `GameCore`**（禁止依赖 `GameCLI`），确保跨平台逻辑一致与可测试。

### 目标（Goals）

- 能完成完整一局：入口 → 地图推进 → 房间（战斗/事件/商店/休息）→ Boss → 结算。
- 同 seed + 同选择路径，核心结果可复现（地图分支/战斗结算/奖励等）。
- Immersive-first：至少一个可交互 ImmersiveSpace（地图或战斗，优先地图）打通闭环。

### 非目标（Non-goals）

- 首版不追求完整的 VFX/动画系统、写实材质、复杂骨骼动画。
- 不把“3D 渲染实现”抽到共享层；共享层仅做状态机/桥接（见下文）。
- 不在 SwiftPM 的 `Sources/` 内引入任何 Apple-only 框架（SwiftUI / SwiftData / RealityKit 等）。

### 核心决策（Decisions）

1. **原生 App 仅保留 `SaluAVP`（visionOS）**
   - 主玩法与输入模型以沉浸式 3D 为中心；桌面端（macOS）如需体验优先使用 `GameCLI`，避免双 UI 维护成本。
2. **RealityKit 必选，但只存在于 `SaluNative/`**
   - `Sources/` 仍然保持纯逻辑、可跨平台构建。
3. **共享层只共享“状态/桥接”，不共享“渲染实现”**
   - 共享：路由状态机 / 与 `GameCore` 的桥接 Session / ViewModels。
   - 不共享：3D 场景构建、实体/材质/动画、沉浸输入手势（全部在 `SaluAVP` 内部）。

### 验收标准（Definition of Done）

- `SaluAVP` 可在 visionOS Simulator 上编译并运行（入口 2D + 至少 1 个可交互 ImmersiveSpace）。
- 完整一局可通关，并能导出/记录“选择路径”（便于复现实验与回归）。
- 关键路径无平台专属逻辑泄漏到 `Sources/`（CI/本地跨平台构建不受影响）。

### 验证命令（Build）

```bash
# visionOS（SaluAVP）
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluAVP \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build
```

```bash
# 若本次改动涉及 SwiftPM 的 `Sources/**`（例如 GameCore 逻辑），需要补跑：
swift test
```

---

## 1. 约束与边界（必须遵守）

- 依赖方向必须保持：
  - `SaluAVP → GameCore` ✅
  - `SaluAVP → Shared` ✅（若存在）
  - `GameCore → (任何 App/UI/RealityKit/SwiftUI/SwiftData)` ❌
- 可复现性：
  - `SaluAVP` 只能把“用户选择”作为输入；随机性必须由 `seed` 驱动并由 `GameCore`（或明确注入的 RNG）提供。
  - UI 层不得用“系统时间/系统随机数”影响战斗与地图结果。
- 多平台约束：
  - 不在 SwiftPM `Sources/` 内使用 Apple-only API；AVP 的 UI 代码全部留在 `SaluNative/`。
  - 若需要“跨 Target 共享”，请放到 `SaluNative/Shared/`，并保持 **不引入 RealityKit**（避免把渲染实现传播到共享层）。

---

## 2. 架构草图（建议，不强制）

### 模块结构（建议）

```
SaluNative/
├── SaluNative.xcodeproj
├── SaluAVP/                         # ✅ visionOS-only App（RealityKit 在此处）
│   ├── SaluAVPApp.swift
│   ├── ControlPanel/                # 2D 控制面板（入口/seed/设置/历史）
│   ├── ViewModels/                  # 会话/路由/桥接（当前阶段放在 Target 内）
│   └── Immersive/                   # 3D 体验主体（ImmersiveSpace）
│       ├── ImmersiveRootView.swift
│       └── (P2) Battle 相关视图/场景
└── Shared/                          # 可选：跨 Target 共享（禁止 RealityKit；目前不启用）
```

### 状态机（建议）

- `AppRoute`（Shared）：`controlPanel` ↔ `immersive(map | battle | room)` ↔ `runSummary`
- `GameSession`（Shared）：持有当前 `RunState`（或其等价的 Source of Truth）以及与存档的转换逻辑。
- `SaluAVP`（Target 内）：只关心“如何渲染”和“如何把手势变成选择”，不关心规则细节。

### 数据流（建议）

`Immersive UI（选择/手势）` → `Session（桥接/路由）` → `GameCore（状态推进）` → `Session（同步到可观察状态）` → `UI`

---

## 3. 关键接口速查（以当前 `GameCore` 实现为准）

> 目标：让 AVP 实现方快速定位“应该调用什么”，而不是在计划里复述字段列表。

### 3.1 `RunState`（冒险全局状态）

- 源码：`Sources/GameCore/Run/RunState.swift`
- 常用入口与流程方法：
  - `RunState.newRun(seed:)`
  - `accessibleNodes` / `enterNode(_:)` / `completeCurrentNode()`
  - `updateFromBattle(playerHP:)` / `restAtNode()`

### 3.2 `RunSnapshot`（存档交换格式）

- 源码：`Sources/GameCore/Run/RunSnapshot.swift`
- 版本策略：`Sources/GameCore/Run/RunSaveVersion.swift`
- `GameCore` 只提供“快照模型”；AVP 的持久化落盘策略在 App 层决定（SwiftData / 文件 / iCloud 等）。

---

## 4. 交互与 UX（Immersive-first）

### 交互映射（MVP）

- ✅ 地图：指向/点选节点 → 进入节点 → 触发房间 → 完成节点 → 回到地图。
- 战斗：选卡 →（若需要）选目标 → 出牌 → 结束回合。
- 强制反馈（所有 MVP 交互都要有）：
  - ✅ 可交互/不可交互（灰度/高亮）
  - 选中态（描边/发光/抬升）
  - 结果反馈（数值飘字/简易日志/状态图标均可）

### 2D 控制面板（MVP）

- ✅ New Run：输入 seed（或随机生成后展示）并开始。
- Continue：从 App 层持久化恢复（如果 P3 之前未做存档，可先隐藏/置灰）。
- ✅ Immersive 控制：进入/退出 ImmersiveSpace，显示当前 run 的关键摘要（楼层/金币/HP）。

---

## 5. 执行计划（以 AVP 为主）

### ✅P0（必须）：工程打通（SaluAVP Skeleton）

- 产出：
  - ✅ `SaluAVP` 目标可编译；能 `import GameCore`。
  - ✅ 2D 控制面板 + 可进入的 ImmersiveSpace（占位场景：地板 + 可点击节点）。
- DoD：
  - ✅ Simulator 可运行；能在 2D 界面控制 ImmersiveSpace 打开/关闭，不崩溃。

### ✅P1（必须）：3D 地图闭环（Map Loop）

- 产出：
  - ImmersiveSpace 中渲染地图节点（占位几何体即可）。
  - 节点状态：可达/已完成/当前节点（至少用三态材质/颜色区分）。
  - 选择节点 → `RunState.enterNode(_:)` → 路由到对应房间（先占位房间）→ `completeCurrentNode()` 返回地图。
- DoD：
  - ✅（功能已实现）能从 Act1 开始一路点击推进到 Boss，并触发“run over/won”（请按下述步骤回归确认）。

当前 P1 的手动验收步骤（Simulator）：

1. 打开 `SaluAVP`，在 2D 控制面板点击 `New Run`。
2. 点击 `Show Immersive` 进入沉浸空间。
3. 在地图上点选高亮（可达）的节点，出现房间面板（含 `Complete` 按钮）。
4. 点击 `Complete` 返回地图，观察：
   - 当前节点变为已完成
   - 下一层节点被解锁为可达（高亮）
5. 重复推进，直到进入 Boss，并最终触发 run 结束状态（`RunState.isOver/won`）。

### P2（重要）：3D 战斗闭环（Battle Loop）

- 产出：
  - ImmersiveSpace 中渲染：玩家/敌人/手牌/能量/日志（形式不限，先可读可用）。
  - Session 桥接 `GameCore` 的战斗推进（当前阶段优先放在 `SaluNative/SaluAVP/ViewModels/`；需要跨 Target 复用时再引入 `SaluNative/Shared/`）。
  - 战斗结束后：更新 `RunState`（例如 `updateFromBattle(playerHP:)`）→ 应用奖励/推进地图（奖励可先最小化）。
- DoD：
  - 战斗可完整结束（胜/负），并能回到地图继续推进。

### P3（后续）：持久化（SwiftData / JSON Blob）

- 原则：继续沿用“索引字段 + JSON Blob”的策略，降低模型演进成本。
  - 索引字段：`seed`、`updatedAt`、`floor`、`won` 等（便于列表与筛选）。
  - Blob：`RunSnapshot`（以及若存在的战斗历史快照）。
- DoD：
  - 能存/读当前 run；能在控制面板展示“继续游戏”。

### P4（后续）：观测性与回归（Determinism + Replay）

- 增加“选择路径记录”（例如节点选择、出牌序列、关键事件），用于：
  - 同 seed 重放验证（快速定位“逻辑回归 vs UI 差异”）。
  - 自动化回归（未来可在 CLI 或测试里复用）。
- DoD：
  - 把一局 run 的关键选择导出为可读文本/JSON，并能用其重放到同一结果（允许表现差异）。

---

## 6. 风险清单（提前规避）

- **Simulator/真机差异**：输入与性能差距大；MVP 阶段所有交互必须在 Simulator 上可用，真机再做增强。
- **可复现性被 UI 污染**：UI 层禁止引入“非确定”输入（时间/随机）；所有决策必须来自用户选择与 seed。
- **共享层膨胀**：Shared 只放状态机/桥接/纯 Swift，禁止把 RealityKit/材质/动画放进去。
- **资产管线不稳定**：先用程序化几何体占位；确认交互与流程稳定后再引入 USDZ/贴图。
