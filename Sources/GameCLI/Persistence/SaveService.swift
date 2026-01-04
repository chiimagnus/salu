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
                roomType: String(describing: node.roomType),
                connections: node.connections,
                isCompleted: node.isCompleted,
                isAccessible: node.isAccessible
            )
        }
        
        // 转换玩家状态
        let playerStatuses = Dictionary(uniqueKeysWithValues: 
            runState.player.statuses.all.map { (String(describing: $0.id), $0.stacks) }
        )
        let player = RunSnapshot.PlayerData(
            maxHP: runState.player.maxHP,
            currentHP: runState.player.currentHP,
            statuses: playerStatuses
        )
        
        // 转换牌组
        let deck = runState.deck.map { card in
            RunSnapshot.CardData(id: card.id, cardId: String(describing: card.cardId))
        }
        
        // 转换遗物
        let relicIds = runState.relicManager.all.map { String(describing: $0) }
        
        return RunSnapshot(
            version: RunSaveVersion.current,
            seed: runState.seed,
            floor: runState.floor,
            mapNodes: mapNodes,
            currentNodeId: runState.currentNodeId,
            player: player,
            deck: deck,
            relicIds: relicIds,
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
            let roomType: RoomType
            switch nodeData.roomType {
            case "start": roomType = .start
            case "battle": roomType = .battle
            case "elite": roomType = .elite
            case "rest": roomType = .rest
            case "boss": roomType = .boss
            default: roomType = .battle  // fallback
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
        var player = Entity(id: "player", name: "铁甲战士", maxHP: snapshot.player.maxHP)
        player.currentHP = snapshot.player.currentHP
        
        // 恢复状态效果
        for (statusIdStr, stacks) in snapshot.player.statuses {
            let statusId = StatusID(statusIdStr)
            player.statuses.set(statusId, stacks: stacks)
        }
        
        // 重建牌组
        let deck = snapshot.deck.map { cardData in
            Card(id: cardData.id, cardId: CardID(cardData.cardId))
        }
        
        // 重建遗物管理器
        var relicManager = RelicManager()
        for relicIdStr in snapshot.relicIds {
            relicManager.add(RelicID(relicIdStr))
        }
        
        // 创建 RunState
        var runState = RunState(
            player: player,
            deck: deck,
            relicManager: relicManager,
            map: mapNodes,
            seed: snapshot.seed,
            floor: snapshot.floor
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
    
    var description: String {
        switch self {
        case .incompatibleVersion(let saved, let current):
            return "存档版本不兼容: 存档版本 \(saved), 当前版本 \(current)"
        }
    }
}
