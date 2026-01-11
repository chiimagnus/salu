// MARK: - Rewritten Intent (改写后的意图类型)

/// 改写后的意图类型
///
/// 用于"改写"机制：将敌人的当前意图替换为指定类型。
/// 只支持有限的意图类型，避免复杂度过高。
public enum RewrittenIntent: Sendable, Equatable {
    /// 改为防御（敌人将获得指定格挡值）
    case defend(block: Int)
    
    /// 跳过行动（敌人本回合不做任何事）
    case skip
}

