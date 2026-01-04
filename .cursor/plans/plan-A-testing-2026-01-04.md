# Plan A：Swift XCTest 测试体系（单元测试 + CLI UI 测试）- 2026-01-04

> 状态：✅ 已落地（本地 `swift build`/`swift build -c release`/`swift test` 全量通过）

---

## 1. 目标

- **只用 Swift XCTest** 做测试实现（单元测试 + CLI「UI」测试），避免“跑一遍脚本/grep 输出也能绿”的假阳性。
- **CI 每次跑全量测试**：同时验证 debug/release 编译 + 全量 XCTest。
- **每个测试写清楚用途**：每个 `XCTestCase`/`test*` 都必须有中文说明。

---

## 2. 测试分层（明确边界，避免互相污染）

### 2.1 单元测试（Unit）

- **位置**：`Tests/GameCoreTests/`
- **覆盖对象**：`GameCore` 纯逻辑（卡牌/状态/敌人/地图/奖励/遗物/战斗计算等）
- **断言风格**：强断言（数值/顺序/确定性/回归保护），不依赖任何 CLI 输出

### 2.2 CLI UI 测试（黑盒 E2E）

- **位置**：`Tests/GameCLIUITests/`
- **实现方式**：使用 `Foundation.Process` 启动 `GameCLI` 可执行文件，通过 stdin 驱动流程，断言：
  - **文件副作用（最强）**：`run_save.json` / `battle_history.json` 存在且可解码
  - **关键字段（强）**：`RunSnapshot.deck.count`、`RunSnapshot.seed`、战绩条数等
  - **stdout 锚点（辅助）**：例如“存档加载成功”“战斗奖励”等（断言前会去 ANSI 控制码）

已覆盖的关键路径：

- 启动主菜单并退出（不挂死）
- 进入第一场战斗并退出（不挂死）
- 存档创建 + 继续冒险（文件副作用 + 文案提示）
- 战斗胜利后奖励入牌并写入存档（deck 增长）
- 战绩落盘并可 JSON 解码（battle_history.json）

---

## 3. CI 运行策略（全量 & 可复现）

### 3.1 Tests workflow

- 文件：`.github/workflows/test.yml`
- 步骤：
  - `swift build`
  - `swift build -c release`
  - `swift test --enable-code-coverage`
  - 上传 coverage 产物：`.build/**/debug/codecov/Salu.json`

> 注意：由于 CLI UI tests 是通过 **外部进程** 运行 `GameCLI`，因此该 coverage 报告目前主要反映 **GameCore + 测试进程内执行的代码**；若要把外部进程的 GameCLI 执行计入覆盖率，需要额外做跨进程 profile 合并或重构为可注入的 in-process runner。

### 3.2 Release workflow

- 文件：`.github/workflows/release.yml`
- 在打包发布前增加 `swift test`，确保发版也被全量测试保护。

---

## 4. UI 测试稳定性机制（CLI 版「UI Testing」常见难点）

为了避免 UI 测试因为战斗过长导致超时/概率性失败，引入了 **仅测试启用** 的稳定化开关：

- 环境变量：`SALU_TEST_MODE=1`
- 作用（仅在设置该 env 时生效）：
  - 敌人 HP 压缩为 1（快速结束战斗）
  - 战斗牌组压缩为稳定的小牌组（避免抽牌/能量导致的不确定性）
- 实现：`Sources/GameCLI/TestMode.swift` + `GameCLI` 的 enemy/deck 创建处接入

> 生产运行不设置 `SALU_TEST_MODE` 时，行为不变。

---

## 5. 测试失败时如何判断：测试代码问题 vs 项目代码问题

### 5.1 先看“失败类型”

- **编译失败（Compile error）**：
  - 大概率是 **测试代码或接口变更** 导致（例如类型改名/可见性变化）
- **断言失败（XCTAssert… failed）**：
  - Unit：通常是 **业务逻辑回归** 或 **规则改变但测试未同步**
  - CLI UI：通常是 **流程断链/文案锚点变化/副作用文件未生成**
- **超时（timed out）**：
  - 多数是 **程序卡死/等待输入/死循环** 或 UI 测试输入序列不足

### 5.2 具体排查路径（建议顺序）

1) **看失败用例的 doc comment**：确认这个测试定义的“规格”是什么  
2) **看失败输出**：`GameCLIUITests` 的 runner 会在超时时打印部分 stdout/stderr（便于定位卡在哪个屏幕）  
3) **本地复现**：按测试里相同的 `--seed` 和 `SALU_DATA_DIR`/`SALU_TEST_MODE` 运行一次（必要时把 stdin 输入保存出来）  
4) **判断是不是“需求变更”**：
   - 如果你确实改了规则/文案 → 更新测试是合理的（测试是规格）  
   - 如果规则没变但测试失败 → 优先修项目代码

---

## 6. 后续扩展（可选）

- 为更多房间类型/更长冒险流程增加 CLI UI tests（仍以“文件副作用/关键字段”为主）
- 将更多“必须可复现”的随机决策做成 Unit tests（例如更多敌人 AI、更多遗物触发点）

 