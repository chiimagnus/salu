import XCTest
@testable import GameCore

final class RegistryEnumerationTests: XCTestCase {
    func testRegistries_getNilAndAllIdsSorted() {
        print("🧪 测试：testRegistries_getNilAndAllIdsSorted")
        
        XCTAssertNil(CardRegistry.get("unknown_card"))
        XCTAssertNil(EnemyRegistry.get("unknown_enemy"))
        XCTAssertNil(StatusRegistry.get("unknown_status"))
        XCTAssertNil(RelicRegistry.get("unknown_relic"))
        XCTAssertNil(EventRegistry.get("unknown_event"))
        
        // all IDs should include known values and be sorted by rawValue
        XCTAssertTrue(CardRegistry.allCardIds.contains("strike"))
        XCTAssertEqual(CardRegistry.allCardIds, CardRegistry.allCardIds.sorted { $0.rawValue < $1.rawValue })
        
        XCTAssertTrue(RelicRegistry.allRelicIds.contains("burning_blood"))
        XCTAssertEqual(RelicRegistry.allRelicIds, RelicRegistry.allRelicIds.sorted { $0.rawValue < $1.rawValue })
        
        XCTAssertTrue(EventRegistry.allEventIds.contains("scavenger"))
        XCTAssertEqual(EventRegistry.allEventIds, EventRegistry.allEventIds.sorted { $0.rawValue < $1.rawValue })
    }
}


