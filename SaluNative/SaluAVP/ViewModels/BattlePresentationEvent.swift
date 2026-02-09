import Foundation
import GameCore

/// AVP 表现层使用的战斗事件包装，包含稳定序号以支持动画队列消费。
struct BattlePresentationEvent: Sendable, Equatable {
    let sequence: Int
    let event: BattleEvent
}
