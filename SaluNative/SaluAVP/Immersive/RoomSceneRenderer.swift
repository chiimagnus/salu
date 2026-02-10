import GameCore
import RealityKit
import UIKit

@MainActor
final class RoomSceneRenderer {
    enum Names {
        static let roomLayer = "roomLayer"
        static let roomRoot = "roomRoot"
        static let npcPrefix = "roomNpc:"
        static let shopActionPrefix = "shopAction:"

        static func shopActionName(_ action: String, index: Int? = nil) -> String {
            if let index {
                return "\(shopActionPrefix)\(action):\(index)"
            }
            return "\(shopActionPrefix)\(action)"
        }
    }

    private struct ShopVisualKey: Equatable {
        let cardOffers: [ShopCardOffer]
        let relicOffers: [ShopRelicOffer]
        let consumableOffers: [ShopConsumableOffer]
        let removeCardPrice: Int
        let deckCardInstanceIds: [String]
        let gold: Int
    }

    private struct RenderKey: Equatable {
        let nodeId: String
        let roomType: RoomType
        let shopVisual: ShopVisualKey?
    }

    private struct RoomRenderStateComponent: Component {
        let signature: UInt64
    }

    func makeRoomLayer() -> RealityKit.Entity {
        let layer = RealityKit.Entity()
        layer.name = Names.roomLayer
        return layer
    }

    func render(
        nodeId: String,
        roomType: RoomType,
        shopState: ShopRoomState?,
        runState: RunState?,
        in layer: RealityKit.Entity
    ) {
        let shopVisual = makeShopVisualKey(roomType: roomType, shopState: shopState, runState: runState)
        let key = RenderKey(nodeId: nodeId, roomType: roomType, shopVisual: shopVisual)
        let signature = renderSignature(for: key)
        if let state = layer.components[RoomRenderStateComponent.self],
           state.signature == signature,
           layer.findEntity(named: Names.roomRoot) != nil {
            return
        }
        rebuildScene(
            nodeId: nodeId,
            roomType: roomType,
            shopState: shopState,
            runState: runState,
            in: layer
        )
        layer.components.set(RoomRenderStateComponent(signature: signature))
    }

    func clear(in layer: RealityKit.Entity) {
        guard !layer.children.isEmpty || layer.components[RoomRenderStateComponent.self] != nil else { return }
        layer.children.forEach { $0.removeFromParent() }
        layer.components.remove(RoomRenderStateComponent.self)
    }

    func panelPosition(for roomType: RoomType) -> SIMD3<Float> {
        switch roomType {
        case .rest:
            return [0.34, 0.14, -0.62]
        case .event:
            return [0.34, 0.14, -0.62]
        default:
            return [0.32, 0.14, -0.62]
        }
    }

    private func makeShopVisualKey(
        roomType: RoomType,
        shopState: ShopRoomState?,
        runState: RunState?
    ) -> ShopVisualKey? {
        guard roomType == .shop, let shopState, let runState else { return nil }
        return ShopVisualKey(
            cardOffers: shopState.inventory.cardOffers,
            relicOffers: shopState.inventory.relicOffers,
            consumableOffers: shopState.inventory.consumableOffers,
            removeCardPrice: shopState.inventory.removeCardPrice,
            deckCardInstanceIds: runState.deck.map(\.id),
            gold: runState.gold
        )
    }

    private func rebuildScene(
        nodeId: String,
        roomType: RoomType,
        shopState: ShopRoomState?,
        runState: RunState?,
        in layer: RealityKit.Entity
    ) {
        layer.children.forEach { $0.removeFromParent() }

        let root = RealityKit.Entity()
        root.name = Names.roomRoot
        layer.addChild(root)

        addCommonEnvironment(roomType: roomType, to: root)

        switch roomType {
        case .rest:
            buildRestScene(nodeId: nodeId, in: root)
        case .shop:
            buildShopScene(nodeId: nodeId, shopState: shopState, runState: runState, in: root)
        case .event:
            buildEventScene(nodeId: nodeId, in: root)
        default:
            buildGenericScene(nodeId: nodeId, roomType: roomType, in: root)
        }
    }

    private func renderSignature(for key: RenderKey) -> UInt64 {
        var parts: [String] = [
            "node:\(key.nodeId)",
            "type:\(key.roomType.rawValue)"
        ]

        if let shopVisual = key.shopVisual {
            parts.append("gold:\(shopVisual.gold)")
            parts.append("remove:\(shopVisual.removeCardPrice)")
            parts.append("deck:\(shopVisual.deckCardInstanceIds.joined(separator: ","))")
            parts.append(
                "cards:\(shopVisual.cardOffers.map { "\($0.cardId.rawValue)-\($0.price)" }.joined(separator: ","))"
            )
            parts.append(
                "relics:\(shopVisual.relicOffers.map { "\($0.relicId.rawValue)-\($0.price)" }.joined(separator: ","))"
            )
            parts.append(
                "consumables:\(shopVisual.consumableOffers.map { "\($0.cardId.rawValue)-\($0.price)" }.joined(separator: ","))"
            )
        } else {
            parts.append("shop:nil")
        }

        return StableHash.fnv1a64(parts.joined(separator: "#"))
    }

    private func addCommonEnvironment(roomType: RoomType, to root: RealityKit.Entity) {
        let floorColor: UIColor
        switch roomType {
        case .rest:
            floorColor = UIColor.systemGreen.withAlphaComponent(0.12)
        case .shop:
            floorColor = UIColor.systemTeal.withAlphaComponent(0.12)
        case .event:
            floorColor = UIColor.systemPurple.withAlphaComponent(0.12)
        default:
            floorColor = UIColor.systemGray.withAlphaComponent(0.10)
        }

        let floor = ModelEntity(
            mesh: .generateBox(size: [2.2, 0.02, 2.8]),
            materials: [SimpleMaterial(color: floorColor, isMetallic: false)]
        )
        floor.name = "roomFloor"
        floor.position = [0, -0.02, -0.75]
        root.addChild(floor)

        let backWall = ModelEntity(
            mesh: .generateBox(size: [2.2, 1.1, 0.02]),
            materials: [SimpleMaterial(color: UIColor.white.withAlphaComponent(0.06), isMetallic: false)]
        )
        backWall.name = "backWall"
        backWall.position = [0, 0.52, -1.35]
        root.addChild(backWall)
    }

    private func buildRestScene(nodeId: String, in root: RealityKit.Entity) {
        _ = nodeId

        let campBase = ModelEntity(
            mesh: .generateCylinder(height: 0.08, radius: 0.18),
            materials: [SimpleMaterial(color: UIColor.brown.withAlphaComponent(0.8), isMetallic: false)]
        )
        campBase.position = [0.0, 0.04, -0.86]
        root.addChild(campBase)

        let fire = ModelEntity(
            mesh: .generateSphere(radius: 0.07),
            materials: [SimpleMaterial(color: UIColor.systemOrange, isMetallic: false)]
        )
        fire.position = [0.0, 0.14, -0.86]
        root.addChild(fire)

        let aira = makeNPC(
            name: "\(Names.npcPrefix)aira",
            color: UIColor.systemMint,
            accessoryColor: UIColor.systemBlue.withAlphaComponent(0.7)
        )
        aira.position = [-0.28, 0, -0.78]
        root.addChild(aira)

        let seat = ModelEntity(
            mesh: .generateBox(size: [0.28, 0.06, 0.12]),
            materials: [SimpleMaterial(color: UIColor.darkGray, isMetallic: false)]
        )
        seat.position = [0.34, 0.03, -0.86]
        root.addChild(seat)
    }

    private func buildShopScene(
        nodeId: String,
        shopState: ShopRoomState?,
        runState: RunState?,
        in root: RealityKit.Entity
    ) {
        guard let shopState, let runState, shopState.nodeId == nodeId else {
            buildGenericScene(nodeId: nodeId, roomType: .shop, in: root)
            return
        }

        let merchant = makeNPC(
            name: "\(Names.npcPrefix)merchant",
            color: UIColor.systemTeal,
            accessoryColor: UIColor.systemOrange.withAlphaComponent(0.7)
        )
        merchant.position = [0, 0, -0.98]
        root.addChild(merchant)

        renderShopGoldBalance(runState: runState, in: root)
        renderShopCardOffers(shopState: shopState, runState: runState, in: root)
        renderShopRelicOffers(shopState: shopState, runState: runState, in: root)
        renderShopConsumables(shopState: shopState, runState: runState, in: root)
        renderShopRemoveCardOffers(shopState: shopState, runState: runState, in: root)
        renderShopLeaveAction(in: root)
    }

    private func renderShopGoldBalance(runState: RunState, in root: RealityKit.Entity) {
        let wallet = ModelEntity(
            mesh: .generateCylinder(height: 0.04, radius: 0.06),
            materials: [SimpleMaterial(color: UIColor.systemYellow.withAlphaComponent(0.88), isMetallic: true)]
        )
        wallet.name = "shopGoldWallet"
        wallet.position = [0.50, 0.14, -0.88]
        root.addChild(wallet)

        if let badge = makeBadgeEntity(text: "\(runState.gold)", affordable: true) {
            badge.name = "shopGoldLabel"
            badge.position = [0.50, 0.24, -0.88]
            root.addChild(badge)
        }
    }

    private func renderShopCardOffers(
        shopState: ShopRoomState,
        runState: RunState,
        in root: RealityKit.Entity
    ) {
        for (index, offer) in shopState.inventory.cardOffers.enumerated() {
            let affordable = runState.gold >= offer.price
            let x = -0.46 + Float(index) * 0.13
            let itemPosition: SIMD3<Float> = [x, 0.18, -0.70]
            let entity = makeShopActionEntity(
                mesh: .generateBox(size: [0.09, 0.11, 0.05]),
                color: actionColor(base: UIColor.systemBlue, affordable: affordable),
                position: itemPosition,
                name: Names.shopActionName("card", index: index),
                collisionSize: [0.12, 0.14, 0.10]
            )
            root.addChild(entity)
            root.addChild(makeAffordabilityMarker(affordable: affordable, near: itemPosition))
            if let tag = makeBadgeEntity(text: "\(offer.price)", affordable: affordable) {
                tag.name = "shopCardPrice:\(index)"
                tag.position = [itemPosition.x, itemPosition.y + 0.10, itemPosition.z + 0.02]
                root.addChild(tag)
            }
        }
    }

    private func renderShopRelicOffers(
        shopState: ShopRoomState,
        runState: RunState,
        in root: RealityKit.Entity
    ) {
        for (index, offer) in shopState.inventory.relicOffers.enumerated() {
            let affordable = runState.gold >= offer.price
            let x = -0.18 + Float(index) * 0.18
            let itemPosition: SIMD3<Float> = [x, 0.22, -0.58]
            let entity = makeShopActionEntity(
                mesh: .generateSphere(radius: 0.055),
                color: actionColor(base: UIColor.systemPurple, affordable: affordable),
                position: itemPosition,
                name: Names.shopActionName("relic", index: index),
                collisionSize: [0.14, 0.14, 0.14]
            )
            root.addChild(entity)
            root.addChild(makeAffordabilityMarker(affordable: affordable, near: itemPosition))
            if let tag = makeBadgeEntity(text: "\(offer.price)", affordable: affordable) {
                tag.name = "shopRelicPrice:\(index)"
                tag.position = [itemPosition.x, itemPosition.y + 0.11, itemPosition.z + 0.02]
                root.addChild(tag)
            }
        }
    }

    private func renderShopConsumables(
        shopState: ShopRoomState,
        runState: RunState,
        in root: RealityKit.Entity
    ) {
        for (index, offer) in shopState.inventory.consumableOffers.enumerated() {
            let affordable = runState.gold >= offer.price
            let x = 0.12 + Float(index) * 0.14
            let itemPosition: SIMD3<Float> = [x, 0.20, -0.72]
            let entity = makeShopActionEntity(
                mesh: .generateCylinder(height: 0.12, radius: 0.045),
                color: actionColor(base: UIColor.systemGreen, affordable: affordable),
                position: itemPosition,
                name: Names.shopActionName("consumable", index: index),
                collisionSize: [0.12, 0.15, 0.12]
            )
            root.addChild(entity)
            root.addChild(makeAffordabilityMarker(affordable: affordable, near: itemPosition))
            if let tag = makeBadgeEntity(text: "\(offer.price)", affordable: affordable) {
                tag.name = "shopConsumablePrice:\(index)"
                tag.position = [itemPosition.x, itemPosition.y + 0.11, itemPosition.z + 0.02]
                root.addChild(tag)
            }
        }
    }

    private func renderShopRemoveCardOffers(
        shopState: ShopRoomState,
        runState: RunState,
        in root: RealityKit.Entity
    ) {
        let isAffordable = runState.gold >= shopState.inventory.removeCardPrice
        if let removeTag = makeBadgeEntity(text: "\(shopState.inventory.removeCardPrice)", affordable: isAffordable) {
            removeTag.name = "shopRemovePrice"
            removeTag.position = [0.06, 0.16, -0.92]
            root.addChild(removeTag)
        }

        let maxCount = min(runState.deck.count, Self.maxRemoveCardDisplayCount)
        for deckIndex in 0..<maxCount {
            let row = deckIndex / 4
            let col = deckIndex % 4
            let x = -0.46 + Float(col) * 0.12
            let z = -0.93 - Float(row) * 0.12
            let itemPosition: SIMD3<Float> = [x, 0.10, z]
            let entity = makeShopActionEntity(
                mesh: .generateBox(size: [0.08, 0.04, 0.10]),
                color: actionColor(base: UIColor.systemPink, affordable: isAffordable),
                position: itemPosition,
                name: Names.shopActionName("remove", index: deckIndex),
                collisionSize: [0.11, 0.08, 0.13],
                metallic: false
            )
            root.addChild(entity)
            root.addChild(makeAffordabilityMarker(affordable: isAffordable, near: itemPosition))
        }

        if runState.deck.count > maxCount {
            let more = ModelEntity(
                mesh: .generateSphere(radius: 0.035),
                materials: [SimpleMaterial(color: UIColor.white.withAlphaComponent(0.85), isMetallic: false)]
            )
            more.position = [0.02, 0.10, -1.00]
            root.addChild(more)
        }
    }

    private func renderShopLeaveAction(in root: RealityKit.Entity) {
        let leavePosition: SIMD3<Float> = [0.44, 0.09, -0.58]
        let leave = makeShopActionEntity(
            mesh: .generateCone(height: 0.14, radius: 0.06),
            color: UIColor.systemGray,
            position: leavePosition,
            name: Names.shopActionName("leave"),
            collisionSize: [0.14, 0.18, 0.14],
            metallic: false
        )
        root.addChild(leave)
        if let leaveTag = makeBadgeEntity(text: "EXIT", affordable: true) {
            leaveTag.name = "shopLeaveLabel"
            leaveTag.position = [leavePosition.x, leavePosition.y + 0.14, leavePosition.z]
            root.addChild(leaveTag)
        }
    }

    private func buildEventScene(nodeId: String, in root: RealityKit.Entity) {
        _ = nodeId

        let monolith = ModelEntity(
            mesh: .generateBox(size: [0.2, 0.52, 0.12]),
            materials: [SimpleMaterial(color: UIColor.systemPurple.withAlphaComponent(0.75), isMetallic: true)]
        )
        monolith.position = [0, 0.26, -0.96]
        root.addChild(monolith)

        let aura = ModelEntity(
            mesh: .generateSphere(radius: 0.09),
            materials: [SimpleMaterial(color: UIColor.systemPink.withAlphaComponent(0.8), isMetallic: false)]
        )
        aura.position = [0, 0.52, -0.96]
        root.addChild(aura)

        let witness = makeNPC(
            name: "\(Names.npcPrefix)witness",
            color: UIColor.systemIndigo,
            accessoryColor: UIColor.systemPurple.withAlphaComponent(0.7)
        )
        witness.position = [-0.34, 0, -0.78]
        root.addChild(witness)
    }

    private func buildGenericScene(nodeId: String, roomType: RoomType, in root: RealityKit.Entity) {
        let marker = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: UIColor.systemGray.withAlphaComponent(0.8), isMetallic: false)]
        )
        marker.position = [0, 0.12, -0.82]
        root.addChild(marker)

        let plate = ModelEntity(
            mesh: .generateBox(size: [0.6, 0.04, 0.12]),
            materials: [SimpleMaterial(color: UIColor.systemGray3.withAlphaComponent(0.9), isMetallic: false)]
        )
        plate.position = [0, 0.03, -0.62]
        plate.name = "roomLabel:\(roomType.rawValue):\(nodeId)"
        root.addChild(plate)
    }

    private func actionColor(base: UIColor, affordable: Bool) -> UIColor {
        if affordable { return base }
        return UIColor.systemRed.withAlphaComponent(0.85)
    }

    private func makeAffordabilityMarker(affordable: Bool, near position: SIMD3<Float>) -> ModelEntity {
        let color = affordable
            ? UIColor.systemGreen.withAlphaComponent(0.70)
            : UIColor.systemRed.withAlphaComponent(0.72)
        let marker = ModelEntity(
            mesh: .generateCylinder(height: 0.004, radius: 0.06),
            materials: [SimpleMaterial(color: color, isMetallic: false)]
        )
        marker.position = [position.x, max(0.01, position.y - 0.08), position.z]
        return marker
    }

    private func makeBadgeEntity(text: String, affordable: Bool) -> ModelEntity? {
        let style: FloatingTextFactory.Style = affordable ? .neutral : .damage
        guard let badge = FloatingTextFactory.makeEntity(text: text, style: style) else { return nil }
        badge.scale = [0.34, 0.34, 0.34]
        badge.components.set(BillboardComponent())
        return badge
    }

    private func makeShopActionEntity(
        mesh: MeshResource,
        color: UIColor,
        position: SIMD3<Float>,
        name: String,
        collisionSize: SIMD3<Float>,
        metallic: Bool = true
    ) -> ModelEntity {
        let entity = ModelEntity(
            mesh: mesh,
            materials: [SimpleMaterial(color: color, isMetallic: metallic)]
        )
        entity.name = name
        entity.position = position
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: collisionSize)]))
        entity.components.set(InputTargetComponent())
        return entity
    }

    private func makeNPC(name: String, color: UIColor, accessoryColor: UIColor) -> RealityKit.Entity {
        let npc = RealityKit.Entity()
        npc.name = name
        npc.components.set(CollisionComponent(shapes: [.generateBox(size: [0.22, 0.42, 0.22])]))
        npc.components.set(InputTargetComponent())

        let body = ModelEntity(
            mesh: .generateCylinder(height: 0.24, radius: 0.06),
            materials: [SimpleMaterial(color: color, isMetallic: false)]
        )
        body.position = [0, 0.13, 0]
        npc.addChild(body)

        let head = ModelEntity(
            mesh: .generateSphere(radius: 0.055),
            materials: [SimpleMaterial(color: UIColor.white.withAlphaComponent(0.9), isMetallic: false)]
        )
        head.position = [0, 0.30, 0]
        npc.addChild(head)

        let accessory = ModelEntity(
            mesh: .generateBox(size: [0.16, 0.02, 0.08]),
            materials: [SimpleMaterial(color: accessoryColor, isMetallic: false)]
        )
        accessory.position = [0, 0.08, 0.06]
        npc.addChild(accessory)

        return npc
    }

    private static let maxRemoveCardDisplayCount = 12
}
