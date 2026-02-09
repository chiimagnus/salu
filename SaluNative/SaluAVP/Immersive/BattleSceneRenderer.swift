import GameCore
import RealityKit
import UIKit

@MainActor
final class BattleSceneRenderer {
    enum Names {
        static let battleLayer = "battleLayer"
        static let battleHeadAnchor = "battleHeadAnchor"
        static let battleHandRoot = "battleHandRoot"
        static let battleEnemyRoot = "battleEnemyRoot"
        static let enemyNamePrefix = "enemy:"
        static let battleInspectRoot = "battleInspectRoot"
        static let battlePilesRoot = "battlePilesRoot"
        static let cardNamePrefix = "card:"
        static let pileNamePrefix = "pile:"
    }

    private var cardFaceTextureCache = CardFaceTextureCache()
    private let animationSystem: BattleAnimationSystem

    init(animationSystem: BattleAnimationSystem) {
        self.animationSystem = animationSystem
    }

    convenience init() {
        self.init(animationSystem: BattleAnimationSystem())
    }

    func makeBattleLayer() -> RealityKit.Entity {
        let battleLayer = RealityKit.Entity()
        battleLayer.name = Names.battleLayer
        battleLayer.isEnabled = false

        addBattleFloor(to: battleLayer)

        let enemyRoot = RealityKit.Entity()
        enemyRoot.name = Names.battleEnemyRoot
        enemyRoot.position = [0, 0.14, -1.0]
        battleLayer.addChild(enemyRoot)

        let headAnchor = AnchorEntity(.head)
        headAnchor.name = Names.battleHeadAnchor
        battleLayer.addChild(headAnchor)

        let handRoot = RealityKit.Entity()
        handRoot.name = Names.battleHandRoot
        handRoot.position = [0, -0.12, -0.35]
        headAnchor.addChild(handRoot)

        return battleLayer
    }

    func clear(in battleLayer: RealityKit.Entity) {
        battleLayer.findEntity(named: Names.battleEnemyRoot)?.children.forEach { $0.removeFromParent() }
        if let headAnchor = battleLayer.findEntity(named: Names.battleHeadAnchor) {
            headAnchor.findEntity(named: Names.battleHandRoot)?.children.forEach { $0.removeFromParent() }
            headAnchor.findEntity(named: Names.battleInspectRoot)?.children.forEach { $0.removeFromParent() }
        }
        battleLayer.findEntity(named: Names.battlePilesRoot)?.children.forEach { $0.removeFromParent() }
        animationSystem.clear(in: battleLayer)
    }

    func render(
        engine: BattleEngine,
        in battleLayer: RealityKit.Entity,
        cardDisplayMode: CardDisplayMode,
        language: GameLanguage,
        peekedHandIndex: Int?,
        selectedEnemyIndex: Int?,
        newEvents: [BattlePresentationEvent]
    ) {
        let enemyRoot = ensureEnemyRoot(in: battleLayer)
        let headAnchor = ensureHeadAnchor(in: battleLayer)
        let handRoot = ensureHandRoot(in: headAnchor)
        let pilesRoot = ensurePilesRoot(in: battleLayer)

        animationSystem.enqueue(events: newEvents)
        animationSystem.beginRenderPass(
            in: battleLayer,
            handRoot: handRoot,
            enemyRoot: enemyRoot
        )

        enemyRoot.children.forEach { $0.removeFromParent() }
        renderEnemies(enemies: engine.state.enemies, selectedEnemyIndex: selectedEnemyIndex, in: enemyRoot)

        let hand = engine.state.hand
        let playable = Set(engine.playableCardIndices)

        if hand.isEmpty {
            handRoot.children.forEach { $0.removeFromParent() }
            clearPeek(in: headAnchor)
            renderPiles(state: engine.state, in: pilesRoot)
            animationSystem.endRenderPass(
                in: battleLayer,
                handRoot: handRoot,
                enemyRoot: enemyRoot,
                pilesRoot: pilesRoot
            )
            return
        }

        let signature = StableHash.fnv1a64(
            hand.map(\.cardId.rawValue).joined(separator: "|")
                + "#"
                + playable.sorted().map(String.init).joined(separator: ",")
                + "#"
                + cardDisplayMode.rawValue
                + "#"
                + language.rawValue
        )

        let needsHandRebuild = (handRoot.components[HandRenderStateComponent.self]?.signature != signature)
        if needsHandRebuild {
            handRoot.components.set(HandRenderStateComponent(signature: signature))
            handRoot.children.forEach { $0.removeFromParent() }

            let center = Float(hand.count - 1) / 2.0
            for (index, card) in hand.enumerated() {
                let isPlayable = playable.contains(index)
                let entity = makeCardEntity(
                    card: card,
                    isPlayable: isPlayable,
                    displayMode: cardDisplayMode,
                    language: language
                )
                entity.name = "\(Names.cardNamePrefix)\(index)"

                let dx = Float(index) - center
                let x = dx * 0.07
                let z = abs(dx) * 0.02
                entity.position = [x, 0, z]

                let yaw = -dx * 0.22
                let pitch: Float = 0.18
                entity.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: pitch, axis: [1, 0, 0])

                handRoot.addChild(entity)
            }
        }

        renderPeek(handRoot: handRoot, in: headAnchor, peekedHandIndex: peekedHandIndex)
        renderPiles(state: engine.state, in: pilesRoot)
        animationSystem.endRenderPass(
            in: battleLayer,
            handRoot: handRoot,
            enemyRoot: enemyRoot,
            pilesRoot: pilesRoot
        )
    }

    func renderReward(
        state: BattleState,
        in battleLayer: RealityKit.Entity,
        newEvents: [BattlePresentationEvent]
    ) {
        let enemyRoot = ensureEnemyRoot(in: battleLayer)
        let pilesRoot = ensurePilesRoot(in: battleLayer)
        let handRoot = battleLayer
            .findEntity(named: Names.battleHeadAnchor)?
            .findEntity(named: Names.battleHandRoot)

        animationSystem.enqueue(events: newEvents)
        animationSystem.beginRenderPass(
            in: battleLayer,
            handRoot: handRoot,
            enemyRoot: enemyRoot
        )

        enemyRoot.children.forEach { $0.removeFromParent() }
        renderEnemies(enemies: state.enemies, selectedEnemyIndex: nil, in: enemyRoot)

        if let headAnchor = battleLayer.findEntity(named: Names.battleHeadAnchor) {
            headAnchor.findEntity(named: Names.battleHandRoot)?
                .children
                .forEach { $0.removeFromParent() }
            clearPeek(in: headAnchor)
        }

        renderPiles(state: state, in: pilesRoot)
        animationSystem.endRenderPass(
            in: battleLayer,
            handRoot: handRoot,
            enemyRoot: enemyRoot,
            pilesRoot: pilesRoot
        )
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

    private func ensureEnemyRoot(in battleLayer: RealityKit.Entity) -> RealityKit.Entity {
        if let root = battleLayer.findEntity(named: Names.battleEnemyRoot) {
            return root
        }

        let root = RealityKit.Entity()
        root.name = Names.battleEnemyRoot
        root.position = [0, 0.14, -1.0]
        battleLayer.addChild(root)
        return root
    }

    private func ensureHeadAnchor(in battleLayer: RealityKit.Entity) -> AnchorEntity {
        if let anchor = battleLayer.findEntity(named: Names.battleHeadAnchor) as? AnchorEntity {
            return anchor
        }

        let anchor = AnchorEntity(.head)
        anchor.name = Names.battleHeadAnchor
        battleLayer.addChild(anchor)
        return anchor
    }

    private func ensureHandRoot(in headAnchor: AnchorEntity) -> RealityKit.Entity {
        if let handRoot = headAnchor.findEntity(named: Names.battleHandRoot) {
            return handRoot
        }

        let handRoot = RealityKit.Entity()
        handRoot.name = Names.battleHandRoot
        handRoot.position = [0, -0.12, -0.35]
        headAnchor.addChild(handRoot)
        return handRoot
    }

    private func ensurePilesRoot(in battleLayer: RealityKit.Entity) -> RealityKit.Entity {
        if let pilesRoot = battleLayer.findEntity(named: Names.battlePilesRoot) {
            return pilesRoot
        }

        let pilesRoot = RealityKit.Entity()
        pilesRoot.name = Names.battlePilesRoot
        pilesRoot.position = [0, 0.045, -0.72]
        pilesRoot.orientation = simd_quatf(angle: -0.55, axis: [1, 0, 0])
        battleLayer.addChild(pilesRoot)
        return pilesRoot
    }

    private func renderPeek(
        handRoot: RealityKit.Entity,
        in headAnchor: AnchorEntity,
        peekedHandIndex: Int?
    ) {
        let inspectRoot = headAnchor.findEntity(named: Names.battleInspectRoot) ?? {
            let root = RealityKit.Entity()
            root.name = Names.battleInspectRoot
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

        guard let cardEntity = handRoot.findEntity(named: "\(Names.cardNamePrefix)\(peekedHandIndex)") else { return }
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
        guard let inspectRoot = headAnchor.findEntity(named: Names.battleInspectRoot) else { return }
        inspectRoot.children.forEach { $0.removeFromParent() }
    }

    private func renderPiles(state: BattleState, in pilesRoot: RealityKit.Entity) {
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

    private func renderEnemies(
        enemies: [GameCore.Entity],
        selectedEnemyIndex: Int?,
        in enemyRoot: RealityKit.Entity
    ) {
        let aliveEnemies = enemies.enumerated().filter { $0.element.isAlive }
        guard !aliveEnemies.isEmpty else { return }
        let count = aliveEnemies.count

        for (visibleIndex, pair) in aliveEnemies.enumerated() {
            let (stateIndex, enemy) = pair
            let isSelected = (selectedEnemyIndex == stateIndex)
            let enemyEntity = makeEnemyEntity(enemy: enemy, isSelected: isSelected)
            enemyEntity.position = enemyPosition(at: visibleIndex, total: count)
            enemyRoot.addChild(enemyEntity)
        }
    }

    private func enemyPosition(at index: Int, total: Int) -> SIMD3<Float> {
        switch total {
        case 1:
            return [0, 0, 0]
        case 2:
            return [
                index == 0 ? -0.22 : 0.22,
                0,
                0.03
            ]
        case 3:
            return [
                Float(index - 1) * 0.24,
                0,
                index == 1 ? 0 : 0.06
            ]
        default:
            let center = Float(total - 1) / 2.0
            let dx = Float(index) - center
            return [dx * 0.2, 0, abs(dx) * 0.05]
        }
    }

    private func makeEnemyEntity(enemy: GameCore.Entity, isSelected: Bool) -> ModelEntity {
        let baseColor = isSelected ? UIColor.systemYellow : UIColor.systemRed
        let material = SimpleMaterial(color: baseColor.withAlphaComponent(0.85), isMetallic: true)
        let mesh = MeshResource.generateSphere(radius: 0.14)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "\(Names.enemyNamePrefix)\(enemy.id)"
        if enemy.isAlive {
            entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.14)]))
            entity.components.set(InputTargetComponent())
        }

        if isSelected {
            let marker = ModelEntity(
                mesh: .generateCylinder(height: 0.008, radius: 0.19),
                materials: [SimpleMaterial(color: UIColor.systemYellow.withAlphaComponent(0.5), isMetallic: false)]
            )
            marker.name = "enemySelectionMarker"
            marker.position = [0, -0.145, 0]
            entity.addChild(marker)
        }
        return entity
    }

    private func makeCardEntity(
        card: Card,
        isPlayable: Bool,
        displayMode: CardDisplayMode,
        language: GameLanguage
    ) -> ModelEntity {
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
}
