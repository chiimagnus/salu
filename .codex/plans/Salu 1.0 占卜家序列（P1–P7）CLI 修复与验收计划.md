# Salu 1.0 占卜家序列（P1–P7）CLI 修复与验收计划

> 目标：把 `.codex/docs/Salu 1.0 占卜家序列（P1–P7）UI 测试核对清单.md` 中的验收点，落到 **CLI 可见、可交互、可复现、可测试** 的实现与工具链上。
>
> 约束（必须遵守）：
> - **GameCore**：纯逻辑层，禁止 I/O / UI / 环境变量读取；随机必须来自 `SeededRNG`；扩展优先 `Definition + Registry`。
> - **GameCLI**：负责渲染/输入/落盘/工具屏幕；展示信息优先从 Registry 读取，不硬编码资源表。

---

## 完成进度（已完成部分）

- [x] **P0.1 数据目录可见性**：设置菜单与帮助中均可看到当前数据目录（支持 `SALU_DATA_DIR` 覆盖）
- [x] **P0.2 资源管理页补齐**：已覆盖 Card/Status/Consumable/Event/Enemy/Relic（含 Act3 池与 EnemyRegistry 全量）
- [x] **P0.3 事件种子工具**：设置菜单提供事件 seed 扫描工具（用于 P5 验收）
- [x] **P0.4 能力叠加问题兜底**：已补测试验证 Strength/SequenceResonance 等状态叠加行为正确
- [x] **P1.1 预知选牌 UI**：预知触发时进入“预知选牌”界面，玩家输入 `1..N` 选择 1 张入手
- [x] **P1.2 帮助补充说明**：HelpScreen 已补充预知/回溯/疯狂与数据目录说明
- [x] **P2 注册与池子可见性**：资源管理页可直接核对 Act2 精英池（mad_prophet/time_guardian）与 Act2 Boss（cipher）
- [x] **P3 遗物可见性与核心机制**：资源管理页可见 Seer 遗物；核心触发逻辑已由测试覆盖（含 battleStart 预知的选牌交互）
- [x] **P4（旧交互，待删除）消耗品战斗内接入**：战斗界面展示消耗品；战斗内支持 `C1-C3` 使用、`X1-X3` 丢弃（已实现，但按新需求将被移除）
- [ ] **P4R（破坏性重构）消耗品=消耗性卡牌**：在 `CardType` 新增「消耗性」类型；消耗品会进入战斗牌堆并抽上来，输入 `1..N` 直接打出；费用恒为 0（不耗能量）；打出后从 RunState 永久移除（跨战斗不恢复）；不提供丢弃（进行中）
- [x] **脚本测试**：`swift test` 已通过（包含对预知 pending 流程的测试更新）

---

## 0. 现状核对（已确认的事实）

基于代码审阅（`Sources/GameCore` / `Sources/GameCLI`）与 `swift test`：

- **预知（Foresight）**：已改为“需要玩家选牌”的交互：`BattleEngine` 暴露 `pendingInput`；CLI 会弹出“预知选牌”界面，输入 `1..N` 选择 1 张入手，其余按原顺序放回。
- **回溯（Rewind）**：在 `BattleEngine.applyRewind()` 中对 `discardPile.removeLast()` 循环；因此是“弃牌堆顶部（最近进入弃牌堆）的牌”，**不是随机**。
- **疯狂（Madness）**：阈值检查/回合末 -1 在 `BattleEngine`；CLI `BattleScreen` 已按阈值着色并可在日志面板看到相关事件格式化。
- **资源管理（ResourceScreen）**：已扩展为覆盖 Card/Status/Consumable/Event/Enemy/Relic（并补 Act3 池、EnemyRegistry 全量列表）。
- **消耗品（Consumables）**：
  - 已接入 GameCore/存档/商店购买链路（`RunSnapshot.consumableIds`、`SaveService`、`ShopRoomHandler`）。
  - 当前实现为“战斗界面工具栏展示 + `C1-C3` 使用 + `X1-X3` 丢弃”（旧交互）。
  - 新需求（破坏性重构）：改为 **消耗品=消耗性卡牌**（新增 `CardType.consumable`），会被抽上来、用 `1..N` 出牌输入使用；0 费不耗能量；打出后从 RunState 永久移除；无需丢弃功能（见第 7 节）。
- **数据目录**：已统一通过 `DataDirectory` 解析；UI 测试会注入 `SALU_DATA_DIR=<系统临时目录>/...`；本地手测如不设置 `SALU_DATA_DIR`，macOS 默认会落在 `~/Library/Application Support/Salu/`。

---

## 1. 你反馈的 1–8 项问题 → 归档到 P0–P7

> 说明：你要求按 P1→P7 排优先级执行，但其中有两类“基础设施/阻断验收”的问题需要先做（记为 P0），否则后续 P 的验收/定位成本会非常高。

### P0（验收基础设施 & 核心正确性兜底）
- **(7) 临时 `SALU_DATA_DIR` 不知道在哪**：提供 CLI 可见的“当前数据目录”显示/输出。
- **(4) 资源管理页缺项**：补齐 Status/Event/Consumable/EnemyRegistry/RelicPool 等关键清单，避免靠“猜”。
- **(6) 事件测试难以命中**：提供“事件→可复现 seeds”查找工具（开发者工具）。
- **(8) 能力牌效果不叠加**：先做最小可复现用例 + 断言（若代码层面确实有 bug，再修；若代码正确则把“误解点”在 CLI/UI/帮助里解释清楚）。

### P1（核心卡牌机制：预知/回溯/改写/清理疯狂）
- **(1) 预知需要真正的“选牌 UI”**：战斗中触发预知时弹出选择界面（你已确认交互偏好：需要一个 screen/界面）。
- **(2) 设置-帮助补充说明**：把预知/回溯/疯狂等写到 HelpScreen，成为验收与新玩家理解入口。
- **(3) 回溯行为说明**：在帮助/日志文案中明确“最近弃牌”，避免歧义。

### P2–P7
- P2/P3/P7 的“注册表可见性”验收依赖资源管理页（因此 P0 里先补）。
- P4（消耗品战斗内接入 + 丢弃）已完成（见第 7 节）。
- P5（事件）需要“种子命中工具”辅助验收。
- P6（赛弗 Boss）主要是 UI 可见性与机制链路验证。

---

## 2. 执行总原则（每个 P 完成后都要做）

### 必做验证
- **单元/集成测试**：`swift test`
- **CLI 手动验收（建议隔离数据）**：

```bash
export SALU_DATA_DIR=/tmp/salu-ui-seer
rm -rf "$SALU_DATA_DIR" && mkdir -p "$SALU_DATA_DIR"
swift run GameCLI --seed 1
```

> 注：后续每个 P 会附上更精准的 `SALU_TEST_MODE=1 ...` 命令组合。

---

## 3. P0：验收基础设施 & 核心正确性兜底（优先做）

### P0.1 在 CLI 明确显示“当前数据目录（SALU_DATA_DIR）”
**目标**：解决“临时 SALU_DATA_DIR 在哪”的问题，并方便你排查 `run_save.json / settings.json / run_log.txt`。

✅ 已完成（实现落地）：
- 新增 `Sources/GameCLI/Persistence/DataDirectory.swift` 统一解析数据目录（支持 `SALU_DATA_DIR` 覆盖 + 平台默认 + 临时目录回退）。
- 持久化存储统一使用该目录：`FileRunSaveStore` / `SettingsStore` / `FileBattleHistoryStore` / `FileRunLogStore`。
- 设置菜单新增入口：`[7] 🗂️ 数据目录（SALU_DATA_DIR）` → `DataDirectoryScreen` 展示当前路径与常见文件名。
- HelpScreen 也会显示当前数据目录路径与来源（满足“设置 + 帮助”双入口）。
- `swift test` 已通过。

**实现建议**（二选一，或都做）：
- **A. 设置菜单新增一项**：`[7] 🗂️ 显示当前数据目录` → 打印实际使用的目录路径（包含覆盖与默认）。
  - 需要为 `FileRunSaveStore`/`SettingsStore`/`FileRunLogStore` 增加一个只读接口（例如 `var resolvedDirectory: URL` 或 `static func resolvedDirectory()`），供 CLI 显示。
- **B. HelpScreen 增加“数据目录说明”**：告诉默认路径规则 + 如何用 `SALU_DATA_DIR` 覆盖。

**涉及文件**：
- `Sources/GameCLI/Persistence/FileRunSaveStore.swift`
- `Sources/GameCLI/Persistence/SettingsStore.swift`
- `Sources/GameCLI/Persistence/FileRunLogStore.swift`
- `Sources/GameCLI/Screens/SettingsScreen.swift`
- `Sources/GameCLI/GameCLI.swift`
- `Sources/GameCLI/Screens/HelpScreen.swift`

**完成标准**：
- 你在 CLI 内无需猜测即可看到“实际落盘目录”。

**验证**：
- `swift test`
- 手动：不设置 `SALU_DATA_DIR` 进入设置菜单查看；再设置 `SALU_DATA_DIR=/tmp/...` 验证显示变化。

---

### P0.2 扩展资源管理页：覆盖 Status/Event/Consumable/Registry（不硬编码）
**目标**：解决“资源管理页面没有显示所有资源”的问题；让 P2/P3/P7 的验收可以直接从 UI 查。

✅ 已完成（实现落地）：
- `ResourceScreen` 已新增：
  - StatusRegistry 全量列表（含 icon/name/id/decay/phase/priority）
  - ConsumableRegistry 全量列表（含是否战斗内/外可用）
  - EventRegistry 全量列表
  - Act3 敌人池与遭遇池
  - EnemyRegistry 全量列表（含 Boss）
- 为了让 CLI 可以列出全量敌人/状态，补充了：
  - `EnemyRegistry.allEnemyIds`
  - `StatusRegistry.allStatusIds`
- `swift test` 已通过。

**内容建议**：
- **状态（StatusRegistry）**：列出所有 `StatusRegistry` 注册项（id/name/icon/decay/positive）。
- **事件（EventRegistry）**：列出所有事件（id/name/icon）。
- **消耗品（ConsumableRegistry）**：列出所有消耗品（id/name/icon/rarity/usableInBattle/usableOutsideBattle）。
- **敌人（EnemyRegistry）**：列出全部敌人（含 Boss），并补上 Act3（当前 ResourceScreen 只显示 Act1/Act2 pool）。
- **池子（Pools）**：保留现有 Act1/Act2 pool + encounter；可补 `RelicPool`（可掉落列表）。

**涉及文件**：
- `Sources/GameCLI/Screens/ResourceScreen.swift`
- （只读）`Sources/GameCore/Status/StatusRegistry.swift`
- （只读）`Sources/GameCore/Events/EventRegistry.swift`
- （只读）`Sources/GameCore/Consumables/ConsumableRegistry.swift`
- （只读）`Sources/GameCore/Enemies/EnemyRegistry.swift`

**完成标准**：
- 你能在资源管理页看到占卜家相关卡/敌人/遗物/事件/消耗品的完整注册表，不再靠“印象/猜测”。

**验证**：
- `swift test`
- 手动：设置 → 资源管理 → 搜索/肉眼确认 `seer_*`、`mad_prophet`、`purification_rune` 等均出现。

---

### P0.3 事件种子定位工具（开发者工具）
**目标**：解决“我不确定什么时候能碰到事件”的痛点；提供稳定方式找到能命中指定事件的 seed。

✅ 已完成（实现落地）：
- 新增 `Sources/GameCLI/Screens/EventSeedToolScreen.swift`，并在设置菜单提供入口：`[8] 🧭 事件种子工具（开发者）`。
- 工具会扫描 seed 范围并按 EventRegistry 全量事件输出命中 seeds（默认上下文对齐测试地图 `floor=1,row=1,nodeId=1_0`）。
- `swift test` 已通过。

**实现建议**：
- 新增一个 CLI 工具屏幕（例如 `EventSeedToolScreen`），从设置菜单进入：
  - 输入：`seedRange`（如 1..2000）、`floor/row/nodeId`（默认采用测试地图的 `floor=1,row=1,nodeId="1_0"`）。
  - 输出：对 `EventRegistry.allEventIds` 逐个扫描，在范围内找出前 N 个能命中的 seed（例如每个事件展示前 5 个 seed）。
  - 计算方式：复用 `EventGenerator.generate(context:)` 的派生 seed 逻辑；只做“试算并显示”，不改游戏状态。

**涉及文件**：
- 新增：`Sources/GameCLI/Screens/EventSeedToolScreen.swift`（或放 `Screens/` 下）
- `Sources/GameCLI/Screens/SettingsScreen.swift`
- `Sources/GameCLI/GameCLI.swift`（`settingsMenuLoop` 新增分支）
- （只读）`Sources/GameCore/Events/EventGenerator.swift`

**完成标准**：
- 你可以快速得到：`seer_time_rift / seer_mad_prophet / seer_sequence_chamber` 等事件在某个上下文下对应的可复现 seeds。

**验证**：
- `swift test`
- 手动：跑工具屏幕输出 seeds，然后用 `SALU_TEST_MODE=1 SALU_TEST_MAP=event swift run GameCLI --seed <seed>` 验证能命中对应事件。

---

### P0.4 “能力牌效果不叠加”问题定位与兜底
**目标**：先把问题变成“可复现 + 可断言”，再决定修还是澄清。

✅ 已完成（结论 & 覆盖）：
- 已补充测试用例，确认 **GameCore 层状态叠加逻辑正常**（`StatusContainer.apply` 为加法叠加）。
  - `CardDefinitionPlayTests.testInflame_canStackStrengthWhenPlayedTwiceInBattle`：两次打出 `Inflame` → `Strength` 从 0→2→4
  - `SeerAdvancedCardsTests.testSequenceResonance_stacksAcrossMultiplePlays_grantsMoreBlock`：两次打出 `序列共鸣` → 预知后格挡从 1→2
- `swift test` 已通过。

**定位思路**：
- 从代码看，`applyStatus` 走 `StatusContainer.apply`（加法叠加），理论上 Strength/Dexterity/SequenceResonance 都应可叠加。
- 需要确认你看到的“不叠加”是：
  - **A. 状态数值不增长**（真正 bug）
  - **B. 状态增长但效果未体现**（例如触发点没接、UI 没展示、战斗过快结束误判）
  - **C. 你期望的是“能力牌不进弃牌堆/只能打一次”之类的语义差异（需要在帮助/文案解释或调整规则）**

**计划动作**：
- 在 `GameCoreTests` 增加/补强用例：同一战斗内连续两次施加同一正面状态，断言 stacks 累加。
  - 例：两次 `applyStatus(.player, Strength.id, +2)` → stacks=4；或两次打出 `Inflame`。
  - 对 `SequenceResonance`：两次施加 stacks=1 → 预知后应获得 2 点格挡。
- 若测试失败：按失败点修引擎/状态/触发点。
- 若测试通过：在 HelpScreen/战斗 UI 中增加说明，避免误判（例如：测试模式敌人 HP=1 会导致你很难在同一战斗里观察到叠加效果）。

**验证**：
- `swift test`

---

## 4. P1：核心卡牌机制（预知/回溯/改写/清理疯狂）

### P1.1 预知“选牌 UI”实现（你确认：需要一个 screen）
**目标**：预知触发时弹出界面，展示“抽牌堆顶 N 张”，玩家输入编号选择 1 张入手；未选中的按原顺序放回。

✅ 已完成（实现落地）：
- GameCore：
  - 新增 `Sources/GameCore/Battle/BattlePendingInput.swift`：`BattlePendingInput.foresight(options:fromCount:)`
  - `BattleEngine` 新增 `public private(set) var pendingInput` 与 `submitForesightChoice(index:)`
  - `applyForesight` 会从抽牌堆顶取出 N 张并进入 pending；选择后 `emit(.foresightChosen...)`，未选按原顺序放回
  - 选择完成时会触发 `序列共鸣`（SequenceResonance）的“预知后获得格挡”
- GameCLI：
  - 新增 `Sources/GameCLI/Screens/ForesightSelectionScreen.swift`
  - `GameCLI.battleLoop` 在渲染战斗屏幕前优先处理 `engine.pendingInput`（输入 `1..N`）
  - 预知选牌界面已按你的要求显示【攻击/技能/能力】中文标签
  - EOF 时默认选第 1 张，避免 UI 测试卡死
- 测试：
  - 已更新 `GameCoreTests` 中所有受影响用例（预知从“自动选牌”改为 “pending + submit”）
  - `swift test` 已通过

**涉及文件**：
- `Sources/GameCore/Battle/BattleEngine.swift`
- `Sources/GameCore/Battle/BattlePendingInput.swift`
- 新增：`Sources/GameCLI/Screens/ForesightSelectionScreen.swift`
- `Sources/GameCLI/GameCLI.swift`（battleLoop 支持 pendingInput 分支）

**完成标准**：
- 打出 `灵视/真相低语` 会弹出预知选择界面，并且选择结果正确进入手牌，日志里有 `👁️ 预知 N 张，选择 XXX 入手`。

**验证**：
- `swift test`
- 手动：

```bash
SALU_TEST_MODE=1 SALU_TEST_MAP=battle SALU_TEST_BATTLE_DECK=seer \
swift run GameCLI --seed 1
```

---

### P1.2 HelpScreen 补充：预知/回溯/疯狂（以及日志面板）
**目标**：让设置→帮助成为“机制说明书”，覆盖你提到的预知/回溯/疯狂（以及关键：日志面板开关）。

✅ 已完成（实现落地）：
- `HelpScreen` 已补充：
  - 预知：规则 + CLI 选牌方式（`1..N`）
  - 回溯：明确为“弃牌堆顶部（最近）”
  - 疯狂：阈值与清理方式
  - 数据目录：显示当前路径与来源，并提示设置菜单 `[7]`
- `swift test` 已通过。

**内容建议**：
- 预知：规则、触发时 UI、选择后落点（入手）、未选中的牌顺序。
- 回溯：明确“从弃牌堆顶部（最近）取回 N 张”。
- 疯狂：阈值（≥3/6/10）、回合末 -1、清理方式（冥想/净化仪式/净化符文等）。
- 消耗品（P4R）：消耗品会以“0 费消耗性卡牌”形式进入战斗牌堆并抽上来，使用走正常出牌输入（不再使用 `C1/X1`，且不提供丢弃）。

**涉及文件**：
- `Sources/GameCLI/Screens/HelpScreen.swift`

**验证**：
- `swift test`
- 手动：设置 → 帮助，确认文本覆盖且排版不炸。

---

## 5. P2：敌人意图扩展（UI/池子）
> 依赖：P0.2 资源管理页补齐后，P2 的“注册可见性”验收会更快。

✅ 已完成（实现落地）：
- 资源管理页现在可直接核对：
  - Act2 精英池：`mad_prophet / time_guardian`（以及现有 `rune_guardian`）
  - Act2 Boss：`cipher`（已在 Act2 敌人池区域明确展示）
- `swift test` 已通过。

**计划动作**：
- 用资源管理页补充 Boss/Act3 列表，确保 `mad_prophet / time_guardian / cipher` 的 id/name/icon 可直接查。
- 若发现池子缺项：修 `Act2EnemyPool`/`Act2EncounterPool`（GameCore）并补测试。

**验证**：
- `swift test`
- 手动：设置 → 资源管理确认池子；或 `SALU_TEST_MODE=1 SALU_TEST_MAP=mini ...` 实战查看意图行。

---

## 6. P3：占卜家遗物（UI）
> 依赖：P0.2 资源管理页补齐后，P3 的“遗物可见性”验收更直观。

✅ 已完成（实现落地）：
- 资源管理页已能看到清单要求的占卜家遗物（`third_eye/broken_watch/sanity_anchor/abyssal_eye/prophet_notes/madness_mask`）。
- 遗物触发预知的交互链路已由 P1 的 `pendingInput` 机制覆盖（battleStart 触发预知会进入“预知选牌”界面）。
- 相关核心逻辑已由 `swift test` 覆盖并通过（第三只眼/深渊之瞳/破碎怀表/预言者手札/理智之锚/疯狂面具等）。

**计划动作**：
- 确认 ResourceScreen/RelicPool 展示包含：第三只眼、破碎怀表、理智之锚、深渊之瞳、预言者手札、疯狂面具。
- 若遗物触发预知也需要“选牌 UI”，在此阶段把 P1 的 pendingInput 机制扩展到 **遗物触发链路**（battleStart/turnStart 触发）。

**验证**：
- `swift test`

---

## 7. P4R：商店扩展 + 消耗品系统（破坏性重构：消耗品=消耗性卡牌）

> 你最新确认的需求（以此为准，不考虑向后兼容）：
> - 消耗品 = 一类「消耗性卡牌」，会进入战斗牌堆并抽上来，出现在手牌列表中
> - 使用方式走“正常出牌输入 `1..N`”（不再有消耗品工具栏/快捷键）
> - 消耗品仅做一次性：打出后从 RunState 永久移除（跨战斗不恢复）
> - 消耗品出牌费用恒为 0（不耗能量）
> - 不需要“丢弃消耗品”功能
> - 能力牌（power）的规则不改动

### P4（旧交互，待删除）：战斗 UI 工具栏展示消耗品 + C/X 输入
**说明**：这部分已实现，但将被删除以满足新交互。

✅ 已完成（实现落地）：
- `BattleScreen.renderBattleScreen` 增加参数：`consumables: [ConsumableID]`，并在玩家区域展示“消耗品：暂无 / [C1]...”
- 操作提示行补充 `C1-Cn`（使用）与 `X1-Xn`（丢弃）的快捷提示

### P4（旧交互，待删除）：战斗内 `C1/C2/C3` 使用；`X1/X2/X3` 丢弃
**说明**：这部分已实现，但将被删除以满足新交互。

✅ 已完成（实现落地）：
- `RoomContext.battleLoop` 改为 `(BattleEngine, UInt64, inout RunState) -> BattleLoopResult`，房间 handler 传入 `&runState`，允许战斗内修改消耗品槽位
- `GameCLI.battleLoop` 输入解析：
  - `C1-Cn`：检查 `usableInBattle`，基于当前战斗状态构造 `BattleSnapshot`，调用 `BattleEngine.applyExternalEffects(_:)` 应用 `useInBattle` 效果；成功后从 `runState` 移除该消耗品并写日志
  - `X1-Xn`：直接从 `runState` 移除并写日志
- `BattleEngine` 新增受控入口 `applyExternalEffects(_:)`（避免 CLI 访问私有 `apply`，并在存在 pendingInput 时拒绝执行）

**涉及文件**：
- `Sources/GameCLI/GameCLI.swift`（battleLoop + 传递 runState/consumables）
- `Sources/GameCLI/Screens/BattleScreen.swift`
- `Sources/GameCore/Battle/BattleEngine.swift`（新增 public API）
- `Sources/GameCore/Consumables/*`（仅复用定义）
- `Sources/GameCore/Run/RunState.swift`（移除消耗品已存在）

**验证**：
- `swift test`
- 手动：

```bash
SALU_TEST_MODE=1 SALU_TEST_MAP=shop swift run GameCLI --seed 1
# 买到消耗品后进入战斗：使用 C1/C2 或丢弃 X1
```

---

## 7.1 P4R：实现方案（不桥接，破坏性重构）

### 7.1.1 新增卡牌类型：`CardType.consumable`
**目标**：在 `Sources/GameCore/Cards/CardDefinition.swift` 的 `CardType` 增加 `.consumable = "消耗性"`。

**涉及改动**：
- UI（战斗/预知选择/日志/资源管理）需要为 `.consumable` 增加类型图标与中文标签。
- 输入校验与出牌提示需要兼容 `.consumable`（消耗品可能不需要目标）。

### 7.1.2 消耗品定义迁移：`ConsumableDefinition` → `CardDefinition`
**目标**：将 `Sources/GameCore/Consumables/Definitions/*` 的定义迁移为 `CardDefinition`：
- `type = .consumable`
- `cost = 0`（费用恒为 0，不耗能量）
- `rulesText` 复用原 `description`
- `play(snapshot:...)` 直接返回原本 `useInBattle(snapshot:)` 的效果

> 破坏性变更：可以删除 `ConsumableDefinition/ConsumableRegistry`，并调整资源管理页不再单列 consumables（全部走 CardRegistry 展示）。

### 7.1.3 RunState/商店/存档：用“卡牌实例”持有消耗品
**目标**：消耗品既然是卡牌，就应以 `Card` 实例加入 `runState.deck`，并随战斗自然抽到。

**计划动作**：
- 商店购买消耗品：直接向 `runState.deck` 追加一个消耗性卡牌实例（实例 id 需要稳定且不冲突）。
- 存档：以 deck 序列为准落盘（不再需要 `consumableIds` 字段；不考虑向后兼容）。

### 7.1.4 战斗内“永久消失”：打出后从 RunState 移除
**目标**：消耗性卡牌打出后：
- 本战斗不再出现（不进入弃牌堆循环）
- 并且从 `runState.deck` 中永久移除（跨战斗不恢复）

**计划动作**：
- `BattleState` 增加 `exhaustPile: [Card]`（用于可视化/调试，或至少保证消耗性卡牌不回到 draw/discard）
- `BattleEngine.playCard`：对 `.consumable` 走专用路径（不扣能量、执行效果、进入 exhaustPile）
- 为了能精确移除“哪一张实例”：需要引擎/事件暴露 card instance id（例如把 `BattleEvent.played` 改为携带 `cardInstanceId`）
- `GameCLI.battleLoop` 在处理一次出牌后，若打出 `.consumable`，就从 `runState.deck` 删除对应实例

### 7.1.5 删除旧交互：工具栏 + C/X 输入
**目标**：彻底移除消耗品工具栏与 `C1/X1` 输入分支（避免双系统并存造成困惑）。

### 7.1.6 验收命令（建议）

```bash
SALU_TEST_MODE=1 SALU_TEST_MAP=shop swift run GameCLI --seed 1
# 在商店购买消耗性卡牌后进入战斗：
# 1) 能抽到该牌（显示为“消耗性”，费用恒为 0）
# 2) 输入牌序号打出 → 效果生效
# 3) 战斗结束后：该牌已从 runState.deck 永久移除（下一场战斗不会再抽到）
```

---

## 8. P5：占卜家专属事件（UI）+ 自动化验收辅助
> 依赖：P0.3 “事件种子定位工具”。

**计划动作**：
- 事件 UI 走现有 EventRoomHandler/EventScreen；主要补“命中 seed”的可复现路径。
- 若 P1 引入 pendingInput 导致事件中进入战斗的流程/输入串变化，需要同步更新 UI 测试输入脚本并确保不卡死。

**验证**：
- `swift test`
- 手动：用工具查 seed → `SALU_TEST_MODE=1 SALU_TEST_MAP=event swift run GameCLI --seed <seed>`

---

## 9. P6：赛弗 Boss 特殊机制（UI）
**计划动作**：
- 重点回归：意图展示、预知惩罚、首牌费用增加、延迟弃牌机制、阶段切换。
- 若 P1/P4 改动 battleLoop 输入解析，需确保 Boss 战仍可顺畅进行并且日志不丢。

**验证**：
- `swift test`
- 手动（建议保留真实 HP）：

```bash
SALU_TEST_MODE=1 SALU_TEST_MAP=mini SALU_TEST_MAX_FLOOR=3 SALU_TEST_ENEMY_HP=normal SALU_TEST_BATTLE_DECK=seer_p7 \
swift run GameCLI --seed 1
```

---

## 10. P7：卡牌池扩展（含能力/罕见/稀有）
**计划动作**：
- 主要是“注册表可见性 + 战斗内效果触发”验收。
- 若 P0.4 最终确认“能力叠加”确有 bug，应在此阶段补齐回归测试，防止再出现。

**验证**：
- `swift test`
- 手动：`SALU_TEST_MODE=1 SALU_TEST_MAP=battle SALU_TEST_BATTLE_DECK=seer_p7 swift run GameCLI --seed 1`

---

## 11. 交付节奏建议（你按清单验收最省心的顺序）

1) **P0 全部完成**（否则后续验收会反复卡在“看不到/找不到/遇不到”）  
2) **P1（预知选牌 UI + 帮助补齐）**  
3) **P4（消耗品战斗内接入）**  
4) **P5（事件 + seed 工具回归）**  
5) **P2/P3/P6/P7** 按清单逐项回归（资源管理页已完善，验收会变快）
