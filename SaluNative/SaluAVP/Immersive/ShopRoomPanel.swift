import SwiftUI
import GameCore

struct ShopRoomPanel: View {
    @Environment(RunSession.self) private var runSession

    let nodeId: String

    var body: some View {
        if let runState = runSession.runState,
           let shopState = runSession.shopRoomState,
           shopState.nodeId == nodeId {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(RoomType.shop.icon) 商店")
                        .font(.headline)

                    Text("金币: \(runState.gold)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    shopSectionTitle("卡牌")
                    ForEach(Array(shopState.inventory.cardOffers.enumerated()), id: \.offset) { index, offer in
                        let cardName = CardRegistry.require(offer.cardId).name.resolved(for: .zhHans)
                        Button {
                            runSession.buyShopCard(at: index)
                        } label: {
                            HStack {
                                Text(cardName)
                                Spacer(minLength: 12)
                                priceLabel(price: offer.price, currentGold: runState.gold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }

                    shopSectionTitle("遗物")
                    if shopState.inventory.relicOffers.isEmpty {
                        Text("遗物已售空")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(shopState.inventory.relicOffers.enumerated()), id: \.offset) { index, offer in
                            let def = RelicRegistry.require(offer.relicId)
                            Button {
                                runSession.buyShopRelic(at: index)
                            } label: {
                                HStack {
                                    Text("\(def.icon) \(def.name.resolved(for: .zhHans))")
                                    Spacer(minLength: 12)
                                    priceLabel(price: offer.price, currentGold: runState.gold)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    shopSectionTitle("消耗性卡牌")
                    ForEach(Array(shopState.inventory.consumableOffers.enumerated()), id: \.offset) { index, offer in
                        let cardName = CardRegistry.require(offer.cardId).name.resolved(for: .zhHans)
                        Button {
                            runSession.buyShopConsumable(at: index)
                        } label: {
                            HStack {
                                Text(cardName)
                                Spacer(minLength: 12)
                                priceLabel(price: offer.price, currentGold: runState.gold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }

                    shopSectionTitle("删牌服务 \(shopState.inventory.removeCardPrice) 金币")
                    if runState.deck.isEmpty {
                        Text("牌组为空")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(runState.deck.enumerated()), id: \.element.id) { deckIndex, card in
                            let cardName = CardRegistry.require(card.cardId).name.resolved(for: .zhHans)
                            Button {
                                runSession.removeCardInShop(deckIndex: deckIndex)
                            } label: {
                                HStack {
                                    Text("删除：\(cardName)")
                                    Spacer(minLength: 12)
                                    priceLabel(
                                        price: shopState.inventory.removeCardPrice,
                                        currentGold: runState.gold
                                    )
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let message = shopState.message, !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(message.contains("成功") ? .green : .red)
                    }

                    Button("离开商店") {
                        runSession.leaveShopRoom()
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Node: \(nodeId)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(width: 380, height: 460)
        } else {
            EmptyView()
        }
    }

    private func shopSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .padding(.top, 4)
    }

    @ViewBuilder
    private func priceLabel(price: Int, currentGold: Int) -> some View {
        let color: Color = currentGold >= price ? .secondary : .red
        Text("\(price)")
            .font(.caption)
            .foregroundStyle(color)
    }
}
