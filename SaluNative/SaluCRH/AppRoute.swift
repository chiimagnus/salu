import Foundation
import GameCore

/// 应用路由枚举 - 表示当前应用所处的页面/状态
enum AppRoute: Equatable {
    /// 主菜单
    case mainMenu
    
    /// 地图界面（冒险中）
    case runMap
    
    /// 战斗界面（普通/精英/Boss）
    case battle
    
    /// 商店界面
    case shop
    
    /// 事件界面
    case event
    
    /// 休息点界面
    case rest
    
    /// 卡牌奖励选择界面
    case cardReward
    
    /// 遗物奖励选择界面
    case relicReward
    
    /// 冒险结果界面（胜利/失败）
    case runResult(won: Bool)
    
    /// 历史记录界面
    case history
    
    /// 统计界面
    case statistics
    
    /// 设置界面
    case settings
}
