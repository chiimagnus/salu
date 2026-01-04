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
        let snapshot = RunSnapshot(
            version: RunSaveVersion.current,
            seed: 123,
            floor: 1,
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
            isOver: false,
            won: false
        )
        
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(RunSnapshot.self, from: data)
        
        XCTAssertEqual(decoded.version, RunSaveVersion.current)
        XCTAssertEqual(decoded.seed, 123)
        XCTAssertEqual(decoded.floor, 1)
        XCTAssertEqual(decoded.player.currentHP, 72)
        XCTAssertEqual(decoded.player.statuses["strength"], 2)
        XCTAssertEqual(decoded.deck.count, 2)
        XCTAssertEqual(decoded.relicIds, ["burning_blood", "lantern"])
        XCTAssertEqual(decoded.mapNodes.first?.roomType, RoomType.start.rawValue)
    }
}


