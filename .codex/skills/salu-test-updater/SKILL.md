---
name: salu-test-updater
description: Generate and update XCTest unit tests for the Salu SwiftPM repo (GameCore/GameCLI), focusing on Tests/GameCoreTests and Tests/GameCLITests. Use when asked to update tests for a specific Swift source file, or based on the last N git commits; keep `swift test` passing; allow small refactors in Sources for testability/bugfixes.
---

# Salu Test Updater

## 快速用法（你对 Codex 的典型说法）

- “请你更新这个文件 `Sources/GameCore/.../X.swift` 对应的单测（允许必要的小重构，跑 `swift test` 直到全绿）”
- “请你基于最近 `N` 个 commit 更新对应单测（同时覆盖 `Sources/GameCore` 和 `Sources/GameCLI`），跑 `swift test`”

## 工作流（建议严格按顺序做）

### 1) 明确输入范围

- 如果用户给了具体文件路径：以这些文件为主（可以再向下追踪直接依赖/调用点，但保持克制）。
- 如果用户给了“最近 N 个 commit”：用 `HEAD~N..HEAD` 作为范围，收集改动的 `Sources/**/*.swift` 文件。

建议先用脚本生成“测试更新清单”（不改代码）：

```bash
python3 ~/.codex/skills/salu-test-updater/scripts/salu_test_plan.py --repo . --files Sources/GameCore/XXX.swift
python3 ~/.codex/skills/salu-test-updater/scripts/salu_test_plan.py --repo . --last 5
```

### 2) 选择“改哪一个测试文件”而不是强行一对一新建

- 项目现状更偏“按功能聚合测试”，优先把用例补进现有 `*Tests.swift`。
- 只有当现有文件没有合适落点时，才新建一个更语义化的测试文件（例如围绕一个子系统/能力链路）。
- 脚本会给出“最可能相关的测试文件候选列表”（基于符号引用命中）。

### 3) 生成/更新单测（目标：真实断言 + 尽量全绿）

#### GameCore（`Tests/GameCoreTests`）偏好的测试形态

- **确定性**：显式使用 `seed` / `SeededRNG`，避免系统随机与时序依赖。
- **不做 I/O**：GameCore 本身是纯逻辑层；如果需要持久化，应该测协议/纯模型，而不是落盘。
- **更像“行为规格”**：通过 `BattleEngine` / `RunState` 等核心入口，用断言锁定可回归的业务行为与事件。

#### GameCLI（`Tests/GameCLITests`）偏好的测试形态

- **白盒 + 依赖注入**：用 `InMemory*Store` / closure 注入，避免触碰真实用户数据。
- **测试文本时先去 ANSI**：如需比对 stdout，参考 `ScreenAndRoomCoverageTests` 的做法。

### 4) 允许必要的小重构/修 bug（但要克制）

- 如果测试无法稳定/无法注入：优先做“小范围可测性重构”（抽出纯函数、增加注入点、修正可见性、避免硬编码依赖）。
- GameCore 仍需遵守“纯逻辑层”约束：不要引入 `print`/stdin/UI；尽量不引入 `Foundation`。

### 5) 验证（强制）

每次改完都跑：

```bash
swift test
```

如果红了：按“最小修复”迭代到全绿（测试/源码都允许改，但避免顺手重构无关代码）。

## 参考资料

- 现有测试风格速查：`references/salu_test_patterns.md`
