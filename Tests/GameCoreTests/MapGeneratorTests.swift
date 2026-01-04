import XCTest
@testable import GameCore

final class MapGeneratorTests: XCTestCase {
    /// 确保相同随机种子下生成的地图完全一致，验证地图可复现性
    func testGenerateBranching_isDeterministicForSameSeed() {
        let first = MapGenerator.generateBranching(seed: 2024, rows: 8)
        let second = MapGenerator.generateBranching(seed: 2024, rows: 8)
        
        XCTAssertEqual(first, second)
    }
    
    /// 起点应可进入，且从起点必须存在一条路径能到达最终 Boss 层，防止生成断路地图
    func testGenerateBranching_hasReachablePathToBoss() {
        let rows = 10
        let nodes = MapGenerator.generateBranching(seed: 77, rows: rows)
        
        guard let start = nodes.node(withId: "0_0") else {
            return XCTFail("缺少起点节点")
        }
        XCTAssertTrue(start.isAccessible, "起点应默认可进入")
        
        var visited: Set<String> = []
        var stack = [start.id]
        
        while let current = stack.popLast() {
            guard visited.insert(current).inserted else { continue }
            guard let node = nodes.node(withId: current) else { continue }
            stack.append(contentsOf: node.connections)
        }
        
        let bossId = "\(rows - 1)_0"
        XCTAssertTrue(visited.contains(bossId), "Boss 层应从起点可达")
    }
}
