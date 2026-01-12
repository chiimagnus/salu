# GameCLI / GameCore 目录树梳理与重构计划（2026-01-12）

目标：
- 让 `Sources/GameCLI` 与 `Sources/GameCore` 的目录结构“可读、可找、可扩展”，并与现有规范（`.cursor/rules/GameCLI模块开发规范.mdc`、`.cursor/rules/GameCore模块开发规范.mdc`）一致。
- 先做低风险的“命名/文件布局整理”，再做中风险的“拆文件/抽流程”，最后才考虑结构性更强的重构。
- **每完成一个 Phase（优先级 P）必须 `swift test` 通过**，再进入下一 Phase。

---

## 现状目录树（基于 `find`）

### GameCLI

```
Sources/GameCLI
├── GameCLI.swift
├── Screens.swift
├── Terminal.swift
├── TestMode.swift
├── Components/
│   ├── EventFormatter.swift
│   ├── NavigationBar.swift
│   └── String+ANSI.swift
├── Flow/
│   ├── RoomHandling.swift
│   └── RoomHandlerRegistry.swift
├── Persistence/
│   ├── FileBattleHistoryStore.swift
│   ├── FileRunLogStore.swift
│   ├── FileRunSaveStore.swift
│   ├── HistoryService.swift
│   ├── RunLogService.swift
│   ├── RunLogStore.swift
│   ├── SaveService.swift
│   └── SettingsStore.swift
├── Rooms/
│   └── Handlers/
│       ├── BattleRoomHandler.swift
│       ├── BossRoomHandler.swift
│       ├── EliteRoomHandler.swift
│       ├── EventRoomHandler.swift
│       ├── RestRoomHandler.swift
│       ├── ShopRoomHandler.swift
│       └── StartRoomHandler.swift
└── Screens/
    ├── BattleScreen.swift
    ├── ChapterEndScreen.swift
    ├── EventScreen.swift
    ├── HelpScreen.swift
    ├── HistoryScreen.swift
    ├── MainMenuScreen.swift
    ├── MapScreen.swift
    ├── PrologueScreen.swift
    ├── RelicRewardScreen.swift
    ├── ResourceScreen.swift
    ├── ResultScreen.swift
    ├── RewardScreen.swift
    ├── SettingsScreen.swift
    ├── ShopScreen.swift
    └── StatisticsScreen.swift
```

### GameCore

```
Sources/GameCore
├── Actions.swift
├── Events.swift
├── History.swift
├── RNG.swift
├── Battle/
│   ├── BattleEngine.swift
│   ├── BattleState.swift
│   ├── BattleStats.swift
│   └── DamageCalculator.swift
├── Cards/
│   ├── Card.swift
│   ├── CardDefinition.swift
│   ├── CardRegistry.swift
│   ├── StarterDeck.swift
│   └── Definitions/
│       ├── Basic/
│       │   ├── CommonCards.swift
│       │   └── StarterCards.swift
│       └── Seer/
│           └── SeerCards.swift
├── Consumables/
│   ├── ConsumableDefinition.swift
│   ├── ConsumableRegistry.swift
│   └── Definitions/
│       ├── CommonConsumables.swift
│       └── SeerConsumables.swift
├── Enemies/
│   ├── Act1EnemyPool.swift
│   ├── Act1EncounterPool.swift
│   ├── Act2EnemyPool.swift
│   ├── Act2EncounterPool.swift
│   ├── Act3EnemyPool.swift
│   ├── Act3EncounterPool.swift
│   ├── EnemyDefinition.swift
│   ├── EnemyMove.swift
│   ├── EnemyRegistry.swift
│   ├── RewrittenIntent.swift
│   └── Definitions/
│       ├── Act1/
│       │   ├── Act1BossEnemies.swift
│       │   ├── Act1EliteEnemies.swift
│       │   └── Act1NormalEnemies.swift
│       ├── Act2/
│       │   ├── Act2BossEnemies.swift
│       │   ├── Act2EliteEnemies.swift
│       │   └── Act2NormalEnemies.swift
│       └── Act3/
│           ├── Act3BossEnemies.swift
│           ├── Act3EliteEnemies.swift
│           └── Act3NormalEnemies.swift
├── Entity/
│   └── Entity.swift
├── Events/
│   ├── EventContext.swift
│   ├── EventDefinition.swift
│   ├── EventFollowUp.swift
│   ├── EventGenerator.swift
│   ├── EventOffer.swift
│   ├── EventOption.swift
│   ├── EventRegistry.swift
│   └── Definitions/
│       ├── BasicEvents.swift
│       ├── RestPointDialogues.swift
│       └── SeerEvents.swift
├── Kernel/
│   ├── BattleEffect.swift
│   ├── BattleTrigger.swift
│   └── IDs.swift
├── Map/
│   ├── MapGenerating.swift
│   ├── MapGenerator.swift
│   ├── MapNode.swift
│   └── RoomType.swift
├── Persistence/
│   ├── BattleHistoryStore.swift
│   └── RunSaveStore.swift
├── Relics/
│   ├── RelicDefinition.swift
│   ├── RelicDropStrategy.swift
│   ├── RelicManager.swift
│   ├── RelicPool.swift
│   ├── RelicRegistry.swift
│   └── Definitions/
│       ├── BossRelics.swift
│       ├── CommonRelics.swift
│       ├── RareRelics.swift
│       ├── SeerRelics.swift
│       ├── StarterRelics.swift
│       └── UncommonRelics.swift
├── Rewards/
│   ├── CardPool.swift
│   ├── CardRewardOffer.swift
│   ├── GoldRewardStrategy.swift
│   ├── RewardContext.swift
│   └── RewardGenerator.swift
├── Run/
│   ├── ChapterText.swift
│   ├── RunEffect.swift
│   ├── RunSaveVersion.swift
│   ├── RunSnapshot.swift
│   └── RunState.swift
├── Shop/
│   ├── ShopContext.swift
│   ├── ShopInventory.swift
│   ├── ShopItem.swift
│   └── ShopPricing.swift
└── Status/
    ├── StatusContainer.swift
    ├── StatusDefinition.swift
    ├── StatusRegistry.swift
    └── Definitions/
        ├── Buffs.swift
        └── Debuffs.swift
```

---

## 主要“混乱感”来源（按影响排序）

1. **同名“文件 vs 目录”的视觉歧义**（不影响编译，但影响导航/沟通）
   - `Sources/GameCLI/Screens.swift` vs `Sources/GameCLI/Screens/`
   - `Sources/GameCore/Events.swift` vs `Sources/GameCore/Events/`
2. **可疑的仓库污染文件**
   - `Sources/GameCLI/.DS_Store`、`.cursor/.DS_Store`（应从 git 中移除并加入 `.gitignore`）
3. **超大文件导致“入口聚集效应”**（会放大“乱”的体验）
   - `Sources/GameCLI/GameCLI.swift` 约 589 行
   - `Sources/GameCLI/Screens/MapScreen.swift` 约 378 行
   - `Sources/GameCore/Battle/BattleEngine.swift` 约 1039 行

---

## Phase 1（P1）：卫生与零风险目录清爽化【不做❌】

目标：不改变任何类型名/对外 API，仅做“仓库卫生 + 文件名可读性”相关的整理，确保后续重构地基稳定。

任务清单：
- 移除仓库内所有 `.DS_Store`（包含但不限于 `Sources/GameCLI/.DS_Store`、`.cursor/.DS_Store`）。
- 在根目录 `.gitignore` 增加对 `.DS_Store` 的忽略（若已有则确认覆盖）。
- （可选）补充一个 `scripts/dev/tree.sh` 或类似脚本，用于以后生成稳定 tree（不强制；若仓库倾向保持纯 Swift，可不做）。

验收：
- `git status` 干净（仅预期变更）。
- 运行 `swift test` 通过。

---

## Phase 2（P2）：消除“文件/目录同名”歧义（低风险）

目标：只改**文件名（filename）**，不改类型名（type）与符号引用；从而减少“我到底在说哪个 Screens/Events”的沟通成本。

建议改动：
- GameCLI：
  - 将 `Sources/GameCLI/Screens.swift` 重命名为 `Sources/GameCLI/ScreensFacade.swift`（或 `ScreenRouter.swift`）。
  - 说明：保留 `enum Screens` 类型名不变，避免全仓引用替换。
- GameCore：
  - 将 `Sources/GameCore/Events.swift` 重命名为 `Sources/GameCore/BattleEvents.swift`。
  - （可选）将 `Sources/GameCore/History.swift` 重命名为 `Sources/GameCore/BattleHistory.swift`（如果团队内部经常把它与“事件历史/日志”混淆）。

验收：
- `swift test` 通过。

---

## Phase 3（P3）：拆分超大入口文件（中风险，但收益高）

目标：降低“一个文件塞所有流程”的聚集效应，让目录结构本身更像“地图”，而不是“单点入口”。

建议改动（优先做 GameCLI，再做 GameCore）：

### P3.1 拆 `GameCLI.swift`
- 保持 `@main struct GameCLI` 不变。
- 将逻辑用 `extension GameCLI` 拆到多个文件（不需要引入新目录也能达标）：
  - `Sources/GameCLI/GameCLI+MainMenu.swift`：`mainMenuLoop()`、`settingsMenuLoop()` 等
  - `Sources/GameCLI/GameCLI+RunLoop.swift`：`startNewRun()`、`continueRun()`、`runLoop()` 等
  - `Sources/GameCLI/GameCLI+Logging.swift`：recentLogs/currentMessage/showLog 等日志相关
  - `Sources/GameCLI/GameCLI+DI.swift`：History/Save/RunLog/Settings 的组装

验收：
- `swift test` 通过。

### P3.2 拆 `MapScreen.swift`
- 按职责拆：
  - Map 主界面渲染
  - Rest/Upgrade 子流程
  - 日志面板渲染（如果存在）

验收：
- `swift test` 通过。

### P3.3（可选）拆 `BattleEngine.swift`
- 这是最大文件，收益高但风险也最高；建议在更后面、并配合现有 `GameCoreTests` 的覆盖来做。
- 拆分方向示例：
  - `BattleEngine+TurnFlow.swift`
  - `BattleEngine+ApplyEffect.swift`
  - `BattleEngine+EnemyAI.swift`
  - `BattleEngine+Events.swift`（仅内部 helper，不与 `BattleEvent` 混淆）

验收：
- `swift test` 通过（必要时先跑 `swift test --filter GameCoreTests` 再全量）。

---

## Phase 4（P4）：目录语义增强（可选，较高风险）

目标：当团队已经对代码边界有共识时，再把“文件拆分的结果”沉淀成更清晰的子目录。

示例（仅当大家认同再做）：
- `Sources/GameCLI/App/`：入口/启动/依赖注入
- `Sources/GameCLI/Flow/`：房间与跨屏流程（保留现有）
- `Sources/GameCLI/Screens/`：纯 UI
- `Sources/GameCLI/Services/`：History/Save/RunLog（当前在 Persistence 下，若觉得偏业务服务可调整命名）

注意：目录移动会让 git diff 很大，建议在完成 P3 拆文件后再做，并确保每一步可 `swift test`。

验收：
- `swift test` 通过。

---

## 执行顺序建议

- 先做 P1（卫生/忽略文件）→ 立刻 `swift test`
- 再做 P2（filename 重命名，消除歧义）→ `swift test`
- 再做 P3（拆大文件）→ 每拆完一组就 `swift test`
- P4 仅在团队确认“目录命名约定”后执行
