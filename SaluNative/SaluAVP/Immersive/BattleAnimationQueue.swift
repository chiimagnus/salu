import GameCore

@MainActor
struct BattleAnimationQueue {
    enum AnimationKind: String, Sendable, Equatable {
        case draw
        case play
        case hit
        case block
        case die
        case pileUpdate
        case turnStart
        case turnEnd
        case energyPulse
    }

    struct AnimationJob: Sendable, Equatable {
        let sequence: Int
        let kind: AnimationKind
        let summary: String
        var cardId: CardID? = nil
        var playedCardContext: PlayedCardPresentationContext? = nil
        var amount: Int? = nil
        var blocked: Int? = nil
        var entityId: String? = nil
        var turn: Int? = nil
        var energy: Int? = nil
    }

    private var pendingJobs: [AnimationJob] = []

    mutating func enqueue(events: [BattlePresentationEvent]) {
        let mapped = events.flatMap(mapToJobs)
        let deduped = dedupeJobsInFrame(mapped)
        pendingJobs.append(contentsOf: deduped)
        pendingJobs.sort { $0.sequence < $1.sequence }
    }

    mutating func drainAll() -> [AnimationJob] {
        let jobs = pendingJobs
        pendingJobs.removeAll(keepingCapacity: true)
        return jobs
    }

    mutating func clear() {
        pendingJobs.removeAll(keepingCapacity: true)
    }

    private func mapToJobs(_ event: BattlePresentationEvent) -> [AnimationJob] {
        switch event.event {
        case .drew(let cardId):
            return [
                AnimationJob(
                    sequence: event.sequence,
                    kind: .draw,
                    summary: "drew:\(cardId.rawValue)",
                    cardId: cardId
                ),
                AnimationJob(sequence: event.sequence, kind: .pileUpdate, summary: "pileUpdate:draw")
            ]

        case .played(_, let cardId, _):
            return [
                AnimationJob(
                    sequence: event.sequence,
                    kind: .play,
                    summary: "played:\(cardId.rawValue)",
                    cardId: cardId,
                    playedCardContext: event.playedCardContext
                ),
                AnimationJob(sequence: event.sequence, kind: .pileUpdate, summary: "pileUpdate:play")
            ]

        case .damageDealt(_, _, let amount, let blocked):
            return [
                AnimationJob(
                    sequence: event.sequence,
                    kind: .hit,
                    summary: "damageDealt",
                    amount: amount,
                    blocked: blocked
                )
            ]

        case .blockGained(_, let amount):
            return [
                AnimationJob(
                    sequence: event.sequence,
                    kind: .block,
                    summary: "blockGained",
                    amount: amount
                )
            ]

        case .entityDied(let entityId, _):
            return [
                AnimationJob(
                    sequence: event.sequence,
                    kind: .die,
                    summary: "entityDied:\(entityId)",
                    entityId: entityId
                )
            ]

        case .turnStarted(let turn):
            return [
                AnimationJob(
                    sequence: event.sequence,
                    kind: .turnStart,
                    summary: "turnStarted:\(turn)",
                    turn: turn
                )
            ]

        case .turnEnded(let turn):
            return [
                AnimationJob(
                    sequence: event.sequence,
                    kind: .turnEnd,
                    summary: "turnEnded:\(turn)",
                    turn: turn
                )
            ]

        case .energyReset(let amount):
            return [
                AnimationJob(
                    sequence: event.sequence,
                    kind: .energyPulse,
                    summary: "energyReset:\(amount)",
                    energy: amount
                )
            ]

        case .shuffled:
            return [AnimationJob(sequence: event.sequence, kind: .pileUpdate, summary: "pileUpdate:shuffled")]

        case .handDiscarded:
            return [AnimationJob(sequence: event.sequence, kind: .pileUpdate, summary: "pileUpdate:discard")]

        default:
            return []
        }
    }

    private func dedupeJobsInFrame(_ jobs: [AnimationJob]) -> [AnimationJob] {
        var merged: [AnimationJob] = []
        var pileUpdateFrames = Set<Int>()

        for job in jobs {
            if job.kind == .pileUpdate {
                guard pileUpdateFrames.insert(job.sequence).inserted else { continue }
            }
            merged.append(job)
        }

        return merged
    }
}
