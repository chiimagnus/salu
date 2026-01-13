import Foundation
import GameCore
import Observation

/// 游戏会话 - 管理应用状态机和冒险状态
@Observable
final class GameSession {
    
    // MARK: - 状态
    
    /// 当前路由
    var route: AppRoute = .mainMenu
    
    /// 当前冒险状态（nil 表示没有进行中的冒险）
    var runState: RunState?
    
    /// 是否有存档可以继续
    var hasSavedRun: Bool {
        // TODO: P3 - 从 SwiftData 检查是否有存档
        false
    }
    
    // MARK: - 主菜单操作
    
    /// 开始新游戏
    /// - Parameter seed: 可选的随机种子，nil 表示使用随机种子
    func startNewGame(seed: UInt64? = nil) {
        let actualSeed = seed ?? UInt64.random(in: 0...UInt64.max)
        runState = RunState.newRun(seed: actualSeed)
        route = .runMap
    }
    
    /// 继续游戏（从存档加载）
    func continueGame() {
        // TODO: P3 - 从 SwiftData 加载存档
        // 暂时不实现，等 P3 再做
    }
    
    /// 放弃当前冒险
    func abandonRun() {
        runState = nil
        route = .mainMenu
        // TODO: P3 - 清除存档
    }
    
    // MARK: - 地图导航
    
    /// 进入指定节点
    func enterNode(_ node: MapNode) {
        guard runState != nil else { return }
        _ = runState?.enterNode(node.id)
        
        // 根据节点类型切换到对应界面
        switch node.roomType {
        case .start:
            // 起始节点：显示章节开场文本后自动完成
            completeCurrentNode()
            
        case .battle:
            route = .battle
            
        case .elite:
            route = .battle
            
        case .boss:
            route = .battle
            
        case .rest:
            route = .rest
            
        case .shop:
            route = .shop
            
        case .event:
            route = .event
        }
    }
    
    /// 完成当前节点，返回地图
    func completeCurrentNode() {
        guard runState != nil else { return }
        runState?.completeCurrentNode()
        
        // 检查冒险是否结束
        if let run = runState, run.isOver {
            route = .runResult(won: run.won)
        } else {
            route = .runMap
        }
        
        // TODO: P3 - 自动保存存档
    }
    
    // MARK: - 设置/历史等辅助页面
    
    func navigateToSettings() {
        route = .settings
    }
    
    func navigateToHistory() {
        route = .history
    }
    
    func navigateToStatistics() {
        route = .statistics
    }
    
    func navigateToMainMenu() {
        route = .mainMenu
    }
}
