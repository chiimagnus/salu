// MARK: - Strong-Typed IDs

/// 卡牌 ID（强类型，禁止散落字符串）
public struct CardID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

/// 状态 ID（强类型）
public struct StatusID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

/// 敌人 ID（强类型，P3 新增）
public struct EnemyID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

/// 遗物 ID（强类型，P4 新增）
public struct RelicID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

/// 事件 ID（强类型，P5 新增）
public struct EventID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}
