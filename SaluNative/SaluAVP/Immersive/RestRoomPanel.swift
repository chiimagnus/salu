import SwiftUI
import GameCore

struct RestRoomPanel: View {
    @Environment(RunSession.self) private var runSession

    let nodeId: String

    var body: some View {
        if let runState = runSession.runState {
            let upgradeableIndices = runState.upgradeableCardIndices

            VStack(alignment: .leading, spacing: 10) {
                Text("\(RoomType.rest.icon) 休息点")
                    .font(.headline)

                Text("HP: \(runState.player.currentHP)/\(runState.player.maxHP)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button("休息恢复") {
                        runSession.restHeal()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("与艾拉对话") {
                        runSession.restTalkToAira()
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                Text("升级卡牌")
                    .font(.subheadline)

                if upgradeableIndices.isEmpty {
                    Text("当前没有可升级的卡牌")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(upgradeableIndices, id: \.self) { deckIndex in
                            let card = runState.deck[deckIndex]
                            let def = CardRegistry.require(card.cardId)
                            let upgradedName = def.upgradedId.map {
                                CardRegistry.require($0).name.resolved(for: .zhHans)
                            } ?? "不可升级"

                            Button {
                                runSession.restUpgradeCard(deckIndex: deckIndex)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(def.name.resolved(for: .zhHans)) -> \(upgradedName)")
                                        .font(.body)
                                    Text("牌组位置 \(deckIndex + 1)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                if let restRoomMessage = runSession.restRoomMessage, !restRoomMessage.isEmpty {
                    Text(restRoomMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Text("Node: \(nodeId)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(width: 360)
        } else {
            EmptyView()
        }
    }
}
