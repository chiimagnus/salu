## Salu 单测风格速查（GameCoreTests / GameCLITests）

### 目标
- 用例应当是“真实断言”，优先锁定行为/事件，避免纯占位。
- 尽量保持 `swift test` 全绿；红了就最小修复到绿（允许小范围改 `Sources/` 以提升可测性）。

### 常用模式（从仓库现状提炼）
- **确定性 RNG**：显式传 `seed`，必要时用 `SeededRNG(seed:)` 复算顺序。
- **通过核心入口驱动**：例如用 `BattleEngine.startBattle()` / `handleAction(_:)` 产出状态与事件，再断言。
- **避免 I/O**：CLI 侧用 `InMemory*Store` 实现协议注入；Core 侧避免引入落盘行为。
- **stdout 比对**：需要时捕获 stdout 并去 ANSI（参考 `ScreenAndRoomCoverageTests` 的 `captureStdout` + `strippingANSICodes()`）。

### “往哪里补测试”常见落点（启发式）
- 注册表/池子可见性：`Tests/GameCoreTests/RegistrySmokeTests.swift`
- 战斗流程/回合管线：`Tests/GameCoreTests/BattleEngineFlowTests.swift`
- 核心卡牌/占卜家机制：`Tests/GameCoreTests/SeerMechanicsTests.swift`、`Tests/GameCoreTests/SeerAdvancedCardsTests.swift`
- 存档/战绩/日志（白盒）：`Tests/GameCLITests/SaveServiceTests.swift`、`Tests/GameCLITests/HistoryServiceTests.swift`、`Tests/GameCLITests/RunLogPersistenceTests.swift`
- 房间 Handler：`Tests/GameCLITests/ShopRoomHandlerTests.swift`
- 屏幕覆盖（非空分支）：`Tests/GameCLITests/ScreenAndRoomCoverageTests.swift`

