import SwiftUI
import GameCore

/// 根视图 - 根据 AppRoute 切换不同界面
struct ContentView: View {
    @State private var session = GameSession()
    
    var body: some View {
        Group {
            switch session.route {
            case .mainMenu:
                MainMenuView()
                
            case .runMap:
                MapView()
                
            case .battle:
                // TODO: P5 - 战斗界面
                PlaceholderView(title: "战斗", icon: "bolt.fill")
                
            case .shop:
                // TODO: P7 - 商店界面
                PlaceholderView(title: "商店", icon: "cart.fill")
                
            case .event:
                // TODO: P6 - 事件界面
                PlaceholderView(title: "事件", icon: "questionmark.circle.fill")
                
            case .rest:
                // TODO: P4 - 休息点界面
                PlaceholderView(title: "休息点", icon: "bed.double.fill")
                
            case .cardReward:
                // TODO: P5 - 卡牌奖励界面
                PlaceholderView(title: "选择卡牌", icon: "rectangle.stack.fill")
                
            case .relicReward:
                // TODO: P5 - 遗物奖励界面
                PlaceholderView(title: "选择遗物", icon: "sparkles")
                
            case .runResult(let won):
                RunResultView(won: won)
                
            case .history:
                // TODO: P3 - 历史记录界面
                PlaceholderView(title: "战斗历史", icon: "clock.fill")
                
            case .statistics:
                // TODO: P3 - 统计界面
                PlaceholderView(title: "统计数据", icon: "chart.bar.fill")
                
            case .settings:
                SettingsView()
            }
        }
        .environment(session)
    }
}

// MARK: - 占位视图

/// 占位视图 - 用于尚未实现的界面
struct PlaceholderView: View {
    let title: String
    let icon: String
    
    @Environment(GameSession.self) private var session
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("功能开发中...")
                .foregroundStyle(.secondary)
            
            Button("返回地图") {
                session.route = .runMap
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - 冒险结果视图

/// 冒险结果视图
struct RunResultView: View {
    let won: Bool
    
    @Environment(GameSession.self) private var session
    
    var body: some View {
        VStack(spacing: 32) {
            // 图标
            Image(systemName: won ? "trophy.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(won ? .yellow : .red)
            
            // 标题
            Text(won ? "胜利！" : "失败")
                .font(.system(size: 48, weight: .bold))
            
            // 描述
            if won {
                Text("恭喜你完成了冒险！")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else {
                Text("你的冒险到此结束...")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            // 冒险信息
            if let run = session.runState {
                VStack(alignment: .leading, spacing: 8) {
                    Text("种子: \(run.seed)")
                    Text("层数: \(run.floor)/\(run.maxFloor)")
                    Text("金币: \(run.gold)")
                }
                .font(.body.monospaced())
                .padding()
                .background(.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 返回主菜单按钮
            Button("返回主菜单") {
                session.abandonRun()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(48)
    }
}

// MARK: - 设置视图

/// 设置视图
struct SettingsView: View {
    @Environment(GameSession.self) private var session
    
    var body: some View {
        VStack(spacing: 24) {
            Text("设置")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("设置功能开发中...")
                .foregroundStyle(.secondary)
            
            Button("返回") {
                session.navigateToMainMenu()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
