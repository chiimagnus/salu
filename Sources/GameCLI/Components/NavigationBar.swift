/// 统一的导航栏组件
/// 用于在界面底部显示操作提示和输入提示符
enum NavigationBar {
    
    /// 导航项类型
    enum Item {
        case back           // 返回（q）
        case continueNext   // 继续（q）
        case backToMenu     // 返回主菜单（q）
        case backToGame     // 返回游戏（q）
        case custom(key: String, label: String)  // 自定义
    }
    
    /// 渲染导航栏并打印
    /// - Parameters:
    ///   - items: 导航项列表
    ///   - showPrompt: 是否显示输入提示符 `请选择 > `
    static func render(items: [Item], showPrompt: Bool = true) {
        var parts: [String] = []
        
        for item in items {
            switch item {
            case .back:
                parts.append("\(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("返回", "Back"))")
            case .continueNext:
                parts.append("\(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("继续", "Continue"))")
            case .backToMenu:
                parts.append("\(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("返回主菜单", "Back to Menu"))")
            case .backToGame:
                parts.append("\(Terminal.cyan)[q]\(Terminal.reset) \(L10n.text("返回游戏", "Back to Game"))")
            case .custom(let key, let label):
                parts.append("\(Terminal.cyan)[\(key)]\(Terminal.reset) \(label)")
            }
        }
        
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        print("\(Terminal.yellow)⌨️\(Terminal.reset) \(parts.joined(separator: "  "))")
        print("\(Terminal.bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Terminal.reset)")
        
        if showPrompt {
            print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
        }
        
        Terminal.flush()
    }
    
    /// 等待用户输入 q 返回
    /// - Parameters:
    ///   - allowEmpty: 是否允许空输入（Enter）也触发返回，默认 false
    /// - Returns: true 如果用户输入了有效返回键；false 如果 EOF
    @discardableResult
    static func waitForBack(allowEmpty: Bool = false) -> Bool {
        while true {
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                return false
            }
            
            if input == "q" {
                return true
            }
            
            // 允许空输入时，空行也可以返回
            if allowEmpty && input.isEmpty {
                return true
            }
            
            // 无效输入：向上移动光标、清除该行、重新打印提示符
            // \u{1B}[A = 光标上移一行
            // \r = 回到行首
            // \u{1B}[K = 清除从光标到行尾
            print("\u{1B}[A\r\u{1B}[K\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
            Terminal.flush()
        }
    }
}
