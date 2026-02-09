import SwiftUI
import RealityKit
import UIKit
import GameCore

struct ImmersiveRootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(RunSession.self) private var runSession
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    @State private var battleSceneRenderer = BattleSceneRenderer()
    @State private var roomSceneRenderer = RoomSceneRenderer()
    @State private var peekedHandIndex: Int? = nil
    @State private var peekedPile: PileKind? = nil
    @State private var didPeekInCurrentPress: Bool = false
    @State private var suppressNextTap: Bool = false

    private let nodeNamePrefix = "node:"
    private let roomPanelAttachmentId = "roomPanel"
    private let battleHudAttachmentId = "battleHUD"
    private let mapHudAttachmentId = "mapHUD"
    private let cardRewardAttachmentId = "cardReward"
    private let pilePeekAttachmentId = "pilePeek"
    private let mapLayerPrefix = "mapLayer_floor_"
    private let uiLayerName = "uiLayer"
    private let hudAnchorName = "hudAnchor"

    var body: some View {
        let isBattleRoute: Bool = {
            if case .battle = runSession.route {
                return true
            }
            return false
        }()

        let tapGesture = SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                // Long-press peek uses `suppressNextTap` to avoid accidental plays. Only relevant in battle.
                if isBattleRoute, suppressNextTap {
                    suppressNextTap = false
                    return
                }
                switch runSession.route {
                case .map:
                    guard value.entity.name.hasPrefix(nodeNamePrefix) else { return }
                    let nodeId = String(value.entity.name.dropFirst(nodeNamePrefix.count))
                    runSession.selectAccessibleNode(nodeId)

                case .battle:
                    if value.entity.name.hasPrefix(BattleSceneRenderer.Names.enemyNamePrefix) {
                        let enemyId = String(
                            value.entity.name.dropFirst(BattleSceneRenderer.Names.enemyNamePrefix.count)
                        )
                        runSession.selectEnemyTarget(entityId: enemyId)
                        return
                    }
                    guard value.entity.name.hasPrefix(BattleSceneRenderer.Names.cardNamePrefix) else { return }
                    let suffix = value.entity.name.dropFirst(BattleSceneRenderer.Names.cardNamePrefix.count)
                    guard let handIndex = Int(suffix) else { return }
                    runSession.playCard(handIndex: handIndex)

                case .cardReward, .room, .runOver:
                    break
                }
            }

        // Simulator-friendly "peek": click-drag a card upward a bit to inspect; release to return.
        // This avoids the unreliable long-press recognition on Simulator, and doesn't interfere with tap-to-play.
        let dragPeekGesture = DragGesture(minimumDistance: 12)
            .targetedToAnyEntity()
            .onChanged { value in
                guard case .battle = runSession.route else { return }
                // Require a deliberate upward move to trigger peek.
                let translation = value.translation
                guard translation.height < -22 else { return }

                let name = value.entity.name
                if name.hasPrefix(BattleSceneRenderer.Names.cardNamePrefix) {
                    let suffix = name.dropFirst(BattleSceneRenderer.Names.cardNamePrefix.count)
                    guard let handIndex = Int(suffix) else { return }
                    didPeekInCurrentPress = true
                    peekedPile = nil
                    peekedHandIndex = handIndex
                    return
                }

                if name.hasPrefix(BattleSceneRenderer.Names.pileNamePrefix) {
                    let suffix = String(name.dropFirst(BattleSceneRenderer.Names.pileNamePrefix.count))
                    guard let kind = PileKind(rawValue: suffix) else { return }
                    didPeekInCurrentPress = true
                    peekedHandIndex = nil
                    peekedPile = kind
                }
            }
            .onEnded { _ in
                suppressNextTap = didPeekInCurrentPress
                didPeekInCurrentPress = false
                peekedHandIndex = nil
                peekedPile = nil
            }

        return RealityView { content, attachments in
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

            let roomLayer = roomSceneRenderer.makeRoomLayer()
            mapRoot.addChild(roomLayer)

            let battleLayer = battleSceneRenderer.makeBattleLayer()
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
                mapRoot.findEntity(named: RoomSceneRenderer.Names.roomLayer)?.isEnabled = false
                mapRoot.findEntity(named: BattleSceneRenderer.Names.battleLayer)?.isEnabled = false
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

            let battleLayer = mapRoot.findEntity(named: BattleSceneRenderer.Names.battleLayer) ?? {
                let battleLayer = battleSceneRenderer.makeBattleLayer()
                mapRoot.addChild(battleLayer)
                return battleLayer
            }()

            let roomLayer = mapRoot.findEntity(named: RoomSceneRenderer.Names.roomLayer) ?? {
                let roomLayer = roomSceneRenderer.makeRoomLayer()
                mapRoot.addChild(roomLayer)
                return roomLayer
            }()

            let isInBattle: Bool = {
                switch runSession.route {
                case .battle, .cardReward:
                    return true
                case .map, .room, .runOver:
                    return false
                }
            }()

            let isInRoom: Bool = {
                if case .room = runSession.route {
                    return true
                }
                return false
            }()

            mapLayer.isEnabled = !isInBattle && !isInRoom
            roomLayer.isEnabled = isInRoom
            battleLayer.isEnabled = isInBattle

            switch runSession.route {
            case .room(let nodeId, let roomType):
                roomSceneRenderer.render(nodeId: nodeId, roomType: roomType, in: roomLayer)
                battleSceneRenderer.clear(in: battleLayer)

            case .battle:
                roomSceneRenderer.clear(in: roomLayer)
                if let engine = runSession.battleEngine {
                    let newEvents = runSession.consumeNewBattlePresentationEvents()
                    battleSceneRenderer.render(
                        engine: engine,
                        in: battleLayer,
                        cardDisplayMode: appModel.cardDisplayMode,
                        language: .zhHans,
                        peekedHandIndex: peekedHandIndex,
                        selectedEnemyIndex: runSession.selectedEnemyIndex,
                        newEvents: newEvents
                    )
                } else {
                    battleSceneRenderer.clear(in: battleLayer)
                }

            case .cardReward:
                roomSceneRenderer.clear(in: roomLayer)
                if let state = runSession.battleState {
                    let newEvents = runSession.consumeNewBattlePresentationEvents()
                    battleSceneRenderer.renderReward(state: state, in: battleLayer, newEvents: newEvents)
                } else {
                    battleSceneRenderer.clear(in: battleLayer)
                }

            case .map, .runOver:
                roomSceneRenderer.clear(in: roomLayer)
                battleSceneRenderer.clear(in: battleLayer)
            }

            if let panel = attachments.entity(for: roomPanelAttachmentId) {
                panel.name = roomPanelAttachmentId
                panel.components.set(BillboardComponent())
                panel.components.set(InputTargetComponent())
                uiLayer.children.first(where: { $0.name == roomPanelAttachmentId })?.removeFromParent()
                roomLayer.children.first(where: { $0.name == roomPanelAttachmentId })?.removeFromParent()

                switch runSession.route {
                case .room(_, let roomType):
                    panel.isEnabled = true
                    panel.position = roomSceneRenderer.panelPosition(for: roomType)
                    roomLayer.addChild(panel)

                case .runOver:
                    panel.isEnabled = true
                    panel.position = [0, 0.25, -0.55]
                    uiLayer.addChild(panel)

                case .map, .battle, .cardReward:
                    panel.isEnabled = false
                }
            }

            if let hud = attachments.entity(for: battleHudAttachmentId) {
                hud.name = battleHudAttachmentId
                hud.components.set(BillboardComponent())
                hud.components.set(InputTargetComponent())
                if case .battle = runSession.route {
                    hud.isEnabled = true
                } else {
                    hud.isEnabled = false
                }

                hudAnchor.children.first(where: { $0.name == battleHudAttachmentId })?.removeFromParent()
                // Place HUD near the top-right in the user's view (avoid clipping on Simulator).
                hud.position = [0.18, 0.15, -0.50]
                hudAnchor.addChild(hud)
            }

            if let hud = attachments.entity(for: mapHudAttachmentId) {
                hud.name = mapHudAttachmentId
                hud.components.set(BillboardComponent())
                hud.components.set(InputTargetComponent())
                hud.isEnabled = !isInBattle && !isInRoom

                hudAnchor.children.first(where: { $0.name == mapHudAttachmentId })?.removeFromParent()
                hud.position = [0.18, 0.17, -0.50]
                hudAnchor.addChild(hud)
            }

            if let panel = attachments.entity(for: cardRewardAttachmentId) {
                panel.name = cardRewardAttachmentId
                panel.components.set(BillboardComponent())
                panel.components.set(InputTargetComponent())
                if case .cardReward = runSession.route {
                    panel.isEnabled = true
                } else {
                    panel.isEnabled = false
                }

                hudAnchor.children.first(where: { $0.name == cardRewardAttachmentId })?.removeFromParent()
                panel.position = [0, 0.02, -0.62]
                hudAnchor.addChild(panel)
            }

            if let panel = attachments.entity(for: pilePeekAttachmentId) {
                panel.name = pilePeekAttachmentId
                panel.components.set(BillboardComponent())
                panel.components.set(InputTargetComponent())

                let isVisible = (peekedPile != nil) && { if case .battle = runSession.route { return true } else { return false } }()
                panel.isEnabled = isVisible

                hudAnchor.children.first(where: { $0.name == pilePeekAttachmentId })?.removeFromParent()
                panel.position = [-0.18, 0.12, -0.50]
                hudAnchor.addChild(panel)
            }
        } attachments: {
            Attachment(id: roomPanelAttachmentId) {
                switch runSession.route {
                case .room(let nodeId, let roomType):
                    switch roomType {
                    case .rest:
                        RestRoomPanel(nodeId: nodeId)
                    case .shop:
                        ShopRoomPanel(nodeId: nodeId)
                    case .event:
                        EventRoomPanel(nodeId: nodeId)
                    default:
                        GenericRoomPanel(nodeId: nodeId, roomType: roomType) {
                            runSession.completeCurrentRoomAndReturnToMap()
                        }
                    }

                case .runOver(_, let won, let floor):
                    RunOverPanel(
                        won: won,
                        floor: floor,
                        onNewRun: { runSession.startNewRun() },
                        onClose: {
                            Task { @MainActor in
                                runSession.resetToControlPanel()
                                await dismissImmersiveSpace()
                                openWindow(id: AppModel.controlPanelWindowID)
                            }
                        }
                    )

                case .map, .battle, .cardReward:
                    EmptyView()
                }
            }

            Attachment(id: battleHudAttachmentId) {
                BattleHUDPanel()
            }

            Attachment(id: mapHudAttachmentId) {
                MapHUDPanel()
            }

            Attachment(id: cardRewardAttachmentId) {
                CardRewardAttachment()
            }

            Attachment(id: pilePeekAttachmentId) {
                PilePeekAttachment(activePile: peekedPile)
            }
        }
        .gesture(
            tapGesture
        )
        .applyIf(isBattleRoute) { view in
            view.highPriorityGesture(dragPeekGesture)
        }
        .onChange(of: isBattleRoute) { _, newValue in
            if !newValue {
                suppressNextTap = false
                didPeekInCurrentPress = false
                peekedHandIndex = nil
                peekedPile = nil
            }
        }
    }

    private func addFloor(to root: RealityKit.Entity) {
        let floor = RealityKit.Entity()
        floor.name = "floor"
        floor.components.set(CollisionComponent(shapes: [.generateBox(size: [2.8, 0.01, 4.2])]))
        floor.components.set(InputTargetComponent())
        root.addChild(floor)
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

private extension View {
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

private struct GenericRoomPanel: View {
    let nodeId: String
    let roomType: RoomType
    let onCompleteRoom: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(roomType.icon) \(roomType.displayName(language: .zhHans))")
                .font(.headline)

            Text("Node: \(nodeId)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("继续") {
                onCompleteRoom()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RunOverPanel: View {
    let won: Bool
    let floor: Int
    let onNewRun: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(won ? "Victory" : "Defeat")
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
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct CardRewardAttachment: View {
    @Environment(RunSession.self) private var runSession

    var body: some View {
        switch runSession.route {
        case .cardReward(let nodeId, let roomType, let offer, let goldEarned):
            CardRewardPanel(nodeId: nodeId, roomType: roomType, offer: offer, goldEarned: goldEarned)

        default:
            EmptyView()
        }
    }
}
