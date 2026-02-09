import SwiftUI
import GameCore

struct EventRoomPanel: View {
    @Environment(RunSession.self) private var runSession

    let nodeId: String

    var body: some View {
        if let eventState = runSession.eventRoomState,
           eventState.nodeId == nodeId {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(eventState.offer.icon) \(eventState.offer.name.resolved(for: .zhHans))")
                    .font(.headline)

                Text(eventState.offer.description.resolved(for: .zhHans))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                switch eventState.phase {
                case .choosing:
                    choosingView(eventState: eventState)

                case .chooseUpgrade(_, let indices, _):
                    upgradeChoiceView(indices: indices)

                case .awaitingBattleResolution(_, let enemyId, _):
                    let enemyName = EnemyRegistry.require(enemyId).name.resolved(for: .zhHans)
                    Text("即将进入战斗：\(enemyName)")
                        .font(.body)
                    Text("战斗结束后将返回事件结果页。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                case .resolved(let optionIndex, let resultLines):
                    resolvedView(eventState: eventState, optionIndex: optionIndex, resultLines: resultLines)
                }

                if let message = eventState.message, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text("Node: \(nodeId)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(width: 380)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func choosingView(eventState: EventRoomState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("请选择一个选项")
                .font(.subheadline)

            ForEach(Array(eventState.offer.options.enumerated()), id: \.offset) { index, option in
                Button {
                    runSession.chooseEventOption(index)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.title.resolved(for: .zhHans))
                            .font(.body)
                        if let preview = option.preview?.resolved(for: .zhHans), !preview.isEmpty {
                            Text(preview)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private func upgradeChoiceView(indices: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择要升级的卡牌")
                .font(.subheadline)

            if let runState = runSession.runState {
                ForEach(indices, id: \.self) { deckIndex in
                    if runState.deck.indices.contains(deckIndex) {
                        let card = runState.deck[deckIndex]
                        let cardDef = CardRegistry.require(card.cardId)
                        let upgradedName = cardDef.upgradedId.map {
                            CardRegistry.require($0).name.resolved(for: .zhHans)
                        } ?? "不可升级"

                        Button {
                            runSession.chooseEventUpgradeCard(deckIndex: deckIndex)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(cardDef.name.resolved(for: .zhHans)) -> \(upgradedName)")
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
            } else {
                Text("运行状态不可用，无法升级卡牌。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("跳过升级") {
                runSession.skipEventUpgradeChoice()
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func resolvedView(eventState: EventRoomState, optionIndex: Int, resultLines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if eventState.offer.options.indices.contains(optionIndex) {
                Text("你选择了：\(eventState.offer.options[optionIndex].title.resolved(for: .zhHans))")
                    .font(.subheadline)
            } else {
                Text("事件结算")
                    .font(.subheadline)
            }

            if resultLines.isEmpty {
                Text("没有发生任何事。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(resultLines.enumerated()), id: \.offset) { _, line in
                    Text("• \(line)")
                        .font(.caption)
                }
            }

            Button("继续前进") {
                runSession.completeEventRoom()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
