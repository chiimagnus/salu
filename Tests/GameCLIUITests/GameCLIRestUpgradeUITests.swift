import Foundation
import GameCore
import XCTest

/// GameCLI 休息点升级流程（P3）黑盒「UI」测试
///
/// 目的：
/// - 验证休息点出现“升级卡牌”选项
/// - 验证升级后 deck 卡牌 ID 被替换并写入存档
final class GameCLIRestUpgradeUITests: XCTestCase {
    func testRestUpgradeUpdatesDeckInSave() throws {
        print("🧪 测试：testRestUpgradeUpdatesDeckInSave")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let seed: UInt64 = 123
        let inputScript = try buildInputScript(seed: seed)
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1"
        ]
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "\(seed)"],
            stdin: inputScript,
            environment: env,
            timeout: 15
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("Upgrade Card"), "Expected Upgrade Card prompt")
        
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        
        let upgradedStrike = snapshot.deck.first { $0.id == "strike_1" }
        XCTAssertEqual(upgradedStrike?.cardId, "strike+", "期望 strike_1 被升级为 strike+")
    }
    
    private func buildInputScript(seed: UInt64) throws -> String {
        let path = try pathToRestNode(seed: seed)
        var inputs: [String] = ["1"] // 主菜单：开始冒险
        var runState = RunState.newRun(seed: seed)
        
        for nodeId in path {
            let accessibleNodes = runState.accessibleNodes
            guard let choiceIndex = accessibleNodes.firstIndex(where: { $0.id == nodeId }) else {
                throw RestPathError.unreachableNode(nodeId)
            }
            
            inputs.append(String(choiceIndex + 1))
            _ = runState.enterNode(nodeId)
            
            guard let node = runState.currentNode else {
                throw RestPathError.unreachableNode(nodeId)
            }
            
            switch node.roomType {
            case .start:
                runState.completeCurrentNode()
                
            case .battle, .elite:
                inputs.append("1") // 战斗：出牌
                inputs.append("1") // 奖励：选第一张
                runState.completeCurrentNode()
                
            case .shop:
                inputs.append("0") // 商店：离开
                runState.completeCurrentNode()
                
            case .event:
                inputs.append("3") // 事件：离开（所有内置事件均提供“离开”选项）
                inputs.append("")  // 事件结算：按 Enter 继续
                runState.completeCurrentNode()

            case .rest:
                inputs.append("2") // 休息点：升级卡牌
                inputs.append("1") // 选择第一张可升级卡
                inputs.append("")  // 按 Enter 继续
                runState.completeCurrentNode()
                
            case .boss:
                throw RestPathError.unexpectedRoomType(node.roomType)
            }
        }
        
        inputs.append("q") // 回主菜单
        inputs.append("4") // 退出
        
        return inputs.joined(separator: "\n") + "\n"
    }
    
    private func pathToRestNode(seed: UInt64) throws -> [String] {
        let map = RunState.newRun(seed: seed).map
        let startId = "0_0"
        
        let primaryAllowed: Set<RoomType> = [.start, .battle, .elite, .event, .rest]
        if let path = findPath(map: map, startId: startId, allowed: primaryAllowed) {
            return path
        }
        
        let fallbackAllowed: Set<RoomType> = [.start, .battle, .elite, .shop, .event, .rest]
        if let path = findPath(map: map, startId: startId, allowed: fallbackAllowed) {
            return path
        }
        
        throw RestPathError.noRestPath
    }
    
    private func findPath(map: [MapNode], startId: String, allowed: Set<RoomType>) -> [String]? {
        var queue: [String] = [startId]
        var visited: Set<String> = [startId]
        var previous: [String: String] = [:]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            guard let node = map.node(withId: current) else { continue }
            
            if node.roomType == .rest {
                return buildPath(from: current, previous: previous)
            }
            
            for nextId in node.connections {
                guard let nextNode = map.node(withId: nextId),
                      allowed.contains(nextNode.roomType) else {
                    continue
                }
                
                if !visited.contains(nextId) {
                    visited.insert(nextId)
                    previous[nextId] = current
                    queue.append(nextId)
                }
            }
        }
        
        return nil
    }
    
    private func buildPath(from target: String, previous: [String: String]) -> [String] {
        var path: [String] = []
        var current: String? = target
        
        while let nodeId = current {
            path.append(nodeId)
            current = previous[nodeId]
        }
        
        return path.reversed()
    }
}

private enum RestPathError: Error, CustomStringConvertible {
    case noRestPath
    case unreachableNode(String)
    case unexpectedRoomType(RoomType)
    
    var description: String {
        switch self {
        case .noRestPath:
            return "未找到通往休息点的路径"
        case .unreachableNode(let nodeId):
            return "路径包含无法到达的节点：\(nodeId)"
        case .unexpectedRoomType(let roomType):
            return "路径包含不支持的房间类型：\(roomType)"
        }
    }
}
