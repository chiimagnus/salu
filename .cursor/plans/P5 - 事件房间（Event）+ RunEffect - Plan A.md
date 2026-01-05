# P5：事件房间（Event）+ RunEffect - Plan A（按优先级 P1~P5）

> 目标：在 Salu 的冒险地图中引入 **事件节点（“？”）**，进入后展示事件文本与多选项，并对本次冒险（RunState）产生可复现影响（金币/HP/卡牌/遗物等）。
>
> 用户交互约束：**地图上先显示“？”事件节点信息**；进入节点后再展示事件与选项。
>
> 全局约束：遵守现有 PDD（Definition + Registry + ID + Effect 管线），保持 **可复现性**（同 seed + 同路径 + 同选择 → 结果稳定）。

---

## 0. 现状盘点（与 P5 相关）

- **地图推进**：`RunState` 只认识 `RoomType.start/battle/elite/rest/shop/boss`，无 event。
- **房间流程**：GameCLI 用 `RoomHandlerRegistry` 按 `RoomType` 选择 handler；缺少 EventRoomHandler。
- **可复现模式**：奖励/商店/遗物均采用“从 context 派生 seed”的策略（可参考 Reward/Shop/Relic 的实现）。
- **测试现状风险点**：
  - 部分 CLI UI 测试使用固定输入脚本进入“第一战斗”，隐含假设：**起点后的首个节点是战斗**。
  - 为避免 P5 接入后大面积测试波动，Plan 会把“事件节点分布”设计为 **不影响 row1/row2 的稳定性**，并先用 `SALU_TEST_MAP` 引入事件 UI 测试入口。

---

## 1. 目标与验收标准（P5 整体）

- **地图显示**：事件节点在地图与节点选择列表中显示为 **“？”**（未知事件）。
- **进入事件**：进入事件房间后展示事件文本 + 多个选项，玩家可选择 1 个选项并结算。
- **影响落地**：事件选择会对 RunState 产生影响（至少覆盖：金币、HP、卡牌、遗物中的若干项）。
- **可复现**：固定 seed 下，同样的路径与选择，事件内容与结算结果保持一致。
- **验证**：每完成一个优先级（P1/P2/…）都必须通过：
  - `swift test`
  - `swift build -c release`

---

## P1（基础能力）：定义 RunEffect + RunState 应用入口（纯逻辑）

### 产出

- GameCore 新增 `RunEffect`（Run 维度效果枚举）
- `RunState` 新增 `apply(_:)`（或等价纯函数）用于将 RunEffect 作用到 RunState

### RunEffect 初版建议覆盖

- 金币：`gainGold(Int)` / `loseGold(Int)`（不允许 gold < 0）
- 生命：`heal(Int)` / `takeDamage(Int)`（HP clamp 到 0...maxHP；为 0 触发 run 失败）
- 卡牌：`addCard(CardID)`（生成实例 ID 并加入 deck）
- 遗物：`addRelic(RelicID)`（复用现有“不可重复”规则）

> 注意：P1 只做“效果定义 + 纯逻辑落地”，不接入 UI、不改地图生成，确保这一阶段不影响现有玩法。

### 单元测试

- `RunEffect` 应用后的 RunState 变化可断言（gold/HP/deck/relicIds）

### 验证

- `swift test`
- `swift build -c release`

---

## P2（事件内容）：EventDefinition + Registry + Pool（纯逻辑，可复现）

### 产出

- 强类型 `EventID`（与 CardID/RelicID 一致的强类型 ID）
- `EventDefinition` 协议：
  - `id / name / description / icon(?) / options`
- `EventOption` 数据结构（选项文本 + 对应的 RunEffect 或“由上下文派生的 RunEffect”）
- `EventRegistry`（新增事件定义的唯一入口）
- `EventPool` / `EventGenerator`（从上下文派生 seed，选择本次事件，保证可复现）

### 上下文（EventContext）

建议定义 `EventContext`（字段与 RewardContext 类似）：

- `seed / floor / currentRow / nodeId`
- （可选）`playerHP / gold / deckCount / relicIds` 用于事件条件判断

### 事件内容（至少 3 个“完整事件”）

初版事件建议覆盖不同 RunEffect 类型（每个事件至少 2 个选项）：

- **事件 A：拾荒者**
  - 选项 1：获得金币（+X）
  - 选项 2：失去生命（-Y）换取更高金币（+Z）
- **事件 B：祭坛**
  - 选项 1：失去金币（-X）获得遗物（从可用遗物池挑 1 个，可复现）
  - 选项 2：跳过
- **事件 C：训练**
  - 选项 1：升级一张起始牌（等价于把某张可升级卡替换成 + 版；若需要玩家选牌，则把“选牌 UI”放到 P3/P4）
  - 选项 2：获得一张普通卡（+CardID）

> 约束：不要用占位事件；每个事件都要能完整结算并改变 RunState。

### 单元测试

- **确定性**：同 context 生成的事件一致
- **排除规则**（如事件给遗物）：不掉落 starter、不重复已拥有

### 验证

- `swift test`
- `swift build -c release`

---

## P3（CLI 接入）：EventScreen + EventRoomHandler（先走测试地图）

### 产出

- GameCLI 新增 `EventScreen`：
  - 展示：标题、事件名/描述、选项列表
  - 输入：`1-n` 选择、`0` 返回/跳过（按事件设计决定）
  - 结算后给出“结果提示”，按 Enter 返回地图
- GameCLI 新增 `EventRoomHandler`：
  - 生成 Event（用 EventContext 派生 seed）
  - 调用 EventScreen 获取选择
  - 将 RunEffect 应用到 RunState
  - `completeCurrentNode()`

### 测试入口（避免破坏既有 UI 测试）

- 扩展 `SALU_TEST_MAP`：
  - 新增一种测试地图：起点 → 事件 → Boss（保证 P5 UI 测试稳定且路径短）
- 在 `RoomHandlerRegistry` 注册 EventRoomHandler（至少对测试地图可达）

### CLI UI 测试

- 新增 `GameCLIEventUITests`：
  - 用 `SALU_TEST_MODE=1` + `SALU_TEST_MAP=event`
  - 驱动：进入事件 → 选项 1 → 返回地图 q → 退出
  - 断言：`run_save.json` 里 gold/HP/deck/relicIds 等字段发生预期变化

### 验证

- `swift test`
- `swift build -c release`

---

## P4（正式接入地图）：RoomType.event + MapGenerator 分布策略 + 真实冒险可达

### 产出

- GameCore：`RoomType` 新增 `.event`
  - `displayName`: 建议“未知事件”
  - `icon`: **“？”**（实现层可用 “❓” 作为字符）
- MapGenerator：增加 event 节点分布策略（可复现）
  - 建议：从 **row3~row12** 才可能出现事件，避免影响“首战”测试与新手节奏
  - （可选）增加“至少 1 个事件节点”的保底规则（类似 shop 保底）
- GameCLI：确保 EventRoomHandler 在默认 registry 中注册

### 回归测试修正点（提前列出）

- 若 event 分布导致某些 UI 测试脚本不再保证进入战斗：
  - 优先方案：保持 row1/row2 不生成 event，确保脚本稳定
  - 备选方案：把依赖固定路径的 UI 测试改为“动态找路径”（像 RestUpgradeUITests 那样）

### 验证

- `swift test`
- `swift build -c release`

---

## P5（完善与扩展）：选项预览、更多 RunEffect、更多事件

### 方向

- 选项预览文本更明确（例如“获得 50 金币 / 失去 8 HP”）
- 引入“需要玩家二次选择”的事件（如：升级任意一张可升级卡 / 删除任意一张牌）
- 增加事件数量与事件池策略（稀有度、重复保护、与楼层/进度关联等）

### 验证

- `swift test`
- `swift build -c release`


