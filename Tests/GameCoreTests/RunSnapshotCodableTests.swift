import Foundation
import XCTest
@testable import GameCore

/// RunSnapshot Codable 单元测试
///
/// 目的：
/// - 验证 Run 维度存档快照可以 JSON 编码/解码（跨平台 Foundation JSONEncoder/Decoder）
/// - 防止后续修改 RunSnapshot 结构时破坏存档能力
final class RunSnapshotCodableTests: XCTestCase {
    /// JSON round-trip 后关键字段必须保持一致（用于保护存档结构）。
    func testRunSnapshot_jsonRoundTrip_preservesKeyFields() throws {
        print("🧪 测试：testRunSnapshot_jsonRoundTrip_preservesKeyFields")
        let snapshot = RunSnapshot(
            version: RunSaveVersion.current,
            seed: 123,
            floor: 1,
            maxFloor: 2,
            gold: 120,
            mapNodes: [
                .init(
                    id: "0_0",
                    row: 0,
                    column: 0,
                    roomType: RoomType.start.rawValue,
                    connections: ["1_0"],
                    isCompleted: true,
                    isAccessible: false
                ),
            ],
            currentNodeId: nil,
            player: .init(maxHP: 80, currentHP: 72, statuses: ["strength": 2]),
            deck: [
                .init(id: "strike_1", cardId: "strike"),
                .init(id: "inflame_1", cardId: "inflame"),
            ],
            relicIds: ["burning_blood", "lantern"],
            consumableIds: ["purification_rune"],
            isOver: false,
            won: false
        )
        
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(RunSnapshot.self, from: data)
        
        XCTAssertEqual(decoded.version, RunSaveVersion.current)
        XCTAssertEqual(decoded.seed, 123)
        XCTAssertEqual(decoded.floor, 1)
        XCTAssertEqual(decoded.gold, 120)
        XCTAssertEqual(decoded.player.currentHP, 72)
        XCTAssertEqual(decoded.player.statuses["strength"], 2)
        XCTAssertEqual(decoded.deck.count, 2)
        XCTAssertEqual(decoded.relicIds, ["burning_blood", "lantern"])
        XCTAssertEqual(decoded.consumableIds, ["purification_rune"])
        XCTAssertEqual(decoded.mapNodes.first?.roomType, RoomType.start.rawValue)
    }
    
    /// 破坏性变更策略：缺少必要字段时，应解码失败（不做向后兼容）。
    func testRunSnapshot_jsonDecode_withMissingGold_throws() throws {
        print("🧪 测试：testRunSnapshot_jsonDecode_withMissingGold_throws")
        let json: [String: Any] = [
            "version": RunSaveVersion.current,
            "seed": 321,
            "floor": 1,
            "maxFloor": 2,
            "mapNodes": [
                [
                    "id": "0_0",
                    "row": 0,
                    "column": 0,
                    "roomType": RoomType.start.rawValue,
                    "connections": ["1_0"],
                    "isCompleted": true,
                    "isAccessible": false,
                ],
            ],
            "currentNodeId": NSNull(),
            "player": [
                "maxHP": 80,
                "currentHP": 70,
                "statuses": ["strength": 1],
            ],
            "deck": [
                ["id": "strike_1", "cardId": "strike"],
            ],
            "relicIds": ["burning_blood"],
            "consumableIds": [],
            "isOver": false,
            "won": false,
        ]
        
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        XCTAssertThrowsError(try JSONDecoder().decode(RunSnapshot.self, from: data))
    }
}

