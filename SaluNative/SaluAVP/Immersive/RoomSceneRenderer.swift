import GameCore
import RealityKit
import UIKit

struct RoomSceneRenderer {
    enum Names {
        static let roomLayer = "roomLayer"
        static let roomRoot = "roomRoot"
        static let npcPrefix = "roomNpc:"
    }

    private struct RenderKey: Equatable {
        let nodeId: String
        let roomType: RoomType
    }

    private var renderKey: RenderKey?

    mutating func makeRoomLayer() -> RealityKit.Entity {
        let layer = RealityKit.Entity()
        layer.name = Names.roomLayer
        return layer
    }

    mutating func render(nodeId: String, roomType: RoomType, in layer: RealityKit.Entity) {
        let key = RenderKey(nodeId: nodeId, roomType: roomType)
        guard renderKey != key else { return }
        rebuildScene(nodeId: nodeId, roomType: roomType, in: layer)
        renderKey = key
    }

    mutating func clear(in layer: RealityKit.Entity) {
        guard renderKey != nil || !layer.children.isEmpty else { return }
        layer.children.forEach { $0.removeFromParent() }
        renderKey = nil
    }

    func panelPosition(for roomType: RoomType) -> SIMD3<Float> {
        switch roomType {
        case .rest:
            return [0.34, 0.14, -0.62]
        case .shop:
            return [0.38, 0.14, -0.62]
        case .event:
            return [0.34, 0.14, -0.62]
        default:
            return [0.32, 0.14, -0.62]
        }
    }

    private mutating func rebuildScene(nodeId: String, roomType: RoomType, in layer: RealityKit.Entity) {
        layer.children.forEach { $0.removeFromParent() }

        let root = RealityKit.Entity()
        root.name = Names.roomRoot
        layer.addChild(root)

        addCommonEnvironment(roomType: roomType, to: root)

        switch roomType {
        case .rest:
            buildRestScene(nodeId: nodeId, in: root)
        case .shop:
            buildShopScene(nodeId: nodeId, in: root)
        case .event:
            buildEventScene(nodeId: nodeId, in: root)
        default:
            buildGenericScene(nodeId: nodeId, roomType: roomType, in: root)
        }
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

    private func buildShopScene(nodeId: String, in root: RealityKit.Entity) {
        _ = nodeId

        let counter = ModelEntity(
            mesh: .generateBox(size: [0.9, 0.16, 0.26]),
            materials: [SimpleMaterial(color: UIColor.systemBrown, isMetallic: false)]
        )
        counter.position = [0, 0.08, -0.82]
        root.addChild(counter)

        let stallTop = ModelEntity(
            mesh: .generateBox(size: [1.0, 0.02, 0.28]),
            materials: [SimpleMaterial(color: UIColor.systemYellow.withAlphaComponent(0.65), isMetallic: false)]
        )
        stallTop.position = [0, 0.44, -0.82]
        root.addChild(stallTop)

        let merchant = makeNPC(
            name: "\(Names.npcPrefix)merchant",
            color: UIColor.systemTeal,
            accessoryColor: UIColor.systemOrange.withAlphaComponent(0.7)
        )
        merchant.position = [0, 0, -0.97]
        root.addChild(merchant)

        let relicPedestalLeft = ModelEntity(
            mesh: .generateCylinder(height: 0.18, radius: 0.05),
            materials: [SimpleMaterial(color: UIColor.systemGray2, isMetallic: true)]
        )
        relicPedestalLeft.position = [-0.26, 0.09, -0.68]
        root.addChild(relicPedestalLeft)

        let relicPedestalRight = ModelEntity(
            mesh: .generateCylinder(height: 0.18, radius: 0.05),
            materials: [SimpleMaterial(color: UIColor.systemGray2, isMetallic: true)]
        )
        relicPedestalRight.position = [0.26, 0.09, -0.68]
        root.addChild(relicPedestalRight)
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
}
