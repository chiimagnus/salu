# 2026-01-04 计划审查记录

## 总览
- 目标文件：`architecture-design.md`、`protocol-driven-design-plan.md`
- 结论：P1~P6 已按文档描述落地；文档存在若干状态标记与内容滞后的问题，已在下方列出并修正。

## 发现的问题
1. `protocol-driven-design-plan.md` 头部状态仍写为 “P3 进行中”，与正文中 P3~P6 已完成的描述不一致。
2. `protocol-driven-design-plan.md` 中 P2 验收清单重复且包含未勾选项，导致完成度表述矛盾。
3. `protocol-driven-design-plan.md` 的 P3/P4 小节仍保留 “Commits: [将在提交时填写]” 的占位符，缺少已合并的提交标记。
4. `architecture-design.md` 的 “当前限制” 列表仍描述为“单场战斗/无地图/无遗物”，与现有实现（地图、遗物、冒险流程已落地）不符。
5. **P7 存档系统实现存在致命序列化问题**：`SaveService` 使用 `String(describing:)` 序列化 `CardID/StatusID/RelicID/RoomType`，会写出 `CardID(rawValue: "...")` 这种字符串，导致加载后 `CardRegistry.require` 崩溃。
6. **GameCore 违反“禁止导入 Foundation”约束**：`BattleHistoryStore.swift` / `RunSaveStore.swift` 不必要地 `import Foundation`（应保持纯协议）。
7. **存在残留向后兼容层**：`ScreenRenderer` 别名与 `BattleEngine.applyDebuff`（deprecated）不符合“破坏性策略：不保留兼容层”的要求。

## 处置
- 已更新上述两份计划文档以反映真实完成状态，消除重复/未勾选的验收项，并注明 P3/P4 提交记录需后续补全。
- ✅ 已修复问题 5：统一使用 `rawValue` 存档；加载时对未知 `RoomType/CardID/RelicID` 直接报错为 `SaveError.corruptedSave`，避免静默 fallback。
- ✅ 已修复问题 6：移除 GameCore 持久化协议文件的 `import Foundation`；并将 `RunSnapshot` 放回 `GameCore/Run`（符合计划结构）。
- ✅ 已修复问题 7：删除 `ScreenRenderer` 别名与 `BattleEngine.applyDebuff` 兼容逻辑，确保无兼容层残留。
- ✅ 新增 `test_save.sh` 并接入 `test_game.sh save`，将存档/继续冒险纳入自动化回归测试。
