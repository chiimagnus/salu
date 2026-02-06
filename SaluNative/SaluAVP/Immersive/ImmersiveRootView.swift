import SwiftUI
import RealityKit
import UIKit
import GameCore

struct ImmersiveRootView: View {
    @Environment(RunSession.self) private var runSession
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    private let nodeNamePrefix = "node:"
    private let cardNamePrefix = "card:"
    private let roomPanelAttachmentId = "roomPanel"
    private let battleHudAttachmentId = "battleHUD"
    private let mapHudAttachmentId = "mapHUD"
    private let mapLayerPrefix = "mapLayer_floor_"
    private let uiLayerName = "uiLayer"
    private let battleLayerName = "battleLayer"
    private let hudAnchorName = "hudAnchor"
    private let battleHeadAnchorName = "battleHeadAnchor"
    private let battleHandRootName = "battleHandRoot"
    private let battleEnemyRootName = "battleEnemyRoot"

    var body: some View {
        RealityView { content, attachments in
            let mapRoot = RealityKit.Entity()
            mapRoot.name = "mapRoot"

            let mapLayer = RealityKit.Entity()
            mapLayer.name = "\(mapLayerPrefix)0"
            mapRoot.addChild(mapLayer)

            let uiLayer = RealityKit.Entity()
            uiLayer.name = uiLayerName
            mapRoot.addChild(uiLayer)

            // Always-on head anchor for 2D attachments (HUDs). Must NOT live under battleLayer,
            // otherwise it will be disabled when we hide battleLayer.
            let hudAnchor = AnchorEntity(.head)
            hudAnchor.name = hudAnchorName
            mapRoot.addChild(hudAnchor)

            let battleLayer = RealityKit.Entity()
            battleLayer.name = battleLayerName
            battleLayer.isEnabled = false

            addBattleFloor(to: battleLayer)

            let enemyRoot = RealityKit.Entity()
            enemyRoot.name = battleEnemyRootName
            enemyRoot.position = [0, 0.14, -1.0]
            battleLayer.addChild(enemyRoot)

            let headAnchor = AnchorEntity(.head)
            headAnchor.name = battleHeadAnchorName
            battleLayer.addChild(headAnchor)

            let handRoot = RealityKit.Entity()
            handRoot.name = battleHandRootName
            handRoot.position = [0, -0.12, -0.35]
            headAnchor.addChild(handRoot)

            mapRoot.addChild(battleLayer)
            content.add(mapRoot)
        } update: { content, attachments in
            guard let mapRoot = content.entities.first(where: { $0.name == "mapRoot" }) else { return }

            let uiLayer = mapRoot.findEntity(named: uiLayerName) ?? {
                let uiLayer = RealityKit.Entity()
                uiLayer.name = uiLayerName
                mapRoot.addChild(uiLayer)
                return uiLayer
            }()

            uiLayer.children.forEach { $0.removeFromParent() }

            let hudAnchor = mapRoot.findEntity(named: hudAnchorName) ?? {
                let hudAnchor = AnchorEntity(.head)
                hudAnchor.name = hudAnchorName
                mapRoot.addChild(hudAnchor)
                return hudAnchor
            }()

            guard let run = runSession.runState else {
                mapRoot.children.first(where: { $0.name.hasPrefix(mapLayerPrefix) })?.removeFromParent()
                mapRoot.findEntity(named: battleLayerName)?.isEnabled = false
                return
            }

            // Only rebuild the map when entering a new floor/act.
            let desiredMapLayerName = "\(mapLayerPrefix)\(run.floor)"
            let existingMapLayer = mapRoot.children.first(where: { $0.name.hasPrefix(mapLayerPrefix) })
            let mapLayer: RealityKit.Entity

            if existingMapLayer?.name == desiredMapLayerName {
                mapLayer = existingMapLayer!
                updateMapState(run: run, in: mapLayer)
            } else {
                existingMapLayer?.removeFromParent()
                let newLayer = RealityKit.Entity()
                newLayer.name = desiredMapLayerName
                mapRoot.addChild(newLayer)
                addFloor(to: newLayer)
                renderMap(run: run, into: newLayer)
                mapLayer = newLayer
            }

            let battleLayer = mapRoot.findEntity(named: battleLayerName) ?? {
                let battleLayer = RealityKit.Entity()
                battleLayer.name = battleLayerName
                battleLayer.isEnabled = false
                addBattleFloor(to: battleLayer)

                let enemyRoot = RealityKit.Entity()
                enemyRoot.name = battleEnemyRootName
                enemyRoot.position = [0, 0.14, -1.0]
                battleLayer.addChild(enemyRoot)

                let headAnchor = AnchorEntity(.head)
                headAnchor.name = battleHeadAnchorName
                battleLayer.addChild(headAnchor)

                let handRoot = RealityKit.Entity()
                handRoot.name = battleHandRootName
                handRoot.position = [0, -0.12, -0.35]
                headAnchor.addChild(handRoot)

                mapRoot.addChild(battleLayer)
                return battleLayer
            }()

            let isInBattle: Bool
            if case .battle = runSession.route {
                isInBattle = true
            } else {
                isInBattle = false
            }

            mapLayer.isEnabled = !isInBattle
            battleLayer.isEnabled = isInBattle

            if isInBattle, let engine = runSession.battleEngine {
                renderBattle(engine: engine, in: battleLayer)
            } else {
                clearBattle(in: battleLayer)
            }

            if let panel = attachments.entity(for: roomPanelAttachmentId) {
                panel.name = roomPanelAttachmentId
                panel.components.set(BillboardComponent())
                panel.components.set(InputTargetComponent())
                let (isVisible, position) = roomPanelPlacement(mapRoot: mapLayer, route: runSession.route)
                panel.isEnabled = isVisible
                panel.position = position
                uiLayer.addChild(panel)
            }

            if let hud = attachments.entity(for: battleHudAttachmentId) {
                hud.name = battleHudAttachmentId
                hud.components.set(BillboardComponent())
                hud.components.set(InputTargetComponent())
                hud.isEnabled = isInBattle

                hudAnchor.children.first(where: { $0.name == battleHudAttachmentId })?.removeFromParent()
                    // Place HUD near the top-right in the user's view (avoid clipping on Simulator).
                    hud.position = [0.18, 0.15, -0.50]
                hudAnchor.addChild(hud)
            }

            if let hud = attachments.entity(for: mapHudAttachmentId) {
                hud.name = mapHudAttachmentId
                hud.components.set(BillboardComponent())
                hud.components.set(InputTargetComponent())
                hud.isEnabled = !isInBattle

                hudAnchor.children.first(where: { $0.name == mapHudAttachmentId })?.removeFromParent()
                    hud.position = [0.18, 0.17, -0.50]
                hudAnchor.addChild(hud)
            }
        } attachments: {
            Attachment(id: roomPanelAttachmentId) {
                RoomPanel(
                    route: runSession.route,
                    onCompleteRoom: { runSession.completeCurrentRoomAndReturnToMap() },
                    onNewRun: { runSession.startNewRun() },
                    onClose: {
                        Task { @MainActor in
                            runSession.resetToControlPanel()
                            await dismissImmersiveSpace()
                            openWindow(id: AppModel.controlPanelWindowID)
                        }
                    }
                )
            }

            Attachment(id: battleHudAttachmentId) {
                BattleHUDPanel()
            }

            Attachment(id: mapHudAttachmentId) {
                MapHUDPanel()
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    switch runSession.route {
                    case .map:
                        guard value.entity.name.hasPrefix(nodeNamePrefix) else { return }
                        let nodeId = String(value.entity.name.dropFirst(nodeNamePrefix.count))
                        runSession.selectAccessibleNode(nodeId)

                    case .battle:
                        guard value.entity.name.hasPrefix(cardNamePrefix) else { return }
                        let suffix = value.entity.name.dropFirst(cardNamePrefix.count)
                        guard let handIndex = Int(suffix) else { return }
                        runSession.playCard(handIndex: handIndex)

                    case .room, .runOver:
                        break
                    }
                }
        )
    }

    private func roomPanelPlacement(mapRoot: RealityKit.Entity, route: RunSession.Route) -> (isVisible: Bool, position: SIMD3<Float>) {
        switch route {
        case .map:
            return (false, .zero)

        case .room(let nodeId, _):
            let nodeName = "\(nodeNamePrefix)\(nodeId)"
            if let node = mapRoot.findEntity(named: nodeName) {
                // Place the panel above the selected node; billboard will face the user.
                return (true, node.position + [0, 0.18, 0])
            }

            // Fallback: place in front of the map origin.
            return (true, [0, 0.25, -0.55])

        case .battle:
            return (false, .zero)

        case .runOver(let lastNodeId, _, _):
            // End-of-run panel should be easy to find: keep it near the map origin instead of far away at the Boss node.
            _ = lastNodeId
            return (true, [0, 0.25, -0.55])
        }
    }

    private func addFloor(to root: RealityKit.Entity) {
        let floor = RealityKit.Entity()
        floor.name = "floor"
        floor.components.set(CollisionComponent(shapes: [.generateBox(size: [2.8, 0.01, 4.2])]))
        floor.components.set(InputTargetComponent())
        root.addChild(floor)
    }

    private func addBattleFloor(to root: RealityKit.Entity) {
        let floorEntity = ModelEntity(
            mesh: .generateBox(size: [2.8, 0.01, 2.8]),
            materials: [SimpleMaterial(color: .black.withAlphaComponent(0.15), isMetallic: false)]
        )
        floorEntity.name = "battleFloor"
        floorEntity.position = [0, -0.01, -1.0]
        root.addChild(floorEntity)
    }

    private func clearBattle(in battleLayer: RealityKit.Entity) {
        battleLayer.findEntity(named: battleEnemyRootName)?.children.forEach { $0.removeFromParent() }
        battleLayer.findEntity(named: battleHeadAnchorName)?
            .findEntity(named: battleHandRootName)?
            .children
            .forEach { $0.removeFromParent() }
    }

    private func renderBattle(engine: BattleEngine, in battleLayer: RealityKit.Entity) {
        let enemyRoot = battleLayer.findEntity(named: battleEnemyRootName) ?? {
            let root = RealityKit.Entity()
            root.name = battleEnemyRootName
            root.position = [0, 0.14, -1.0]
            battleLayer.addChild(root)
            return root
        }()

        enemyRoot.children.forEach { $0.removeFromParent() }

        if let enemy = engine.state.enemies.first {
            let enemyEntity = makeEnemyEntity(enemy: enemy)
            enemyEntity.position = .zero
            enemyRoot.addChild(enemyEntity)
        }

        let headAnchor = battleLayer.findEntity(named: battleHeadAnchorName) ?? {
            let anchor = AnchorEntity(.head)
            anchor.name = battleHeadAnchorName
            battleLayer.addChild(anchor)
            return anchor
        }()

        let handRoot = headAnchor.findEntity(named: battleHandRootName) ?? {
            let root = RealityKit.Entity()
            root.name = battleHandRootName
            root.position = [0, -0.12, -0.35]
            headAnchor.addChild(root)
            return root
        }()

        handRoot.children.forEach { $0.removeFromParent() }

        let hand = engine.state.hand
        guard !hand.isEmpty else { return }

        let playable = Set(engine.playableCardIndices)
        let count = hand.count
        let center = Float(count - 1) / 2.0

        for (index, card) in hand.enumerated() {
            let isPlayable = playable.contains(index)
            let entity = makeCardEntity(card: card, isPlayable: isPlayable)
            entity.name = "\(cardNamePrefix)\(index)"

            let dx = Float(index) - center
            let x = dx * 0.07
            // Outer cards should come slightly closer to the user.
            let z = abs(dx) * 0.02
            entity.position = [x, 0, z]

            // Fan the cards toward the user (arc center facing the player).
            let yaw = -dx * 0.22
            let pitch: Float = 0.18
            entity.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: pitch, axis: [1, 0, 0])

            handRoot.addChild(entity)
        }
    }

    private func makeEnemyEntity(enemy: GameCore.Entity) -> ModelEntity {
        let material = SimpleMaterial(color: UIColor.systemRed.withAlphaComponent(0.85), isMetallic: true)
        let mesh = MeshResource.generateSphere(radius: 0.14)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "enemy:0"
        entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.14)]))
        entity.components.set(InputTargetComponent())
        return entity
    }

    private func makeCardEntity(card: Card, isPlayable: Bool) -> ModelEntity {
        let def = CardRegistry.require(card.cardId)
        let baseColor: UIColor
        switch def.type {
        case .attack:
            baseColor = .systemRed
        case .skill:
            baseColor = .systemBlue
        case .power:
            baseColor = .systemPurple
        case .consumable:
            baseColor = .systemGreen
        }

        let color = isPlayable ? baseColor.withAlphaComponent(0.9) : baseColor.withAlphaComponent(0.25)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let entity = ModelEntity(mesh: .generateBox(size: [0.06, 0.002, 0.09]), materials: [material])
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.065, 0.02, 0.095])]))
        entity.components.set(InputTargetComponent())
        return entity
    }

    private func updateMapState(run: RunState, in mapLayer: RealityKit.Entity) {
        // Map topology within the same floor doesn't change; only node state changes.
        for node in run.map {
            guard let entity = mapLayer.findEntity(named: "\(nodeNamePrefix)\(node.id)") as? ModelEntity else { continue }
            applyNodeAppearance(entity: entity, node: node, isCurrent: run.currentNodeId == node.id)
        }
    }

    private func renderMap(run: RunState, into root: RealityKit.Entity) {
        let rowSpacing: Float = 0.18
        let colSpacing: Float = 0.22
        let baseZ: Float = -0.6
        let nodeY: Float = 0.08
        let edgeY: Float = 0.035

        let nodesByRow = Dictionary(grouping: run.map, by: \.row)
        let maxRow = run.map.maxRow

        var positionsByNodeId: [String: SIMD3<Float>] = [:]

        for row in 0...maxRow {
            let rowNodes = (nodesByRow[row] ?? []).sorted { $0.column < $1.column }
            let offset = Float(rowNodes.count - 1) / 2.0

            for node in rowNodes {
                let x = (Float(node.column) - offset) * colSpacing
                let z = baseZ - Float(node.row) * rowSpacing
                positionsByNodeId[node.id] = [x, nodeY, z]
            }
        }

        for node in run.map {
            guard let from = positionsByNodeId[node.id] else { continue }
            for toId in node.connections {
                guard let to = positionsByNodeId[toId] else { continue }
                let edge = makeEdgeEntity(from: [from.x, edgeY, from.z], to: [to.x, edgeY, to.z])
                root.addChild(edge)
            }
        }

        for node in run.map {
            guard let position = positionsByNodeId[node.id] else { continue }
            let isCurrent = (run.currentNodeId == node.id)
            let entity = makeNodeEntity(node: node, isCurrent: isCurrent)
            entity.position = position
            root.addChild(entity)
        }
    }

    private func makeEdgeEntity(from: SIMD3<Float>, to: SIMD3<Float>) -> ModelEntity {
        let direction = to - from
        let length = max(0.0001, simd_length(direction))
        let unit = direction / length

        let mesh = MeshResource.generateCylinder(height: length, radius: 0.004)
        let material = SimpleMaterial(color: .gray.withAlphaComponent(0.25), isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "edge"
        entity.position = (from + to) / 2
        entity.orientation = simd_quatf(from: [0, 1, 0], to: unit)
        return entity
    }

    private func makeNodeEntity(node: MapNode, isCurrent: Bool) -> ModelEntity {
        let (mesh, _, _) = nodeStyle(roomType: node.roomType)
        let entity = ModelEntity(mesh: mesh, materials: [])
        entity.name = "\(nodeNamePrefix)\(node.id)"
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.18, 0.18, 0.18])]))
        entity.components.set(InputTargetComponent())
        applyNodeAppearance(entity: entity, node: node, isCurrent: isCurrent)

        return entity
    }

    private func applyNodeAppearance(entity: ModelEntity, node: MapNode, isCurrent: Bool) {
        let (_, baseColor, metallic) = nodeStyle(roomType: node.roomType)

        let color: UIColor
        if node.isCompleted {
            color = .systemGray3
        } else if isCurrent {
            color = .systemYellow
        } else if node.isAccessible {
            color = baseColor
        } else {
            color = baseColor.withAlphaComponent(0.25)
        }

        entity.model?.materials = [SimpleMaterial(color: color, isMetallic: metallic)]

        let shouldShowHalo = node.isAccessible && !node.isCompleted
        let existingHalo = entity.children.first(where: { $0.name == "halo" })
        if shouldShowHalo {
            if existingHalo == nil {
                let halo = ModelEntity(
                    mesh: .generateCylinder(height: 0.004, radius: 0.085),
                    materials: [SimpleMaterial(color: .white.withAlphaComponent(0.2), isMetallic: false)]
                )
                halo.name = "halo"
                halo.position = [0, -0.06, 0]
                entity.addChild(halo)
            }
        } else {
            existingHalo?.removeFromParent()
        }
    }

    private func nodeStyle(roomType: RoomType) -> (mesh: MeshResource, color: UIColor, metallic: Bool) {
        switch roomType {
        case .start:
            return (.generateCylinder(height: 0.14, radius: 0.045), .systemMint, false)
        case .battle:
            return (.generateSphere(radius: 0.055), .systemBlue, true)
        case .elite:
            return (.generateBox(size: 0.11), .systemOrange, true)
        case .rest:
            return (.generateCylinder(height: 0.12, radius: 0.05), .systemGreen, false)
        case .shop:
            return (.generateCone(height: 0.14, radius: 0.07), .systemTeal, false)
        case .event:
            return (.generateSphere(radius: 0.055), .systemPurple, false)
        case .boss:
            return (.generateBox(size: 0.14), .systemRed, true)
        }
    }
}

private struct RoomPanel: View {
    let route: RunSession.Route
    let onCompleteRoom: () -> Void
    let onNewRun: () -> Void
    let onClose: () -> Void

    var body: some View {
        Group {
            switch route {
            case .map:
                EmptyView()

            case .room(let nodeId, let roomType):
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(roomType.icon) \(roomType.displayName(language: .zhHans))")
                        .font(.headline)

                    Text("Node: \(nodeId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Complete") {
                        onCompleteRoom()
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .battle:
                EmptyView()

            case .runOver(_, let won, let floor):
                VStack(alignment: .leading, spacing: 10) {
                    Text(won ? "🎉 Victory" : "💀 Defeat")
                        .font(.headline)

                    Text("Run ended at Act \(floor)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button("New Run") {
                            onNewRun()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Close") {
                            onClose()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension RunSession.Route {
    var isRoom: Bool {
        if case .room = self { return true }
        return false
    }
}
