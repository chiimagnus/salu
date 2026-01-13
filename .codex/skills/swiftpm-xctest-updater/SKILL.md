---
name: swiftpm-xctest-updater
description: Generate and update XCTest unit tests for a Swift Package Manager repo, focusing on `Sources/` and `Tests/` and keeping `swift test` passing. Use when asked to update tests for specific Swift source files or for changes in the last N git commits; allow small refactors/bugfixes in `Sources/` to improve testability and determinism.
---

# SwiftPM XCTest Updater

## 快速用法（你对 Codex 的典型说法）

- “请你更新这个文件 `Sources/<Target>/.../X.swift` 对应的单测（允许必要的小重构，跑 `swift test` 直到全绿）”
- “请你基于最近 `N` 个 commit 更新对应单测（覆盖所有改动到的 `Sources/**/*.swift`），跑 `swift test`”

## 工作流（建议严格按顺序做）

### 1) 明确输入范围

- 如果用户给了具体文件路径：以这些文件为主（可以再向下追踪直接依赖/调用点，但保持克制）。
- 如果用户给了“最近 N 个 commit”：用 `HEAD~N..HEAD` 作为范围，收集改动的 `Sources/**/*.swift` 文件。

建议先用脚本生成“测试更新清单”（不改代码）：

```bash
python3 .codex/skills/swiftpm-xctest-updater/scripts/test_plan.py --repo . --files Sources/MyTarget/XXX.swift
python3 .codex/skills/swiftpm-xctest-updater/scripts/test_plan.py --repo . --last 5
```

### 2) 选择“改哪一个测试文件”而不是强行一对一新建

- 项目现状更偏“按功能聚合测试”，优先把用例补进现有 `*Tests.swift`。
- 只有当现有文件没有合适落点时，才新建一个更语义化的测试文件（例如围绕一个子系统/能力链路）。
- 脚本会给出“最可能相关的测试文件候选列表”（基于符号引用命中）。

### 3) 生成/更新单测（目标：真实断言 + 尽量全绿）

- **确定性**：避免系统随机与时序依赖（必要时显式 seed，或注入可控 RNG/Clock）。
- **避免真实 I/O**：优先用依赖注入/协议/闭包替代落盘、网络、系统时间等不可控因素。
- **更像“行为规格”**：从稳定入口驱动（公开 API/核心流程），用断言锁定可回归行为。
- **输出文本**：如果要断言 stdout/stderr，先考虑去除 ANSI、去抖动时间戳等噪声。

### 4) 允许必要的小重构/修 bug（但要克制）

- 如果测试无法稳定/无法注入：优先做“小范围可测性重构”（抽出纯函数、增加注入点、修正可见性、避免硬编码依赖）。
- 尽量不要为了测试引入不必要依赖；优先保持 API 面向使用者清晰。

### 5) 验证（强制）

每次改完都跑：

```bash
swift test
```

如果红了：按“最小修复”迭代到全绿（测试/源码都允许改，但避免顺手重构无关代码）。

## 参考资料

- XCTest/SwiftPM 测试风格速查：`references/xctest_test_patterns.md`
