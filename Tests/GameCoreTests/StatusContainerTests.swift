import XCTest
@testable import GameCore

/// StatusContainer 单元测试
///
/// 目的：
/// - 验证状态层数增减/清除规则正确（<=0 自动移除）
/// - 验证 `all` 输出顺序确定（按 StatusID.rawValue 排序），避免遍历 Dictionary 导致不稳定
final class StatusContainerTests: XCTestCase {
    /// `apply` 增减层数，降到 0（或以下）时应自动移除该状态。
    func testApplyAndRemove_whenStacksDropToZero_removesStatus() {
        print("🧪 测试：testApplyAndRemove_whenStacksDropToZero_removesStatus")
        var container = StatusContainer()
        container.apply("weak", stacks: 2)
        XCTAssertEqual(container.stacks(of: "weak"), 2)
        
        container.apply("weak", stacks: -2)
        XCTAssertEqual(container.stacks(of: "weak"), 0)
        XCTAssertFalse(container.hasAny)
    }
    
    /// `set` 直接设置层数，设置为 0（或以下）时应移除该状态。
    func testSet_whenStacksLessOrEqualZero_removesStatus() {
        print("🧪 测试：testSet_whenStacksLessOrEqualZero_removesStatus")
        var container = StatusContainer()
        container.set("vulnerable", stacks: 1)
        XCTAssertTrue(container.hasAny)
        
        container.set("vulnerable", stacks: 0)
        XCTAssertEqual(container.stacks(of: "vulnerable"), 0)
        XCTAssertFalse(container.hasAny)
    }
    
    /// `all` 必须按 StatusID.rawValue 排序，保证确定性（避免 Dictionary 迭代顺序带来不稳定）。
    func testAll_isSortedByIdRawValue() {
        print("🧪 测试：testAll_isSortedByIdRawValue")
        var container = StatusContainer()
        container.apply("weak", stacks: 1)
        container.apply("strength", stacks: 2)
        container.apply("frail", stacks: 1)
        
        let ids = container.all.map(\.id.rawValue)
        XCTAssertEqual(ids, ["frail", "strength", "weak"])
    }
}


