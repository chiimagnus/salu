# GameCLI 模块开发规范

> 设定/剧情/玩法规则文档优先对齐 `.codex/docs/`。

## 模块定位

GameCLI 是 CLI 表现层，负责：

- 终端渲染（ANSI/布局/导航栏）
- 用户输入解析（`readLine()`）
- 流程编排（主菜单 → 冒险地图 → 房间 → 战斗）
- 本地持久化（存档/战斗历史/设置/调试日志）

**GameCLI 不承载规则计算**：伤害、奖励生成、地图推进、敌人/卡牌/状态定义均来自 GameCore。

## 目录结构（以当前代码为准）

```
Sources/GameCLI/
├── GameCLI.swift               # 入口 + 主菜单 + 冒险循环 + 战斗循环 + 统一日志
├── Screens.swift               # 屏幕聚合入口（只做转发/组织）
├── Terminal.swift              # ANSI 常量与终端工具（clear/flush/healthBar 等）
├── TestMode.swift              # UI 黑盒测试模式（环境变量开关、压缩地图/牌组/敌人 HP）
├── Components/
│   ├── EventFormatter.swift    # BattleEvent → 彩色字符串
│   ├── NavigationBar.swift     # 底部导航栏与 waitForBack
│   └── String+ANSI.swift       # 去 ANSI（落盘日志/稳定对比）
├── Flow/
│   ├── RoomHandling.swift      # RoomHandling/RoomContext/结果枚举
│   └── RoomHandlerRegistry.swift # RoomType → handler（makeDefault 注册）
├── Rooms/Handlers/
│   ├── StartRoomHandler.swift
│   ├── BattleRoomHandler.swift
│   ├── EliteRoomHandler.swift
│   ├── RestRoomHandler.swift
│   ├── ShopRoomHandler.swift
│   ├── EventRoomHandler.swift
│   └── BossRoomHandler.swift
├── Persistence/
│   ├── SaveService.swift
│   ├── FileRunSaveStore.swift
│   ├── HistoryService.swift
│   ├── FileBattleHistoryStore.swift
│   ├── SettingsStore.swift
│   ├── RunLogService.swift
│   ├── RunLogStore.swift
│   └── FileRunLogStore.swift
└── Screens/
    ├── MainMenuScreen.swift
    ├── MapScreen.swift
    ├── BattleScreen.swift
    ├── RewardScreen.swift
    ├── RelicRewardScreen.swift
    ├── ShopScreen.swift
    ├── EventScreen.swift
    ├── PrologueScreen.swift
    ├── ChapterEndScreen.swift
    ├── HistoryScreen.swift
    ├── StatisticsScreen.swift
    ├── SettingsScreen.swift
    ├── HelpScreen.swift
    ├── ResourceScreen.swift
    └── ResultScreen.swift
```

---

## 设计原则

### 单一职责（SRP）

- `Screens/*`：只负责“渲染 + 读取输入”（不要在 Screen 里直接写文件/拼存档/写历史）。
- `Rooms/Handlers/*`：负责单个房间的完整流程（必要时调用 Screen、更新 `RunState`、写日志）。
- `Persistence/*Store`：只做文件 I/O 与路径选择。
- `Persistence/*Service`：承载业务转换/缓存/兼容校验（例如 `RunSnapshot ↔︎ RunState`）。

### 依赖方向（必须）

```
GameCLI → GameCore  ✅ 允许
GameCore → GameCLI  ❌ 禁止
```

### 避免对“扩展点 ID”写 switch

- 卡牌/状态/敌人/遗物/消耗品的展示信息，必须从 GameCore 的 Registry 读取。
- 允许对“封闭事件枚举”做 switch（例如 `BattleEvent` 在 `EventFormatter` 里）。

### 可复现性（强烈建议）

- CLI 默认 seed 来源是时间戳（不可复现）；复现/验收请显式传 `--seed`。
- 不要在 GameCLI 里引入额外随机源；需要随机行为应落在 GameCore（受 seed/RNG 控制）。

### 输入/EOF 约定（避免测试卡死）

- 在可能跑于管道/黑盒测试的输入点，遇到 EOF（`readLine()==nil`）应默认“退出/跳过”。
- `battleLoop`：`q` 视为中途退出（上层保留存档），`0` 结束回合，出牌支持 `N` 或 `N M`。
- `runLoop`：地图输入 `q` 返回主菜单并保存，输入 `abandon` 进入放弃确认。

---

## 运行与调试

### CLI 参数（当前实现）

- `--seed 1` / `--seed=1`：固定种子
- `--history` / `-H`：直接打开历史
- `--stats` / `-S`：直接打开统计

### 常用环境变量

- `SALU_DATA_DIR=/tmp/salu`：覆盖数据目录（存档/历史/设置/调试日志都会写入这里）
- `SALU_TEST_MODE=1`：启用 UI 黑盒测试模式
- `SALU_TEST_MAP=mini|battle|shop|rest|event`：固定小地图（加速 UI 测试）
- `SALU_TEST_MAX_FLOOR=2`：覆盖 Act 数（验证“推进下一幕”链路）
- `SALU_TEST_BATTLE_DECK=minimal|run|seer|seer_p7`：覆盖测试战斗牌组
- `SALU_TEST_ENEMY_HP=1|10|normal|keep`：测试模式下覆盖敌人 HP（默认 1；`normal/keep` 保留真实 HP）
- `SALU_FORCE_MULTI_ENEMY=1`：强制普通战斗进入双敌人遭遇（本地验收目标选择）

### 数据文件名（便于排查/清理）

- 存档：`run_save.json`
- 战斗历史：`battle_history.json`
- 设置：`settings.json`
- 调试日志：`run_log.txt`

---

## 扩展指南

### 添加新屏幕

1. 在 `Screens/` 新增 `XxxScreen.swift`。
2. 需要对外暴露时，在 `Screens.swift` 增加一个静态转发函数。
3. 确保：屏幕函数只做渲染与输入，不做持久化。

### 添加新房间

1. 在 `Rooms/Handlers/` 新增 `XxxRoomHandler.swift` 并实现 `RoomHandling`。
2. 在 `RoomHandlerRegistry.makeDefault()` 注册。
3. 房间内更新 `RunState` 后，交由 `GameCLI.runLoop` 在节点完成时自动存档。

### 添加/修改持久化

- 新增文件存储：优先 `*Store`（路径选择/JSON 编解码/原子写）。
- 需要业务转换或缓存：放在 `*Service`。
- 测试/调试隔离数据：优先使用 `SALU_DATA_DIR`。

---

## 导航栏组件（NavigationBar）

统一的底部导航栏，用于在界面底部显示操作提示：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⌨️ [q] 返回
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
请选择 >
```

使用方式：

```swift
NavigationBar.render(items: [.back])
NavigationBar.waitForBack()
```

---

## 终端控制

### 颜色使用

```swift
print("\(Terminal.red)错误文本\(Terminal.reset)")
print("\(Terminal.bold)\(Terminal.green)成功\(Terminal.reset)")
```

### 屏幕刷新

```swift
Terminal.clear()
// ... 打印所有内容 ...
Terminal.flush()
```

---

## 界面布局（战斗）

```
┌─────────────────────────────────────────────┐
│ 标题栏（回合数、种子）                         │
├─────────────────────────────────────────────┤
│ 敌人区域（敌人列表：序号、名称、HP条、格挡、意图）│
├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤
│ 玩家区域（名称、HP条、格挡、能量）              │
├─────────────────────────────────────────────┤
│ 手牌区域（卡牌列表）                          │
├─────────────────────────────────────────────┤
│ 牌堆信息（抽牌堆/弃牌堆）                      │
├─────────────────────────────────────────────┤
│ 日志（最近6条，可在设置中开关）                 │
├─────────────────────────────────────────────┤
│ 消息区域（错误提示等）                        │
├━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┤
│ 操作提示栏                                   │
└─────────────────────────────────────────────┘
```

---

## 检查清单

- [ ] 颜色使用 `Terminal` 常量（不硬编码 ANSI）
- [ ] Screen 只做渲染/输入，不做持久化
- [ ] 新房间通过 `RoomHandling` + 注册表扩展
- [ ] 复现/验收使用 `--seed`，测试隔离用 `SALU_DATA_DIR`
