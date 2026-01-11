import XCTest
@testable import GameCore

/// 注册表（Registry）冒烟测试
///
/// 目的：
/// - 确认核心内容点已注册：卡牌/敌人/遗物
/// - 防止“新增内容忘记注册导致运行时 fatalError”的回归
final class RegistrySmokeTests: XCTestCase {
    /// 起始卡牌必须存在（用于起始牌组与基础流程）。
    func testCardRegistry_hasStarterCards() {
        print("🧪 测试：testCardRegistry_hasStarterCards")
        XCTAssertNotNil(CardRegistry.get("strike"))
        XCTAssertNotNil(CardRegistry.get("defend"))
        XCTAssertNotNil(CardRegistry.get("bash"))
    }
    
    /// 常见卡牌必须存在（用于 P1 奖励卡池与基础内容扩展）。
    func testCardRegistry_hasCommonCards() {
        print("🧪 测试：testCardRegistry_hasCommonCards")
        XCTAssertNotNil(CardRegistry.get("pommel_strike"))
        XCTAssertNotNil(CardRegistry.get("shrug_it_off"))
        XCTAssertNotNil(CardRegistry.get("inflame"))
        XCTAssertNotNil(CardRegistry.get("clothesline"))
    }
    
    /// Act1EnemyPool 中出现的所有敌人，都必须能从 EnemyRegistry resolve 到定义。
    func testEnemyRegistry_containsAct1PoolEnemies() {
        print("🧪 测试：testEnemyRegistry_containsAct1PoolEnemies")
        for id in Act1EnemyPool.all {
            XCTAssertNotNil(EnemyRegistry.get(id))
        }
    }
    
    /// Act2EnemyPool 中出现的所有敌人，都必须能从 EnemyRegistry resolve 到定义。
    func testEnemyRegistry_containsAct2PoolEnemies() {
        print("🧪 测试：testEnemyRegistry_containsAct2PoolEnemies")
        for id in Act2EnemyPool.all {
            XCTAssertNotNil(EnemyRegistry.get(id))
        }
        
        // Boss 也必须可 resolve（P2 替换：chrono_watcher → cipher）
        XCTAssertNotNil(EnemyRegistry.get("cipher"))
    }
    
    /// 基础遗物必须存在（用于 Run 起始遗物与遗物触发回归测试）。
    func testRelicRegistry_hasBasicRelics() {
        print("🧪 测试：testRelicRegistry_hasBasicRelics")
        XCTAssertNotNil(RelicRegistry.get("burning_blood"))
        XCTAssertNotNil(RelicRegistry.get("vajra"))
        XCTAssertNotNil(RelicRegistry.get("lantern"))
    }
}


