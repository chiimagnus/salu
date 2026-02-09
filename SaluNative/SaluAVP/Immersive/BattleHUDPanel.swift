import SwiftUI
import GameCore

struct BattleHUDPanel: View {
    @Environment(RunSession.self) private var runSession
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    @State private var isLogExpanded: Bool = false
    @State private var turnBannerText: String?
    @State private var turnBannerToken: UUID = UUID()
    @State private var displayedEnergy: Int = 0
    @State private var displayedMaxEnergy: Int = 0
    @State private var energyPulse: Bool = false
    @State private var energyPulseToken: UUID = UUID()
    @State private var processedEventCount: Int = 0

    var body: some View {
        @Bindable var runSession = runSession

        let battleState = runSession.battleState
        let engine = runSession.battleEngine
        let events = engine?.events ?? []
        let eventCount = events.count

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Battle")
                    .font(.headline)

                Spacer(minLength: 0)

                Button(isLogExpanded ? "Hide" : "Log") {
                    isLogExpanded.toggle()
                }
                .font(.caption2)
                .buttonStyle(.bordered)
            }

            if let turnBannerText {
                Text(turnBannerText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.82))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let state = battleState {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Player HP \(state.player.currentHP)/\(state.player.maxHP)  Block \(state.player.block)")
                        .font(.caption)
                    let enemy = state.enemies.first
                    Text("Enemy: \(enemy.map { $0.name.resolved(for: .zhHans) } ?? "-")  HP \(enemy?.currentHP ?? 0)/\(enemy?.maxHP ?? 0)  Block \(enemy?.block ?? 0)")
                        .font(.caption)
                    HStack(spacing: 8) {
                        Text("Turn \(state.turn) · \(state.isPlayerTurn ? "Player" : "Enemy")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption2.weight(.bold))
                            Text("\(displayedEnergy)/\(displayedMaxEnergy)")
                                .font(.caption2.monospacedDigit().weight(.semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.yellow.opacity(0.20))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.yellow.opacity(0.36), lineWidth: 1)
                        )
                        .scaleEffect(energyPulse ? 1.12 : 1.0)
                        .animation(.spring(response: 0.24, dampingFraction: 0.68), value: energyPulse)
                    }
                    Text("Draw \(state.drawPile.count)  Discard \(state.discardPile.count)  Exhaust \(state.exhaustPile.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let pending = engine?.pendingInput {
                        Text("Pending: \(pendingLabel(pending))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No battle state.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let engine, case .foresight(let options, let fromCount) = engine.pendingInput {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Foresight \(fromCount) → pick 1")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(Array(options.prefix(6).enumerated()), id: \.offset) { index, card in
                        let def = CardRegistry.require(card.cardId)
                        Button {
                            runSession.submitForesightChoice(index: index)
                        } label: {
                            Text(def.name.resolved(for: .zhHans))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack(spacing: 10) {
                Button("End Turn") {
                    runSession.endTurn()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!(battleState?.isPlayerTurn ?? false) || (engine?.pendingInput != nil))

                Button("Exit") {
                    Task { @MainActor in
                        await dismissImmersiveSpace()
                        openWindow(id: AppModel.controlPanelWindowID)
                    }
                }
                .buttonStyle(.bordered)
            }

            if isLogExpanded, let events = engine?.events, !events.isEmpty {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(events.suffix(8).enumerated()), id: \.offset) { _, event in
                            Text(event.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 260)
        .onAppear {
            syncEnergyFromState(battleState)
            processNewEvents(events)
        }
        .onChange(of: eventCount) { _, _ in
            processNewEvents(engine?.events ?? [])
        }
        .onChange(of: battleState?.energy ?? 0) { _, _ in
            syncEnergyFromState(battleState, animate: true)
        }
        .onChange(of: battleState?.maxEnergy ?? 0) { _, _ in
            syncEnergyFromState(battleState)
        }
        .animation(.easeInOut(duration: 0.18), value: turnBannerText != nil)
    }

    private func pendingLabel(_ pending: BattlePendingInput) -> String {
        switch pending {
        case .foresight(_, let fromCount):
            return "Foresight(\(fromCount))"
        }
    }

    private func processNewEvents(_ events: [BattleEvent]) {
        if events.count < processedEventCount {
            processedEventCount = 0
        }
        guard processedEventCount < events.count else { return }

        for event in events[processedEventCount..<events.count] {
            switch event {
            case .turnStarted(let turn):
                showTurnBanner("Turn \(turn) Started")
            case .turnEnded(let turn):
                showTurnBanner("Turn \(turn) Ended")
            case .energyReset(let amount):
                syncEnergy(to: amount, maxEnergy: max(displayedMaxEnergy, amount), animate: true)
            default:
                continue
            }
        }
        processedEventCount = events.count
    }

    private func showTurnBanner(_ text: String) {
        let token = UUID()
        turnBannerToken = token
        withAnimation(.easeOut(duration: 0.16)) {
            turnBannerText = text
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 950_000_000)
            guard turnBannerToken == token else { return }
            withAnimation(.easeIn(duration: 0.18)) {
                turnBannerText = nil
            }
        }
    }

    private func syncEnergyFromState(_ state: BattleState?, animate: Bool = false) {
        guard let state else {
            syncEnergy(to: 0, maxEnergy: 0, animate: animate)
            return
        }
        syncEnergy(to: state.energy, maxEnergy: state.maxEnergy, animate: animate)
    }

    private func syncEnergy(to energy: Int, maxEnergy: Int, animate: Bool) {
        displayedMaxEnergy = maxEnergy
        if animate {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.68)) {
                displayedEnergy = energy
            }
            let token = UUID()
            energyPulseToken = token
            energyPulse = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 180_000_000)
                guard energyPulseToken == token else { return }
                energyPulse = false
            }
        } else {
            displayedEnergy = energy
            energyPulse = false
        }
    }
}
