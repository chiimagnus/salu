import GameCore

/// 屏幕统一入口
/// 将各个 Screen 统一组织在一起，集中管理跨屏依赖与调用方式
enum Screens {
    
    // MARK: - 主菜单
    
    static func showMainMenu(historyService: HistoryService, hasSave: Bool = false) {
        MainMenuScreen.show(historyService: historyService, hasSave: hasSave)
    }
    
    // MARK: - 地图屏幕
    
    static func showMap(runState: RunState, message: String? = nil) {
        MapScreen.show(runState: runState, message: message)
    }
    
    static func showRestOptions(runState: RunState) {
        MapScreen.showRestOptions(runState: runState)
    }
    
    static func showRestResult(healedAmount: Int, newHP: Int, maxHP: Int) {
        MapScreen.showRestResult(healedAmount: healedAmount, newHP: newHP, maxHP: maxHP)
    }

    // MARK: - 商店

    static func showShop(inventory: ShopInventory, runState: RunState, message: String? = nil) {
        ShopScreen.show(inventory: inventory, runState: runState, message: message)
    }

    static func showShopRemoveCard(runState: RunState, price: Int, message: String? = nil) {
        ShopScreen.showRemoveCardOptions(runState: runState, price: price, message: message)
    }
    
    // MARK: - 设置菜单
    
    static func showSettingsMenu(historyService: HistoryService) {
        SettingsScreen.show(historyService: historyService)
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
    
    static func showHistory(historyService: HistoryService) {
        HistoryScreen.show(historyService: historyService)
    }
    
    // MARK: - 统计屏幕
    
    static func showStatistics(historyService: HistoryService) {
        StatisticsScreen.show(historyService: historyService)
    }
}
