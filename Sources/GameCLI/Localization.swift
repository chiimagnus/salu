import GameCore

enum L10n {
    static var language: GameLanguage = .zhHans

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
