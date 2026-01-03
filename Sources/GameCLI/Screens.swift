import Foundation
import GameCore

/// 屏幕统一入口（向后兼容层）
/// 将各个 Screen 统一组织在一起
enum Screens {
    
    // MARK: - 主菜单
    
    static func showMainMenu() {
        MainMenuScreen.show()
    }
    
    // MARK: - 设置菜单
    
    static func showSettingsMenu() {
        SettingsScreen.show()
    }
    
    // MARK: - 帮助屏幕
    
    static func showHelp() {
        HelpScreen.show()
    }
    
    // MARK: - 退出屏幕
    
    static func showExit() {
        ResultScreen.showExit()
    }
    
    // MARK: - 战斗结果屏幕
    
    static func showVictory(state: BattleState) {
        ResultScreen.showVictory(state: state)
    }
    
    static func showDefeat(state: BattleState) {
        ResultScreen.showDefeat(state: state)
    }
    
    static func showFinal(state: BattleState, record: BattleRecord? = nil) {
        ResultScreen.showFinal(state: state, record: record)
    }
    
    // MARK: - 历史记录屏幕
    
    static func showHistory() {
        HistoryScreen.show()
    }
    
    // MARK: - 统计屏幕
    
    static func showStatistics() {
        StatisticsScreen.show()
    }
    
    // MARK: - 地图屏幕
    
    static func showMap(nodes: [MapNode], paths: [MapPath]) {
        MapScreen.show(nodes: nodes, paths: paths)
    }
}
