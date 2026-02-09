import RealityKit
import OSLog

@MainActor
final class BattleAnimationSystem {
    private var queue = BattleAnimationQueue()
    private let logger = Logger(subsystem: "com.chiimagnus.SaluAVP", category: "BattleAnimation")

    func enqueue(events: [BattlePresentationEvent]) {
        queue.enqueue(events: events)
    }

    func beginRenderPass(in battleLayer: RealityKit.Entity) {
        _ = battleLayer
        processQueuedJobs()
    }

    func endRenderPass(in battleLayer: RealityKit.Entity) {
        _ = battleLayer
    }

    func clear(in battleLayer: RealityKit.Entity) {
        _ = battleLayer
        queue.clear()
    }

    private func processQueuedJobs() {
        let jobs = queue.drainAll()
        guard !jobs.isEmpty else { return }

        for job in jobs {
            logger.info("[AnimationQueue] seq=\(job.sequence, privacy: .public) kind=\(job.kind.rawValue, privacy: .public) summary=\(job.summary, privacy: .public)")
        }
    }
}
