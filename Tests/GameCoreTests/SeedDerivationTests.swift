import XCTest
@testable import GameCore

final class SeedDerivationTests: XCTestCase {
    func testBattleSeed_isDeterministic_givenSameInputs() {
        print("🧪 测试：testBattleSeed_isDeterministic_givenSameInputs")
        let a = SeedDerivation.battleSeed(runSeed: 123, floor: 1, nodeId: "3_1")
        let b = SeedDerivation.battleSeed(runSeed: 123, floor: 1, nodeId: "3_1")
        XCTAssertEqual(a, b)
    }

    func testBattleSeed_changesWhenNodeIdChanges() {
        print("🧪 测试：testBattleSeed_changesWhenNodeIdChanges")
        let a = SeedDerivation.battleSeed(runSeed: 123, floor: 1, nodeId: "3_1")
        let b = SeedDerivation.battleSeed(runSeed: 123, floor: 1, nodeId: "3_2")
        XCTAssertNotEqual(a, b)
    }

    func testBattleSeed_changesWhenFloorChanges() {
        print("🧪 测试：testBattleSeed_changesWhenFloorChanges")
        let a = SeedDerivation.battleSeed(runSeed: 123, floor: 1, nodeId: "3_1")
        let b = SeedDerivation.battleSeed(runSeed: 123, floor: 2, nodeId: "3_1")
        XCTAssertNotEqual(a, b)
    }
}

