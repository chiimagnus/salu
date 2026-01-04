### Plan A：全面测试体系（Swift XCTest + CLI UI Tests）

> 目标：用 **Swift/XCTest** 覆盖 `Sources/GameCore`（白盒逻辑）与 `Sources/GameCLI`（黑盒 CLI UI + 必要的白盒服务测试），让 CI 每次都跑**全量测试**，并用覆盖率量化缺口。

---

### 总体原则（本仓库约束对齐）

- **GameCore 只做纯逻辑**：不引入 I/O / UI / `print()`；测试应尽量在 `GameCoreTests` 内完成。
- **GameCLI 是表现层**：允许 `Foundation`、I/O、stdin/stdout；测试分两层：
  - **白盒**：对 `SaveService/HistoryService` 等可注入组件做单元测试（更稳定、更快）。
  - **黑盒 UI**：用 `Process + stdin` 驱动 `GameCLI`，对 stdout/文件副作用断言（替代 sh）。
- **每条测试都写清“目的”**：每个 `XCTestCase` / `test*` 必须有中文 doc comment（为什么测、测什么回归）。
- **每完成一个优先级 P**：必须本地验证 `swift test` 全绿（CI 也应全绿）。

---

### 现状发现（用于确定优先级）

- **GameCore 覆盖率约 70%**，主要缺口在：
  - `BattleEngine` 的多分支流程（能量不足、弃牌洗牌、状态递减/过期事件、战斗结束事件等）
  - 卡牌定义 `Cards/Definitions/Ironclad/Common.swift`（Pommel/Shrug/Inflame/Clothesline）几乎没被执行
  - `BattleEvent.description`（`Sources/GameCore/Events.swift`）几乎未覆盖
- **GameCLI 覆盖率统计里几乎看不到文件**：关键原因是 `Tests/GameCLIUITests/Support/CLIRunner.swift` **优先选择 `.build/release/GameCLI`**，
  而 CI 里先 `swift build -c release`，导致 UI tests 运行的是 release binary（通常不带 coverage instrumentation），覆盖率自然缺失。

---

### P1（最高优先）：补齐 GameCore 单测（战斗引擎/卡牌/事件）

#### P1.1 卡牌定义（白盒）
- **新增** `Tests/GameCoreTests/CardDefinitionPlayTests.swift`
- **覆盖点**
  - 对所有 `CardDefinition.play(snapshot:)` 做纯函数断言：
    - `Strike/Strike+`、`Defend/Defend+`、`Bash/Bash+`
    - `PommelStrike`、`ShrugItOff`、`Inflame`、`Clothesline`
  - 断言输出 `BattleEffect` 列表与参数正确（顺序也要固定）

#### P1.2 BattleEngine 关键分支（白盒集成级单测）
- **新增** `Tests/GameCoreTests/BattleEngineFlowTests.swift`
- **覆盖点（示例）**
  - **能量不足**：能量用尽后尝试出牌 → `handleAction` 返回 `false` + 产生 `.notEnoughEnergy`
  - **非法索引**：`handIndex` 越界 → `false` + `.invalidAction(reason: "无效的卡牌索引")`
  - **弃牌洗回抽牌堆**：下一回合抽牌触发 `.shuffled(count:)`
  - **状态递减与过期事件**：`vulnerable/weak` 在回合结束递减到 0 → `.statusExpired`
  - **回合事件**：`.turnStarted/.turnEnded` 等事件链条不回归
  - **战斗结束**：击杀敌人 → `.battleWon` 且 `state.isOver == true`

#### P1.3 BattleEvent.description（白盒）
- **新增** `Tests/GameCoreTests/BattleEventDescriptionTests.swift`
- **覆盖点**
  - 对关键事件调用 `BattleEvent.description`，确保：
    - 文案稳定
    - 不会因为 Registry 缺失导致 fatalError（必要时先构造已注册的 cardId/statusId）

#### P1 验收（必须）
- 本地 `swift test` 全绿（包含 `GameCoreTests` + `GameCLIUITests`）。

---

### P2：增强 GameCLI 测试（先修覆盖率采集，再扩 UI 场景）

#### P2.1 修复 UI tests 的 binary 选择（覆盖率与一致性关键）
- **修改** `Tests/GameCLIUITests/Support/CLIRunner.swift`
- **策略**
  - 默认 **优先使用 `.build/debug/GameCLI`**（更符合测试/覆盖率）
  - 提供环境变量覆盖（例如 `SALU_CLI_BINARY_PATH`），便于本地/CI 显式指定
  - 如需验证 release 运行，可在少量 smoke tests 中显式走 release path（不影响覆盖率主流程）

#### P2.2 增加 GameCLI 白盒单测（可选但推荐）
- **新增 test target**：`GameCLITests`（依赖 `GameCLI`）
- **测试对象**
  - `SaveService`：snapshot ↔︎ restore 的一致性、版本不兼容、未知卡牌/遗物的错误
  - `HistoryService`：缓存行为、clear 后状态
  - 通过 in-memory fake store（避免真实文件 I/O），提高稳定性

#### P2.3 扩充 CLI UI tests 场景（黑盒）
- **新增/增强** `Tests/GameCLIUITests/*`
- **优先覆盖**
  - 设置菜单：进入设置、查看统计、返回、清除历史（yes/no 分支）
  - 帮助页：战斗中按 `h` → 显示帮助 → Enter 返回
  - 地图：选择节点、无效输入回退、返回主菜单 `q`
  - 休息点：回血 30% 并落盘（与存档/继续冒险串起来验证）
  - Boss 节点（至少 smoke：不挂死即可）
- 继续遵循既定折中：**90% 用 `SALU_TEST_MODE=1`** + **1~2 个 real-mode smoke**

#### P2 验收（必须）
- 本地 `swift test` 全绿。

---

### P3：覆盖率报告与 CI 量化（不是“为了好看”，而是为了持续发现缺口）

#### P3.1 生成可读的覆盖率摘要（CI log）
- 在 CI 中，在 `swift test --enable-code-coverage` 之后：
  - 输出 `llvm-cov report` 的 **TOTAL 行覆盖率/函数覆盖率**（作为 PR 可见信号）
  - 同时上传 `default.profdata` / `Salu.json` 作为 artifact

#### P3.2 覆盖率门槛（渐进式）
- 先以 “只提示不阻断” 开始（打印当前基线）
- 等 P1/P2 补齐后，再逐步加门槛（例如：`TOTAL Lines >= 80%`）

#### P3 验收（必须）
- 本地 `swift test` 全绿。
- CI 的 coverage artifact 可用、日志能看到汇总百分比。

---

### 执行顺序（强制）

1. 先做 **P1**（GameCore 单测补齐）
2. 再做 **P2.1**（修 CLIRunner binary 选择）→ 否则 coverage 始终缺 GameCLI
3. 再做 **P2.2 / P2.3**（扩 GameCLI 测试）
4. 最后做 **P3**（覆盖率报告/门槛）


