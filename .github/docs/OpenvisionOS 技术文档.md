# OpenvisionOS 技术文档

## 1. 项目定位与范围

OpenvisionOS 是一个 visionOS 示例应用集合，使用 SwiftUI + RealityKit 展示多个 3D 交互/展示场景。当前版本以多窗口方式暴露 3 个独立体验：

- AirPods Max 模型展示与持续旋转动画
- Flower Pot 组合场景（前景模型 + 背景粒子效果）
- New Year Fireworks 新年主题模型展示

该项目定位为「视觉/动效演示工程」，不是完整商业应用；重点在于空间内容展示、模型资源组织、以及 SwiftUI 与 `Model3D` 的集成方式。

## 2. 技术栈与运行环境

- 语言：Swift 5
- UI：SwiftUI
- 3D 渲染：RealityKit（通过 `Model3D` 加载本地 USDZ 资源）
- 资源包：本地 Swift Package `RealityKitContent`
- 目标平台：`xros`、`xrsimulator`（visionOS）
- 最低部署：visionOS 1.0（`XROS_DEPLOYMENT_TARGET = 1.0`）

## 3. 工程结构

### 3.1 顶层目录

- `OpenvisionOS/`：主应用源码与资源
- `OpenvisionOSTests/`：单元测试 target（当前为模板）
- `Packages/RealityKitContent/`：本地 Swift Package（RealityKit 内容包）
- `OpenvisionOS.xcodeproj/`：Xcode 工程配置
- `Img/`：README 展示用 GIF 资源

### 3.2 应用层结构

`OpenvisionOS/` 下核心结构：

- `OpenvisionOSApp.swift`：应用入口，声明多个 `WindowGroup`
- `AirPodsMax/`：AirPods Max 场景与模型资源
- `Own3DModel/`：Flower Pot 场景与模型资源
- `NewYearFireworks/`：新年场景与模型资源
- `Assets.xcassets/`：图标与通用视觉资源
- `Info.plist`：应用基础配置（多场景支持）

## 4. 应用启动与场景生命周期

### 4.1 启动入口

`OpenvisionOS/OpenvisionOSApp.swift` 通过 `@main` 声明应用入口，并在 `body` 中注册三个 `WindowGroup`：

- `WindowGroup("AirPods Max")` -> `AirPodsMaxAnimation`
- `WindowGroup("Flower Pot View")` -> `FlowerPotView`
- `WindowGroup("New Year Fireworks")` -> `NewYearFireworksTwentyFour`

这意味着系统可将三个体验作为独立窗口管理，符合 visionOS 的多窗口体验模式。

### 4.2 多场景支持

`OpenvisionOS/Info.plist` 中配置：

- `UIApplicationSupportsMultipleScenes = YES`

确保应用可同时托管多个场景实例，与入口中的多 `WindowGroup` 设计一致。

## 5. 关键模块实现解析

### 5.1 AirPods Max 动画模块

文件：`OpenvisionOS/AirPodsMax/AirPodsMaxAnimation.swift`

核心逻辑：

1. 使用 `Model3D(named: "Airpods_Max_Pink")` 加载 USDZ 模型
2. 通过 `.resizable()` + `.aspectRatio(contentMode: .fit)` 控制模型布局
3. 使用 `.phaseAnimator([false, true])` 驱动旋转状态
4. 在动画块中通过 `.rotation3DEffect(... axis: y)` 进行 Y 轴连续旋转
5. 动画参数为 `.linear(duration: 5).repeatForever(autoreverses: false)`，形成持续自转
6. 底部工具栏使用 `bottomOrnament` 展示电量图标与文本（UI 装饰信息）

设计特点：

- UI 与 3D 渲染耦合度低，逻辑简单，便于演示动效 API
- 动画由视图层直接驱动，没有额外状态管理器

### 5.2 Flower Pot 组合场景模块

文件：`OpenvisionOS/Own3DModel/FlowerPotView.swift`

核心逻辑：

1. 以 `ZStack` 构建前后景层次
2. 前景 `VStack` 先渲染 `pointSparkle`，再渲染 `Flower-Port`
3. `pointSparkle` 通过缩放与偏移形成高光/粒子点缀
4. 背景层单独渲染 `BgSparcle` 模型以增强空间氛围

设计特点：

- 通过多个独立 USDZ 叠加构建视觉合成，而不是单一大模型
- 布局主要依赖 SwiftUI 变换（`scaleEffect`/`offset`），开发成本低

### 5.3 New Year Fireworks 模块

文件：`OpenvisionOS/NewYearFireworks/NewYearFireworksTwentyFour.swift`

核心逻辑：

1. 使用 `NavigationStack` 承载界面容器
2. 加载 `newYear` 模型并应用基础显示参数（fit/scale/padding）
3. 提供 `ProgressView` 作为模型加载占位

设计特点：

- 模块职责单一，便于扩展节日主题场景
- 当前尚未加入交互与时序动画逻辑

## 6. 资源管理策略

### 6.1 USDZ 资源组织

- AirPods 模型：`OpenvisionOS/AirPodsMax/*.usdz`
- Flower Pot 模型：`OpenvisionOS/Own3DModel/*.usdz`
- New Year 模型：`OpenvisionOS/NewYearFireworks/newYear.usdz`

资源按功能模块同目录放置，降低查找成本，符合「场景与资产共置」策略。

### 6.2 构建打包

`OpenvisionOS.xcodeproj/project.pbxproj` 中，所有相关 USDZ 资源都加入 `Resources` build phase，确保运行期可被 `Model3D(named:)` 直接按名称加载。

### 6.3 Package 角色

`Packages/RealityKitContent/` 当前只暴露 `realityKitContentBundle`，未被主逻辑深度使用，主要作为模板遗留的内容包与未来扩展预留位。

## 7. 依赖关系与约束

### 7.1 依赖关系

- 视图模块依赖：`SwiftUI`、`RealityKit`、`RealityKitContent`
- 业务层/服务层：当前未引入（项目尚未分层）
- 测试 target 依赖主应用 target（`@testable import OpenvisionOS`）

### 7.2 架构约束（现状）

- 当前代码以视图直连模型资源为主，不经过中间抽象层
- 场景间没有共享状态，不存在跨模块通信复杂度
- 可维护性优点：简单、直接；缺点：扩展后可能出现重复逻辑

## 8. 构建、运行与测试

## 8.1 构建命令

```bash
xcodebuild -project OpenvisionOS.xcodeproj -scheme OpenvisionOS -configuration Debug -destination 'generic/platform=visionOS' -derivedDataPath ./.derived build
```

说明：使用本地 `-derivedDataPath` 可避免默认目录权限问题。

## 8.2 测试命令

```bash
xcodebuild -project OpenvisionOS.xcodeproj -scheme OpenvisionOS -destination 'generic/platform=visionOS Simulator' -derivedDataPath ./.derived test
```

## 8.3 当前测试状态

- `OpenvisionOSTests/OpenvisionOSTests.swift` 为 Xcode 默认模板
- 尚未覆盖任何场景加载、资源可用性、UI 渲染或动画行为验证

## 9. 已知技术风险与改进建议

### 9.1 主要风险

1. `Model3D(named:)` 依赖字符串资源名，重命名资源易引入运行时加载失败
2. 场景内错误处理能力弱（占位视图固定为 `ProgressView`，无失败态展示）
3. 缺少自动化测试，回归依赖手工运行
4. 动画参数硬编码，后续批量调整成本较高

### 9.2 建议改进

1. 引入集中化资源常量（如 `enum ModelAsset`）减少硬编码
2. 增加加载失败降级视图与日志
3. 为每个场景增加最小快照测试或 UI 可见性断言
4. 提炼通用 `Model3D` 容器组件，统一 placeholder、缩放策略与装饰样式

## 10. 扩展路线（技术视角）

### 10.1 短期（低成本）

- 新增第 4 个场景模块，验证模块化目录扩展性
- 将 `NavigationStack` 与标题/工具栏策略统一成可复用模板

### 10.2 中期（结构优化）

- 引入 `ViewModel` 层承载场景配置数据（标题、资源名、动画参数）
- 将窗口注册改造成配置驱动（减少 `OpenvisionOSApp` 内硬编码）

### 10.3 长期（产品化）

- 引入交互手势、空间锚点、动态材质与音频反馈
- 结合性能分析（帧率/内存）制定多模型场景预算

## 11. 文件清单（源码）

- `OpenvisionOS/OpenvisionOSApp.swift`
- `OpenvisionOS/AirPodsMax/AirPodsMaxAnimation.swift`
- `OpenvisionOS/Own3DModel/FlowerPotView.swift`
- `OpenvisionOS/NewYearFireworks/NewYearFireworksTwentyFour.swift`
- `OpenvisionOS/Info.plist`
- `OpenvisionOSTests/OpenvisionOSTests.swift`
- `Packages/RealityKitContent/Package.swift`
- `Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.swift`
- `OpenvisionOS.xcodeproj/project.pbxproj`

