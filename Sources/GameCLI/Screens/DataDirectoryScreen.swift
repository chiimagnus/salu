import Foundation

/// 数据目录信息页面（开发者/排查用）
enum DataDirectoryScreen {
    static func show() {
        Terminal.clear()
        
        let (dir, source) = DataDirectory.resolved()
        let env = (ProcessInfo.processInfo.environment[DataDirectory.envKey] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let sourceText: String
        switch source {
        case .envOverride:
            sourceText = "\(L10n.text("环境变量", "Env var")) \(DataDirectory.envKey)"
        case .platformDefault:
            sourceText = L10n.text("平台默认目录", "Platform default directory")
        case .temporaryFallback:
            sourceText = L10n.text("系统临时目录回退", "System temp fallback")
        }
        
        var lines: [String] = []
        lines.append("\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.cyan)  🗂️ \(L10n.text("数据目录（存档/设置/日志落盘位置）", "Data Directory (saves/settings/logs)"))\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("")
        lines.append("\(Terminal.bold)📁 \(L10n.text("当前目录", "Current directory"))：\(Terminal.reset)\(Terminal.yellow)\(dir.path)\(Terminal.reset)")
        lines.append("\(Terminal.dim)   \(L10n.text("来源", "Source"))：\(sourceText)\(Terminal.reset)")
        if !env.isEmpty {
            lines.append("\(Terminal.dim)   \(DataDirectory.envKey)=\(env)\(Terminal.reset)")
        } else {
            lines.append("\(Terminal.dim)   \(DataDirectory.envKey) \(L10n.text("未设置（使用默认规则）", "not set (using default)"))\(Terminal.reset)")
        }
        lines.append("")
        lines.append("\(Terminal.bold)📄 \(L10n.text("常见文件", "Common files"))：\(Terminal.reset)")
        lines.append("  - run_save.json       (\(L10n.text("冒险存档", "run save")))")
        lines.append("  - battle_history.json (\(L10n.text("战斗历史", "battle history")))")
        lines.append("  - settings.json       (\(L10n.text("设置", "settings")))")
        lines.append("  - run_log.txt         (\(L10n.text("调试日志", "debug log")))")
        lines.append("")
        lines.append("\(Terminal.bold)💡 \(L10n.text("提示", "Tip"))：\(Terminal.reset)\(Terminal.dim)\(L10n.text("可用环境变量隔离数据，例如：", "Use an env var to isolate data, e.g.:"))\(Terminal.reset)")
        lines.append("  \(Terminal.cyan)SALU_DATA_DIR=/tmp/salu-test swift run GameCLI --seed 1\(Terminal.reset)")
        lines.append("")
        
        for line in lines {
            print(line)
        }
        
        NavigationBar.render(items: [.back])
    }
}
