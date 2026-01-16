public enum GameLanguage: String, CaseIterable, Sendable, Codable {
    case zhHans = "zh-Hans"
    case en = "en"

    public var displayName: String {
        switch self {
        case .zhHans:
            return "中文"
        case .en:
            return "English"
        }
    }
}

public struct LocalizedText: Sendable, Equatable {
    public let zhHans: String
    public let en: String

    public init(zhHans: String, en: String) {
        self.zhHans = zhHans
        self.en = en
    }

    public init(_ zhHans: String, _ en: String) {
        self.zhHans = zhHans
        self.en = en
    }

    public func resolved(for language: GameLanguage) -> String {
        switch language {
        case .zhHans:
            return zhHans
        case .en:
            return en
        }
    }
}
