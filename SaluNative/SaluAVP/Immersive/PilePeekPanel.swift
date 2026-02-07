import SwiftUI

import GameCore

struct PilePeekPanel: View {
    @Environment(AppModel.self) private var appModel
    @Environment(RunSession.self) private var runSession

    let pile: PileKind

    var body: some View {
        let displayMode = appModel.cardDisplayMode
        let language: GameLanguage = .zhHans

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("\(pile.title) Pile")
                    .font(.headline)
                Spacer(minLength: 0)
                Text("Mode \(displayMode.shortLabel)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let state = runSession.battleState {
                let cards = pileCards(from: state, pile: pile)
                Text("Count \(cards.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(cards.suffix(10).reversed().enumerated()), id: \.offset) { _, card in
                            let def = CardRegistry.require(card.cardId)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(primaryLine(def: def, displayMode: displayMode, language: language))
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if let secondary = secondaryLine(def: def, displayMode: displayMode, language: language) {
                                    Text(secondary)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
            } else {
                Text("No battle state.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 320)
    }

    private func pileCards(from state: BattleState, pile: PileKind) -> [Card] {
        switch pile {
        case .draw:
            return state.drawPile
        case .discard:
            return state.discardPile
        case .exhaust:
            return state.exhaustPile
        }
    }

    private func primaryLine(def: any CardDefinition.Type, displayMode: CardDisplayMode, language: GameLanguage) -> String {
        let name = def.name.resolved(for: language)
        switch displayMode {
        case .modeA:
            return name
        case .modeB:
            return "\(def.cost)  \(name)"
        case .modeC, .modeD:
            let type = def.type.displayName(language: language)
            return "\(def.cost)  \(name)  •  \(type)"
        }
    }

    private func secondaryLine(def: any CardDefinition.Type, displayMode: CardDisplayMode, language: GameLanguage) -> String? {
        switch displayMode {
        case .modeA, .modeB:
            return nil
        case .modeC:
            return shortRules(def.rulesText.resolved(for: language), maxChars: 70)
        case .modeD:
            return def.rulesText.resolved(for: language)
        }
    }

    private func shortRules(_ text: String, maxChars: Int) -> String {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        if firstLine.count <= maxChars {
            return firstLine
        }
        let idx = firstLine.index(firstLine.startIndex, offsetBy: maxChars)
        return String(firstLine[..<idx]) + "…"
    }
}

struct PilePeekAttachment: View {
    let activePile: PileKind?

    var body: some View {
        if let activePile {
            PilePeekPanel(pile: activePile)
        }
    }
}
