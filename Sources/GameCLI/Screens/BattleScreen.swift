import GameCore

/// 战斗界面渲染器
/// 负责构建和渲染战斗主界面
enum BattleScreen {
    
    // MARK: - 主屏幕渲染
    
    /// 渲染战斗主界面
    static func renderBattleScreen(
        engine: BattleEngine,
        seed: UInt64,
        logs: [String],
        message: String?,
        showLog: Bool = false
    ) {
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
        lines.append(contentsOf: buildHandArea(engine: engine))
        lines.append("")
        
        // 牌堆信息
        lines.append(
            "\(Terminal.dim)  📚 \(L10n.text("抽牌堆", "Draw")): \(engine.state.drawPile.count)\(L10n.text("张", " cards"))    🗑️ \(L10n.text("弃牌堆", "Discard")): \(engine.state.discardPile.count)\(L10n.text("张", " cards"))    💨 \(L10n.text("消耗堆", "Exhaust")): \(engine.state.exhaustPile.count)\(L10n.text("张", " cards"))\(Terminal.reset)"
        )
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
        lines.append(contentsOf: buildInputPrompt(
            handCount: engine.state.hand.count,
            enemyCount: engine.state.enemies.count,
            showLog: showLog
        ))
        
        // 清屏并打印
        Terminal.clear()
        for line in lines {
            print(line)
        }
        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
        Terminal.flush()
    }
    
    // MARK: - 组件构建
    
    private static func buildHeader(turn: Int, seed: UInt64) -> [String] {
        let testModeTag = TestMode.isEnabled ? "  🧪\(L10n.text("测试模式", "Test Mode"))" : ""
        let turnText = L10n.text("第\(turn)回合", "Turn \(turn)")
        return [
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)  🔥 Salu the Fire   \(Terminal.dim)\(turnText)  🎲 \(seed)\(testModeTag)\(Terminal.reset)",
            "\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)"
        ]
    }
    
    private static func buildEnemiesArea(_ enemies: [Entity]) -> [String] {
        var lines: [String] = []
        
        guard !enemies.isEmpty else {
            lines.append("  \(Terminal.bold)\(Terminal.red)👹 \(L10n.text("敌人", "Enemies"))：\(L10n.text("无", "None"))\(Terminal.reset)")
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
        
        let deadText = enemy.isAlive ? "" : " \(Terminal.dim)(\(L10n.text("已死亡", "Dead")))\(Terminal.reset)"
        lines.append("  \(Terminal.bold)\(Terminal.red)👹 [\(index + 1)] \(L10n.resolve(enemy.name))\(Terminal.reset)\(deadText)")
        lines.append("     \(hpColor)\(hpBar)\(Terminal.reset) \(enemy.currentHP)/\(enemy.maxHP) HP")
        
        if enemy.block > 0 {
            lines.append("     \(Terminal.cyan)🛡️ \(enemy.block) \(L10n.text("格挡", "Block"))\(Terminal.reset)")
        }
        
        // 显示状态效果
        let statusLine = buildStatusLine(entity: enemy)
        if !statusLine.isEmpty {
            lines.append("     \(statusLine)")
        }
        
        // 显示敌人意图（P3: 从 Entity.plannedMove 读取）
        if let move = enemy.plannedMove {
            let intentIcon = move.intent.icon
            let intentText = L10n.resolve(move.intent.text)
            lines.append("     \(Terminal.yellow)📢 \(L10n.text("意图", "Intent")): \(intentIcon) \(intentText)\(Terminal.reset)")
        } else {
            lines.append("     \(Terminal.yellow)📢 \(L10n.text("意图", "Intent")): ❓ \(L10n.text("未知", "Unknown"))\(Terminal.reset)")
        }
        
        return lines
    }
    
    private static func buildPlayerArea(_ state: BattleState, relicIds: [RelicID]) -> [String] {
        var lines: [String] = []
        
        let hpPercent = Double(state.player.currentHP) / Double(state.player.maxHP)
        let hpBar = Terminal.healthBar(percent: hpPercent)
        let hpColor = Terminal.colorForPercent(hpPercent)
        
        lines.append("  \(Terminal.bold)\(Terminal.blue)🧑 \(L10n.resolve(state.player.name))\(Terminal.reset)")
        lines.append("     \(hpColor)\(hpBar)\(Terminal.reset) \(state.player.currentHP)/\(state.player.maxHP) HP")
        
        if state.player.block > 0 {
            lines.append("     \(Terminal.cyan)🛡️ \(state.player.block) \(L10n.text("格挡", "Block"))\(Terminal.reset)")
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
            lines.append("     \(Terminal.dim)🏺 \(L10n.text("遗物", "Relics"))：\(L10n.text("暂无", "None"))\(Terminal.reset)")
        } else {
            let relicText = relicIds.compactMap { relicId -> String? in
                guard let def = RelicRegistry.get(relicId) else { return nil }
                return "\(def.icon)\(L10n.resolve(def.name))"
            }.joined(separator: "  ")
            lines.append("     \(Terminal.dim)🏺 \(L10n.text("遗物", "Relics"))：\(Terminal.reset)\(relicText)")
        }

        return lines
    }
    
    private static func buildHandArea(engine: BattleEngine) -> [String] {
        var lines: [String] = []
        
        let state = engine.state
        lines.append("  \(Terminal.bold)🃏 \(L10n.text("手牌", "Hand")) (\(state.hand.count)\(L10n.text("张", " cards")))\(Terminal.reset)")
        
        for (index, card) in state.hand.enumerated() {
            let def = CardRegistry.require(card.cardId)
            let baseCost = def.cost
            let cost = engine.costToPlay(cardAtHandIndex: index)
            let canPlay = cost <= state.energy
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
            case .consumable:
                effectIcon = "🧪"
            }

            let costText = cost == baseCost
                ? "◆\(cost)"
                : "◆\(cost)\(L10n.text("（原", " (base "))\(baseCost)\(L10n.text("）", ")"))"
            
            lines.append(
                "     \(statusIcon) \(cardColor)[\(index + 1)] \(L10n.resolve(def.name))\(Terminal.reset)  \(Terminal.yellow)\(costText)\(Terminal.reset)  \(effectIcon) \(L10n.resolve(def.rulesText))"
            )
        }
        
        return lines
    }
    
    private static func buildEventLog(_ events: [String], maxEvents: Int = 6) -> [String] {
        var lines: [String] = []
        
        lines.append("\(Terminal.bold)───────────── \(L10n.text("日志", "Log")) ─────────────\(Terminal.reset)")
        
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
        let targetHint = enemyCount > 1
            ? "  \(Terminal.cyan)\(L10n.text("输入「卡牌 目标」", "Enter \"card target\""))\(Terminal.reset) \(L10n.text("选择目标", "to choose a target"))（\(L10n.text("目标", "targets")) 1-\(enemyCount)）"
            : "  \(Terminal.dim)（\(L10n.text("单敌人：可直接输入卡牌序号", "Single enemy: enter card number directly"))）\(Terminal.reset)"
        return [
            "\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)",
            "\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(handCount)]\(Terminal.reset) \(L10n.text("出牌", "Play"))  \(Terminal.cyan)[0]\(Terminal.reset) \(L10n.text("结束", "End"))  \(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("返回主菜单", "Back to Menu"))\(targetHint)",
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
            
            // P0 占卜家序列：疯狂状态根据阈值显示不同颜色
            let color: String
            if statusId == Madness.id {
                color = madnessColor(stacks: stacks)
            } else {
                color = def.isPositive ? Terminal.green : Terminal.red
            }
            
            let stackDisplay: String
            
            // 对于永久正面状态（不递减的 buff），显示带符号
            // 疯狂虽然不递减（由 BattleEngine 手动处理），但它是负面效果，不显示 + 号
            if case .none = def.decay, def.isPositive {
                stackDisplay = stacks >= 0 ? "+\(stacks)" : "\(stacks)"
            } else {
                stackDisplay = "\(stacks)"
            }
            
            parts.append("\(color)\(def.icon)\(L10n.resolve(def.name))\(stackDisplay)\(Terminal.reset)")
        }
        
        return parts.joined(separator: " ")
    }
    
    /// 根据疯狂层数返回颜色（阈值越高越危险）
    private static func madnessColor(stacks: Int) -> String {
        if stacks >= Madness.threshold3 {
            return Terminal.red + Terminal.bold  // ≥10：红色加粗（最危险）
        } else if stacks >= Madness.threshold2 {
            return Terminal.red  // ≥6：红色
        } else if stacks >= Madness.threshold1 {
            return Terminal.yellow  // ≥3：黄色（警告）
        } else {
            return Terminal.dim  // <3：暗淡（安全）
        }
    }
}
