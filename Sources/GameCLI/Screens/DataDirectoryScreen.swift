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
            sourceText = "环境变量 \(DataDirectory.envKey)"
        case .platformDefault:
            sourceText = "平台默认目录"
        case .temporaryFallback:
            sourceText = "系统临时目录回退"
        }
        
        var lines: [String] = []
        lines.append("\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.cyan)  🗂️ 数据目录（存档/设置/日志落盘位置）\(Terminal.reset)")
        lines.append("\(Terminal.bold)\(Terminal.cyan)═══════════════════════════════════════════════\(Terminal.reset)")
        lines.append("")
        lines.append("\(Terminal.bold)📁 当前目录：\(Terminal.reset)\(Terminal.yellow)\(dir.path)\(Terminal.reset)")
        lines.append("\(Terminal.dim)   来源：\(sourceText)\(Terminal.reset)")
        if !env.isEmpty {
            lines.append("\(Terminal.dim)   \(DataDirectory.envKey)=\(env)\(Terminal.reset)")
        } else {
            lines.append("\(Terminal.dim)   \(DataDirectory.envKey) 未设置（使用默认规则）\(Terminal.reset)")
        }
        lines.append("")
        lines.append("\(Terminal.bold)📄 常见文件：\(Terminal.reset)")
        lines.append("  - run_save.json       （冒险存档）")
        lines.append("  - battle_history.json （战斗历史）")
        lines.append("  - settings.json       （设置）")
        lines.append("  - run_log.txt         （调试日志）")
        lines.append("")
        lines.append("\(Terminal.bold)💡 提示：\(Terminal.reset)\(Terminal.dim)可用环境变量隔离数据，例如：\(Terminal.reset)")
        lines.append("  \(Terminal.cyan)SALU_DATA_DIR=/tmp/salu-test swift run GameCLI --seed 1\(Terminal.reset)")
        lines.append("")
        
        for line in lines {
            print(line)
        }
        
        NavigationBar.render(items: [.back])
    }
}

