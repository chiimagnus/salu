# Plan A：TUI「Tab 切换分栏（tab to cycle）」改造（2026-01-07）

> 目标：参考截图里 Claude code 的交互（顶部 tabs + “tab to cycle”），在 Salu 的 CLI/TUI 中引入 **按 Tab 键循环切换分栏** 的能力，并优先落地到最需要的页面。
>
> 关键约束：
> - **用户可见文本全中文**（可保留 “Tab”/“ESC” 等按键名）。
> - `GameCLI → GameCore` 单向依赖不变。
> - 不能破坏现有 `readLine()` 驱动的流程与 `Tests/GameCLIUITests`（它们通过 stdin 管道输入，通常不是 TTY）。
> - 每完成一个优先级 **P**，必须跑一次 `swift test`，确保全绿再进入下一优先级。

## 0. 现状梳理（已确认）

- 当前 GameCLI 输入模型基本都是 `readLine()`（需要 Enter），没有“单键立即生效”的输入层。
- `ResourceScreen.show()` 当前一次性把“卡牌/敌人&遭遇/遗物”全部输出，信息量很大，最适合做成“分栏 + Tab 切换”。
- 测试现状：
  - `Tests/GameCLITests/ScreenAndRoomCoverageTests.swift` 直接调用 `ResourceScreen.show()` 并断言关键字。
  - `Tests/GameCLIUITests/*` 通过 `Process` + stdin 管道驱动（通常 `isatty(STDIN_FILENO)==false`）。

## P1（必须）：在资源管理页落地 Tab 分栏（且不破坏测试）

（已实现 ✅）

### P1.1 输入层：增加“可选的单键读取”（只在 TTY 启用）

（已实现 ✅）

实现位置：
- Sources/GameCLI/TerminalKey.swift

实现要点：
- 仅在 `isatty(STDIN_FILENO)==true` 且非 XCTest 环境时启用（XCTest 下强制退化，避免 `swift test` 在交互终端里挂起）。
- macOS/Linux 使用 termios 进入 raw-ish 模式读取按键，并解析 `Tab` / `Shift+Tab` / `ESC` / 方向键。
- Windows 先退化为非交互（保持可编译），后续可在 P3 再补 Console API。

新增一个轻量输入抽象（建议新增文件，避免污染现有 `GameCLI.swift` 逻辑）：

- `Sources/GameCLI/TerminalKey.swift`（或类似命名）
  - `enum TerminalKey { case tab, shiftTab, escape, enter, backspace, printable(Character), arrowUp, arrowDown, arrowLeft, arrowRight, unknown }`
  - `struct TerminalKeyReader`
    - `static func isInteractiveTTY() -> Bool`：用 `isatty(STDIN_FILENO)` 判断；**非 TTY 直接禁用 raw mode**
    - `mutating func readKey() -> TerminalKey`：
      - macOS/Linux：termios 进入 raw-ish 模式（non-canonical + no-echo），读取 stdin bytes
      - 解析常见 ESC 序列（方向键、Shift+Tab 的 `ESC [ Z`）
    - `withRawMode { ... }`：确保退出时恢复 termios（`defer` 必须覆盖异常路径）
  - Windows 策略（P1 先保证能编译）：
    - `#if os(Windows)` 下先返回 `isInteractiveTTY=false`（即退化为旧行为），或后续 P3 再补 Console API。

验收点：
- **非 TTY**（测试/管道场景）不进入 raw mode，不改变现有输入流程。
- 代码改动集中在 GameCLI 模块，且不引入 GameCore 依赖反转。

### P1.2 UI 组件：新增 TabBar 渲染工具（可复用）

（已实现 ✅）

实现位置：
- Sources/GameCLI/Components/TabBar.swift
- Sources/GameCLI/Terminal.swift（新增 `Terminal.inverse`）

新增一个非常小的 UI 组件（不做复杂布局系统）：

- `Sources/GameCLI/Components/TabBar.swift`
  - 输入：`tabs: [String]`、`selectedIndex: Int`、可选 `hint: String`（如“（Tab 切换）”）
  - 输出：一行字符串（用 `Terminal.bold` + `Terminal.inverse` 或等价方案高亮选中 tab）
  - 同步补充 `Terminal.inverse`（ANSI `\u{001B}[7m`）或背景色常量（按项目风格二选一）

验收点：
- 选中 tab 的视觉区分清晰（粗体/反显即可）。
- 所有文案中文，例如：`（Tab 切换）`、`（Shift+Tab 反向）`（如果实现）。

### P1.3 ResourceScreen：提供“分栏视图 + Tab 循环切换”

（已实现 ✅）

实现位置：
- Sources/GameCLI/Screens/ResourceScreen.swift

实现要点：
- 非交互（非 TTY / XCTest / 管道）保持原来的“一次性输出全量内容”行为（用于稳定单测与日志）。
- 交互（TTY）模式：顶部 tabs + `Tab` 循环切换；`q` / `ESC` 返回；每次按键后 `Terminal.clear()` 重绘。

把 `ResourceScreen.show()` 拆成两条路径：

1) **非交互（非 TTY / 测试）**：保持当前“一次性输出全量内容”的行为（以保证现有测试与日志行为稳定）。
2) **交互（TTY）**：进入 Tab 分栏浏览模式：
   - Tabs 建议：
     - `卡牌`
     - `敌人/遭遇`
     - `遗物`
   - 页面结构建议：
     - 顶部：标题 + TabBar（包含提示“（Tab 切换）”）
     - 中间：当前 tab 对应的内容（沿用现有渲染逻辑，但按 tab 分段）
     - 底部：操作提示（中文）
       - `Tab`：切换分栏
       - `q` / `ESC`：返回

对应改造建议：
- 抽取现有内容构建为纯函数：
  - `buildCardsSectionLines() -> [String]`
  - `buildEnemiesAndEncountersSectionLines() -> [String]`
  - `buildRelicsSectionLines() -> [String]`
- 交互循环里：每次按键 → 更新 selectedTab → `Terminal.clear()` → 重绘。

验收点（手动）：
- 在真实终端运行 `swift run GameCLI` → 设置 → 资源管理页：
  - 按 Tab 能循环切换 3 个分栏，且不会需要按 Enter。
  - 按 `q` 或 `ESC` 能退出该页面回到设置菜单。

### P1.4 测试与验证（P1 完成后必须做）

（已完成 ✅）已运行 `swift test` 全绿。

- 运行：`swift test`
- 确认：
  - `GameCLITests/ScreenAndRoomCoverageTests.testResourceScreen_rendersRegistriesAndPools` 仍通过（因为非 TTY 仍走旧输出）。
  - `GameCLIUITests` 不超时、不挂起（确保没有在非 TTY 下错误启用 raw mode）。

## P2（应该）：资源管理页支持“滚动/分页”，避免内容太长刷屏

动机：仅靠 Tab 分栏仍可能很长（尤其卡牌/遗物列表），需要最基础的可读性改进。

### P2.1 在交互模式加入滚动窗口

- 在 `ResourceScreen` 的交互分支中加入：
  - `offset`（当前滚动偏移）
  - `pageSize`（可先固定，如 24 行；后续再做动态终端高度探测）
- 支持按键：
  - `↑/↓`：逐行滚动
  - `PageUp/PageDown`（可选）：整页滚动
  - Tab 切换分栏时重置 offset（避免越界）

### P2.2 明确底部提示栏（中文）

示例（仅示意，最终以实际键支持为准）：
- `↑↓ 滚动  Tab 切换  q/ESC 返回`

### P2.3 测试与验证（P2 完成后必须做）

- 运行：`swift test`
- 额外手动验收：
  - 列表可滚动，切 tab 不乱跳、不越界。

## P3（可选）：把 Tab/滚动能力推广到其他“多段信息屏幕”

候选页面（按收益排序）：

1) `HelpScreen`：拆成 `操作说明 / 游戏规则` 两个 tabs（信息更聚焦）
2) `HistoryScreen` + `StatisticsScreen`：做成“历史 / 统计”同屏 tabs（减少返回/进入操作）
3) `MapScreen`：把“地图 / 日志”做 tabs（替代当前 `l` 折叠逻辑），但要谨慎避免牵动主循环输入方式

### P3.1 输入兼容策略（关键）

- **不强推全局 raw mode**：只在“纯展示型屏幕”启用单键交互，避免改动战斗/地图的命令行输入（它们目前依赖 `readLine()` 的“输入一行命令”）。
- 对需要“输入一行字符串”的界面仍保留 `readLine()`，以保证 UI 测试稳定与成本可控。

### P3.2 测试与验证（P3 完成后必须做）

- 运行：`swift test`
- 如果新增了 tabs 的屏幕在非 TTY 输出发生变化，需要同步调整相关断言（优先让非 TTY 继续保持原输出结构）。

## 里程碑与交付顺序

- 先做 P1：把 “tab to cycle” 真正跑起来（资源管理页最直观、风险最低）。
- 再做 P2：解决“内容太长”的可用性问题。
- 最后评估 P3：逐步推广到更多屏幕，但避免大规模重写输入模型。

