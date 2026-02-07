enum CardDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case modeA
    case modeB
    case modeC
    case modeD

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .modeA: return "A"
        case .modeB: return "B"
        case .modeC: return "C"
        case .modeD: return "D"
        }
    }

    var description: String {
        switch self {
        case .modeA:
            return "只显示：卡名"
        case .modeB:
            return "显示：卡名 + 费用"
        case .modeC:
            return "显示：卡名 + 费用 + 类型 + 简短描述（1–2 行）"
        case .modeD:
            return "显示：卡名 + 费用 + 完整规则文本"
        }
    }
}

