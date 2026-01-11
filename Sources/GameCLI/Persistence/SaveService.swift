import Foundation
import GameCore

/// Run 存档服务
/// 封装存档的业务逻辑，提供依赖注入支持
final class SaveService {
    private let store: any RunSaveStore
    
    init(store: any RunSaveStore) {
        self.store = store
    }
    
    /// 从 RunState 创建快照
    func createSnapshot(from runState: RunState) -> RunSnapshot {
        // 转换地图节点
        let mapNodes = runState.map.map { node in
            RunSnapshot.NodeData(
                id: node.id,
                row: node.row,
                column: node.column,
                roomType: node.roomType.rawValue,
                connections: node.connections,
                isCompleted: node.isCompleted,
                isAccessible: node.isAccessible
            )
        }
        
        // 转换玩家状态
        let playerStatuses = Dictionary(
            uniqueKeysWithValues: runState.player.statuses.all.map { ($0.id.rawValue, $0.stacks) }
        )
        let player = RunSnapshot.PlayerData(
            maxHP: runState.player.maxHP,
            currentHP: runState.player.currentHP,
            statuses: playerStatuses
        )
        
        // 转换牌组
        let deck = runState.deck.map { card in
            RunSnapshot.CardData(id: card.id, cardId: card.cardId.rawValue)
        }
        
        // 转换遗物
        let relicIds = runState.relicManager.all.map { $0.rawValue }

        // 转换消耗品（P4）
        let consumableIds = runState.consumables.map { $0.rawValue }
        
        return RunSnapshot(
            version: RunSaveVersion.current,
            seed: runState.seed,
            floor: runState.floor,
            maxFloor: runState.maxFloor,
            gold: runState.gold,
            mapNodes: mapNodes,
            currentNodeId: runState.currentNodeId,
            player: player,
            deck: deck,
            relicIds: relicIds,
            consumableIds: consumableIds,
            isOver: runState.isOver,
            won: runState.won
        )
    }
    
    /// 从快照恢复 RunState
    func restoreRunState(from snapshot: RunSnapshot) throws -> RunState {
        // 检查版本兼容性
        guard RunSaveVersion.isCompatible(snapshot.version) else {
            throw SaveError.incompatibleVersion(snapshot.version, RunSaveVersion.current)
        }
        
        // 重建地图节点
        var mapNodes: [MapNode] = []
        for nodeData in snapshot.mapNodes {
            guard let roomType = RoomType(rawValue: nodeData.roomType) else {
                throw SaveError.corruptedSave("未知房间类型: \(nodeData.roomType)")
            }
            
            let node = MapNode(
                id: nodeData.id,
                row: nodeData.row,
                column: nodeData.column,
                roomType: roomType,
                connections: nodeData.connections,
                isCompleted: nodeData.isCompleted,
                isAccessible: nodeData.isAccessible
            )
            mapNodes.append(node)
        }
        
        // 重建玩家实体
        var player = Entity(id: "player", name: "安德", maxHP: snapshot.player.maxHP)
        player.currentHP = snapshot.player.currentHP
        
        // 恢复状态效果
        for (statusIdStr, stacks) in snapshot.player.statuses {
            player.statuses.set(StatusID(statusIdStr), stacks: stacks)
        }
        
        // 重建牌组
        let deck = try snapshot.deck.map { cardData in
            let cardId = CardID(cardData.cardId)
            guard CardRegistry.get(cardId) != nil else {
                throw SaveError.corruptedSave("未知卡牌: \(cardData.cardId)")
            }
            return Card(id: cardData.id, cardId: cardId)
        }
        
        // 重建遗物管理器
        var relicManager = RelicManager()
        for relicIdStr in snapshot.relicIds {
            let relicId = RelicID(relicIdStr)
            guard RelicRegistry.get(relicId) != nil else {
                throw SaveError.corruptedSave("未知遗物: \(relicIdStr)")
            }
            relicManager.add(relicId)
        }

        // 重建消耗品（P4）
        let consumables: [ConsumableID] = try snapshot.consumableIds.map { consumableIdStr in
            let consumableId = ConsumableID(consumableIdStr)
            guard ConsumableRegistry.get(consumableId) != nil else {
                throw SaveError.corruptedSave("未知消耗品: \(consumableIdStr)")
            }
            return consumableId
        }
        
        // 创建 RunState
        var runState = RunState(
            player: player,
            deck: deck,
            gold: snapshot.gold,
            relicManager: relicManager,
            consumables: consumables,
            map: mapNodes,
            seed: snapshot.seed,
            floor: snapshot.floor,
            maxFloor: snapshot.maxFloor
        )
        
        runState.currentNodeId = snapshot.currentNodeId
        runState.isOver = snapshot.isOver
        runState.won = snapshot.won
        
        return runState
    }
    
    /// 保存冒险进度
    func saveRun(_ runState: RunState) {
        let snapshot = createSnapshot(from: runState)
        try? store.save(snapshot)
    }
    
    /// 加载冒险进度
    func loadRun() throws -> RunState? {
        guard let snapshot = try store.load() else {
            return nil
        }
        return try restoreRunState(from: snapshot)
    }
    
    /// 清除存档
    func clearSave() {
        try? store.clear()
    }
    
    /// 检查是否有存档
    func hasSave() -> Bool {
        if let fileStore = store as? FileRunSaveStore {
            return fileStore.hasSave()
        }
        // Fallback: 尝试加载
        return (try? store.load()) != nil
    }
}

/// 存档错误
enum SaveError: Error, CustomStringConvertible {
    case incompatibleVersion(Int, Int)  // (存档版本, 当前版本)
    case corruptedSave(String)
    
    var description: String {
        switch self {
        case .incompatibleVersion(let saved, let current):
            return "存档版本不兼容: 存档版本 \(saved), 当前版本 \(current)"
        case .corruptedSave(let reason):
            return "存档已损坏或数据不合法：\(reason)"
        }
    }
}
