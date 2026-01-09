# Plan A（P1/P2/P3...）：先把 GameCore + GameCLI 做到“可长期演进的完整游戏”，再启动 macOS SwiftUI App - 2026-01-09

## 0. 目标（你最新确认的方向）

- **先完成 `GameCore` + `GameCLI`**：把玩法、内容、难度、存档等做扎实，形成一个“可长期运营/可持续扩展”的基线版本。
- **macOS SwiftUI App 放后面**：等核心系统稳定后，再做 macOS 原生 UI（届时能最大化复用 GameCore +（可选）应用层状态机）。

---

## 1. 为什么这个顺序合理

- **GameCLI 是最快的验证前端**：迭代内容/数值/规则更快，能尽早发现“核心玩法是否成立”。
- **GameCore 越稳定，未来 UI 越省事**：等规则、快照、难度、内容池稳定后，SwiftUI 只是换一层 View。

---

## 2. 核心约束（必须遵守）

- `GameCore`：
  - 纯逻辑：禁止 `print()`/stdin/UI；尽量不引入 `Foundation`
  - 内容扩展优先 “Definition + Registry”，避免在引擎里加 `switch` 扩展点
- `GameCLI`：
  - 用户可见文本中文
  - 颜色/清屏/刷新走 `Terminal`
  - 作为参考实现与调试入口（可加测试模式、资源查看、快速跑图等）

---

## 3. 里程碑定义（先把“完整”落地）

这里把“完整游戏”拆成 3 档：

- **M0：可通关版**：至少 2~3 Act、完整房间链路、存档/继续、结算与统计
- **M1：1.0 内容版**：显著扩充卡/敌人/事件/遗物 + 平衡调优 + 难度阶梯（Ascension/挑战）
- **M2：长期演进版**：多角色、多模式、成就、本地存档、更多可扩展点与工具链

你当前希望至少做到 **M1 + 部分 M2（多角色/多模式/成就/本地存档）**。

---

## 4. Plan A（P1 / P2 / P3 / P4 / P5 / P6）

每个 P 完成后都要求：

- `swift build`
- `swift test`
- （建议）用 CLI 快速冒烟：`swift run GameCLI --seed 1` + `SALU_TEST_MODE=1` 的测试路径

---

## P1：把“可通关主线”做完整（M0 目标）

### P1.1 交付

- 冒险主线可稳定通关（建议目标：**3 Act**；若当前先 2 Act，也要把扩到 3 Act 的接口留好）
- 节点完成自动存档、主菜单继续、冒险结束清档稳定可靠
- 战斗/奖励/遗物/事件/商店/休息点链路无硬崩

### P1.2 GameCore 重点

- Act 结构补齐：`Map`、`EnemyPool/EncounterPool`、Boss、奖励池覆盖
- RunSnapshot/版本管理：保证升级兼容（已有 `RunSaveVersion`，需要持续维护迁移策略）

### P1.3 GameCLI 重点

- 测试模式完善：稳定复现关键链路（多敌人/目标选择/Act 跳转/存档恢复）
- 结果页/统计页/资源页继续作为验收入口

---

## P2：内容扩充（卡/敌人/事件/遗物）+ 基础数值平衡（M1 目标的一半）

### P2.1 交付

- 卡池扩充到一个“能玩出 Build”的规模（例如：每个角色 60~120 张）
- 每个 Act 的普通/精英/Boss 有足够多样性（避免重复遭遇）
- 事件池扩充（风险/收益更丰富）
- 遗物池扩充（Build 方向更明确）

### P2.2 落地方式（遵循现有 Registry 设计）

- 卡牌：`Sources/GameCore/Cards/Definitions/...` 新增 Definition + 在 `CardRegistry` 注册
- 敌人：`Sources/GameCore/Enemies/Definitions/...` 新增 Definition + 遭遇池扩展
- 事件：`Sources/GameCore/Events/Definitions/...` 新增 Definition + 在 `EventRegistry` 注册
- 遗物：`Sources/GameCore/Relics/Definitions/...` 新增 Definition + 在 `RelicRegistry` 注册

### P2.3 验证

- 用固定 seed 跑 20 次，统计崩溃/软锁/数值异常
- 补若干 GameCore 单测覆盖关键新规则（确定性）

---

## P3：难度阶梯（Ascension / 挑战）+ 平衡调优（M1 完整）

### P3.1 交付

- 引入 `Difficulty`/`AscensionLevel`（建议在 GameCore RunState 里持有）
- 在关键策略中接入难度：
  - 敌人生命/伤害/意图概率
  - 奖励/金币/商店价格
  - 精英出现率/事件风险

### P3.2 CLI 接入

- 主菜单：选择难度（默认 0）
- 存档：保存难度

---

## P4：多角色（M2 的核心）

### P4.1 交付

- 新增 `CharacterID`/角色选择
- 每角色独立：起始牌组、遗物、卡池、（可选）专属事件/遗物

### P4.2 架构建议

- GameCore 继续坚持：内容通过 Registry 扩展
- 把“角色→可用内容集合”建模为策略/配置（避免在引擎写 switch）

### P4.3 CLI 接入

- 新开冒险：选择角色
- 资源页：按角色查看内容池

---

## P5：多模式（每日挑战/特殊规则/无尽等）（M2）

### P5.1 交付（先做 1~2 个模式）

- Daily Seed：每天固定 seed + 固定规则 modifier
- Challenge：例如“起始诅咒”“精英更强但奖励更好”等

### P5.2 落地方式

- GameCore：引入 `RunModifier`（或类似概念），影响生成策略/战斗规则
- CLI：模式选择入口 + 展示当前 modifiers

---

## P6：成就与本地存档（M2）

### P6.1 交付

- 成就定义（GameCore 纯定义/条件）+ 解锁记录（CLI 侧持久化）
- 统计页：显示成就进度
- 本地存档：存档格式稳定、可迁移、可清理

---

## 5. macOS SwiftUI App（后续启动时的最小策略）

当 P1~P3 稳定后，再启动 macOS App：

- UI 侧（Xcode SwiftUI）依赖本仓库 package
- 建议新增 `SaluApp`（应用层状态机）作为 SwiftUI 的 ViewModel 来源
- i18n 先做 UI 文案本地化，内容文本再分阶段抽离


