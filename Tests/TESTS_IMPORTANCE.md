## Tests 重要性分级（P0–P3）

目的：在不影响核心玩法/存档/确定性的前提下，帮助你**只删除最无关紧要的测试文件**，降低测试数量与维护成本。

### 分级标准

- **P0（强烈建议保留）**：核心业务规则/引擎关键流程/存档兼容性/确定性（determinism）。删了之后，最容易出现“功能悄悄变错但 CI 仍可能绿”的回归。
- **P1（建议保留）**：重要系统的关键边界与落盘链路；能显著降低回归概率，但通常可被更大范围测试部分覆盖。
- **P2（可考虑删除）**：偏 UX/文案/入口分支/覆盖率导向；删除风险相对低，但会降低对 UI/输出稳定性的保护。
- **P3（优先候选删除）**：高度重复/只测 trivial 行为/主要用于补覆盖率；删除对产品正确性影响最小。

> 备注：本分级**只针对“删测试文件的风险”**，不代表这些测试写得不好。

### 总览（按目录）

- **GameCoreTests**：P0=8，P1=12，P2=2，P3=6
- **GameCLITests**：P0=1，P1=4，P2=1，P3=1
- **GameCLIUITests**：P0=2，P1=5，P2=1

---

## GameCoreTests（纯逻辑层）

### P0（强烈建议保留）

- **`Tests/GameCoreTests/BattleEngineFlowTests.swift`**：回合管线/能量/洗牌/战斗结束/状态递减等最容易回归的关键逻辑。
- **`Tests/GameCoreTests/DamageAndBlockCalculatorTests.swift`**：伤害/格挡修正顺序（加法→乘法 + 向下取整），属于“确定性核心”。
- **`Tests/GameCoreTests/MapGeneratorTests.swift`**：地图生成结构约束 + 同 seed 一致性，属于 run 可复现基础。
- **`Tests/GameCoreTests/RunSnapshotCodableTests.swift`**：存档 JSON 编解码与缺字段兼容（gold 默认值），是存档生命线。
- **`Tests/GameCoreTests/RunEffectTests.swift`**：run 层 effect 的 clamp/终局/加卡/加遗物/升级等通用结算，影响事件/商店/奖励多系统。
- **`Tests/GameCoreTests/StatusDefinitionTests.swift`**：易伤/虚弱/脆弱/力量/敏捷/中毒等规则；属于数值与结算核心。
- **`Tests/GameCoreTests/CardDefinitionPlayTests.swift`**：卡牌 `play(snapshot:)` 产出的 effect 列表是否正确；能防止“数值/状态写错但能编译”的回归。
- **`Tests/GameCoreTests/RelicIntegrationTests.swift`**：遗物触发点与引擎集成（灯笼能量不被覆盖、燃烧之血胜利回血），属于细节但非常致命的回归点。

### P1（建议保留）

- **`Tests/GameCoreTests/EnemyDeterminismTests.swift`**：敌人池/敌人 AI 在同 seed 下可复现；对可测试性与回放一致性很关键。
- **`Tests/GameCoreTests/EnemyPoolAndBasicEnemiesTests.swift`**：敌人池 pick 合法、createEnemy HP 范围、多个敌人的 chooseMove 分支可达性。
- **`Tests/GameCoreTests/EntityTests.swift`**：Entity 的伤害/格挡与默认玩家创建；属于底座行为验证。
- **`Tests/GameCoreTests/EventGeneratorTests.swift`**：事件生成确定性 + 事件规则边界（范围、排除 starter/已拥有、二次选择 follow-up）。
- **`Tests/GameCoreTests/GoldRewardStrategyTests.swift`**：金币奖励范围 + 确定性（battle/elite）。
- **`Tests/GameCoreTests/RegistrySmokeTests.swift`**：关键内容点已注册（卡/敌/遗物），能避免运行期 fatalError。
- **`Tests/GameCoreTests/RelicDropStrategyTests.swift`**：遗物掉落池排除 starter/已拥有 + 确定性。
- **`Tests/GameCoreTests/RelicManagerAndRelicsTests.swift`**：RelicManager 去重/触发效果聚合 + 基础遗物触发规则。
- **`Tests/GameCoreTests/RewardGeneratorTests.swift`**：战斗后卡牌奖励生成确定性 + 去重 + 排除起始牌。
- **`Tests/GameCoreTests/RunStateDeckTests.swift`**：加卡实例 ID 规则稳定、可升级卡筛选、升级保持实例 ID。
- **`Tests/GameCoreTests/ShopInventoryTests.swift`**：商店定价与库存生成确定性、去重、排除 starter 卡。
- **`Tests/GameCoreTests/StatusContainerTests.swift`**：状态容器增减/清除规则 + `all` 输出排序确定性。

### P2（可考虑删除）

- **`Tests/GameCoreTests/BattleEventDescriptionTests.swift`**：事件 description 文案稳定性/非空；偏 UI/输出层质量（不直接影响规则正确性）。
- **`Tests/GameCoreTests/RunStateUpgradeTests.swift`**：与 `RunStateDeckTests` 有明显重叠（升级相关多处重复验证），更多是“细分单元测试冗余”。

### P3（优先候选删除）

- **`Tests/GameCoreTests/IDsTests.swift`**：强类型 ID 的 init/string literal 语法层行为，回归风险极低。
- **`Tests/GameCoreTests/RegistryRequireTests.swift`**：`require()` 基本行为测试，通常由更高层 smoke/集成路径隐式覆盖。
- **`Tests/GameCoreTests/RegistryEnumerationTests.swift`**：unknown 返回 nil + allIds 排序，偏确定性细节但价值相对低。
- **`Tests/GameCoreTests/ShopItemTests.swift`**：ShopItem equatable/init 等 trivial 行为，价值最低之一。
- **`Tests/GameCoreTests/ShopTests.swift`**：与 `ShopInventoryTests` 重叠度高（定价/去重/确定性重复验证）。
- **`Tests/GameCoreTests/StatusDefinitionDefaultImplementationTests.swift`**：协议默认实现“恒等/空数组”验证，属于很低风险的底层行为。

---

## GameCLITests（CLI 白盒/业务层）

### P0（强烈建议保留）

- **`Tests/GameCLITests/SaveServiceTests.swift`**：存档 snapshot ↔︎ restore、版本不兼容、未知卡/遗物损坏存档错误路径（非常关键）。

### P1（建议保留）

- **`Tests/GameCLITests/HistoryServiceTests.swift`**：HistoryService 缓存与失效策略，防“UI 显示旧数据”。
- **`Tests/GameCLITests/RunLogPersistenceTests.swift`**：RunLog 去 ANSI + 时间戳、FileRunLogStore 真实落盘/清除。
- **`Tests/GameCLITests/ShopRoomHandlerTests.swift`**：商店交互（买卡/删牌）能改变 runState 且可持久化。
- **`Tests/GameCLITests/ScreenAndRoomCoverageTests.swift`**：BossRoomHandler 快速胜利路径 + 写战绩；以及 History/Stats/Result 屏幕非空分支覆盖。

### P2（可考虑删除）

- **`Tests/GameCLITests/EventFormatterTests.swift`**：EventFormatter 输出覆盖与关键字断言，偏 UI 文案/格式稳定性。

### P3（优先候选删除）

- **`Tests/GameCLITests/TerminalAndLogPanelTests.swift`**：Terminal 工具方法与“不会崩溃”检查，价值较低且不直接保护玩法正确性。

---

## GameCLIUITests（端到端黑盒 CLI 测试）

### P0（强烈建议保留）

- **`Tests/GameCLIUITests/GameCLIIntegrationUITests.swift`**：主菜单/战斗/帮助/设置/真实模式 smoke 的核心可达性，能抓住“流程断了但单测仍绿”的问题。
- **`Tests/GameCLIUITests/GameCLISaveUITests.swift`**：自动存档生成 + 继续冒险加载成功提示，属于关键用户路径。

### P1（建议保留）

- **`Tests/GameCLIUITests/GameCLIRewardUITests.swift`**：战斗胜利 → 奖励界面 → 选卡 → 存档 deck 增长。
- **`Tests/GameCLIUITests/GameCLIRestUpgradeUITests.swift`**：休息点升级 → deck 替换为 `+` 卡 → 写入存档。
- **`Tests/GameCLIUITests/GameCLIEventUITests.swift`**：事件房间进入/选择选项后 run_save 出现可观察变化。
- **`Tests/GameCLIUITests/GameCLIHistoryUITests.swift`**：真实落盘 battle_history.json 且可 JSONDecoder 解码（链路：handler → service → file store）。
- **`Tests/GameCLIUITests/GameCLIRelicRewardUITests.swift`**：精英掉落遗物 → 存档 → 继续冒险遗物效果仍生效。

### P2（可考虑删除）

- **`Tests/GameCLIUITests/GameCLIArgumentUITests.swift`**：`--history`/`--stats` 早退分支（属于“入口分支稳定性”，价值中等偏低）。

### Support（不是测试，但删除会破坏 UI 测试）

- **`Tests/GameCLIUITests/Support/CLIRunner.swift`**：启动 GameCLI 子进程、收集 stdout/stderr 的基础设施（删它就等于删掉 UI tests）。
- **`Tests/GameCLIUITests/Support/String+ANSI.swift`**：用于稳定断言的 ANSI stripping（UI tests 必需）。
- **`Tests/GameCLIUITests/Support/TemporaryDirectory.swift`**：临时目录隔离真实用户数据（UI tests 必需）。

---

## 建议优先删除候选（“最无关紧要”从低到高）

如果你的目标是“只删最无关紧要”，我建议**先只动 P3**（基本不会影响核心回归保护）：

- **第一批（P3，基本无痛）**：
  - `Tests/GameCoreTests/ShopItemTests.swift`
  - `Tests/GameCoreTests/RegistryRequireTests.swift`
  - `Tests/GameCoreTests/IDsTests.swift`
  - `Tests/GameCoreTests/StatusDefinitionDefaultImplementationTests.swift`
  - `Tests/GameCoreTests/ShopTests.swift`
  - `Tests/GameCoreTests/RegistryEnumerationTests.swift`
  - `Tests/GameCLITests/TerminalAndLogPanelTests.swift`

- **第二批（P2，仍偏低风险但会少一层保障）**：
  - `Tests/GameCoreTests/BattleEventDescriptionTests.swift`
  - `Tests/GameCLITests/EventFormatterTests.swift`
  - `Tests/GameCLIUITests/GameCLIArgumentUITests.swift`
  - `Tests/GameCoreTests/RunStateUpgradeTests.swift`（建议保留 `RunStateDeckTests.swift`，删这个即可显著减冗余）

删除任意一批后，建议至少跑一次：

```bash
swift test
```


