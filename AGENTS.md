# Salu 项目 Agent 指南

本仓库是 SwiftPM 项目（Swift 6.2），包含：

- `Sources/GameCore/`：纯逻辑层（游戏规则/状态/战斗引擎）
- `Sources/GameCLI/`：终端表现层（渲染/输入/存档与战绩服务）
- `Tests/`：XCTest

## 权威规范（优先阅读）

本仓库已有较完整的 Cursor 规则文档；它们也是当前项目的“事实来源”。在做任何较大改动前请先打开对应文档：

- `./.cursor/rules/CLAUDE.mdc`：项目总览、运行方式、CLI 参数、数据目录等
- `./.cursor/rules/gamecore.mdc`：`GameCore` 模块开发规范（纯逻辑层、PDD、Registry、Effect 管线等）
- `./.cursor/rules/gamecli.mdc`：`GameCLI` 模块开发规范（界面系统、依赖方向、I/O 服务注入等）
- `./.cursor/plans/backlog-2026-01-04.md`：未接入系统与后续扩展计划

## 本文件的用途

`AGENTS.md` 作为 **Codex CLI / 通用 Agent 的全局入口**，避免每次都需要人工指定“该看哪些规范”。细节约束以 `.cursor/rules/*.mdc` 为准，本文件只做索引与最小共识。

## 最小共识（适用于整个仓库）

- 改 `GameCore`：严格遵守“纯逻辑层”约束（禁止 `print`/stdin/UI；尽量不依赖 `Foundation`），优先 “新增 Definition + Registry 注册”，避免在引擎里新增分支型 `switch` 扩展点。
- 改 `GameCLI`：所有用户可见文本使用中文；终端控制/颜色使用 `Terminal`；保持 `GameCLI → GameCore` 单向依赖（禁止反向依赖）。
- 验证方式：优先运行 `swift test`；需要临时数据目录时使用环境变量 `SALU_DATA_DIR`。
- 变更范围：保持改动最小；新增/改行为尽量补对应测试，并按适用范围同步更新 `README.md` 或 `.cursor/rules/CLAUDE.mdc`。

