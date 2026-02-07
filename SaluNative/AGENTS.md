# SaluNative（原生 App / visionOS）AI 开发规范（Codex）

本文件适用于 `SaluNative/` 目录树内的所有改动：用于让 Codex 这类 AI 直接上手开发 `SaluAVP`（Apple Vision Pro / visionOS）原生 3D（XR）App。

> 仓库总规范见根目录 `AGENTS.md`。逻辑层约束见 `Sources/GameCore/AGENTS.md`（强制遵守）。

## 0. 模块定位与边界（必须遵守）

### 依赖方向（硬约束）

- `SaluAVP（visionOS App） → GameCore` ✅ 允许、鼓励复用逻辑与内容
- `SaluAVP → SaluNative/Shared` ✅（如果存在）
- `SaluAVP → GameCLI` ❌ 禁止（不要把 CLI 的 I/O/渲染/持久化带进来）
- `GameCore → SwiftUI/RealityKit/SwiftData/*App` ❌ 永远禁止（保持 SwiftPM 可跨平台构建）

### 业务一致性（Salu vs SaluAVP，硬约束）

- `Salu` 与 `SaluAVP` 的**玩法业务规则必须一致**（战斗结算、地图推进、奖励发放、商店/休息点效果、状态衰减等）。
- `SaluAVP` 的差异应仅限于**表现层与交互层**（3D 沉浸场景、空间手势、UI 布局、动效与反馈形式）。
- 任何会影响玩法结果的逻辑都必须走 `GameCore`；禁止在 `SaluAVP` 内新增“另一套结算规则”。
- 如确需调整玩法规则：先更新 `GameCore` 与 `.github/docs/Salu游戏业务说明.md`，再在 `SaluAVP` 对齐接入。

### 3D 与 ViewModels 的分工（当前不使用 Shared）

- `SaluNative/SaluAVP/`：**RealityKit + ImmersiveSpace**（所有 3D 场景构建、实体/材质/动画、沉浸输入手势都在这里）。
- `SaluNative/SaluAVP/ViewModels/`：只给 `SaluAVP` 用的 ViewModels / Session（**当前阶段统一放这里**）。
- `SaluNative/Shared/`：**当前不创建/不使用**。只有当未来需要跨 Target 复用时才引入；引入后也必须禁止 `import RealityKit`，避免把渲染实现扩散到共享层。

#### ViewModels 目录约束

`SaluNative/SaluAVP/ViewModels/` 用于存放 `SaluAVP` 专用的 ViewModels / Session（与 `GameCore` 对接的纯状态层）。

- ✅ 允许依赖 `GameCore`
- ✅ 建议保持“纯状态/纯桥接”：尽量不依赖 `RealityKit`（让状态层更容易测试/复用）

### 可复现性（Determinism）

- 影响玩法结果的随机性必须由 `seed` 驱动，并通过 `GameCore`（或明确注入的 RNG）提供。
- UI 层不得用“系统时间/系统随机数”参与战斗/地图/奖励等决策。
- UI 层可以做“表现层随机”（例如抖动动画的相位），但必须不影响任何可回放/可测试的核心结果。

## 1. 目标 App：SaluAVP（Immersive-first）

### 体验定位

- 2D Window：只做“控制面板”（入口 / seed / 存档选择 / 设置 / 历史 / 调试）。
- 3D ImmersiveSpace：主体验（承载地图/战斗/奖励等核心流程）。

### 当前基线能力（以代码为准）

- 已具备 `ControlPanel → ImmersiveSpace` 的双场景切换。
- 已具备 `地图选择 → 房间/战斗 → 结算/奖励 → 回地图` 主流程。
- 已具备战斗失败/通关的 run over 路由收束。
- 后续新增功能应在不破坏上述闭环的前提下迭代。

### 推荐目录组织（不强制，但强烈建议）

把文件拆成“控制面板”和“沉浸体验”两块，降低耦合：

```
SaluNative/SaluAVP/
├── SaluAVPApp.swift
├── AppModel.swift                 # App 级状态（路由/沉浸开关）
├── ControlPanel/                  # 2D：入口/seed/存档/设置/历史
├── ViewModels/                    # App 会话/桥接（优先不依赖 RealityKit）
└── Immersive/                     # 3D：地图/战斗/房间
```

如果未来需要跨 Target 共享（新增其它原生 Target 时）：

```
SaluNative/Shared/
├── AppRoute.swift                 # 路由/状态机
└── GameSession.swift              # 封装 RunState / BattleEngine 等（不依赖 RealityKit）
```

## 2. RealityKit / SwiftUI 编码约定

### 并发与 Actor 隔离

- SwiftUI/Observation 状态默认在主线程：`@MainActor` / `@Observable` / `@State` / `@Environment`。
- RealityKit 场景增删实体通常发生在 `RealityView { content in ... }` 的闭包里；异步加载（`Entity(named:in:)`）请用 `await`，不要阻塞主线程。
- 长耗时工作（加载资源/解析快照/生成大型几何）放到后台任务，最终以主线程更新 UI 或把结果交给 `RealityView` 更新闭包。

### 交互与命中（MVP）

- 用 `TapGesture().targetedToAnyEntity()` 或 `SpatialTapGesture()` 做点选；不要依赖屏幕坐标硬编码。
- 给可交互实体加稳定标识（推荐：`entity.name` 约定前缀，或自定义 Component），把“命中 → 业务选择”映射成纯数据事件（例如 `selectNode(id:)`）。

### 资源与内容（RealityKitContent）

- `SaluNative/Packages/RealityKitContent/` 用于承载 `.reality/.usdz/纹理/材质` 等内容资源（可从 Xcode 的 visionOS 模板演进）。
- 资源加载失败时必须有降级路径（占位几何体 + 可读错误），避免沉浸空间白屏。

## 3. 与 GameCore 对接（建议做法）

### 主流程技术基线（当前）

1. **Run 会话**
   - 使用 `RunSession` 作为 AVP 侧主流程的唯一业务会话入口（run、battle、route）。
   - `AppModel` 只承载 App 级状态（窗口/沉浸空间状态、纯表现偏好）。
2. **地图与房间**
   - `RunState.newRun(seed:)` 建立 run。
   - 节点交互通过 `enterNode` / `completeCurrentNode` 推进地图状态。
3. **战斗与奖励**
   - 战斗推进使用 `BattleEngine`（出牌/结束回合/输入分支）。
   - 战斗结束后更新 run，再进入奖励或终局路由。

> 具体架构与里程碑以 `.github/plans/Apple Vision Pro 原生 3D 实现（SaluAVP）.md` 为准。

### 业务状态建议

- App/UI 不直接散落持有 `RunState/BattleState` 的多个副本：保持一个“Source of Truth”（可放 `Shared/GameSession`）。
- UI 的输入只产出“用户选择”（节点选择、出牌索引、目标索引等），其余都交给 `GameCore` 推进。
- 优先采用“路由驱动渲染”模式：UI 根据 `RunSession.Route` 决定显示地图/房间/战斗/奖励/终局，而不是分散维护多个布尔状态。

### Seed 与可复现（补充约束）

- 允许在“用户未输入 seed”时生成默认 seed，但必须回填并展示给用户，保证可复制与可重放。
- battle seed 必须由 run seed 派生（例如通过 `SeedDerivation`），禁止直接使用系统随机数。

## 4. 构建与验证（按改动范围执行）

### visionOS 编译（必须）

当修改了 `SaluNative/**` 任意 Swift/资源/工程设置时，至少执行：

```bash
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluAVP \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build
```

## 5. 常见坑（优先规避）

- 不要把 `RealityKit` / `SwiftUI` / `SwiftData` 引入到 `Sources/`（会破坏跨平台构建与测试）。
- 沉浸空间的生命周期（open/close）要以系统回调为准：`ImmersiveView.onAppear/onDisappear` 才是可靠状态源。
- Simulator 与真机差异很大：MVP 交互必须在 Simulator 可用，再做真机增强。
