import XCTest
@testable import GameCore

final class EventRegistryTests: XCTestCase {
    func testEventRegistry_getAndRequire() {
        print("🧪 测试：testEventRegistry_getAndRequire")
        let timeRift = EventRegistry.get(SeerTimeRiftEvent.id)
        XCTAssertNotNil(timeRift)
        XCTAssertTrue(timeRift == SeerTimeRiftEvent.self)

        let required = EventRegistry.require(SeerMadProphetEvent.id)
        XCTAssertTrue(required == SeerMadProphetEvent.self)
        XCTAssertNil(EventRegistry.get(EventID("unknown_event")))
    }

    func testEventRegistry_allEventIdsSortedAndContainsKnownIds() {
        print("🧪 测试：testEventRegistry_allEventIdsSortedAndContainsKnownIds")
        let ids = EventRegistry.allEventIds
        let sorted = ids.sorted { $0.rawValue < $1.rawValue }
        XCTAssertEqual(ids, sorted)
        XCTAssertTrue(ids.contains(SeerSequenceChamberEvent.id))
        XCTAssertTrue(ids.contains(AltarEvent.id))
    }
}
