# Plan A（P1/P2/P3）：开发者调试「创造模式」- 2026-01-09

## 0. 背景与目标

你希望在 **设置菜单** 增加一个 **开发者调试功能**，让开发者能像“创造模式”一样：

- 用 **选择器 UI** 快速进入任意房间类型（事件/商店/休息/普通战斗/精英/Boss…）
- 可自定义/预设 **金币、遗物、牌组、HP** 等玩家状态
- 可在进入战斗/事件等房间时，**指定敌人 ID / 事件 ID**（而不是纯随机）
- 用于快速验收玩法系统的任意细节，同时尽量避免对工程带来不必要的复杂度

实现原则：**尽量复用现有 RoomHandler / Screen / GameCore Registry**，调试能力与正式流程隔离，避免把调试分支散落到各处。

---

## 1. 相关代码现状（已核对）

### GameCLI 入口与菜单

- `Sources/GameCLI/GameCLI.swift`：主菜单、设置菜单循环、runLoop、RoomHandlerRegistry 使用方式
- `Sources/GameCLI/Screens/SettingsScreen.swift`：设置菜单渲染（当前 1-6）
- `Sources/GameCLI/Screens.swift`：屏幕统一入口

### 房间系统（可复用）

- `Sources/GameCLI/Flow/RoomHandling.swift`：`RoomHandling` / `RoomContext` / 统一日志入口
- `Sources/GameCLI/Flow/RoomHandlerRegistry.swift`：默认注册表 `makeDefault()`
- `Sources/GameCLI/Rooms/Handlers/*`：Battle/Elite/Boss/Shop/Rest/Event/Start 的完整房间流程

### 现有“开发者工具”入口（但不是创造模式）

- 设置菜单项 `[4] 资源管理` → `Sources/GameCLI/Screens/ResourceScreen.swift`

### GameCore 可选内容来源（做选择器需要）

- `CardRegistry.allCardIds` / `RelicRegistry.allRelicIds` / `EventRegistry.allEventIds` ✅
- `EnemyRegistry` **目前没有 allEnemyIds**（计划补一个只读列表，便于 UI 选择器与测试）

### 测试基础设施

- 白盒：`Tests/GameCLITests/*`（已有 stdin 驱动模式）
- 黑盒 UI：`Tests/GameCLIUITests/*`（Process 启动 GameCLI，稳定性主要靠 `SALU_TEST_MODE`）

---

## 2. 设计约束与权衡

### 2.1 必须满足

- **不污染正式存档/战绩（默认）**：调试房间的战斗记录、存档写入默认禁用或写入隔离目录/内存
- **不影响玩家体验**：调试入口必须 gated（例如 `SALU_DEV=1` 或 `--dev`）
- **依赖方向不破坏**：仅在 GameCLI 改动；GameCore 最多补充“只读查询 API”（如 `allEnemyIds`）
- **实现完每个优先级 P 后必须 `swift test`**（并确保测试稳定）

### 2.2 不做（本计划范围外）

- 不做“指令控制台/脚本系统”（那会显著膨胀复杂度）
- 不做把调试能力暴露给普通玩家的 UI/配置
- 不做跨版本长期持久化的“调试配置文件格式”（最多做轻量保存/最近一次配置）

---

## 3. Plan A 的总体方案（推荐）

做一个 **开发者调试沙盒（Sandbox Session）**：

- 开发者从设置进入「🧪 开发者调试」
- 在一个独立菜单里：
  - 查看当前沙盒状态摘要（Act/HP/金币/遗物/牌组规模）
  - 随时编辑：金币、HP、遗物、牌组
  - 选择“传送到房间”并为该房间提供可选的“内容覆盖”（敌人/事件/商店库存）
  - 运行房间流程后回到调试菜单（可连续测试多个房间）
- 沙盒默认 **不落盘**（不写真实存档/战绩）；必要时再提供“导出/复制为真实 run”的增强项（放到 P3+）

核心实现思路（尽量不引入分支型复杂度）：

1) 新增 `DeveloperMode`（只负责：判断是否启用 dev 功能）
2) 设置菜单新增入口（仅 dev 模式可见）
3) 新增 `DeveloperToolsScreen`（UI + 沙盒编辑）
4) 新增 `DeveloperRoomRunner`（把沙盒 RunState + override 组合成一次房间执行）
5) 为了“指定敌人/事件/商店库存”，给相关 RoomHandler 增加 **可选 override**（默认 nil，不影响正式流程）
6) 加 tests：白盒验证沙盒/override 生效，UI 测试验证入口 gated 且不 hang

---

## 4. 数据结构草案（用于实现时对齐）

> 这是实现时的建议形态，具体字段可按 P1/P2 逐步加。

### 4.1 DeveloperSandboxState（GameCLI 内部）

- `seed: UInt64`（默认沿用 `--seed` 或当前时间）
- `floor: Int`（Act 1/2）
- `playerMaxHP: Int` / `playerHP: Int`
- `gold: Int`
- `deck: [Card]`（或更便于编辑的计数形式，最后再生成 [Card]）
- `relics: [RelicID]`

### 4.2 DeveloperRoomOverride（一次“传送”用的覆盖）

- `roomType: RoomType`
- 战斗类：
  - `battleEncounterEnemyIds: [EnemyID]?`（允许 1~N）
  - `eliteEnemyId: EnemyID?`
  - `bossEnemyId: EnemyID?`
- 事件：
  - `eventId: EventID?`
- 商店：
  - `shopInventory: ShopInventory?`（或 `shopSeedOverride: UInt64?`，二选一）

### 4.3 Debug History/Save 隔离策略（P1 先做最小）

- 方案 A（最简单）：调试 Runner 使用 **InMemoryBattleHistoryStore**，不写入真实历史文件
- 存档：调试模式下不调用 `SaveService`（完全内存会话）

---

## 5. 优先级拆分（P1 / P2 / P3）

下面每个 P 都包含：
1) 交付内容（用户可见能力）
2) 代码改动点（文件级）
3) 验收标准
4) 测试与验证（每个 P 结束都跑 `swift test`）

---

## P1：打通沙盒 + 传送到任意房间（不要求“指定内容”，但支持基础预设）

### P1.1 交付内容

- 设置菜单新增：`[7] 🧪 开发者调试`（仅在 `SALU_DEV=1` 或 `--dev` 时显示）
- 进入后看到“调试沙盒”主界面，能做到：
  - 选择 Act（1/2）
  - 设置金币、HP/MaxHP（数字输入）
  - 选择“传送到房间类型”（start/rest/shop/event/battle/elite/boss）
  - 运行后返回调试沙盒菜单（可重复）
- 默认不写入真实历史/存档

> P1 的 battle/event/shop 允许先用现有逻辑（随机/固定）跑通，保证沙盒的“闭环”先稳定。

### P1.2 代码改动点（建议）

- `Sources/GameCLI/GameCLI.swift`
  - 增加 dev 模式判断（或调用 `DeveloperMode.isEnabled`）
  - 设置菜单处理新增 input `"7"` → 打开 `DeveloperToolsScreen`
- `Sources/GameCLI/Screens/SettingsScreen.swift`
  - 支持条件渲染 dev 菜单项（新增参数 `showDevTools: Bool`）
- 新增 `Sources/GameCLI/DeveloperMode.swift`
  - `static var isEnabled: Bool`（读取 env/args；优先 env）
- 新增 `Sources/GameCLI/Screens/DeveloperToolsScreen.swift`
  - 沙盒主界面 + 基础编辑 + 传送入口
- 新增 `Sources/GameCLI/Flow/DeveloperRoomRunner.swift`
  - 用“最小 MapNode + RunState.enterNode + handler.run”执行一次房间
  - 提供 `makeRoomContext(...)`（日志可以直接打印或走现有 unified log）
  - 使用 InMemoryHistoryService（避免污染）

### P1.3 验收标准

- 不开启 dev：设置菜单不出现“开发者调试”
- 开启 dev：可进入调试菜单，能进入任意房间并返回（不 hang）
- 调试过程中不会生成/修改真实 `run_save.json` / battle history 文件（默认）

### P1.4 测试与验证

- 新增白盒测试（GameCLITests）：
  - 驱动 `DeveloperToolsScreen` 的最小 happy path：进入 battle → q 退出 → 返回调试菜单 → q 返回设置
  - 断言：不会写入真实数据目录（或使用临时目录断言文件不存在）
- 新增/调整黑盒 UI 测试（GameCLIUITests）：
  - `SALU_DEV=1` 下进入设置看到 dev 入口（只做 “contains” 断言，避免脆弱的行匹配）
- 完成 P1 后执行：`swift test`

---

## P2：加入“选择器 UI”与“内容覆盖”（敌人 ID / 事件 ID / 遗物 / 牌组）

### P2.1 交付内容（核心目标）

调试沙盒可以做到“完全自定义”的核心能力：

1) **敌人选择器**
   - 普通战斗：选择 1~N 个 `EnemyID` 组成遭遇（至少支持 1 或 2）
   - 精英战斗：选择一个 `EnemyID`
   - Boss：选择一个 `EnemyID`（默认仍给出 Act 推荐 boss）

2) **事件选择器**
   - 选择一个 `EventID`（或选择“随机”）

3) **遗物编辑器**
   - 从 `RelicRegistry.allRelicIds` 里多选添加/移除

4) **牌组编辑器**
   - 从 `CardRegistry.allCardIds` 里添加/移除（至少支持添加多张同 ID）
   - 提供“一键预设”（起始牌组 / 极简牌组）以加速常用场景

5) 运行房间后回到沙盒，沙盒状态会反映房间结算（例如商店买卡、事件给卡/遗物、战斗奖励等）

### P2.2 代码改动点（建议）

#### GameCore（小改动，提升可用性）

- `Sources/GameCore/Enemies/EnemyRegistry.swift`
  - 增加 `public static var allEnemyIds: [EnemyID]`（按 rawValue 排序）

#### GameCLI（覆盖能力落在 CLI，不污染 GameCore）

- `Sources/GameCLI/Rooms/Handlers/BattleRoomHandler.swift`
  - 增加 `encounterOverride: EnemyEncounter?`（默认 nil）
- `Sources/GameCLI/Rooms/Handlers/EliteRoomHandler.swift`
  - 增加 `enemyOverride: EnemyID?`
- `Sources/GameCLI/Rooms/Handlers/BossRoomHandler.swift`
  - 增加 `bossOverride: EnemyID?`
- `Sources/GameCLI/Rooms/Handlers/EventRoomHandler.swift`
  - 增加 `eventOverride: EventID?`
  - override 时用 `EventRegistry.require(eventId).generate(context:rng:)` 生成 offer（rng 使用 runState.seed 派生即可，P2 不强求与原 deriveSeed 完全一致）
- （可选，若要自定义商店库存）`Sources/GameCLI/Rooms/Handlers/ShopRoomHandler.swift`
  - 增加 `inventoryOverride: ShopInventory?`

#### UI（选择器屏幕）

- `Sources/GameCLI/Screens/DeveloperToolsScreen.swift`
  - 拆分成若干小屏幕/函数（避免单文件过大）：
    - `DeveloperTeleportScreen`：房间类型 + 覆盖选择
    - `DeveloperDeckEditorScreen`
    - `DeveloperRelicEditorScreen`
    - `DeveloperResourceEditorScreen`（HP/金币/Act/seed）
- 选择器交互建议（尽量简单稳定）：
  - 单选：显示 `[1..N]` 列表 + `[0] 取消`
  - 多选：显示当前已选 + `[a] 添加` / `[r] 移除` / `[q] 完成`
  - 列表过长时支持“输入过滤关键字”（例如输入 `/jaw` 过滤）

### P2.3 验收标准

- 能在调试沙盒中：
  - 指定敌人 ID 并进入战斗（战斗界面显示选择的敌人名称/数量）
  - 指定事件 ID 并进入事件（事件标题与 icon 对应）
  - 添加遗物后进入战斗，战斗界面遗物栏可见
  - 编辑牌组后进入战斗，手牌/抽牌来自编辑后的牌组
- 不开启 dev 时：以上能力不可见/不可触达

### P2.4 测试与验证

新增/扩展白盒测试（GameCLITests）：

- `EnemyRegistry.allEnemyIds` smoke：非空且包含已知 enemyId
- Dev teleport 覆盖：
  - 选择指定 `EnemyID`（例如 `jaw_worm`）→ 进入 battle → stdout 含敌人名
  - 指定 `EventID`（例如 `training`）→ 进入 event → stdout 含事件名
  - 设置金币/牌组/遗物后状态变化符合预期

完成 P2 后执行：`swift test`

---

## P3：体验与可维护性增强（可选但推荐）

### P3.1 交付内容（按需取舍）

- **更顺手的编辑体验**
  - 牌组编辑支持批量数量（例如一次加 5 张）
  - 遗物编辑支持按稀有度分组
  - 更好的过滤（上一轮关键字记忆）
- **沙盒配置保存（轻量）**
  - 保存“上次调试配置”到 `settings.json`（仅 dev 模式读取/写入）
- **隔离策略增强**
  - 提供选项：将调试战绩写入独立历史文件（例如 `battle_history_dev.json`）
- **文档**
  - 在 `.cursor/rules/Salu游戏业务说明（玩法系统与触发规则）.mdc` 或 HelpScreen 中补充开发者开关说明：
    - `SALU_DEV=1` / `--dev` 启用开发者调试

### P3.2 测试与验证

- 针对“保存上次配置”的单测（GameCLITests）
- 若增加新的 UI 路径：补一个最小黑盒 UI 测试，确保不超时
- 完成 P3 后执行：`swift test`

---

## 6. 风险点与规避

- **菜单项变更导致 UI 测试脆弱**：所有 UI 测试尽量使用 `contains` 断言关键文案；避免严格行匹配
- **覆盖逻辑污染正式流程**：override 字段默认 nil，仅 DeveloperTools 构造 handler 时赋值；正式 `RoomHandlerRegistry.makeDefault()` 继续用默认 init
- **列表增长导致选择器太长**：P2 预留过滤输入（最小实现：支持输入 `/关键词`）
- **不小心写入真实数据目录**：调试模式默认用 InMemory store 或强制 `SALU_DATA_DIR` 指向临时目录（两层保险）

