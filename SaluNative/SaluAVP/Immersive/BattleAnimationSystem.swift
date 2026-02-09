import RealityKit
import OSLog
import UIKit
import GameCore

@MainActor
final class BattleAnimationSystem {
    private enum Names {
        static let animationRoot = "battleAnimationRoot"
        static let floatingTextRoot = "battleFloatingTextRoot"
        static let cardPrefix = "card:"
        static let pilePrefix = "pile:"
        static let enemyPrefix = "enemy:"
        static let battleFloor = "battleFloor"
    }

    private struct HandCardSnapshot {
        let index: Int
        let transform: Transform
    }

    private var queue = BattleAnimationQueue()
    private let logger = Logger(subsystem: "com.chiimagnus.SaluAVP", category: "BattleAnimation")
    private var previousHandTransforms: [Int: Transform] = [:]
    private var previousEnemyTransforms: [String: Transform] = [:]

    func enqueue(events: [BattlePresentationEvent]) {
        queue.enqueue(events: events)
    }

    func beginRenderPass(
        in battleLayer: RealityKit.Entity,
        handRoot: RealityKit.Entity?,
        enemyRoot: RealityKit.Entity?
    ) {
        capturePreviousHandState(handRoot: handRoot, relativeTo: battleLayer)
        capturePreviousEnemyState(enemyRoot: enemyRoot, relativeTo: battleLayer)
    }

    func endRenderPass(
        in battleLayer: RealityKit.Entity,
        handRoot: RealityKit.Entity?,
        enemyRoot: RealityKit.Entity?,
        pilesRoot: RealityKit.Entity?
    ) {
        processQueuedJobs(
            in: battleLayer,
            handRoot: handRoot,
            enemyRoot: enemyRoot,
            pilesRoot: pilesRoot
        )
    }

    func clear(in battleLayer: RealityKit.Entity) {
        queue.clear()
        previousHandTransforms = [:]
        previousEnemyTransforms = [:]
        battleLayer.findEntity(named: Names.animationRoot)?.removeFromParent()
    }

    private func processQueuedJobs(
        in battleLayer: RealityKit.Entity,
        handRoot: RealityKit.Entity?,
        enemyRoot: RealityKit.Entity?,
        pilesRoot: RealityKit.Entity?
    ) {
        let jobs = queue.drainAll()
        guard !jobs.isEmpty else { return }

        var drawTargets = drawTargetQueue(from: handRoot, drawCount: jobs.filter { $0.kind == .draw }.count)

        for job in jobs {
            logger.info("[AnimationQueue] seq=\(job.sequence, privacy: .public) kind=\(job.kind.rawValue, privacy: .public) summary=\(job.summary, privacy: .public)")
            switch job.kind {
            case .draw:
                let target = drawTargets.isEmpty ? nil : drawTargets.removeFirst()
                playDrawAnimation(
                    job: job,
                    target: target,
                    in: battleLayer,
                    handRoot: handRoot,
                    pilesRoot: pilesRoot
                )
            case .play:
                playCardAnimation(
                    job: job,
                    in: battleLayer,
                    handRoot: handRoot,
                    pilesRoot: pilesRoot
                )
            case .hit:
                playDamageFeedback(job: job, in: battleLayer, enemyRoot: enemyRoot)
            case .block:
                playBlockFeedback(job: job, in: battleLayer, enemyRoot: enemyRoot)
            case .die:
                playDeathAnimation(job: job, in: battleLayer, enemyRoot: enemyRoot)
            case .turnStart:
                pulseBattleFloor(in: battleLayer, color: UIColor.systemTeal.withAlphaComponent(0.48))
            case .turnEnd:
                pulseBattleFloor(in: battleLayer, color: UIColor.systemOrange.withAlphaComponent(0.46))
            case .energyPulse:
                pulseHandRoot(handRoot, in: battleLayer)
            case .pileUpdate:
                continue
            }
        }
    }

    private func capturePreviousHandState(handRoot: RealityKit.Entity?, relativeTo battleLayer: RealityKit.Entity) {
        previousHandTransforms = [:]
        guard let handRoot else { return }
        for child in handRoot.children {
            guard let index = handIndex(from: child.name) else { continue }
            previousHandTransforms[index] = transform(of: child, relativeTo: battleLayer)
        }
    }

    private func capturePreviousEnemyState(enemyRoot: RealityKit.Entity?, relativeTo battleLayer: RealityKit.Entity) {
        previousEnemyTransforms = [:]
        guard let enemyRoot else { return }
        for child in enemyRoot.children {
            guard let enemyId = enemyId(from: child.name) else { continue }
            previousEnemyTransforms[enemyId] = transform(of: child, relativeTo: battleLayer)
        }
    }

    private func drawTargetQueue(from handRoot: RealityKit.Entity?, drawCount: Int) -> [HandCardSnapshot] {
        guard drawCount > 0, let handRoot else { return [] }
        let cards = handRoot.children.compactMap { child -> HandCardSnapshot? in
            guard let index = handIndex(from: child.name) else { return nil }
            return HandCardSnapshot(index: index, transform: child.transform)
        }
        guard !cards.isEmpty else { return [] }
        let sorted = cards.sorted { $0.index < $1.index }
        let suffixCount = min(drawCount, sorted.count)
        return Array(sorted.suffix(suffixCount))
    }

    private func playDrawAnimation(
        job: BattleAnimationQueue.AnimationJob,
        target: HandCardSnapshot?,
        in battleLayer: RealityKit.Entity,
        handRoot: RealityKit.Entity?,
        pilesRoot: RealityKit.Entity?
    ) {
        guard let target else { return }
        let animationRoot = ensureAnimationRoot(in: battleLayer)

        let targetEntityName = "\(Names.cardPrefix)\(target.index)"
        let targetEntity = handRoot?.findEntity(named: targetEntityName)
        let drawPile = pilesRoot?.findEntity(named: "\(Names.pilePrefix)draw")

        let tempCard: RealityKit.Entity
        if let targetEntity {
            tempCard = targetEntity.clone(recursive: true)
        } else if let fallback = makeFallbackCardEntity(cardId: job.cardId) {
            tempCard = fallback
        } else {
            return
        }

        tempCard.name = "drawAnim:\(job.sequence)"
        tempCard.components.remove(InputTargetComponent.self)
        tempCard.components.remove(CollisionComponent.self)

        animationRoot.addChild(tempCard)
        if let targetEntity {
            targetEntity.components.set(OpacityComponent(opacity: 0))
        }

        let startTransform: Transform
        if let drawPile {
            startTransform = transform(of: drawPile, relativeTo: battleLayer)
        } else {
            startTransform = target.transform
        }
        tempCard.transform = startTransform

        let endTransform = target.transform
        tempCard.move(to: endTransform, relativeTo: battleLayer, duration: 0.30, timingFunction: .easeInOut)

        Task { @MainActor [weak tempCard, weak targetEntity] in
            try? await Task.sleep(nanoseconds: 340_000_000)
            if let targetEntity {
                targetEntity.components.set(OpacityComponent(opacity: 1))
            }
            tempCard?.removeFromParent()
        }
    }

    private func playCardAnimation(
        job: BattleAnimationQueue.AnimationJob,
        in battleLayer: RealityKit.Entity,
        handRoot: RealityKit.Entity?,
        pilesRoot: RealityKit.Entity?
    ) {
        guard let context = job.playedCardContext else { return }

        let animationRoot = ensureAnimationRoot(in: battleLayer)
        let sourceEntity = handRoot?.findEntity(named: "\(Names.cardPrefix)\(context.sourceHandIndex)")
        let sourceTransform = previousHandTransforms[context.sourceHandIndex]
            ?? sourceEntity.map { transform(of: $0, relativeTo: battleLayer) }
        guard let sourceTransform else { return }

        let tempCard: RealityKit.Entity
        if let sourceEntity {
            tempCard = sourceEntity.clone(recursive: true)
            sourceEntity.components.set(OpacityComponent(opacity: 0))
        } else if let fallback = makeFallbackCardEntity(cardId: job.cardId) {
            tempCard = fallback
        } else {
            return
        }

        tempCard.name = "playAnim:\(job.sequence)"
        tempCard.components.remove(InputTargetComponent.self)
        tempCard.components.remove(CollisionComponent.self)
        tempCard.transform = sourceTransform
        animationRoot.addChild(tempCard)

        let pileEntity = pilesRoot?.findEntity(named: "\(Names.pilePrefix)\(context.destinationPile.rawValue)")
        let pileTransform = pileEntity.map { transform(of: $0, relativeTo: battleLayer) } ?? sourceTransform

        var endTransform = pileTransform
        endTransform.translation += [0, 0.05, 0]
        endTransform.scale = SIMD3<Float>(repeating: 0.58)
        endTransform.rotation = pileTransform.rotation * simd_quatf(angle: .pi * 0.75, axis: [0, 1, 0])

        tempCard.move(to: endTransform, relativeTo: battleLayer, duration: 0.25, timingFunction: .easeIn)

        Task { @MainActor [weak tempCard, weak sourceEntity] in
            try? await Task.sleep(nanoseconds: 280_000_000)
            if let sourceEntity {
                sourceEntity.components.set(OpacityComponent(opacity: 1))
            }
            tempCard?.removeFromParent()
        }
    }

    private func playDamageFeedback(
        job: BattleAnimationQueue.AnimationJob,
        in battleLayer: RealityKit.Entity,
        enemyRoot: RealityKit.Entity?
    ) {
        guard let target = enemyRoot?.children.first else { return }
        pulseEntity(target, relativeTo: battleLayer, amplitude: 1.10)

        if let amount = job.amount, amount > 0 {
            spawnFloatingText(
                text: "-\(amount)",
                style: .damage,
                near: target,
                in: battleLayer
            )
        }

        if let blocked = job.blocked, blocked > 0 {
            spawnFloatingText(
                text: "BLOCK \(blocked)",
                style: .block,
                near: target,
                in: battleLayer
            )
        }
    }

    private func playBlockFeedback(
        job: BattleAnimationQueue.AnimationJob,
        in battleLayer: RealityKit.Entity,
        enemyRoot: RealityKit.Entity?
    ) {
        guard let target = enemyRoot?.children.first else { return }
        pulseEntity(target, relativeTo: battleLayer, amplitude: 1.06)
        if let amount = job.amount, amount > 0 {
            spawnFloatingText(
                text: "+\(amount) BLOCK",
                style: .block,
                near: target,
                in: battleLayer
            )
        }
    }

    private func playDeathAnimation(
        job: BattleAnimationQueue.AnimationJob,
        in battleLayer: RealityKit.Entity,
        enemyRoot: RealityKit.Entity?
    ) {
        guard let entityId = job.entityId else { return }

        let entityName = "\(Names.enemyPrefix)\(entityId)"
        let targetEntity = enemyRoot?.findEntity(named: entityName)

        if let targetEntity {
            fadeOutAndRemove(targetEntity, relativeTo: battleLayer)
            return
        }

        guard let previous = previousEnemyTransforms[entityId] else { return }
        let ghost = ModelEntity(
            mesh: .generateSphere(radius: 0.14),
            materials: [SimpleMaterial(color: UIColor.systemRed.withAlphaComponent(0.72), isMetallic: true)]
        )
        ghost.name = "deathGhost:\(entityId)"
        ghost.transform = previous
        ensureAnimationRoot(in: battleLayer).addChild(ghost)
        fadeOutAndRemove(ghost, relativeTo: battleLayer)
    }

    private func fadeOutAndRemove(_ entity: RealityKit.Entity, relativeTo battleLayer: RealityKit.Entity) {
        let initial = transform(of: entity, relativeTo: battleLayer)
        var final = initial
        final.translation += [0, -0.04, 0]
        final.scale *= SIMD3<Float>(repeating: 0.72)
        entity.move(to: final, relativeTo: battleLayer, duration: 0.36, timingFunction: .easeIn)

        Task { @MainActor [weak entity] in
            let steps = 5
            for step in 1...steps {
                try? await Task.sleep(nanoseconds: 60_000_000)
                guard let entity else { return }
                let opacity = max(0, 1 - (Float(step) / Float(steps)))
                entity.components.set(OpacityComponent(opacity: opacity))
            }
            entity?.removeFromParent()
        }
    }

    private func pulseBattleFloor(in battleLayer: RealityKit.Entity, color: UIColor) {
        guard let floor = battleLayer.findEntity(named: Names.battleFloor) as? ModelEntity else { return }
        guard let originalMaterials = floor.model?.materials else { return }

        floor.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
        Task { @MainActor [weak floor] in
            try? await Task.sleep(nanoseconds: 160_000_000)
            floor?.model?.materials = originalMaterials
        }
    }

    private func pulseHandRoot(_ handRoot: RealityKit.Entity?, in battleLayer: RealityKit.Entity) {
        guard let handRoot else { return }
        let initial = transform(of: handRoot, relativeTo: battleLayer)
        var peak = initial
        peak.translation += [0, 0.008, 0]
        peak.scale *= SIMD3<Float>(repeating: 1.04)

        handRoot.move(to: peak, relativeTo: battleLayer, duration: 0.10, timingFunction: .easeInOut)
        Task { @MainActor [weak handRoot] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            handRoot?.move(to: initial, relativeTo: battleLayer, duration: 0.16, timingFunction: .easeInOut)
        }
    }

    private func pulseEntity(
        _ entity: RealityKit.Entity,
        relativeTo battleLayer: RealityKit.Entity,
        amplitude: Float
    ) {
        let initial = transform(of: entity, relativeTo: battleLayer)
        var peak = initial
        peak.scale *= SIMD3<Float>(repeating: amplitude)
        entity.move(to: peak, relativeTo: battleLayer, duration: 0.08, timingFunction: .easeOut)

        Task { @MainActor [weak entity] in
            try? await Task.sleep(nanoseconds: 90_000_000)
            entity?.move(to: initial, relativeTo: battleLayer, duration: 0.16, timingFunction: .easeInOut)
        }
    }

    private func spawnFloatingText(
        text: String,
        style: FloatingTextFactory.Style,
        near target: RealityKit.Entity,
        in battleLayer: RealityKit.Entity
    ) {
        guard let label = FloatingTextFactory.makeEntity(text: text, style: style) else { return }

        let animationRoot = ensureAnimationRoot(in: battleLayer)
        let textRoot = ensureFloatingTextRoot(in: animationRoot)
        textRoot.addChild(label)

        let targetTransform = transform(of: target, relativeTo: battleLayer)
        var start = targetTransform
        start.translation += [0, 0.18, 0]
        start.scale = SIMD3<Float>(repeating: 0.52)
        label.transform = start

        var end = start
        end.translation += [0, 0.07, 0]
        end.scale *= SIMD3<Float>(repeating: 1.08)
        label.move(to: end, relativeTo: battleLayer, duration: 0.42, timingFunction: .easeOut)

        Task { @MainActor [weak label] in
            try? await Task.sleep(nanoseconds: 520_000_000)
            label?.removeFromParent()
        }
    }

    private func ensureAnimationRoot(in battleLayer: RealityKit.Entity) -> RealityKit.Entity {
        if let existing = battleLayer.findEntity(named: Names.animationRoot) {
            return existing
        }
        let root = RealityKit.Entity()
        root.name = Names.animationRoot
        battleLayer.addChild(root)
        return root
    }

    private func ensureFloatingTextRoot(in animationRoot: RealityKit.Entity) -> RealityKit.Entity {
        if let existing = animationRoot.findEntity(named: Names.floatingTextRoot) {
            return existing
        }
        let root = RealityKit.Entity()
        root.name = Names.floatingTextRoot
        animationRoot.addChild(root)
        return root
    }

    private func makeFallbackCardEntity(cardId: CardID?) -> ModelEntity? {
        let color: UIColor
        if let cardId {
            let definition = CardRegistry.require(cardId)
            switch definition.type {
            case .attack:
                color = UIColor.systemRed.withAlphaComponent(0.88)
            case .skill:
                color = UIColor.systemBlue.withAlphaComponent(0.88)
            case .power:
                color = UIColor.systemPurple.withAlphaComponent(0.88)
            case .consumable:
                color = UIColor.systemGreen.withAlphaComponent(0.88)
            }
        } else {
            color = UIColor(white: 0.72, alpha: 0.88)
        }

        let entity = ModelEntity(
            mesh: .generateBox(size: [0.06, 0.002, 0.09]),
            materials: [SimpleMaterial(color: color, isMetallic: false)]
        )
        return entity
    }

    private func handIndex(from name: String) -> Int? {
        guard name.hasPrefix(Names.cardPrefix) else { return nil }
        return Int(name.dropFirst(Names.cardPrefix.count))
    }

    private func enemyId(from name: String) -> String? {
        guard name.hasPrefix(Names.enemyPrefix) else { return nil }
        return String(name.dropFirst(Names.enemyPrefix.count))
    }

    private func transform(of entity: RealityKit.Entity, relativeTo reference: RealityKit.Entity?) -> Transform {
        Transform(
            scale: entity.scale(relativeTo: reference),
            rotation: entity.orientation(relativeTo: reference),
            translation: entity.position(relativeTo: reference)
        )
    }
}
