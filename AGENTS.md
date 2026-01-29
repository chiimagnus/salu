# 仓库指南

Salu 是一个跨平台（macOS/Linux/Windows）的回合制卡牌战斗游戏，基于 Swift Package Manager（Swift 6.2+）。贡献代码前请按本次改动范围跑通对应的构建与测试，并按模块规范修改对应目录下的代码。

## 项目结构与模块组织

- `Sources/GameCore/`：纯逻辑层（规则/状态/战斗/卡牌/敌人/地图/存档快照模型）。禁止 I/O、禁止 UI；详细约束见 `Sources/GameCore/AGENTS.md`。
- `Sources/GameCLI/`：CLI/TUI 表现层（终端渲染/输入/房间流程/持久化落盘）。详细约束见 `Sources/GameCLI/AGENTS.md`。
- `SaluNative/`：原生 App（Xcode 管理，依赖 `GameCore`，不依赖 `GameCLI`）
  - `SaluNative/SaluCRH/`：macOS App（2D SwiftUI，可选/不阻塞）
  - `SaluNative/SaluAVP/`：Apple Vision Pro（visionOS）App（原生 3D：ImmersiveSpace + RealityKit，主线）
  - （可选）`SaluNative/Shared/`：跨 Target 共享的状态机/桥接层（禁止引入 RealityKit）
- `Tests/`：`GameCoreTests`、`GameCLITests`、`GameCLIUITests`。
- `.giithub/docs/`：设定、剧情与玩法规则说明（写内容/做 UI 时优先对齐这里）。
- `.giithub/plans/`：技术方案与执行计划。

## 构建、测试和开发命令

### SwiftPM（CLI 版本 / 跨平台）

```bash
swift build          # 编译
swift test           # 跑全部测试
swift run            # 本地运行（GameCLI）

# 说明：
# - 修改了 `Sources/**/*.swift` 或 `Package.swift`：需要跑 `swift test`
# - 仅修改 `SaluNative/`（原生 App）：优先跑 `xcodebuild ... build`，可不跑 `swift test`
# - 仅修改文档/CI 配置：通常可跳过构建与测试（但建议至少保证相关命令不明显失效）
```

### Xcode（原生 App：macOS / visionOS）

```bash
# 或直接双击 SaluNative/SaluNative.xcodeproj
open SaluNative/SaluNative.xcodeproj

# 命令行编译（macOS）
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluCRH \
  -destination 'platform=macOS' \
  build

# 命令行编译（visionOS Simulator）
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluAVP \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build
```

## 本地存储与配置

- 本地存储默认位置与文件结构见 `.giithub/docs/本地存储说明.md`（run 存档、战斗历史、设置、调试日志）。
- 需要隔离数据（测试/调试/复现 bug）时，优先用环境变量覆盖数据目录：`SALU_DATA_DIR=/tmp/salu-test`。
- 复现战斗/地图行为时建议固定随机种子：`swift run GameCLI --seed 1`（也可用 `--seed=1`）。

## 代码风格与命名规范

- 遵循 Swift 6 并发与 `Sendable` 约束，避免全局可变状态与不可复现的随机源。
- 内容扩展优先走 `Definition + Registry`（卡牌/状态/敌人/遗物等），避免在引擎里新增 `switch` 分支。
- 命名保持可读：类型用 UpperCamelCase，方法/属性用 lowerCamelCase；新增文件避免 basename 重名（SwiftPM 会报 multiple producers）。

## 测试指南

- 逻辑改动优先补 `Tests/GameCoreTests/` 单元测试；CLI 的 I/O 相关逻辑优先补 `Tests/GameCLITests/`（可注入组件做断言）。
- 需要覆盖到完整交互流程时再用 `GameCLIUITests`（通过 `Process` 黑盒运行可执行文件，配合 `SALU_TEST_MODE`）。
- 尽量让测试可复现：不要直接依赖系统随机数/时间；需要随机行为时使用注入 RNG（见 `GameCore` 约束）。

```bash
swift test --filter GameCoreTests
swift test --filter GameCLITests
```

## 开发流程建议

- 修改前先定位模块边界：规则与状态放 `GameCore`，文件读写与终端渲染放 `GameCLI`（避免反向依赖）。
- 提交前按影响范围验证：修改 `Sources/**/*.swift` 或 `Package.swift` 时至少跑一次 `swift test`；仅改 `SaluNative/` 时至少跑一次 `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluCRH -destination 'platform=macOS' build`。
- 文档/剧情/玩法规则的变更优先同步到 `.giithub/docs/`，并在 PR 描述里注明对应章节。

## 提交与 Pull Request 规范

- Commit message 建议采用 `feat:` / `fix:` / `refactor:` 等前缀，单次提交聚焦一个主题。
- PR 描述需包含：做了什么、为什么、如何验证（附上运行过的命令）；涉及 CLI 界面时建议附截图/录屏。
