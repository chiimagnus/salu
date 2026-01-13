---
name: plan-reviewer
description: Review an existing plan markdown (P1/P2/P3...) by turning priorities into TODOs, auditing the code for gaps/risks/missed cases, and recording findings in a new markdown review file. Use when the user says "审查 plan/根据 plan 建 todo/按 P1~PN 查漏补缺/做代码审计但按计划维度输出".
---

# Plan Reviewer（按计划审查）

## 目标输出

- 从 plan 的 `P1..PN` 生成 `N` 个 TODO（顺序审查）。
- 对每个 P：定位相关代码、找问题/遗漏/潜在回归点。
- **先记录**发现（保存为 `.codex/plans/review-YYYY-MM-DD-<topic>.md` 或用户指定路径），再决定是否动代码。

## 工作流（强制）

### Step 1：拿到 plan 路径（一次只问一个问题）
- 如果用户没给 plan 文件：先问“要审查哪份 plan？”

### Step 2：解析 plan，生成 TODO 列表
- TODO 命名：`P1 - <title>`、`P2 - <title>`...
- 每个 TODO 需要指向：目标、改动点（文件/类型）、验收。

### Step 3：逐个 TODO 审查（只做“审查”，不先改代码）
- 打开 plan 中提到的文件；再通过 `rg` 追踪相关符号/调用点。
- 重点关注：边界条件、错误路径、并发/可复现性、I/O/持久化、依赖方向、对外文案/接口一致性（按项目实际情况）。

### Step 4：记录发现（必须先落盘）
- 输出文件包含：
  - TODO 列表（打勾进度）
  - 每个 P 的发现：问题、影响、建议修复、建议测试
  - “高风险项”汇总（最应该优先补的回归测试/修复）

### Step 5：如果用户同意，再进入修复环节
- 用户确认后才开始按建议修复代码与补测试。
- 修复时遵守：最小改动、每修一块就 `swift test`。

## 模板

见：`references/review_template.md`
