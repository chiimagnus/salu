# OpenvisionOS 业务全局地图（business-logic）

## 产品概述
OpenvisionOS 是一个面向 visionOS 开发者与设计探索者的 3D 体验示例应用集合。目标用户是想快速学习 SwiftUI + RealityKit 场景组织方式的人。核心体验是在同一应用内打开多个独立窗口，分别浏览不同主题的 3D 模型与动效展示。技术栈为 Swift 5 + SwiftUI + RealityKit + 本地 USDZ 资产（含本地 Swift Package `RealityKitContent`）。

## 架构分层
目录结构 → 职责说明 → 依赖方向

- `OpenvisionOS/OpenvisionOSApp.swift` → 应用编排层：注册窗口与入口场景
- `OpenvisionOS/AirPodsMax/`、`OpenvisionOS/Own3DModel/`、`OpenvisionOS/NewYearFireworks/` → 场景展示层：每个模块负责一个主题场景 UI + 模型加载
- `OpenvisionOS/**/*.usdz`、`OpenvisionOS/Assets.xcassets` → 资源层：模型与视觉资源
- `Packages/RealityKitContent/` → 内容包层：作为 RealityKit 内容包与未来复用入口
- `OpenvisionOSTests/` → 测试层：预留测试入口（当前为模板）

依赖方向：

- 应用编排层 → 场景展示层
- 场景展示层 → 资源层 / RealityKit / SwiftUI
- 测试层 → 应用编排层与场景展示层（`@testable import OpenvisionOS`）

禁止（建议约束）：

- 禁止跨场景模块直接互相依赖（例如 AirPods 模块直接调用 Flower 模块实现）
- 禁止把业务流程写入资源层（资源层只放素材，不放逻辑）

## 核心业务流程

### 流程 1：用户进入并浏览 AirPods Max 动画窗口
1. 用户在系统中打开应用后，看到三个可用窗口入口（由 `OpenvisionOS/OpenvisionOSApp.swift` 注册）。
2. 用户进入 “AirPods Max” 窗口，加载 `OpenvisionOS/AirPodsMax/AirPodsMaxAnimation.swift`。
3. 视图调用 `Model3D(named: "Airpods_Max_Pink")` 查找并加载 `OpenvisionOS/AirPodsMax/Airpods_Max_Pink.usdz`。
4. 加载期间显示 `ProgressView` 占位；加载成功后显示模型。
5. `phaseAnimator` 驱动持续旋转，用户看到 3D 模型循环转动并显示底部电量装饰信息。

### 流程 2：用户浏览 Flower Pot 组合场景
1. 用户进入 “Flower Pot View” 窗口，渲染 `OpenvisionOS/Own3DModel/FlowerPotView.swift`。
2. 场景在 `ZStack` 中分层加载多个模型：`pointSparkle`、`Flower-Port`、`BgSparcle`。
3. 通过缩放与偏移控制前景点缀位置，背景模型增强空间氛围。
4. 用户最终看到前中后景叠加的组合式 3D 视觉效果。

### 流程 3：用户浏览 New Year 主题场景
1. 用户进入 “New Year Fireworks” 窗口，渲染 `OpenvisionOS/NewYearFireworks/NewYearFireworksTwentyFour.swift`。
2. 视图加载 `newYear` 模型（`OpenvisionOS/NewYearFireworks/newYear.usdz`）。
3. 场景按适配比例展示并留白，形成单主题沉浸展示页。

## 模块详情

### 模块 A：应用编排模块
- 做什么：定义应用入口与窗口结构，决定用户可访问的体验集合。
- 关键实现：通过多个 `WindowGroup` 并行注册体验，而不是单 Tab 内切。
- 相关文件：
  - `OpenvisionOS/OpenvisionOSApp.swift`
  - `OpenvisionOS/Info.plist`
- 单测：无专门单测。

### 模块 B：AirPods Max 场景模块
- 做什么：展示 AirPods 模型并持续旋转，作为动效示例。
- 关键实现：使用 `phaseAnimator + rotation3DEffect` 形成无限旋转；工具栏添加设备状态感 UI。
- 相关文件：
  - `OpenvisionOS/AirPodsMax/AirPodsMaxAnimation.swift`
  - `OpenvisionOS/AirPodsMax/Airpods_Max_Pink.usdz`
  - `OpenvisionOS/AirPodsMax/Airpods_Max.usdz`
  - `OpenvisionOS/AirPodsMax/kulaklıksketchfab.usdz`
- 单测：无专门单测。

### 模块 C：Flower Pot 场景模块
- 做什么：构建多模型叠加场景，演示组合式空间画面搭建。
- 关键实现：使用 `ZStack` 构建前后景，前景粒子点缀 + 主体花盆 + 背景闪烁层。
- 相关文件：
  - `OpenvisionOS/Own3DModel/FlowerPotView.swift`
  - `OpenvisionOS/Own3DModel/Flower-Port.usdz`
  - `OpenvisionOS/Own3DModel/pointSparkle.usdz`
  - `OpenvisionOS/Own3DModel/BgSparcle.usdz`
- 单测：无专门单测。

### 模块 D：New Year Fireworks 场景模块
- 做什么：提供节日主题场景展示页。
- 关键实现：单模型加载 + 基础缩放布局，当前不含复杂交互。
- 相关文件：
  - `OpenvisionOS/NewYearFireworks/NewYearFireworksTwentyFour.swift`
  - `OpenvisionOS/NewYearFireworks/newYear.usdz`
- 单测：无专门单测。

### 模块 E：RealityKitContent 包模块
- 做什么：提供 RealityKit 内容包与 bundle 访问点。
- 关键实现：当前仅导出 `Bundle.module`，作为后续共享资源或工具层预留。
- 相关文件：
  - `Packages/RealityKitContent/Package.swift`
  - `Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.swift`
- 单测：无。

### 模块 F：测试模块
- 做什么：承载未来自动化测试。
- 关键实现：目前仍是 Xcode 默认模板，未落地业务测试。
- 相关文件：
  - `OpenvisionOSTests/OpenvisionOSTests.swift`
- 单测：当前文件本身为模板测试入口。

## 当前状态与待办

### 已完成
- [x] 完成多窗口架构（AirPods Max、Flower Pot、New Year 三个独立窗口）
- [x] 完成三个基础 3D 场景视图与本地模型加载
- [x] 完成 AirPods 模块的持续旋转动效实现
- [x] 完成核心 USDZ 资源打包与工程资源绑定

### 进行中
- [ ] 场景工程化改造（复用组件、资源常量化、错误态展示）— 当前仍以演示代码为主，尚未抽象公共层

### 已知问题
- 缺少有效单测，场景正确性依赖手工验证
- 模型名硬编码为字符串，资源重命名有运行时风险
- 场景异常处理较弱，仅有加载占位，缺少失败态与可观测日志
- 三个场景存在重复 `Model3D` 加载模式，后续维护成本会增加

### 下一步计划
1. 建立统一模型资源索引（例如 `enum` 常量）并替换硬编码字符串
2. 抽取通用 `Model3D` 渲染容器（统一占位、错误态、缩放策略）
3. 为每个场景补最小可运行测试（至少覆盖视图可构建与关键资源可解析）
4. 增加新场景模板，验证模块化扩展路径与代码复用效果
5. 评估将窗口注册改为配置驱动，降低入口文件修改成本

## 设计决策记录

### 决策 1：采用“多 WindowGroup”而不是“单 Window + Tab”作为默认入口
- 背景：项目定位为 visionOS 多体验示例集合，需支持并行展示多个主题场景。
- 选项：
  - A. 单窗口 + Tab 切换
  - B. 多窗口（多个 `WindowGroup`）
- 决定：选 B（多窗口）。
- 原因：更贴近 visionOS 空间多窗口使用方式，也便于独立演示每个场景。

### 决策 2：采用“模块就近资源存放”，而不是“全局资源大目录”
- 背景：当前项目主要是主题化演示模块，单模块内强依赖专属模型。
- 选项：
  - A. 所有 USDZ 集中到一个全局目录
  - B. 模块目录内就近存放本模块资源
- 决定：选 B（就近存放）。
- 原因：提高可读性与迁移便利性，新增/删除场景时改动边界更清晰。

### 决策 3：优先使用 SwiftUI `Model3D` 直接渲染，而非先构建复杂 RealityKit ECS
- 背景：项目目标是快速验证视觉展示与动画效果，非复杂交互仿真。
- 选项：
  - A. 从一开始就搭建完整实体组件系统（ECS）
  - B. 先用 `Model3D` + SwiftUI 组合实现核心体验
- 决定：选 B（`Model3D` 优先）。
- 原因：实现路径更短，便于快速迭代展示；后续若交互复杂再下沉到更底层 RealityKit 架构。

## 构建与测试
- Build:
  - `xcodebuild -project OpenvisionOS.xcodeproj -scheme OpenvisionOS -configuration Debug -destination 'generic/platform=visionOS' -derivedDataPath ./.derived build`
- Test:
  - `xcodebuild -project OpenvisionOS.xcodeproj -scheme OpenvisionOS -destination 'generic/platform=visionOS Simulator' -derivedDataPath ./.derived test`
- Lint:
  - 当前未配置专门 lint 工具（如 SwiftLint）。

