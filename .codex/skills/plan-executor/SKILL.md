---
name: plan-executor
description: Execute an existing prioritized plan markdown (P1/P2/P3...) by implementing one priority at a time, verifying after each priority (tests/build/lint), and updating the plan status with commands/results. Use when the user says "执行这个 plan/按 plan 开始干/照这个清单做/从 P1 开始实现", wants iterative implementation with verification per priority, and expects code/docs updates as priorities are completed.
---

# Plan Executor（执行 Plan）

## 输入要求

- 用户指定一个 plan 文件路径（通常在 `.codex/plans/*.md`，也可以是任意 `.md`）。
- 如果用户没给路径，先问 1 个问题：要执行哪份 plan？（一次只问一个）

## 核心工作流（强制）

### Step 1：只看 P1
- 先定位 P1 的目标/改动点/验收。
- 打开所有相关代码与文档再动手（不要凭记忆）。

### Step 2：实现 P1（最小改动、可回滚）
- 优先修根因，不做无关重构。
- 遵守仓库的本地规范：`AGENTS.md` / `CONTRIBUTING.md` / `README.md` / CI 约束（按项目实际情况）。
- 若 P1 需要新增/更新测试：同步补齐（让变更可回归）。

### Step 3：验证 P1
- 优先使用 plan 里写明的验证命令；若 plan 未写明：先查 CI/README 里的标准命令。
- 至少跑一条“能发现明显回归”的验证（单测/构建/静态检查任一），并记录命令与结果。
- 红了就修到绿（必要时可做小范围可测性重构/修 bug，但保持克制）。

### Step 4：更新文档与计划状态
- 在 plan 文件里把 P1 标记为完成，并记录验证命令与结果。
- 如对外行为/接口/用法有变化：同步更新对应文档（仅在必要时）。

### Step 5：调用反馈 MCP（如果你的环境里有）
- 在每个 P 完成后做一次回合式反馈；用户无异议再进入下一优先级。

### Step 6：进入 P2、P3…（重复 Step 1-5）

## 输出格式（每个 P 完成后）
- 已完成内容（按文件/模块）
- 验证命令与结果
- 文档变更（如有）
- 下一步：确认是否继续 P{n+1}
