import Foundation

enum PileKind: String, CaseIterable, Identifiable, Sendable {
    case draw
    case discard
    case exhaust

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draw:
            return "Draw"
        case .discard:
            return "Discard"
        case .exhaust:
            return "Exhaust"
        }
    }
}

