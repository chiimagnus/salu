---
title: Plan A（Salu）
date: YYYY-MM-DD
---

# Plan A：<主题>

## 0. 目标与验收（必须可验证）
- 目标：
- 非目标（不做什么）：
- 验收标准（可复现的操作 + 预期结果）：

## 1. 约束与前置
- 约束：GameCore 纯逻辑层（无 print / stdin / UI；尽量不依赖 Foundation）
- 约束：GameCLI → GameCore 单向依赖；用户可见文本中文
- 测试策略：每完成一个 P 必须跑 `swift test`（至少 `swift build`）

## 2. 调研范围（本次 plan 实际查过的文件）
- 文档：
  - `.cursor/rules/...`
  - `.cursor/plans/...`
- 代码：
  - `Sources/...`
  - `Tests/...`

## 3. Plan A（按优先级）

### P1（必须）
#### 目标
- ...
#### 改动点
- `path/to/file.swift`（关键类型：`TypeName`）
#### 实现步骤
1. ...
2. ...
#### 测试/验证
- `swift test`
#### 风险与回归点
- ...

### P2（重要）
（同上结构）

### P3（优化）
（同上结构）

## 4. 执行工作流（执行 plan 时遵守）
- 只做当前 P 的内容；做完立刻验证；验证通过才进入下一个 P。
- 每完成一个 P：更新本文件状态与验证结果。

