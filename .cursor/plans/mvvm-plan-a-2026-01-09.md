# Plan A（P1/P2/P3/P4/P5）：Salu 彻底分层改造（GameCore = Model + Service，GameCLI = ViewModel + View）- 2026-01-09

## 0. 目标（按你的口径）

你要的口径是：

- **GameCore**：做成 **Model + Service**（领域层：规则/状态/算法/引擎）
- **GameCLI**：做成 **ViewModel + View**（表现层：终端 UI + 输入/流程状态机）

必须遵守的项目约束（来自仓库规范）：

- **依赖方向**：`GameCLI → GameCore` ✅；`GameCore → GameCLI` ❌
- **GameCore 纯逻辑**：禁止 `print()`、禁止读取 `stdin`、禁止 UI；尽量不依赖 `Foundation`（`History.swift` 例外）
- **GameCLI 表现层**：用户可见文本中文；颜色用 `Terminal` 常量；全屏界面清屏+重绘
- **验证**：每完成一个优先级 **P**，必须能通过 `swift build`（建议同时 `swift test`）

> 说明：GameCLI 仍然需要“基础设施能力”（存档/战绩/设置/调试日志、stdin/stdout）。这些能力 **作为 ViewModel 的依赖注入**存在，不单独算一个架构层级（避免和你要的“Core=Model+Service”口径打架）。

“做得彻底”的验收口径（本 Plan A 以此为准，并兼容你未来的 SwiftUI macOS app 版本）：

- **CLI ViewModel 不做 I/O**：`Sources/GameCLI/**/ViewModels/**` 不直接读写 stdin/stdout（不调用 `readLine()/print()`，也不依赖 `ConsoleIO`）
- **CLI ViewModel 不知道 Terminal/ANSI**：`Sources/GameCLI/**/ViewModels/**` 不引用 `Terminal` 常量、不拼 ANSI 色码（颜色/格式只在 View）
- **ViewModel 事件驱动（可复用到 SwiftUI）**：ViewModel 对外暴露 `Action -> State`（或 `reduce(action:)`）接口；CLI 只是一个“驱动器”，SwiftUI 也能复用同一套 ViewModel/State
- **View 不做结算**：`Screens/Components/Terminal` 只渲染，不推进 RunState、不写存档/战绩
- **GameCore 仍然纯逻辑**：除 `History.swift` 外不新增 `Foundation` 依赖；无 `print/stdin/UI`

---

## 1. 现状盘点（已逐一阅读的关键代码）

### 1.1 已核对范围（抽取关键点）

- **结构/规范**：`Package.swift`、`.cursor/rules/GameCore模块开发规范.mdc`、`.cursor/rules/GameCLI模块开发规范.mdc`
- **GameCore（领域层）**：
  - `Battle/BattleEngine.swift`、`Battle/BattleState.swift`、`Battle/DamageCalculator.swift`
  - `Run/RunState.swift`、`Run/RunSnapshot.swift`
  - `Rewards/*`、`Events/*`、`Shop/*`、`Relics/*`
  - `CardRegistry/EnemyRegistry/StatusRegistry/...`
- **GameCLI（表现层）**：
  - `GameCLI.swift`（主菜单/设置菜单/冒险循环/战斗循环/输入解析）
  - `Flow/*`、`Rooms/Handlers/*`
  - `Screens/*`（全量）+ `Components/*` + `Terminal.swift`
  - `Persistence/*`（Save/History/Settings/RunLog 及 FileStore）

### 1.2 关键“混杂点”（迁移抓手）

- **View 直接读输入**：`RewardScreen` / `RelicRewardScreen` / `EventScreen` / `MapScreen(放弃确认)` / `NavigationBar.waitForBack` 直接 `readLine()`
- **流程控制强耦合**：`GameCLI.swift` 里有大量 static 状态（recentLogs/showLog/currentRunState 等）+ 输入解析 + 流程跳转
- **Rooms/Handlers 更像 ViewModel**：它们做“房间流程（状态机）”，但命名/目录仍按“Handler”组织，边界不够 MVVM 化

---

## 2. 目标架构定义（可执行口径）

### 2.1 GameCore = Model + Service

#### Model（领域模型：纯数据/状态/值对象）

判定规则（经验法则）：

- `*ID` / `*State` / `*Snapshot` / `*Offer` / `*Option` / `*Context` / `*Record` 多数属于 **Model**

示例映射（不要求一次性移动，但口径先统一）：

- `Kernel/IDs.swift`
- `Entity/Entity.swift`
- `Cards/Card.swift`
- `Battle/BattleState.swift`、`Battle/BattleStats.swift`
- `Map/MapNode.swift`
- `Run/RunState.swift`、`Run/RunSnapshot.swift`
- `Events/EventOffer.swift`、`Events/EventOption.swift`、`Events/EventContext.swift`
- `Shop/ShopItem.swift`、`Shop/ShopContext.swift`（偏模型）

#### Service（领域服务：纯逻辑/算法/状态机/工厂；仍然无 I/O）

判定规则：

- `*Engine` / `*Generator` / `*Strategy` / `*Calculator` / `*Manager` / `*Registry` 多数属于 **Service**

示例映射：

- `Battle/BattleEngine.swift`
- `Battle/DamageCalculator.swift`（含 BlockCalculator）
- `Map/MapGenerator.swift` / `Map/MapGenerating.swift`
- `Rewards/RewardGenerator.swift` / `Rewards/GoldRewardStrategy.swift`
- `Events/EventGenerator.swift`
- `Shop/ShopInventory.generate` / `Shop/ShopPricing.swift`
- `Relics/RelicDropStrategy.swift` / `Relics/RelicManager.swift`
- `CardRegistry` / `EnemyRegistry` / `StatusRegistry` / `RelicRegistry` / `EventRegistry`
- `createEnemy(...)` 这类工厂函数

> 注意：GameCore 的“Service”不是 I/O Service，而是 **领域服务（domain service）**；它必须继续满足 GameCore 的纯逻辑约束。

### 2.2 GameCLI = ViewModel + View

#### View（渲染层：只负责显示，不做业务决策）

- `Terminal.swift`
- `Components/*`
- `Screens/*`（建议后续可统一改名为 `Views/*`，但不是必须）

View 约束（迁移后的目标）：

- 不做结算/不写文件/不改 RunState（只展示）
- 尽量不在 View 内 `readLine()`；输入读取交给 ViewModel（P2 实现）

#### ViewModel（状态机：流程控制 + 输入解析 + 调用 GameCore Service）

ViewModel 的职责：

- 维护“当前屏幕状态（ViewState）”
- **处理 Action（事件驱动）**：UI（CLI/SwiftUI）把用户交互转换为 Action，交给 ViewModel 推进状态
- 调用 GameCore（Model+Service）推进状态
- 调用基础设施依赖（Persistence/IO）落盘或读取（注入）

建议拆分（最终形态，允许渐进达成）：

- `AppViewModel`：主菜单/设置/进入冒险/进入战斗的总协调
- `RunViewModel`：地图推进与节点选择（run loop）
- `BattleViewModel`：战斗循环 + 指令解析（play card / end turn / target）
- `Room*ViewModel`：Battle/Elite/Boss/Shop/Rest/Event 的房间流程（可复用现有 Handler 逻辑逐步迁移）

---

## 3. 迁移策略（为什么这样分 P）

- **先把 CLI 梳成 ViewModel+View（收益最大）**：目前耦合点主要在 CLI 的输入/流程与 View 混杂
- **再把 CLI 做到“彻底隔离”（可测、无 Terminal 依赖）**：把 ViewState/Renderer 体系建立起来
- **再把 Core 显式切成 Model+Service（偏组织结构 + 认知对齐）**：目录/命名/文档落地
- **最后做编译期强约束（SwiftPM targets 拆分，P5 必做收尾）**：彻底阻止跨层引用，并为未来 SwiftUI macOS app 最大化复用铺路

---

## 4. Plan A（P1 / P2 / P3 / P4 / P5）

## P1：GameCLI 引入 ViewModel 骨架（行为不变）

### P1.1 交付内容

- 新增 `AppViewModel` 作为 CLI 的 **唯一流程入口**
- `GameCLI.swift` 变成“薄入口”：只负责依赖注入 + 调用 `AppViewModel.run()`
- 把 `GameCLI.swift` 中的大量 static 状态搬到 ViewModel 实例属性（避免全局静态状态）
- 功能与文案保持不变（等价重构）

### P1.2 代码改动点（建议）

- 新增 `Sources/GameCLI/ViewModels/AppViewModel.swift`
  - 承接原 `GameCLI.swift` 的：
    - 主菜单循环
    - 设置菜单循环
    - 冒险 runLoop
    - 战斗 battleLoop（用于冒险模式与快速战斗模式）
    - unified log 追加逻辑（recentLogs/message/showLog）
- 新增 `Sources/GameCLI/ViewModels/AppDependencies.swift`（或 `AppEnvironment`）
  - 聚合注入依赖：`HistoryService` / `SaveService` / `RunLogService` / `SettingsStore`
- 修改 `Sources/GameCLI/GameCLI.swift`
  - 只保留：初始化依赖 + `AppViewModel(deps:).run()`

### P1.3 验收标准

- `swift run GameCLI` 启动后功能与当前一致：
  - 主菜单、设置、冒险、战斗、存档、战绩、日志开关均正常
- 不引入任何 GameCore 侧的 I/O 或反向依赖

### P1.4 构建验证（P1 完成后必做）

- `swift build`
- （建议）`swift build -c release`
- （建议）`swift test`

---

## P2：让 View 纯渲染（收敛输入到 CLI Driver）+ 加可测试的 IO 抽象

### P2.1 交付内容

- 引入 `ConsoleIO`（stdin/stdout 抽象）：
  - **只给 CLI 驱动器使用**（ViewModel 不依赖 ConsoleIO；为未来 SwiftUI 复用做准备）
  - 支持 `BufferedIO`，用来写 CLI 单测（避免 “交互卡死”）
- 把以下 View 内的输入读取迁移到 **CLI Driver**（Driver 读入 → 解析为 Action → 交给 ViewModel 推进状态）：
  - `RewardScreen.chooseCard`
  - `RelicRewardScreen.chooseRelic`
  - `EventScreen.chooseOption` / `chooseUpgradeableCard`
  - `MapScreen.showAbandonConfirmation`
  - `NavigationBar.waitForBack`
- View 的职责收敛为：`render(...)`（渲染）+（可选）纯函数解析（无副作用）

### P2.2 代码改动点（建议）

- 新增 `Sources/GameCLI/Services/ConsoleIO.swift`
  - `protocol InputProviding { func readLine() -> String? }`
  - `protocol OutputWriting { func write(_ text: String); func writeLine(_ text: String) }`
  - `struct StdIO: InputProviding, OutputWriting`
  - `struct BufferedIO: InputProviding, OutputWriting`（用于测试）
- 新增 CLI 驱动器（CLI 专属，负责循环读入并派发 Action）：
  - `Sources/GameCLI/CLIDriver.swift`（或 `Sources/GameCLI/Flow/CLIDriver.swift`）
  - 该 Driver：
    - 使用 `ConsoleIO` 读入字符串
    - 用 `Parsers/*` 把字符串解析为 `Action`
    - 调用 ViewModel 的 `reduce(action:)` 推进状态
    - 调用 Renderer 渲染（P3 完成后会更干净）
- 新增 `Sources/GameCLI/ViewModels/Parsers/*`
  - `BattleCommandParser` / `MapCommandParser` 等，统一输入解析规则
- 修改 `Screens/*` 与 `Components/NavigationBar.swift`
  - 移除 `while true { readLine() ... }` 这类循环
  - 改为只渲染 UI（由 CLI Driver 循环读取输入并派发 Action）
- 开始补测试（建议从 P2 起必须落地）：
  - 新增 `Tests/GameCLITests/` 并创建最小测试：
    - EOF 下的奖励/事件/遗物选择不会 hang
    - battle 指令解析（例如 `0` / `1` / `1 2`）的基本路径可被驱动

### P2.3 验收标准

- CLI 行为不变，且管道输入/EOF 情况下不 hang（对 UI 测试很关键）
- 可以用 `BufferedIO` 驱动 ViewModel 做单测（至少 2~3 条）

### P2.4 构建验证（P2 完成后必做）

- `swift build`
- `swift test`

---

## P3：彻底 “ViewModel + View” —— ViewModel 不依赖 Terminal/Screens（ViewState + Renderer）

### P3.1 交付内容

- **ViewModel 彻底纯逻辑化（表现层逻辑）**：
  - ViewModel 内不出现 `readLine()/print()`
  - ViewModel 内不引用 `Terminal`、不拼 ANSI
- **兼容未来 SwiftUI macOS app**：
  - ViewModel 的核心接口为 `reduce(action:)`（事件驱动）
  - ViewState 不包含任何 CLI 专属内容（不含 ANSI/Terminal/IO 句柄）
- 建立统一的 “ViewState → View 渲染” 协议：
  - ViewModel 产出 `ScreenState`（或各 Screen 的 `*ViewState`）
  - View 层实现 `Renderer`（一个入口渲染当前 Screen）
- 日志与消息结构化：
  - ViewModel 维护 `[LogEntry]`（只含中文纯文本 + level）
  - View 决定颜色/格式（Terminal）
  - `RunLogService` 落盘写纯文本（可直接用 `LogEntry.plainText`）
- 房间流程目录/命名对齐（做到“真·ViewModel”）：
  - `Rooms/Handlers/*` 迁移/重命名为 `ViewModels/Rooms/*`（或至少类型名改为 `*RoomViewModel`）

### P3.2 代码改动点（建议）

- 新增 CLI “表现层模型”（用于 View 渲染，但不属于 GameCore）：
  - `Sources/GameCLI/Models/ScreenState.swift`（enum：mainMenu/map/battle/shop/event/…）
  - `Sources/GameCLI/Models/LogEntry.swift`（level + plainText + timestamp?）
  - `Sources/GameCLI/Models/ViewState/*`（逐屏拆：`BattleViewState`、`MapViewState`…）
- 新增 View 渲染器：
  - `Sources/GameCLI/Views/CLIRenderer.swift`（实现 `render(screen:)`，内部调用现有 `Screens/*` 或逐步替换）
  - （过渡期）允许 `Screens/*` 继续存在，但只接受 `ViewState` 输入，不持有业务依赖
- 重构 ViewModel 与房间系统：
  - `RoomHandling` 逐步演进为 `RoomViewModeling`（或保留协议名但把实现移动到 ViewModels）
  - ViewModel 调用 GameCore Service 推进状态，产出新的 `ScreenState`
- 增加“硬验收检查”（实现阶段每次合并都跑）：
  - `rg "readLine\\(" Sources/GameCLI` 只能命中 `Services/ConsoleIO.swift` 与 tests
  - `rg "\\bTerminal\\b" Sources/GameCLI/**/ViewModels` 结果必须为空
  - `rg "\\bprint\\(" Sources/GameCLI/**/ViewModels` 结果必须为空

### P3.3 验收标准

- 通过上述 3 条 `rg` 硬检查
- CLI 行为不变：战斗/地图/事件/商店/休息流程正常
- 日志仍可彩色显示，但彩色逻辑仅在 View

### P3.4 构建验证（P3 完成后必做）

- `swift build`
- `swift test`
- （建议）`swift build -c release`

---

## P4：GameCore 显式整理为 Model/Service（目录 + 命名 + 文档）

### P4.1 交付内容

- 在 **不破坏现有领域分组**的前提下，显式落地 `Model`/`Service`：
  - 推荐做法：每个领域目录下再拆 `Models/` 与 `Services/`
    - 例：`Battle/Models/BattleState.swift`、`Battle/Services/BattleEngine.swift`
- 增加一份 “Model vs Service 判定规则与清单” 的文档（建议放 `Sources/GameCore/ARCHITECTURE.md`）
- 同步更新 `.cursor/rules/GameCore模块开发规范.mdc`，避免新贡献者继续把模型/服务混在一起

### P4.2 迁移批次（建议分批移动，降低 churn）

> 每一批做完都要 `swift build`，确认无问题再继续下一批。

**批次 1：Battle**

- Model：`BattleState.swift`、`BattleStats.swift`
- Service：`BattleEngine.swift`、`DamageCalculator.swift`

**批次 2：Run / Map / Rewards**

- Model：`RunState.swift`、`RunSnapshot.swift`、`MapNode.swift`
- Service：`MapGenerator.swift`、`RewardGenerator.swift`、`GoldRewardStrategy.swift`

**批次 3：Events / Shop / Relics / Registries**

- Model：`EventOffer/EventOption/EventContext`、`ShopItem/ShopContext` 等
- Service：`EventGenerator`、`ShopPricing`、`RelicDropStrategy`、`*Registry`、工厂函数（如 `createEnemy`）

### P4.3 验收标准

- 从目录结构即可快速看出：哪些是 Model、哪些是 Service
- GameCore 仍然满足纯逻辑约束（无 print/stdin/UI；无新增 Foundation 依赖）
- 行为不变（只是结构整理）

### P4.4 构建验证（P4 每批次都要做）

- `swift build`
- （建议）`swift test`
- （建议）`swift build -c release`

---

---

## P5（必做）：SwiftPM targets 拆分（编译期强约束分层，为 SwiftUI macOS app 复用做准备）

> 目标：让“CLI 只能是 ViewModel+View”“Core 只能是 Model+Service”不仅靠约定，还能被编译器强制。

### P5.1 交付内容

- SwiftPM 拆 target，使跨层引用在编译期就报错（例如 ViewModel 不能 import View，Model 不能 import Service）
- 更新测试 target 依赖关系
- 把“可复用的 App 层（ViewModel + ViewState）”沉淀为独立 target（CLI 与未来 macOS app **共同依赖同一套状态机/用例**）
- 把“可复用的持久化能力（Save/History/Settings/RunLog 的文件实现）”沉淀为独立 target，供 CLI 与未来 macOS app 共享（最大化复用）

### P5.2 推荐的 target 拆分（建议落地形态）

- `GameCoreModel`：只放领域 Model（IDs/State/Snapshot/Offer/Context/Record/Entity/Card…）
- `GameCoreServices`：领域 Service（Engine/Generator/Strategy/Calculator/Registry/Factory…），依赖 `GameCoreModel`
- `SaluPersistence`：可复用持久化（Save/History/Settings/RunLog + FileStores），依赖 `GameCoreModel` + `GameCoreServices`
- `SaluApp`（或 `GameApp`）：所有 ViewModel + ViewState/LogEntry（UI 无关），依赖 `GameCoreServices`（通过协议注入 persistence；不依赖 CLI/终端）
- `SaluCLIViews`：Terminal/Components/Screens/Renderer（CLI View），依赖 `SaluApp`
- `SaluCLI`（executable）：`@main` + `ConsoleIO` + `CLIDriver`（CLI 专属输入循环），依赖 `SaluCLIViews` + `SaluPersistence`

（未来新增，不在本次实现范围内）：

- `SaluMacApp`（SwiftUI macOS app）：依赖 `SaluApp` + `SaluPersistence` + `GameCoreServices`（实现 SwiftUI View，并复用同一套状态机/用例）

> 备注：当前仓库只有 `Sources/GameCore/` 与 `Sources/GameCLI/` 两个目录。做 P5 需要**新增多个 Sources 子目录并迁移文件**，因此放在最后。

### P5.3 验收标准

- 任何“跨层调用”会在编译期失败（例如 ViewModel 里引用 `Terminal` 会直接编译不过）
- `swift build` / `swift test` 仍然通过

### P5.4 构建验证（P5 完成后必做）

- `swift build`
- `swift test`
- （建议）`swift build -c release`

---

## 6. 风险与规避

- **SwiftPM basename 唯一性**：新增文件必须避免同名（已在仓库规范中强调）；P3 移动文件不会引入该问题，但新增文件要注意命名。
- **CLI 交互容易卡死**：P2 必须引入 IO 抽象 + EOF 测试，避免 `readLine()` 在 UI 测试/管道模式挂住。
- **大规模移动造成 review 困难**：P4 分批移动，每批都 build；必要时一个 PR 只做一批。
- **targets 拆分改动巨大**：P5 涉及文件迁移与 `Package.swift` 重构，务必在前面 P1~P4 稳定后再做，并保持每一步都可 build。


