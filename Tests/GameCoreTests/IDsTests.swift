import XCTest
@testable import GameCore

final class IDsTests: XCTestCase {
    func testAllIDs_initAndStringLiteral() {
        print("🧪 测试：testAllIDs_initAndStringLiteral")
        let c1 = CardID("strike")
        let c2: CardID = "strike"
        XCTAssertEqual(c1.rawValue, "strike")
        XCTAssertEqual(c2.rawValue, "strike")
        
        let s1 = StatusID("weak")
        let s2: StatusID = "weak"
        XCTAssertEqual(s1.rawValue, "weak")
        XCTAssertEqual(s2.rawValue, "weak")
        
        let e1 = EnemyID("jaw_worm")
        let e2: EnemyID = "jaw_worm"
        XCTAssertEqual(e1.rawValue, "jaw_worm")
        XCTAssertEqual(e2.rawValue, "jaw_worm")
        
        let r1 = RelicID("burning_blood")
        let r2: RelicID = "burning_blood"
        XCTAssertEqual(r1.rawValue, "burning_blood")
        XCTAssertEqual(r2.rawValue, "burning_blood")
        
        let ev1 = EventID("scavenger")
        let ev2: EventID = "scavenger"
        XCTAssertEqual(ev1.rawValue, "scavenger")
        XCTAssertEqual(ev2.rawValue, "scavenger")
    }
}


