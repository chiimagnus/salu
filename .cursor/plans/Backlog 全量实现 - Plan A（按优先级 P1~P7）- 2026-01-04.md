# Backlog 全量实现 - Plan A（按优先级 P1~P7）- 2026-01-04

> 目标：把目前“已具备主干闭环（地图/房间/战斗/存档/历史）”的 Salu，推进到具备《杀戮尖塔》核心成长循环（奖励/商店/升级/遗物/事件/多敌人/内容扩展）的版本。  
> 约束：遵守现有的**协议驱动开发（PDD）**架构（Definition + Registry + ID + Effect 管线），并确保**可复现性**（所有随机来自注入的 `SeededRNG`）。

> 更新（2026-01-06）：P1~P7 已完成；P7 的详细实现记录与分阶段验收见 `.cursor/plans/P7-内容扩展-PlanA-2026-01-06.md`。

## 0. 现状基线（已完成）

- 结构：GameCore（逻辑）/ GameCLI（表现）模块分离
- 框架：Cards/Status/Enemies/Relics/Events 均已协议化 + registry 化
- Run：地图（Act1）+ 房间 handler 流程 + HP/金币/牌组/遗物 跨房间保持
- I/O：History/Save 已隔离在 GameCLI
- 测试：`swift test` 可通过

## 1. 总体优先级策略

优先做“玩家体验闭环”，再做大规模架构改动：

1) **战斗复杂度提升**：多敌人 + 目标选择（P6，架构级）  
2) **内容扩展**：Act2、更多敌人/精英/Boss/卡牌/遗物（P7）

每完成一个 Px：必须执行一次验证（至少 `build + all tests`）。

---

## P7：内容扩展（Act2/更多卡牌/敌人/精英/Boss）⭐⭐⭐

### 目标

- 扩充卡牌、敌人、遗物数量
- 至少提供 1 个“真正的 Boss 定义”（独特技能循环）
- 为 Act2 引入新的地图生成策略（继续沿用 MapGenerating 扩展点）

### 验证

- `swift test`
- `swift build -c release`

### 当前实现状态（摘要）

- ✅ Act1：已扩充真 Boss、普通/精英敌人、遭遇池、卡牌与遗物池
- ✅ Act2：已接入最小骨架（Act1→Act2 推进、Act2 敌人池/遭遇池/Boss）

 