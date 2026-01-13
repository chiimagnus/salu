---
name: plan-writer
description: Write a prioritized implementation plan (P1/P2/P3...) and save it as markdown (usually under `.codex/plans/*.md`). Use when the user asks to "制定 plan/写 plan/出方案 A/做 roadmap/先规划再开工", wants a detailed prioritized backlog with acceptance criteria, or wants a plan before coding; ask one question at a time until requirements are clear, then inspect relevant code/docs and include per-priority verification steps (tests/build/lint).
---

# Plan Writer（制定 Plan）

## 输出目标

- 产出一份 **Plan A**（按 `P1/P2/P3...` 排序、可执行、可验收）并保存到 `.codex/plans/<name>.md`。
- 每个优先级完成后都明确“如何验证”：优先跑项目标准命令（测试/构建/静态检查），并写清预期结果。

## 交互规则（强制）

### 1) 先问问题（一次只问一个）

- 在写 plan 之前，先通过“单问单答”澄清需求。
- 每轮只问一个问题；根据回答继续追问，直到有 ≥95% 信心理解目标/范围/验收。
- 问题优先级：目标 → 范围 → 验收标准 → 风险/约束 → 交付格式。

### 2) 再读代码/文档（不要凭空写）

- 必须检索并打开所有“相关 & 可能相关”的文件再落笔：
  - `.codex/docs/*.md`
  - `.codex/plans/*.md`（现有计划/清单）
  - `Sources/` & `Tests/` 中命中的实现与测试
  - `README.md` / `Package.swift`
  - 所有`AGENTS.md`

## 工作流

### Step 1：确定计划文件名与路径
- 默认命名：`.codex/plans/plan-YYYY-MM-DD-<topic>.md`
- 如果用户已有命名偏好，按用户给的来。

### Step 2：建立范围清单（你要去看的文件）
- 用 `rg` 在 `Sources/`、`Tests/`、`.codex/`、`README.md`、`Package.swift` 搜索关键词。
- 把“将要查看的文件列表”写进 plan 的“调研范围”小节，便于复盘。

### Step 3：写 Plan A（分 P1/P2/P3...）
- **P1**：必须完成且能显著降低风险/阻塞后续（例如：架构走通、关键 bug、关键测试、关键接口）。
- **P2**：重要但可延后（功能补齐、覆盖更多边界）。
- **P3**：优化/清理/体验（重构、性能、文案）。

每个 P 至少包含：
- **目标**：一句话说明完成后用户能得到什么。
- **改动点**：指向具体模块/文件/关键类型。
- **实现步骤**：按依赖顺序列出。
- **测试/验证**：明确命令与预期（例如 `swift test`）。
- **风险**：潜在回归点与缓解方式（例如补回归测试）。

### Step 4：在 plan 末尾加“执行工作流约束”
- 每做完一个 P：先跑项目标准验证命令确认无回归，再进入下一个 P。
- 每个 P 完成后：更新 plan 中该 P 的状态与验证结果。

## Plan 模板（复制到新文件再填充）

见：`references/plan_template.md`

## 项目约束速查

- 参考：所有 `AGENTS.md` / `CONTRIBUTING.md` / CI 配置
