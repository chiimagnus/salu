import GameCore

private final class L10nState: @unchecked Sendable {
    static let shared = L10nState()
    var language: GameLanguage = .en
}

enum L10n {
    static var language: GameLanguage {
        get { L10nState.shared.language }
        set { L10nState.shared.language = newValue }
    }

    static func text(_ zhHans: String, _ en: String) -> String {
        switch language {
        case .zhHans:
            return zhHans
        case .en:
            return en
        }
    }

    static func resolve(_ text: LocalizedText) -> String {
        text.resolved(for: language)
    }
}
