import SwiftUI
import RealityKit
import UIKit
import GameCore

struct ImmersiveRootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(RunSession.self) private var runSession
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    @State private var cardFaceTextureCache = CardFaceTextureCache()
    @State private var peekedHandIndex: Int? = nil
    @State private var peekedPile: PileKind? = nil
    @State private var didPeekInCurrentPress: Bool = false
    @State private var suppressNextTap: Bool = false

    private let nodeNamePrefix = "node:"
    private let cardNamePrefix = "card:"
    private let pileNamePrefix = "pile:"
    private let roomPanelAttachmentId = "roomPanel"
    private let battleHudAttachmentId = "battleHUD"
    private let mapHudAttachmentId = "mapHUD"
    private let cardRewardAttachmentId = "cardReward"
    private let pilePeekAttachmentId = "pilePeek"
    private let mapLayerPrefix = "mapLayer_floor_"
    private let uiLayerName = "uiLayer"
    private let battleLayerName = "battleLayer"
    private let hudAnchorName = "hudAnchor"
    private let battleHeadAnchorName = "battleHeadAnchor"
    private let battleHandRootName = "battleHandRoot"
    private let battleEnemyRootName = "battleEnemyRoot"
    private let battleInspectRootName = "battleInspectRoot"
    private let battlePilesRootName = "battlePilesRoot"

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
                    guard value.entity.name.hasPrefix(cardNamePrefix) else { return }
                    let suffix = value.entity.name.dropFirst(cardNamePrefix.count)
                    guard let handIndex = Int(suffix) else { return }
                    runSession.playCard(handIndex: handIndex)

                case .cardReward, .room, .runOver:
                    break
                }
            }

        // NOTE: In Simulator, click press duration can be ambiguous; keep this long enough so a normal click
        // still plays the card, while a deliberate hold triggers peek.
        let longPressPeekGesture = LongPressGesture(minimumDuration: 0.45, maximumDistance: 12)
            .targetedToAnyEntity()
            .onChanged { value in
                guard case .battle = runSession.route else { return }
                let name = value.entity.name

                if name.hasPrefix(cardNamePrefix) {
                    let suffix = name.dropFirst(cardNamePrefix.count)
                    guard let handIndex = Int(suffix) else { return }
                    didPeekInCurrentPress = true
                    peekedPile = nil
                    peekedHandIndex = handIndex
                    return
                }

                if name.hasPrefix(pileNamePrefix) {
                    let suffix = String(name.dropFirst(pileNamePrefix.count))
                    guard let kind = PileKind(rawValue: suffix) else { return }
                    didPeekInCurrentPress = true
                    peekedHandIndex = nil
                    peekedPile = kind
                }
            }
            .onEnded { _ in
                if didPeekInCurrentPress {
                    suppressNextTap = true
                }
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

            let isInBattle: Bool = {
                switch runSession.route {
                case .battle, .cardReward:
                    return true
                case .map, .room, .runOver:
                    return false
                }
            }()

            mapLayer.isEnabled = !isInBattle
            battleLayer.isEnabled = isInBattle

            switch runSession.route {
            case .battle:
                if let engine = runSession.battleEngine {
                    renderBattle(engine: engine, in: battleLayer)
                } else {
                    clearBattle(in: battleLayer)
                }

            case .cardReward:
                if let state = runSession.battleState {
                    renderBattleReward(state: state, in: battleLayer)
                } else {
                    clearBattle(in: battleLayer)
                }

            case .map, .room, .runOver:
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
                hud.isEnabled = !isInBattle

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
            view.highPriorityGesture(longPressPeekGesture)
        }
        .onChange(of: isBattleRoute) { newValue in
            if !newValue {
                suppressNextTap = false
                didPeekInCurrentPress = false
                peekedHandIndex = nil
                peekedPile = nil
            }
        }
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

        case .cardReward:
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
        if let headAnchor = battleLayer.findEntity(named: battleHeadAnchorName) {
            headAnchor.findEntity(named: battleHandRootName)?.children.forEach { $0.removeFromParent() }
            headAnchor.findEntity(named: battleInspectRootName)?.children.forEach { $0.removeFromParent() }
        }
        battleLayer.findEntity(named: battlePilesRootName)?.children.forEach { $0.removeFromParent() }
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

        let hand = engine.state.hand
        guard !hand.isEmpty else {
            clearPeek(in: headAnchor)
            return
        }

        let displayMode = appModel.cardDisplayMode
        let language: GameLanguage = .zhHans
        let playable = Set(engine.playableCardIndices)
        let signature = StableHash.fnv1a64(
            hand.map(\.cardId.rawValue).joined(separator: "|")
                + "#"
                + playable.sorted().map(String.init).joined(separator: ",")
                + "#"
                + displayMode.rawValue
                + "#"
                + language.rawValue
        )

        let needsHandRebuild = (handRoot.components[HandRenderStateComponent.self]?.signature != signature)
        if needsHandRebuild {
            handRoot.components.set(HandRenderStateComponent(signature: signature))
            handRoot.children.forEach { $0.removeFromParent() }

            let count = hand.count
            let center = Float(count - 1) / 2.0

            for (index, card) in hand.enumerated() {
                let isPlayable = playable.contains(index)
                let entity = makeCardEntity(card: card, isPlayable: isPlayable, displayMode: displayMode, language: language)
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

        renderPeek(handRoot: handRoot, in: headAnchor)
        renderPiles(state: engine.state, in: battleLayer)
    }

    private func renderPeek(handRoot: RealityKit.Entity, in headAnchor: RealityKit.Entity) {
        let inspectRoot = headAnchor.findEntity(named: battleInspectRootName) ?? {
            let root = RealityKit.Entity()
            root.name = battleInspectRootName
            root.position = [0, 0.02, -0.22]
            headAnchor.addChild(root)
            return root
        }()

        guard let peekedHandIndex else {
            inspectRoot.children.forEach { $0.removeFromParent() }
            return
        }

        let signature = StableHash.fnv1a64("peek#\(peekedHandIndex)")
        if let state = inspectRoot.components[PileRenderStateComponent.self], state.signature == signature, !inspectRoot.children.isEmpty {
            return
        }
        inspectRoot.components.set(PileRenderStateComponent(signature: signature))
        inspectRoot.children.forEach { $0.removeFromParent() }

        guard let cardEntity = handRoot.findEntity(named: "\(cardNamePrefix)\(peekedHandIndex)") else { return }
        let clone = cardEntity.clone(recursive: true)
        clone.components.remove(InputTargetComponent.self)
        clone.components.remove(CollisionComponent.self)
        clone.name = "peekCard"
        clone.position = .zero
        clone.scale = [3.2, 3.2, 3.2]
        clone.orientation = simd_quatf(angle: 0.35, axis: [1, 0, 0])
        inspectRoot.addChild(clone)
    }

    private func clearPeek(in headAnchor: RealityKit.Entity) {
        guard let inspectRoot = headAnchor.findEntity(named: battleInspectRootName) else { return }
        inspectRoot.children.forEach { $0.removeFromParent() }
    }

    private func renderPiles(state: BattleState, in battleLayer: RealityKit.Entity) {
        let pilesRoot = battleLayer.findEntity(named: battlePilesRootName) ?? {
            let root = RealityKit.Entity()
            root.name = battlePilesRootName
            // Keep piles fixed on the "table" (world space), not attached to the user's head.
            // Position is relative to battleLayer.
            root.position = [0, 0.045, -0.72]
            root.orientation = simd_quatf(angle: -0.55, axis: [1, 0, 0])
            battleLayer.addChild(root)
            return root
        }()

        let signature = StableHash.fnv1a64("piles#\(state.drawPile.count)#\(state.discardPile.count)#\(state.exhaustPile.count)")
        if let stateComponent = pilesRoot.components[PileRenderStateComponent.self], stateComponent.signature == signature {
            return
        }
        pilesRoot.components.set(PileRenderStateComponent(signature: signature))
        pilesRoot.children.forEach { $0.removeFromParent() }

        let draw = PileEntityFactory.makePileEntity(kind: .draw, count: state.drawPile.count)
        draw.position = [-0.22, 0, 0]
        pilesRoot.addChild(draw)

        let exhaust = PileEntityFactory.makePileEntity(kind: .exhaust, count: state.exhaustPile.count)
        exhaust.position = [0.0, 0, 0]
        pilesRoot.addChild(exhaust)

        let discard = PileEntityFactory.makePileEntity(kind: .discard, count: state.discardPile.count)
        discard.position = [0.22, 0, 0]
        pilesRoot.addChild(discard)
    }

    private func renderBattleReward(state: BattleState, in battleLayer: RealityKit.Entity) {
        let enemyRoot = battleLayer.findEntity(named: battleEnemyRootName) ?? {
            let root = RealityKit.Entity()
            root.name = battleEnemyRootName
            root.position = [0, 0.14, -1.0]
            battleLayer.addChild(root)
            return root
        }()

        enemyRoot.children.forEach { $0.removeFromParent() }
        if let enemy = state.enemies.first {
            let enemyEntity = makeEnemyEntity(enemy: enemy)
            enemyEntity.position = .zero
            enemyRoot.addChild(enemyEntity)
        }

        battleLayer.findEntity(named: battleHeadAnchorName)?
            .findEntity(named: battleHandRootName)?
            .children
            .forEach { $0.removeFromParent() }
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

    private func makeCardEntity(card: Card, isPlayable: Bool, displayMode: CardDisplayMode, language: GameLanguage) -> ModelEntity {
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

        if let texture = cardFaceTextureCache.texture(for: card.cardId, displayMode: displayMode, language: language) {
            let faceWidth: Float = 0.056
            let faceHeight: Float = 0.086
            let faceMesh = MeshResource.generatePlane(width: faceWidth, height: faceHeight)

            var faceMaterial = UnlitMaterial()
            faceMaterial.color = .init(tint: .white)
            faceMaterial.color.texture = .init(texture)

            let face = ModelEntity(mesh: faceMesh, materials: [faceMaterial])
            face.name = "cardFace"
            face.position = [0, 0.0012, 0]
            entity.addChild(face)
        }

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

            case .cardReward:
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

private extension RunSession.Route {
    var isRoom: Bool {
        if case .room = self { return true }
        return false
    }
}
