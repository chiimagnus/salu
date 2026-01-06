# 仓库指南
`AGENTS.md` 作为 **Codex CLI / 通用 Agent 的全局入口**，避免每次都需要人工指定“该看哪些规范”。细节约束以 `.cursor/rules/*.mdc` 为准，本文件只做索引与最小共识。

## 权威规范（优先阅读）

本仓库已有较完整的 Cursor 规则文档；它们也是当前项目的“事实来源”。在做任何较大改动前请先打开对应文档：

- `./.cursor/rules/CLAUDE.mdc`：项目总览、运行方式、CLI 参数、数据目录等
- `./.cursor/rules/gamecore.mdc`：`GameCore` 模块开发规范（纯逻辑层、PDD、Registry、Effect 管线等）
- `./.cursor/rules/gamecli.mdc`：`GameCLI` 模块开发规范（界面系统、依赖方向、I/O 服务注入等）
- `./.cursor/plans/backlog-2026-01-04.md`：未接入系统与后续扩展计划

## 项目结构与模块组织

- `Package.swift`: SwiftPM 清单文件 (Swift 6.2)。
- `Sources/GameCore/`: 纯游戏逻辑 (规则/状态/引擎)。保持无UI且可测试。
- `Sources/GameCLI/`: 终端前端 (界面、渲染/输入、持久化服务)。
- `Tests/`: XCTest 目标
  - `Tests/GameCoreTests/`: 确定性核心逻辑的单元测试。
  - `Tests/GameCLITests/`: 可注入CLI服务的白盒测试 (例如 save/history)。
  - `Tests/GameCLIUITests/`: 通过 `Process` 启动 `GameCLI` 的黑盒"UI"测试。
- `.github/workflows/`: CI 构建 debug + release 并运行测试 (在 `test.yml` 上启用覆盖率)。
- `.cursor/rules/`: 更深入的架构说明 (`CLAUDE.mdc`, `gamecore.mdc`, `gamecli.mdc`)。

## 最小共识（适用于整个仓库）

- 改 `GameCore`：严格遵守“纯逻辑层”约束（禁止 `print`/stdin/UI；尽量不依赖 `Foundation`），优先 “新增 Definition + Registry 注册”，避免在引擎里新增分支型 `switch` 扩展点。
- 改 `GameCLI`：所有用户可见文本使用中文；终端控制/颜色使用 `Terminal`；保持 `GameCLI → GameCore` 单向依赖（禁止反向依赖）。
- 验证方式：优先运行 `swift test`；需要临时数据目录时使用环境变量 `SALU_DATA_DIR`。
- 变更范围：保持改动最小；新增/改行为尽量补对应测试，并按适用范围同步更新 `README.md` 或 `.cursor/rules/CLAUDE.mdc`。

## 构建、测试和开发命令

- 运行游戏: `swift run` (或 `swift run GameCLI`)
- 确定性运行: `swift run GameCLI --seed 1`
- 构建二进制文件: `swift build` (debug), `swift build -c release`
- 运行测试: `swift test` (所有目标), `swift test --enable-code-coverage`
- 有用的环境变量:
  - `SALU_DATA_DIR=/tmp/salu`: 覆盖 save/history 目录 (测试/调试用)。
  - `SALU_TEST_MODE=1`: CLI UI 测试的稳定快速模式。
  - `SALU_TEST_MAP=1|mini|battle|shop|rest|event`: 测试模式下使用极小地图（加速 UI 测试）。
  - `SALU_TEST_MAX_FLOOR=2`: （测试模式）覆盖最大楼层（Act 数，默认 1），用于验证 Act1→Act2 推进与存档。
  - `SALU_FORCE_MULTI_ENEMY=1`: 强制普通战斗进入双敌人遭遇（便于验收目标选择）。
  - `SALU_CLI_BINARY_PATH=...`: 指向特定的已构建 `GameCLI` 二进制文件。

## 编码风格与命名规范

- 遵循 Swift API 设计指南；匹配现有风格 (4空格缩进, `// MARK:` 部分)。
- 命名: `PascalCase` 类型, `camelCase` 成员, `*Tests.swift` 用于测试文件。
- 架构经验法则:
  - `GameCore`: 避免 `print`/stdin/UI；优先使用"Definition + Registry"扩展而不是添加 `switch` 分支。
  - `GameCLI`: 保持依赖方向 `GameCLI → GameCore`；面向用户的文本为中文。

## 测试指南

- 使用 XCTest；优先在 `GameCoreTests` 中使用小型确定性测试 (种子RNG，无计时)。
- 对于端到端流程，添加/扩展 `GameCLIUITests` 并使用 `SALU_TEST_MODE=1` + `SALU_DATA_DIR` 以避免接触真实用户数据。

## 提交与拉取请求指南

- 提交消息通常遵循 `type: summary` (例如 `feat: ...`, `fix: ...`, `test: ...`, `docs: ...`, `ci: ...`, `chore: ...`)。
- PR: 解释什么/为什么，包括测试说明 (通常是 `swift test`)，并在适用时链接相关问题/计划。
