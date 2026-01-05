import GameCore

/// 事件界面（P5）
enum EventScreen {
    /// 展示事件并读取选择
    /// - Returns: 选择的选项索引（0-based）；nil 表示离开/跳过（由上层决定）
    static func chooseOption(offer: EventOffer) -> Int? {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  \(offer.icon) 事件：\(offer.name)\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(offer.description)
        
        \(Terminal.bold)请选择一个选项：\(Terminal.reset)
        """)
        
        for (index, option) in offer.options.enumerated() {
            let preview = option.preview.map { " \(Terminal.dim)(\($0))\(Terminal.reset)" } ?? ""
            print("  \(Terminal.cyan)[\(index + 1)]\(Terminal.reset) \(option.title)\(preview)")
        }
        
        print("")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)⌨️\(Terminal.reset) \(Terminal.cyan)[1-\(max(offer.options.count, 1))]\(Terminal.reset) 选择")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        
        while true {
            print("\(Terminal.green)>>>\(Terminal.reset) ", terminator: "")
            Terminal.flush()
            
            // EOF：默认不选择，避免测试/脚本卡死
            guard let raw = readLine() else {
                return nil
            }
            
            let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if input.isEmpty {
                continue
            }
            
            if let n = Int(input), n >= 1, n <= offer.options.count {
                return n - 1
            }
        }
    }
    
    static func showResult(title: String, lines: [String]) {
        Terminal.clear()
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)  ✅ 事件结算\(Terminal.reset)
        \(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)
        
        \(Terminal.bold)\(title)\(Terminal.reset)
        """)
        
        for line in lines {
            print("  \(line)")
        }
        
        print("")
        print("\(Terminal.dim)按 Enter 继续...\(Terminal.reset)")
        Terminal.flush()
    }
}


