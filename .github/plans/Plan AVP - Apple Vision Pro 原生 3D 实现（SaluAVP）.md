---
title: Plan AVP - Apple Vision Pro 原生 3D 实现（SaluAVP）
date: 2026-01-29
updated: 2026-01-29
architecture: visionOS-only App + Immersive-first (RealityKit)
target: SaluAVP
---

# Plan AVP：Apple Vision Pro（visionOS）原生 3D 实现（SaluAVP）

## 0. 目标与核心决策

### 目标

- 在本仓库提供一个 **visionOS-only** 的原生 App：`SaluAVP`
- **体验形态**：以 **ImmersiveSpace + RealityKit（原生 3D）** 为主；2D Window 仅作为入口/设置/历史等“控制面板”
- 逻辑与内容 **100% 复用 `GameCore`**，不引入对 `GameCLI` 的依赖
- 对外验收：能完成完整一局（入口 → 地图推进 → 战斗/事件/商店/休息 → Boss → 结算），并保持 seed 可复现

### 核心决策

1. **拆分产品线：SaluCRH（macOS）与 SaluAVP（visionOS）**
   - AVP 的主玩法呈现与输入模型（沉浸式 3D）与 macOS 窗口化长期分叉，拆 Target 能减少 `#if os()` 污染与耦合

2. **RealityKit 必选，但只存在于 `SaluNative/`**
   - 禁止把任何 Apple-only 代码（SwiftUI/SwiftData/RealityKit）放入 SwiftPM 的 `Sources/`，避免影响 Linux/Windows 构建

3. **共享层只共享“状态/桥接”，不共享“渲染实现”**
   - 共享：`GameSession` / 路由状态机 / 与 `GameCore` 的桥接 ViewModels（例如 `BattleSession`）
   - 不共享：3D 场景构建、实体/材质/动画、沉浸输入手势（全部放在 `SaluAVP` 内部）

### 验收标准

- Xcode：`SaluAVP` 能在 visionOS Simulator 上编译并运行
- 行为：同 seed + 同选择路径，战斗/地图/奖励/事件/商店结果可复现（允许 3D 表现差异）
- 3D：核心流程至少有一个可交互 ImmersiveSpace（地图/战斗二选一先打通）

### 验证命令参考

```bash
# visionOS（SaluAVP）
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluAVP \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build
```

---

## 1. 关键接口（与 AVP 直接相关）

> 注意：以下接口以 `Sources/GameCore/` 为准，UI 不猜测 API。

### 1.1 `RunState`（冒险全局状态）

- 冒险状态包含：玩家 `Entity`、牌组 `[Card]`、金币 `gold`、遗物 `relicManager`、地图 `[MapNode]` + `currentNodeId`、`seed/floor/maxFloor/isOver/won`
- “消耗性”现在是 **Consumable Cards**（卡牌类型 `.consumable`），作为卡牌实例存在于 `deck` 中，并受槽位上限约束（见 `RunState.maxConsumableCardSlots`）

### 1.2 `RunSnapshot`（存档交换格式）

- `RunSnapshot` 是 `Codable`，覆盖 Run 的核心状态：
  - `version/seed/floor/maxFloor/gold/mapNodes/currentNodeId/player/deck/relicIds/isOver/won`
- 版本策略由 `RunSaveVersion` 管理

---

## 2. 工程与目录建议（visionOS-only）

```
SaluNative/
├── SaluNative.xcodeproj
├── SaluAVP/                         # ✅ visionOS-only App
│   ├── SaluAVPApp.swift
│   ├── ContentView.swift            # 2D 控制面板（入口/设置/历史）
│   ├── Immersive/                   # 3D 体验主体（ImmersiveSpace）
│   │   ├── ImmersiveRootView.swift
│   │   ├── MapScene.swift
│   │   └── BattleScene.swift
│   └── Assets.xcassets
└── Shared/                          # 可选：跨 Target 共享（不含 RealityKit）
    ├── AppRoute.swift
    ├── GameSession.swift
    └── ViewModels/
        └── BattleSession.swift
```

依赖方向：

- `SaluAVP → GameCore` ✅
- `SaluAVP → Shared` ✅（若存在）
- `GameCore → (任何 App/UI/RealityKit)` ❌

---

## 3. 交互与 UX（Immersive-first）

- 核心策略：把“选择式交互”映射为 3D 的稳定输入模型
  - 选卡 →（若需要）选目标 → 出牌 → 结束回合
- 必须有清晰反馈：
  - 可交互/不可交互（灰度/高亮）
  - 选中态（描边/发光/抬升）
  - 操作结果（伤害/格挡/状态变化的可视化或日志）
- 2D 控制面板负责：
  - 新游戏（可输入 seed）
  - 打开/关闭 ImmersiveSpace
  - 设置/历史（后续）

---

## 4. 执行计划（以 AVP 为主）

### P0（必须）：工程打通（SaluAVP）

- `SaluAVP` 目标可编译；能 `import GameCore`
- 最小页面：2D 控制面板 + 一个可进入的 ImmersiveSpace（占位场景）

### P1（必须）：3D 地图闭环

- ImmersiveSpace 中渲染地图节点（占位几何体即可）
- 节点状态：可达/已完成/当前节点
- 选择节点 → 调用 `RunState.enterNode` → 路由到对应房间（先用占位房间也可）→ `completeCurrentNode` 返回地图

### P2（重要）：3D 战斗闭环

- ImmersiveSpace 中渲染：玩家/敌人/手牌/能量/日志（形式不限）
- 用 `BattleSession` 桥接 `BattleEngine`，实现出牌与结束回合
- 战斗结束后应用奖励/推进地图（可先最小化奖励）

### P3（后续）：SwiftData 存档与历史

- 继续沿用“索引字段 + JSON Blob”的 SwiftData 策略
- `RunSnapshot`/`BattleRecord` blob 存储，避免模型演进成本

