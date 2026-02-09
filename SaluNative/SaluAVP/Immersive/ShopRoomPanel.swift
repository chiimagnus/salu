import SwiftUI
import GameCore

enum ShopItemSelection: Equatable, Sendable {
    case card(Int)
    case relic(Int)
    case consumable(Int)
    case removeCard(Int)
}

struct ShopRoomPanel: View {
    @Environment(RunSession.self) private var runSession

    let nodeId: String
    @Binding var selection: ShopItemSelection?

    var body: some View {
        if let selection,
           let shopState = runSession.shopRoomState,
           let runState = runSession.runState,
           shopState.nodeId == nodeId,
           let descriptor = makeDescriptor(
            selection: selection,
            shopState: shopState,
            runState: runState
           ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(descriptor.icon) \(descriptor.title)")
                    .font(.headline)

                Text(descriptor.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(descriptor.details)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("价格：\(descriptor.price)G · 当前金币：\(runState.gold)G")
                    .font(.caption)
                    .foregroundStyle(descriptor.canAfford ? Color.secondary : Color.red)

                if let message = shopState.message, !message.isEmpty {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(shopMessageColor(for: message))
                }

                HStack(spacing: 8) {
                    Button(descriptor.purchaseButtonTitle) {
                        executePurchase(for: selection)
                        self.selection = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!descriptor.canAfford)

                    Button("关闭") {
                        self.selection = nil
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(12)
            .frame(width: 320, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            EmptyView()
        }
    }

    private func makeDescriptor(
        selection: ShopItemSelection,
        shopState: ShopRoomState,
        runState: RunState
    ) -> ShopPanelDescriptor? {
        switch selection {
        case .card(let index):
            guard shopState.inventory.cardOffers.indices.contains(index) else { return nil }
            let offer = shopState.inventory.cardOffers[index]
            let def = CardRegistry.require(offer.cardId)
            return ShopPanelDescriptor(
                icon: "🃏",
                title: def.name.resolved(for: .zhHans),
                subtitle: "\(def.type.displayName(language: .zhHans)) · 消耗 \(def.cost)",
                details: def.rulesText.resolved(for: .zhHans),
                price: offer.price,
                canAfford: runState.gold >= offer.price,
                purchaseButtonTitle: "购买卡牌"
            )

        case .relic(let index):
            guard shopState.inventory.relicOffers.indices.contains(index) else { return nil }
            let offer = shopState.inventory.relicOffers[index]
            let def = RelicRegistry.require(offer.relicId)
            return ShopPanelDescriptor(
                icon: def.icon,
                title: def.name.resolved(for: .zhHans),
                subtitle: "\(def.rarity.displayName(language: .zhHans))遗物",
                details: def.description.resolved(for: .zhHans),
                price: offer.price,
                canAfford: runState.gold >= offer.price,
                purchaseButtonTitle: "购买遗物"
            )

        case .consumable(let index):
            guard shopState.inventory.consumableOffers.indices.contains(index) else { return nil }
            let offer = shopState.inventory.consumableOffers[index]
            let def = CardRegistry.require(offer.cardId)
            return ShopPanelDescriptor(
                icon: "🧪",
                title: def.name.resolved(for: .zhHans),
                subtitle: "消耗性卡牌 · 消耗 \(def.cost)",
                details: def.rulesText.resolved(for: .zhHans),
                price: offer.price,
                canAfford: runState.gold >= offer.price,
                purchaseButtonTitle: "购买消耗牌"
            )

        case .removeCard(let deckIndex):
            guard runState.deck.indices.contains(deckIndex) else { return nil }
            let card = runState.deck[deckIndex]
            let def = CardRegistry.require(card.cardId)
            let price = shopState.inventory.removeCardPrice
            return ShopPanelDescriptor(
                icon: "🗑️",
                title: "删除：\(def.name.resolved(for: .zhHans))",
                subtitle: "牌组位置 \(deckIndex + 1)",
                details: "从牌组永久移除该卡牌。",
                price: price,
                canAfford: runState.gold >= price,
                purchaseButtonTitle: "支付并删除"
            )
        }
    }

    private func executePurchase(for selection: ShopItemSelection) {
        switch selection {
        case .card(let index):
            runSession.buyShopCard(at: index)
        case .relic(let index):
            runSession.buyShopRelic(at: index)
        case .consumable(let index):
            runSession.buyShopConsumable(at: index)
        case .removeCard(let deckIndex):
            runSession.removeCardInShop(deckIndex: deckIndex)
        }
    }

    private func shopMessageColor(for message: String) -> Color {
        if message.contains("不足")
            || message.contains("无效")
            || message.contains("失败")
            || message.contains("已满") {
            return .red
        }
        return .green
    }
}

private struct ShopPanelDescriptor {
    let icon: String
    let title: String
    let subtitle: String
    let details: String
    let price: Int
    let canAfford: Bool
    let purchaseButtonTitle: String
}
