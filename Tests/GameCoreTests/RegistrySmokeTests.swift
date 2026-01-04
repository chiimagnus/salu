import XCTest
@testable import GameCore

final class RegistrySmokeTests: XCTestCase {
    func testCardRegistry_hasStarterCards() {
        XCTAssertNotNil(CardRegistry.get("strike"))
        XCTAssertNotNil(CardRegistry.get("defend"))
        XCTAssertNotNil(CardRegistry.get("bash"))
    }
    
    func testCardRegistry_hasCommonCards() {
        XCTAssertNotNil(CardRegistry.get("pommel_strike"))
        XCTAssertNotNil(CardRegistry.get("shrug_it_off"))
        XCTAssertNotNil(CardRegistry.get("inflame"))
        XCTAssertNotNil(CardRegistry.get("clothesline"))
    }
    
    func testEnemyRegistry_containsAct1PoolEnemies() {
        for id in Act1EnemyPool.all {
            XCTAssertNotNil(EnemyRegistry.get(id))
        }
    }
    
    func testRelicRegistry_hasBasicRelics() {
        XCTAssertNotNil(RelicRegistry.get("burning_blood"))
        XCTAssertNotNil(RelicRegistry.get("vajra"))
        XCTAssertNotNil(RelicRegistry.get("lantern"))
    }
}


