---
name: salu-plan-executor
description: Execute an existing Salu plan document under `.codex/plans/*.md` by implementing priorities P1..PN sequentially. Use when the user says "执行这个 plan/按 plan 开始干/照这个清单做", wants iterative implementation with verification after each priority (swift test/build), and expects code/docs updates per completed priority.
---

# Salu Plan Executor（执行 Plan）

## 输入要求

- 用户指定一个 plan 文件路径（通常在 `.codex/plans/*.md`）。
- 如果用户没给路径，先问 1 个问题：要执行哪份 plan？（一次只问一个）

## 核心工作流（强制）

### Step 1：只看 P1
- 先定位 P1 的目标/改动点/验收。
- 打开所有相关代码与文档再动手（不要凭记忆）。

### Step 2：实现 P1（最小改动、可回滚）
- 优先修根因，不做无关重构。
- GameCore：保持纯逻辑层约束；GameCLI：中文文案、依赖方向正确。
- 若 P1 需要新增/更新测试：同步补齐。

### Step 3：验证 P1
- 默认跑：`swift test`
- 如果 P1 改动极小且测试很慢：至少 `swift build`，并说明为什么不跑全量测试。
- 红了就修到绿（必要时可修 bug / 小重构以提升可测性）。

### Step 4：更新文档与计划状态
- 在 plan 文件里把 P1 标记为完成，并记录验证命令与结果。
- 如行为有变化：同步更新 `README.md` 或对应 `.codex/docs/*.md`（仅在必要时）。

### Step 5：调用反馈 MCP（如果你的环境里有）
- 在每个 P 完成后做一次回合式反馈；用户无异议再进入下一优先级。

### Step 6：进入 P2、P3…（重复 Step 1-5）

## 输出格式（每个 P 完成后）
- 已完成内容（按文件/模块）
- 验证命令与结果
- 文档变更（如有）
- 下一步：确认是否继续 P{n+1}
