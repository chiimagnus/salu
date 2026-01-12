import XCTest
@testable import GameCore

final class StrongTypedIDTests: XCTestCase {
    func testCardID_initAndStringLiteral() {
        print("🧪 测试：testCardID_initAndStringLiteral")
        let fromInit = CardID("strike")
        let fromLiteral: CardID = "defend"

        XCTAssertEqual(fromInit.rawValue, "strike")
        XCTAssertEqual(fromLiteral.rawValue, "defend")
        XCTAssertNotEqual(fromInit, fromLiteral)
    }

    func testStatusID_initAndHashable() {
        print("🧪 测试：testStatusID_initAndHashable")
        let a = StatusID("madness")
        let b = StatusID("madness")
        let c = StatusID("weak")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(Set([a, b, c]).count, 2)
    }

    func testEnemyID_andRelicID() {
        print("🧪 测试：testEnemyID_andRelicID")
        let enemy: EnemyID = "mad_prophet"
        let relic: RelicID = "third_eye"

        XCTAssertEqual(enemy.rawValue, "mad_prophet")
        XCTAssertEqual(relic.rawValue, "third_eye")
    }

    func testEventID_initAndStringLiteral() {
        print("🧪 测试：testEventID_initAndStringLiteral")
        let fromInit = EventID("seer_time_rift")
        let fromLiteral: EventID = "seer_sequence_chamber"

        XCTAssertEqual(fromInit.rawValue, "seer_time_rift")
        XCTAssertEqual(fromLiteral.rawValue, "seer_sequence_chamber")
    }
}
