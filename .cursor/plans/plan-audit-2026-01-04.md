# 计划审查（P1~P7）- 2026-01-04

> 审查范围：
> - `.cursor/plans/architecture-design.md`（已归档，仅做宏观参考）
> - `.cursor/plans/protocol-driven-design-plan.md`（实施主文档）
> - 代码实现（Sources/GameCore + Sources/GameCLI）
> - 测试脚本（.cursor/Scripts/tests）

## 结论（高层）

- **P1~P6：实现与计划一致（核心框架已落地）**：Card/Status/Enemy/Relic/RoomFlow/Persistence 都已协议化 + registry 化。
- **P7：代码层面已具备“继续上次冒险 + 自动保存 + 版本校验”**，但计划文档头部仍标为“P7 进行中”，需要同步更新（见“问题清单”）。

## P1：卡牌系统协议化 ✅

- **关键点**：
  - 移除 `CardKind` 与按 kind 的 switch 扩展点
  - `CardID` + `CardDefinition` + `CardRegistry` 成为唯一扩展点
  - `BattleEvent.drew/played` 使用 `CardID`
- **代码证据**：
  - `Sources/GameCore/Cards/Card.swift`：`Card` 仅包含 `id` + `cardId`
  - `Sources/GameCore/Cards/CardRegistry.swift`：注册表
  - `Sources/GameCore/Events.swift`：`.drew(cardId:)`/`.played(cardId:, cost:)`
  - `Sources/GameCLI/Screens/BattleScreen.swift`：使用 `def.rulesText` 渲染手牌

## P1 审查发现的问题（已修复）

1. **卡牌显示名非中文（已修复）**
   - 现象：`CardDefinition.name` 仍为英文（例如 "Strike"），会直接影响 UI 与事件日志显示，违背“所有用户可见文本使用中文”的约束。
   - 修复：将 `Strike/Defend/Bash/...` 的 `name` 统一改为中文（含 `+` 版本）。

## P2：状态效果系统协议化 ✅

- **关键点**：
  - `Entity` 只保留 `statuses: StatusContainer`
  - 修正顺序确定（phase + priority）
  - UI 通过 `StatusRegistry` 渲染状态
- **代码证据**：
  - `Sources/GameCore/Entity/Entity.swift`：`statuses: StatusContainer`
  - `Sources/GameCore/Status/*`：Definition/Registry/Container 已存在
  - `Sources/GameCore/Battle/BattleEngine.swift`：`calculateDamage`/`applyBlock` 走 phase+priority

## P2 审查发现的问题（已修复）

1. **缺失 `DamageCalculator` / `BlockCalculator`（已补齐）**
   - 现象：计划文档要求将状态修正的确定性顺序集中在 `DamageCalculator`，但代码中逻辑散落在 `BattleEngine.calculateDamage/applyBlock`。
   - 修复：新增 `Sources/GameCore/Battle/DamageCalculator.swift`（包含 `DamageCalculator` 与 `BlockCalculator`），并在 `BattleEngine` 中统一调用。

## P3：敌人系统统一 ✅

- **关键点**：
  - `EnemyID` + `EnemyDefinition` + `EnemyRegistry` + `EnemyMove(effects:)`
  - plan 阶段固化随机结果，execute 阶段只执行 effects
- **代码证据**：
  - `Sources/GameCore/Enemies/EnemyDefinition.swift` / `EnemyMove.swift` / `EnemyRegistry.swift`
  - `Sources/GameCore/Enemies/EnemyPool.swift`：pool 只返回 `EnemyID`
  - `Sources/GameCore/Battle/BattleEngine.swift`：使用 `EnemyRegistry.require(enemyId).chooseMove(...)`

## P3 审查发现的问题（已修复）

1. **意图文本与实际效果不一致（已修复）**
   - 现象：信徒第一回合意图显示为“仪式 +3”，但实际效果是 `strength +3`（力量）。
   - 修复：统一意图文本为“力量 +3”，与实现和业务规则保持一致。

## P4：遗物系统 ✅

- **关键点**：
  - `RelicID` + `RelicDefinition` + `RelicRegistry` + `RelicManager`
  - 触发点统一为 `BattleTrigger`，效果统一为 `[BattleEffect]`
- **代码证据**：
  - `Sources/GameCore/Kernel/BattleTrigger.swift`
  - `Sources/GameCore/Relics/*`
  - `Sources/GameCore/Battle/BattleEngine.swift`：`triggerRelics(_:)` 集成

## P5：Run/房间/地图流程协议化 ✅

- **关键点**：
  - `RoomHandling` + `RoomHandlerRegistry` 消灭 `runLoop` 的 roomType switch
  - Map 生成可替换（`MapGenerating`）
- **代码证据**：
  - `Sources/GameCLI/Flow/RoomHandling.swift` / `RoomHandlerRegistry.swift`
  - `Sources/GameCLI/Rooms/Handlers/*`
  - `Sources/GameCore/Map/MapGenerating.swift`

## P6：持久化与 I/O 协议化 ✅

- **关键点**：
  - GameCore 定义协议；GameCLI 做文件 I/O 实现
  - 移除 History 单例，改依赖注入
- **代码证据**：
  - `Sources/GameCore/Persistence/BattleHistoryStore.swift`（协议）
  - `Sources/GameCLI/Persistence/FileBattleHistoryStore.swift`（实现）
  - `Sources/GameCLI/Persistence/HistoryService.swift`（业务服务）

## P7：Run 存档系统（Save/Load）✅（实现已具备，文档需同步）

- **关键点（代码已具备）**：
  - 主菜单显示“继续上次冒险”
  - 节点完成后自动保存
  - 版本不匹配提示，不崩溃
- **代码证据**：
  - `Sources/GameCore/Run/RunSnapshot.swift` / `RunSaveVersion.swift`
  - `Sources/GameCLI/Persistence/SaveService.swift` / `FileRunSaveStore.swift`
  - `Sources/GameCLI/GameCLI.swift`：`hasSave/continueRun/saveRun/clearSave`

## 问题清单（已记录 + 已修复）

1. **存档序列化致命 bug（已修复）**
   - 问题：`String(describing:)` 序列化 `CardID/StatusID/RelicID/RoomType` 会写出 `CardID(rawValue: ...)`，加载后无法 resolve，导致崩溃。
   - 修复：统一存储 `rawValue`；加载时对未知数据抛 `SaveError.corruptedSave`。

2. **GameCore 不必要导入 Foundation（已修复）**
   - 问题：`BattleHistoryStore.swift` / `RunSaveStore.swift` 不应依赖 Foundation。
   - 修复：移除 `import Foundation`；`RunSnapshot` 放回 `GameCore/Run`。

3. **残留向后兼容层（已修复）**
   - 问题：`ScreenRenderer` typealias 与 `BattleEngine.applyDebuff` deprecated 兼容逻辑违背“破坏性策略”。
   - 修复：删除兼容别名与 deprecated 逻辑。

4. **测试覆盖缺口（已补齐）**
   - 新增：`.cursor/Scripts/tests/test_save.sh`
   - 接入：`./.cursor/Scripts/test_game.sh save`

## 仍需同步的文档项（待处理）

- `protocol-driven-design-plan.md` 顶部状态仍写为 “P7 进行中”，与当前实现不一致（建议更新为 ✅ 并勾选检查清单）。
- `architecture-design.md` 已归档，但其“当前限制”与现状有偏差；建议仅保留宏观愿景，限制表可简化或标注“历史信息”。


