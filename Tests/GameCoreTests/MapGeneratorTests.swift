import XCTest
@testable import GameCore

/// MapGenerator 单元测试
///
/// 目的：
/// - 验证地图生成可复现（同 seed → 同图）
/// - 验证地图基本结构约束：起点可进入、Boss 层存在、所有节点可达
final class MapGeneratorTests: XCTestCase {
    /// 相同 seed 的地图生成结果必须完全一致（保证可复现与测试稳定）。
    func testGenerateBranching_isDeterministic() {
        print("🧪 测试：testGenerateBranching_isDeterministic")
        let a = MapGenerator.generateBranching(seed: 42)
        let b = MapGenerator.generateBranching(seed: 42)
        XCTAssertEqual(a, b)
    }
    
    /// 起点节点（0_0）必须存在且可进入（isAccessible == true）。
    func testStartNode_isAccessible() {
        print("🧪 测试：testStartNode_isAccessible")
        let map = MapGenerator.generateBranching(seed: 1)
        guard let start = map.node(withId: "0_0") else {
            return XCTFail("未找到起点节点 0_0")
        }
        XCTAssertEqual(start.roomType, .start)
        XCTAssertTrue(start.isAccessible)
    }
    
    /// 最后一层必须只有一个 Boss 节点。
    func testBossRow_hasBossNode() {
        print("🧪 测试：testBossRow_hasBossNode")
        let rows = MapGenerator.defaultRowCount
        let map = MapGenerator.generateBranching(seed: 1, rows: rows)
        let bossRow = rows - 1
        let bossNodes = map.nodes(atRow: bossRow)
        XCTAssertEqual(bossNodes.count, 1)
        XCTAssertEqual(bossNodes.first?.roomType, .boss)
    }
    
    /// 每个非起点节点必须至少有一个入口连接（确保地图可通关）。
    func testAllNonStartNodes_haveIncomingConnection() {
        print("🧪 测试：testAllNonStartNodes_haveIncomingConnection")
        let rows = MapGenerator.defaultRowCount
        let map = MapGenerator.generateBranching(seed: 7, rows: rows)
        
        for row in 1..<rows {
            let currentRowNodes = map.nodes(atRow: row)
            let prevRowNodes = map.nodes(atRow: row - 1)
            for node in currentRowNodes {
                let hasIncoming = prevRowNodes.contains { $0.connections.contains(node.id) }
                XCTAssertTrue(hasIncoming, "节点 \(node.id)（row=\(row)）没有入口连接")
            }
        }
    }

    /// MapGenerating 的默认实现应委托给 MapGenerator（用于覆盖扩展点与防回归）。
    func testBranchingMapGenerator_delegatesToMapGenerator() {
        print("🧪 测试：testBranchingMapGenerator_delegatesToMapGenerator")
        let generator = BranchingMapGenerator()
        let a = generator.generate(seed: 42, rows: 15)
        let b = MapGenerator.generateBranching(seed: 42, rows: 15)
        XCTAssertEqual(a, b)
    }
}


