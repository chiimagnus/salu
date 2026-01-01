import GameCore

/// 屏幕渲染器
/// 负责构建和渲染游戏界面
enum ScreenRenderer {
    
    // MARK: - 主屏幕渲染
    
    /// 渲染战斗主界面
    static func renderBattleScreen(engine: BattleEngine, seed: UInt64, events: [String], message: String?) {
        var lines: [String] = []
        
        // 顶部标题栏
        lines.append(contentsOf: buildHeader(turn: engine.state.turn, seed: seed))
        lines.append("")
        
        // 敌人区域
        lines.append(contentsOf: buildEnemyArea(engine.state.enemy))
        lines.append("")
        
        // 分隔线
        lines.append("\(Terminal.dim)─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─\(Terminal.reset)")
        lines.append("")
        
        // 玩家区域
        lines.append(contentsOf: buildPlayerArea(engine.state))
        lines.append("")
        
        // 手牌区域
        lines.append(contentsOf: buildHandArea(engine.state))
        lines.append("")
        
        // 牌堆信息
        lines.append("\(Terminal.dim)  📚 抽牌堆: \(engine.state.drawPile.count)张    🗑️ 弃牌堆: \(engine.state.discardPile.count)张\(Terminal.reset)")
        lines.append("")
        
        // 事件日志区域
        lines.append(contentsOf: buildEventLog(events))
        lines.append("")
        
        // 消息区域
        lines.append(message ?? "")
        lines.append("")
        
        // 操作提示
        lines.append(contentsOf: buildInputPrompt(handCount: engine.state.hand.count))
        
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
    
    private static func buildEnemyArea(_ enemy: Entity) -> [String] {
        var lines: [String] = []
        
        let hpPercent = Double(enemy.currentHP) / Double(enemy.maxHP)
        let hpBar = Terminal.healthBar(percent: hpPercent)
        let hpColor = Terminal.colorForPercent(hpPercent)
        
        lines.append("  \(Terminal.bold)\(Terminal.red)👹 \(enemy.name)\(Terminal.reset)")
        lines.append("     \(hpColor)\(hpBar)\(Terminal.reset) \(enemy.currentHP)/\(enemy.maxHP) HP")
        
        if enemy.block > 0 {
            lines.append("     \(Terminal.cyan)🛡️ \(enemy.block) 格挡\(Terminal.reset)")
        }
        
        // 显示状态效果
        let statusLine = buildStatusLine(entity: enemy)
        if !statusLine.isEmpty {
            lines.append("     \(statusLine)")
        }
        
        lines.append("     \(Terminal.yellow)📢 意图: 攻击 7 伤害\(Terminal.reset)")
        
        return lines
    }
    
    private static func buildPlayerArea(_ state: BattleState) -> [String] {
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
        
        let energyDisplay = String(repeating: "◆", count: state.energy) + 
                           String(repeating: "◇", count: state.maxEnergy - state.energy)
        lines.append("     \(Terminal.yellow)⚡ \(energyDisplay) \(state.energy)/\(state.maxEnergy)\(Terminal.reset)")
        
        return lines
    }
    
    private static func buildHandArea(_ state: BattleState) -> [String] {
        var lines: [String] = []
        
        lines.append("  \(Terminal.bold)🃏 手牌 (\(state.hand.count)张)\(Terminal.reset)")
        
        for (index, card) in state.hand.enumerated() {
            let canPlay = card.cost <= state.energy
            let statusIcon = canPlay ? "\(Terminal.green)●\(Terminal.reset)" : "\(Terminal.red)○\(Terminal.reset)"
            let cardColor = canPlay ? Terminal.bold : Terminal.dim
            
            let effect: String
            let effectIcon: String
            switch card.kind {
            case .strike:
                effect = "造成 \(card.damage) 伤害"
                effectIcon = "⚔️"
            case .defend:
                effect = "获得 \(card.block) 格挡"
                effectIcon = "🛡️"
            }
            
            lines.append("     \(statusIcon) \(cardColor)[\(index + 1)] \(card.displayName)\(Terminal.reset)  \(Terminal.yellow)◆\(card.cost)\(Terminal.reset)  \(effectIcon) \(effect)")
        }
        
        return lines
    }
    
    private static func buildEventLog(_ events: [String], maxEvents: Int = 6) -> [String] {
        var lines: [String] = []
        
        lines.append("\(Terminal.bold)───────────── 事件日志 ─────────────\(Terminal.reset)")
        
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
    
    private static func buildInputPrompt(handCount: Int) -> [String] {
        return [
            "\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)",
            "\(Terminal.yellow)⌨️ 操作:\(Terminal.reset) \(Terminal.cyan)[1-\(handCount)]\(Terminal.reset) 出牌  \(Terminal.cyan)[0]\(Terminal.reset) 结束回合  \(Terminal.cyan)[h]\(Terminal.reset) 帮助  \(Terminal.cyan)[q]\(Terminal.reset) 退出",
            "\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)"
        ]
    }
    
    // MARK: - Status Effects
    
    /// 构建状态效果显示行
    private static func buildStatusLine(entity: Entity) -> String {
        var parts: [String] = []
        
        if entity.vulnerable > 0 {
            parts.append("\(Terminal.red)💔易伤\(entity.vulnerable)\(Terminal.reset)")
        }
        
        if entity.weak > 0 {
            parts.append("\(Terminal.yellow)😵虚弱\(entity.weak)\(Terminal.reset)")
        }
        
        if entity.strength > 0 {
            parts.append("\(Terminal.green)💪力量+\(entity.strength)\(Terminal.reset)")
        } else if entity.strength < 0 {
            parts.append("\(Terminal.dim)💪力量\(entity.strength)\(Terminal.reset)")
        }
        
        return parts.joined(separator: " ")
    }
}

