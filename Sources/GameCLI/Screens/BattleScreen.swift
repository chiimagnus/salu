import GameCore

/// 战斗界面渲染器
/// 负责构建和渲染战斗主界面
enum BattleScreen {
    
    // MARK: - 主屏幕渲染
    
    /// 渲染战斗主界面
    static func renderBattleScreen(engine: BattleEngine, seed: UInt64, logs: [String], message: String?, showLog: Bool = false) {
        var lines: [String] = []
        
        // 顶部标题栏
        lines.append(contentsOf: buildHeader(turn: engine.state.turn, seed: seed))
        lines.append("")
        
        // 敌人区域
        lines.append(contentsOf: buildEnemiesArea(engine.state.enemies))
        lines.append("")
        
        // 分隔线
        lines.append("\(Terminal.dim)─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─\(Terminal.reset)")
        lines.append("")
        
        // 玩家区域
        lines.append(contentsOf: buildPlayerArea(engine.state, relicIds: engine.relicIds))
        lines.append("")
        
        // 手牌区域
        lines.append(contentsOf: buildHandArea(engine.state))
        lines.append("")
        
        // 牌堆信息
        lines.append("\(Terminal.dim)  📚 抽牌堆: \(engine.state.drawPile.count)张    🗑️ 弃牌堆: \(engine.state.discardPile.count)张\(Terminal.reset)")
        lines.append("")
        
        // 事件日志区域（可折叠）
        if showLog {
            lines.append(contentsOf: buildEventLog(logs))
            lines.append("")
        }
        
        // 消息区域
        lines.append(message ?? "")
        lines.append("")
        
        // 操作提示
        lines.append(contentsOf: buildInputPrompt(handCount: engine.state.hand.count, enemyCount: engine.state.enemies.count, showLog: showLog))
        
        // 清屏并打印
        Terminal.clear()
        for line in lines {
            print(line)
        }
        print("\(Terminal.green)>>>\(Terminal.reset) ", terminator: "")
        Terminal.flush()
    }
    
    // MARK: - 组件构建
    
    private static func buildHeader(turn: Int, seed: UInt64) -> [String] {
        return [
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)  ⚔️ SALU - 杀戮尖塔 CLI   \(Terminal.dim)第 \(turn) 回合  🎲 \(seed)\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)"
        ]
    }
    
    private static func buildEnemiesArea(_ enemies: [Entity]) -> [String] {
        var lines: [String] = []
        
        guard !enemies.isEmpty else {
            lines.append("  \(Terminal.bold)\(Terminal.red)👹 敌人：无\(Terminal.reset)")
            return lines
        }
        
        for (index, enemy) in enemies.enumerated() {
            lines.append(contentsOf: buildEnemyArea(enemy, index: index))
            if index != enemies.count - 1 {
                lines.append("")
            }
        }
        
        return lines
    }
    
    private static func buildEnemyArea(_ enemy: Entity, index: Int) -> [String] {
        var lines: [String] = []
        
        let hpPercent = Double(enemy.currentHP) / Double(enemy.maxHP)
        let hpBar = Terminal.healthBar(percent: hpPercent)
        let hpColor = Terminal.colorForPercent(hpPercent)
        
        let deadText = enemy.isAlive ? "" : " \(Terminal.dim)(已死亡)\(Terminal.reset)"
        lines.append("  \(Terminal.bold)\(Terminal.red)👹 [\(index + 1)] \(enemy.name)\(Terminal.reset)\(deadText)")
        lines.append("     \(hpColor)\(hpBar)\(Terminal.reset) \(enemy.currentHP)/\(enemy.maxHP) HP")
        
        if enemy.block > 0 {
            lines.append("     \(Terminal.cyan)🛡️ \(enemy.block) 格挡\(Terminal.reset)")
        }
        
        // 显示状态效果
        let statusLine = buildStatusLine(entity: enemy)
        if !statusLine.isEmpty {
            lines.append("     \(statusLine)")
        }
        
        // 显示敌人意图（P3: 从 Entity.plannedMove 读取）
        if let move = enemy.plannedMove {
            let intentIcon = move.intent.icon
            let intentText = move.intent.text
            lines.append("     \(Terminal.yellow)📢 意图: \(intentIcon) \(intentText)\(Terminal.reset)")
        } else {
            lines.append("     \(Terminal.yellow)📢 意图: ❓ 未知\(Terminal.reset)")
        }
        
        return lines
    }
    
    private static func buildPlayerArea(_ state: BattleState, relicIds: [RelicID]) -> [String] {
        var lines: [String] = []
        
        let hpPercent = Double(state.player.currentHP) / Double(state.player.maxHP)
        let hpBar = Terminal.healthBar(percent: hpPercent)
        let hpColor = Terminal.colorForPercent(hpPercent)
        
        lines.append("  \(Terminal.bold)\(Terminal.blue)🧑 \(state.player.name)\(Terminal.reset)")
        lines.append("     \(hpColor)\(hpBar)\(Terminal.reset) \(state.player.currentHP)/\(state.player.maxHP) HP")
        
        if state.player.block > 0 {
            lines.append("     \(Terminal.cyan)🛡️ \(state.player.block) 格挡\(Terminal.reset)")
        }
        
        // 显示状态效果
        let statusLine = buildStatusLine(entity: state.player)
        if !statusLine.isEmpty {
            lines.append("     \(statusLine)")
        }
        
        let filledEnergy = min(state.energy, state.maxEnergy)
        let emptyEnergy = max(state.maxEnergy - state.energy, 0)
        let energyDisplay = String(repeating: "◆", count: filledEnergy) +
                           String(repeating: "◇", count: emptyEnergy)
        lines.append("     \(Terminal.yellow)⚡ \(energyDisplay) \(state.energy)/\(state.maxEnergy)\(Terminal.reset)")

        // P4：遗物展示（至少 icon + 名称）
        if relicIds.isEmpty {
            lines.append("     \(Terminal.dim)🏺 遗物：暂无\(Terminal.reset)")
        } else {
            let relicText = relicIds.compactMap { relicId -> String? in
                guard let def = RelicRegistry.get(relicId) else { return nil }
                return "\(def.icon)\(def.name)"
            }.joined(separator: "  ")
            lines.append("     \(Terminal.dim)🏺 遗物：\(Terminal.reset)\(relicText)")
        }
        
        return lines
    }
    
    private static func buildHandArea(_ state: BattleState) -> [String] {
        var lines: [String] = []
        
        lines.append("  \(Terminal.bold)🃏 手牌 (\(state.hand.count)张)\(Terminal.reset)")
        
        for (index, card) in state.hand.enumerated() {
            let def = CardRegistry.require(card.cardId)
            let canPlay = def.cost <= state.energy
            let statusIcon = canPlay ? "\(Terminal.green)●\(Terminal.reset)" : "\(Terminal.red)○\(Terminal.reset)"
            let cardColor = canPlay ? Terminal.bold : Terminal.dim
            
            // 从 CardDefinition 获取类型图标
            let effectIcon: String
            switch def.type {
            case .attack:
                effectIcon = "⚔️"
            case .skill:
                effectIcon = "🛡️"
            case .power:
                effectIcon = "💪"
            }
            
            lines.append("     \(statusIcon) \(cardColor)[\(index + 1)] \(def.name)\(Terminal.reset)  \(Terminal.yellow)◆\(def.cost)\(Terminal.reset)  \(effectIcon) \(def.rulesText)")
        }
        
        return lines
    }
    
    private static func buildEventLog(_ events: [String], maxEvents: Int = 6) -> [String] {
        var lines: [String] = []
        
        lines.append("\(Terminal.bold)───────────── 日志 ─────────────\(Terminal.reset)")
        
        let displayEvents = events.suffix(maxEvents)
        for event in displayEvents {
            lines.append("  \(event)")
        }
        
        // 填充空行保持高度一致
        let padding = maxEvents - displayEvents.count
        for _ in 0..<padding {
            lines.append("")
        }
        
        lines.append("\(Terminal.bold)─────────────────────────────────────\(Terminal.reset)")
        
        return lines
    }
    
    private static func buildInputPrompt(handCount: Int, enemyCount: Int, showLog: Bool = false) -> [String] {
        let logHint = showLog 
            ? "\(Terminal.dim)[l] 隐藏日志\(Terminal.reset)" 
            : "\(Terminal.cyan)[l]\(Terminal.reset) 日志"
        let targetHint = enemyCount > 1
            ? "  \(Terminal.cyan)输入「卡牌 目标」\(Terminal.reset) 选择目标（目标 1-\(enemyCount)）"
            : "  \(Terminal.dim)（单敌人：可直接输入卡牌序号）\(Terminal.reset)"
        return [
            "\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)",
            "\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(handCount)]\(Terminal.reset) 出牌  \(Terminal.cyan)[0]\(Terminal.reset) 结束  \(Terminal.cyan)[h]\(Terminal.reset) 帮助  \(logHint)  \(Terminal.cyan)[q]\(Terminal.reset) 退出\(targetHint)",
            "\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)"
        ]
    }
    
    // MARK: - Status Effects
    
    /// 构建状态效果显示行
    private static func buildStatusLine(entity: Entity) -> String {
        var parts: [String] = []
        
        // P2: 使用 StatusRegistry 驱动状态显示
        for (statusId, stacks) in entity.statuses.all {
            guard let def = StatusRegistry.get(statusId) else { continue }
            
            let color = def.isPositive ? Terminal.green : Terminal.red
            let stackDisplay: String
            
            // 对于永久状态（不递减），显示带符号
            if case .none = def.decay {
                stackDisplay = stacks >= 0 ? "+\(stacks)" : "\(stacks)"
            } else {
                stackDisplay = "\(stacks)"
            }
            
            parts.append("\(color)\(def.icon)\(def.name)\(stackDisplay)\(Terminal.reset)")
        }
        
        return parts.joined(separator: " ")
    }
}
