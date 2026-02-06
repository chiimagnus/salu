import SwiftUI
import GameCore

struct CardRewardPanel: View {
    @Environment(RunSession.self) private var runSession

    let nodeId: String
    let roomType: RoomType
    let offer: CardRewardOffer
    let goldEarned: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rewards")
                .font(.headline)

            Text("Gold +\(goldEarned)")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(offer.choices, id: \.rawValue) { cardId in
                    let def = CardRegistry.require(cardId)
                    Button {
                        runSession.chooseCardReward(cardId)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(def.name.resolved(for: .zhHans))
                                .font(.body)
                            Text(verbatim: "\(def.type)  cost \(def.cost)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            HStack(spacing: 10) {
                Button("Skip") {
                    runSession.chooseCardReward(nil)
                }
                .buttonStyle(.bordered)
                .disabled(!offer.canSkip)

                Spacer(minLength: 0)

                Text("\(roomType.icon) \(nodeId)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 320)
    }
}
