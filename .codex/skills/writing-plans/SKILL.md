---
name: writing-plans
description: "当需求/设计已明确且工作是多步骤时使用：在动代码前写可执行实施计划（含文件路径、验证命令与 Swift 示例）。"
---

# 编写实施计划（Writing Plans）

## 目的

把“已确认的需求/设计要点”拆成可执行的小任务清单，让执行者在几乎不了解仓库的情况下也能照着做，并且每一步都有验证方式（优先 TDD）。

进入本 skill 后先声明：正在使用 `writing-plans` 编写实施计划（此阶段不改代码）。

前置条件：
- 需求/范围/验收标准已明确（否则先用 `brainstorming` 澄清）

计划保存位置：
- 保存为 Markdown 文件，路径放在 `.codex/plans/`，文件名建议 `YYYY-MM-DD-主题-implementation-plan.md`
- 如果存在明确的优先级（如 P1/P2/P3…），在计划中用标题分组，并标注“Plan A（主方案）”

## 任务粒度（必须够小）

每一步最好是 2–10 分钟可完成的单动作（避免“做一大坨再验证”）：
- 写一个失败用例（或更新既有用例）
- 运行它，确认是失败且失败原因符合预期
- 写最小实现让它通过
- 再跑一次确认通过
- 需要时再小步重构 + 跑测试回归

## 计划文档头部模板

每个计划建议从以下结构开始（可按需精简）：

```markdown
# [主题] 实施计划

> 执行方式：建议使用 `executing-plans` 按批次实现与验收。

**Goal（目标）:** [一句话描述要达成什么]

**Non-goals（非目标）:** [明确不做什么，避免范围漂移]

**Approach（方案）:** [2–5 句描述核心思路与关键权衡]

**Acceptance（验收）:** [可测的验收条目，最好能对应测试/命令]

---
```

## 任务结构模板（Swift 版本）

```markdown
## Plan A（主方案）

### P1（最高优先级）：[目标/范围]

### Task N: [任务名]

**Files:**
- Create: `Sources/MyModule/MyType.swift`
- Modify: `Sources/MyModule/ExistingType.swift`
- Test: `Tests/MyModuleTests/MyTypeTests.swift`

**Step 1: 写一个失败的测试（XCTest）**

```swift
import XCTest
@testable import MyModule

final class MyTypeTests: XCTestCase {
    func test_parsesIntOrNil() {
        XCTAssertEqual(MyType.parseIntOrNil("42"), 42)
        XCTAssertNil(MyType.parseIntOrNil("not-a-number"))
    }
}
```

**Step 2: 运行测试，确认按预期失败**

Run: `swift test --filter MyModuleTests.MyTypeTests/test_parsesIntOrNil`  
Expected: FAIL（例如：`MyType.parseIntOrNil` 不存在或行为不符）

**Step 3: 写最小实现让测试通过**

```swift
public enum MyType {
    public static func parseIntOrNil(_ text: String) -> Int? {
        Int(text)
    }
}
```

**Step 4: 再跑一次测试，确认通过**

Run: `swift test --filter MyModuleTests.MyTypeTests/test_parsesIntOrNil`  
Expected: PASS

**Step 5:（可选）小步提交**

```bash
git add Sources/MyModule/MyType.swift Tests/MyModuleTests/MyTypeTests.swift
git commit -m "feat: implement parseIntOrNil"
```
```

## 计划必须包含的信息（清单）

- **精确文件路径**：不要写“改某个文件”，要写到具体路径（必要时写到符号名）
- **可验证步骤**：每个任务至少一个验证命令（最好是 `swift test --filter ...`）
- **边界条件**：错误输入、空值、极端值、并发/线程安全（如适用）
- **回归策略**：每完成一个优先级分组（P1/P2/P3…）后，明确要跑的验证（例如 `swift build`、`swift test`，或需要时 `xcodebuild`）
- **不确定项**：把需要确认的问题列出来，避免执行者猜

## 交接给执行

计划写好后给出下一步选择：
- 直接进入执行：使用 `executing-plans` 分批实现并在每批后汇报验证结果
- 先 review：等待对计划的修改意见，再开始执行

不要在计划里写“做完再看情况”。计划的价值在于：每一步都能被执行、被验证、被回滚。
