import XCTest
@testable import GameCore

final class RelicManagerAndRelicsTests: XCTestCase {
    func testRelicManager_addRemoveHasAll() {
        print("🧪 测试：testRelicManager_addRemoveHasAll")
        var mgr = RelicManager()
        XCTAssertFalse(mgr.has("vajra"))
        XCTAssertEqual(mgr.all.count, 0)
        
        mgr.add("vajra")
        XCTAssertTrue(mgr.has("vajra"))
        XCTAssertEqual(mgr.all, ["vajra"])
        
        // 不重复
        mgr.add("vajra")
        XCTAssertEqual(mgr.all, ["vajra"])
        
        mgr.add("lantern")
        XCTAssertEqual(mgr.all, ["vajra", "lantern"])
        
        mgr.remove("vajra")
        XCTAssertFalse(mgr.has("vajra"))
        XCTAssertEqual(mgr.all, ["lantern"])
    }
    
    func testRelicManager_onBattleTrigger_collectsEffects() {
        print("🧪 测试：testRelicManager_onBattleTrigger_collectsEffects")
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let enemy = Entity(id: "enemy", name: "敌人", maxHP: 40, enemyId: "jaw_worm")
        let snapshot = BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: 3)
        
        let mgr = RelicManager(relics: ["burning_blood", "vajra", "lantern", "unknown_relic"])
        
        let start = mgr.onBattleTrigger(.battleStart, snapshot: snapshot)
        XCTAssertTrue(start.contains { if case .applyStatus(target: .player, statusId: "strength", stacks: 1) = $0 { return true } else { return false } })
        XCTAssertTrue(start.contains { if case .gainEnergy(amount: 1) = $0 { return true } else { return false } })
        XCTAssertFalse(start.contains { if case .heal = $0 { return true } else { return false } })
        
        let endWin = mgr.onBattleTrigger(.battleEnd(won: true), snapshot: snapshot)
        XCTAssertTrue(endWin.contains { if case .heal(target: .player, amount: 6) = $0 { return true } else { return false } })
        
        let endLose = mgr.onBattleTrigger(.battleEnd(won: false), snapshot: snapshot)
        XCTAssertTrue(endLose.isEmpty)
    }
    
    func testBasicRelics_triggers() {
        print("🧪 测试：testBasicRelics_triggers")
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let enemy = Entity(id: "enemy", name: "敌人", maxHP: 40, enemyId: "jaw_worm")
        let snapshot = BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: 3)
        
        // Burning Blood：仅胜利战斗结束触发
        XCTAssertEqual(BurningBloodRelic.onBattleTrigger(.battleStart, snapshot: snapshot).count, 0)
        XCTAssertEqual(BurningBloodRelic.onBattleTrigger(.battleEnd(won: false), snapshot: snapshot).count, 0)
        let heal = BurningBloodRelic.onBattleTrigger(.battleEnd(won: true), snapshot: snapshot)
        XCTAssertEqual(heal, [.heal(target: .player, amount: 6)])
        
        // Vajra：战斗开始触发力量
        XCTAssertEqual(VajraRelic.onBattleTrigger(.battleEnd(won: true), snapshot: snapshot).count, 0)
        XCTAssertEqual(VajraRelic.onBattleTrigger(.battleStart, snapshot: snapshot), [.applyStatus(target: .player, statusId: "strength", stacks: 1)])
        
        // Lantern：战斗开始触发能量
        XCTAssertEqual(LanternRelic.onBattleTrigger(.battleEnd(won: true), snapshot: snapshot).count, 0)
        XCTAssertEqual(LanternRelic.onBattleTrigger(.battleStart, snapshot: snapshot), [.gainEnergy(amount: 1)])
    }
}


