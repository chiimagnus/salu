import XCTest
@testable import GameCore

final class RegistryRequireTests: XCTestCase {
    func testRequire_returnsDefinition() {
        print("🧪 测试：testRequire_returnsDefinition")
        XCTAssertEqual(CardRegistry.require("strike").id, CardID("strike"))
        XCTAssertEqual(EnemyRegistry.require("jaw_worm").id, EnemyID("jaw_worm"))
        XCTAssertEqual(StatusRegistry.require("weak").id, StatusID("weak"))
        XCTAssertEqual(RelicRegistry.require("burning_blood").id, RelicID("burning_blood"))
        XCTAssertEqual(EventRegistry.require("scavenger").id, EventID("scavenger"))
    }
}


