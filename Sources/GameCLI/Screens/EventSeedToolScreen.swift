import Foundation
import GameCore

/// 事件种子工具（开发者/验收辅助）
///
/// 用途：
/// - 给定（floor,row,nodeId）上下文，在一个 seed 范围内扫描，找出每个事件可复现的命中 seed。
/// - 主要用于“事件 UI 验收”与回归测试定位。
enum EventSeedToolScreen {
    static func show() {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🧭 \(L10n.text("事件种子工具（开发者）", "Event Seed Tool (Dev)"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(L10n.text("说明：", "Notes:"))
        - \(L10n.text("事件的出现由 seed + floor + row + nodeId 派生，保证可复现。", "Events are derived from seed + floor + row + nodeId for determinism."))
        - \(L10n.text("这个工具会在给定 seed 范围内，扫描并列出“每个事件”的可命中 seeds。", "This tool scans a seed range and lists matching seeds for each event."))
        
        \(L10n.text("默认上下文（匹配测试地图 SALU_TEST_MAP=event）：", "Default context (matches SALU_TEST_MAP=event):")
        - floor=1, row=1, nodeId=1_0
        
        \(L10n.text("直接回车使用默认值。", "Press Enter to use defaults."))
        """)
        
        // Defaults
        let defaultFloor = 1
        let defaultRow = 1
        let defaultNodeId = "1_0"
        let defaultRangeStart: UInt64 = 1
        let defaultRangeEnd: UInt64 = 2000
        let defaultPerEventLimit = 5
        
        let floor = readInt(prompt: L10n.text("楼层 floor", "Floor"), defaultValue: defaultFloor)
        let row = readInt(prompt: L10n.text("层内序号 row", "Row"), defaultValue: defaultRow)
        let nodeId = readString(prompt: L10n.text("节点 ID", "Node ID"), defaultValue: defaultNodeId)
        let rangeStart = readUInt64(prompt: L10n.text("seed 起始", "seed start"), defaultValue: defaultRangeStart)
        let rangeEnd = readUInt64(prompt: L10n.text("seed 结束", "seed end"), defaultValue: defaultRangeEnd)
        let perEventLimit = readInt(prompt: L10n.text("每个事件展示多少个 seed", "Seeds shown per event"), defaultValue: defaultPerEventLimit)
        
        let start = min(rangeStart, rangeEnd)
        let end = max(rangeStart, rangeEnd)
        let limit = max(1, perEventLimit)
        
        Terminal.clear()
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  🧭 \(L10n.text("事件种子工具（结果）", "Event Seed Tool (Results)"))\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(L10n.text("上下文", "Context"))：floor=\(floor)  row=\(row)  nodeId=\(nodeId)
        \(L10n.text("扫描范围", "Range"))：seed \(start) .. \(end)
        \(L10n.text("每个事件最多展示", "Max per event"))：\(limit) \(L10n.text("个", "entries"))
        """)
        
        let results = findSeeds(
            floor: floor,
            row: row,
            nodeId: nodeId,
            seedStart: start,
            seedEnd: end,
            perEventLimit: limit
        )
        
        // 输出
        for eventId in EventRegistry.allEventIds {
            let def = EventRegistry.require(eventId)
            let seeds = results[eventId] ?? []
            let seedText: String
            if seeds.isEmpty {
                seedText = "\(Terminal.dim)（\(L10n.text("未在范围内找到", "not found in range"))）\(Terminal.reset)"
            } else {
                seedText = seeds.map { String($0) }.joined(separator: ", ")
            }
            print("\n\(Terminal.bold)\(def.icon)\(L10n.resolve(def.name))\(Terminal.reset)  \(Terminal.dim)(\(eventId.rawValue))\(Terminal.reset)")
            print("  \(seedText)")
        }
        
        print("""
        
        \(Terminal.dim)\(L10n.text("验证示例", "Example"))：\(Terminal.reset)
          \(Terminal.cyan)SALU_TEST_MODE=1 SALU_TEST_MAP=event swift run GameCLI --seed <seed>\(Terminal.reset)
        """)
        
        NavigationBar.render(items: [.back])
    }
    
    // MARK: - Seed Scan
    
    private static func findSeeds(
        floor: Int,
        row: Int,
        nodeId: String,
        seedStart: UInt64,
        seedEnd: UInt64,
        perEventLimit: Int
    ) -> [EventID: [UInt64]] {
        let player = createDefaultPlayer()
        let deck = createStarterDeck()
        
        // 默认给一个起始遗物，避免 future 事件/定义以后依赖 relicIds 时出现差异
        let relicIds: [RelicID] = ["burning_blood"]
        
        var result: [EventID: [UInt64]] = [:]
        for id in EventRegistry.allEventIds {
            result[id] = []
        }
        
        // 早停：全部事件都已找到足够 seeds
        func isDone() -> Bool {
            result.values.allSatisfy { $0.count >= perEventLimit }
        }
        
        guard seedStart <= seedEnd else { return result }
        
        var seed = seedStart
        while seed <= seedEnd {
            if isDone() { break }
            
            let context = EventContext(
                seed: seed,
                floor: floor,
                currentRow: row,
                nodeId: nodeId,
                playerMaxHP: player.maxHP,
                playerCurrentHP: player.currentHP,
                gold: RunState.startingGold,
                deck: deck,
                relicIds: relicIds
            )
            
            let offer = EventGenerator.generate(context: context)
            if var arr = result[offer.eventId], arr.count < perEventLimit {
                arr.append(seed)
                result[offer.eventId] = arr
            }
            
            if seed == UInt64.max { break }
            seed += 1
        }
        
        return result
    }
    
    // MARK: - Input Helpers
    
    private static func readString(prompt: String, defaultValue: String) -> String {
        print("\(Terminal.yellow)\(prompt)\(Terminal.reset)（\(L10n.text("默认", "default"))：\(defaultValue)）> ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return defaultValue }
        return input.isEmpty ? defaultValue : input
    }
    
    private static func readInt(prompt: String, defaultValue: Int) -> Int {
        let text = readString(prompt: prompt, defaultValue: "\(defaultValue)")
        return Int(text) ?? defaultValue
    }
    
    private static func readUInt64(prompt: String, defaultValue: UInt64) -> UInt64 {
        let text = readString(prompt: prompt, defaultValue: "\(defaultValue)")
        return UInt64(text) ?? defaultValue
    }
}
