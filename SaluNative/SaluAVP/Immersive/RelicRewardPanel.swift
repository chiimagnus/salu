import SwiftUI
import GameCore

struct RelicRewardPanel: View {
    @Environment(RunSession.self) private var runSession

    let rewardState: RewardRouteState
    let relicReward: RewardRouteState.RelicReward

    var body: some View {
        let def = RelicRegistry.require(relicReward.relicId)

        VStack(alignment: .leading, spacing: 10) {
            Text("Relic Reward")
                .font(.headline)

            Text("Gold +\(rewardState.goldEarned)")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(def.icon) \(def.name.resolved(for: .zhHans))")
                    .font(.body)
                Text(sourceLabel(relicReward.source))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(def.description.resolved(for: .zhHans))
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button("Take") {
                    runSession.chooseRelicReward(take: true)
                }
                .buttonStyle(.borderedProminent)

                Button("Skip") {
                    runSession.chooseRelicReward(take: false)
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 0)

                Text("\(rewardState.roomType.icon) \(rewardState.nodeId)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 320)
    }

    private func sourceLabel(_ source: RelicDropSource) -> String {
        switch source {
        case .elite:
            return "Elite Relic"
        case .boss:
            return "Boss Relic"
        }
    }
}

