import SwiftUI

/// 主菜单视图
struct MainMenuView: View {
    @Environment(GameSession.self) private var session
    
    /// 是否显示种子输入弹窗
    @State private var showSeedInput = false
    
    /// 输入的种子字符串
    @State private var seedInput = ""
    
    var body: some View {
        VStack(spacing: 32) {
            // 标题
            titleSection
            
            // 菜单按钮
            menuButtons
            
            // 底部信息
            footerInfo
        }
        .padding(48)
        .frame(minWidth: 400, minHeight: 500)
        .alert("输入种子", isPresented: $showSeedInput) {
            TextField("留空使用随机种子", text: $seedInput)
            Button("开始") {
                startWithSeed()
            }
            Button("取消", role: .cancel) {
                seedInput = ""
            }
        } message: {
            Text("输入数字种子以复现特定冒险")
        }
    }
    
    // MARK: - 子视图
    
    private var titleSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
            
            Text("Salu")
                .font(.system(size: 48, weight: .bold))
            
            Text("the Fire")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var menuButtons: some View {
        VStack(spacing: 16) {
            // 新游戏按钮
            Button {
                session.startNewGame()
            } label: {
                menuButtonLabel("新游戏", icon: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            
            // 新游戏（指定种子）
            Button {
                showSeedInput = true
            } label: {
                menuButtonLabel("新游戏（指定种子）", icon: "number")
            }
            .buttonStyle(.bordered)
            
            // 继续游戏
            Button {
                session.continueGame()
            } label: {
                menuButtonLabel("继续游戏", icon: "arrow.right.circle.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!session.hasSavedRun)
            
            Divider()
                .padding(.vertical, 8)
            
            // 历史记录
            Button {
                session.navigateToHistory()
            } label: {
                menuButtonLabel("战斗历史", icon: "clock.fill")
            }
            .buttonStyle(.bordered)
            
            // 统计
            Button {
                session.navigateToStatistics()
            } label: {
                menuButtonLabel("统计数据", icon: "chart.bar.fill")
            }
            .buttonStyle(.bordered)
            
            // 设置
            Button {
                session.navigateToSettings()
            } label: {
                menuButtonLabel("设置", icon: "gear")
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var footerInfo: some View {
        VStack(spacing: 4) {
            Text("版本 0.1.0")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            #if DEBUG
            Text("DEBUG 模式")
                .font(.caption2)
                .foregroundStyle(.orange)
            #endif
        }
    }
    
    // MARK: - 辅助方法
    
    private func menuButtonLabel(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
        }
        .frame(width: 200)
    }
    
    private func startWithSeed() {
        if seedInput.isEmpty {
            session.startNewGame()
        } else if let seed = UInt64(seedInput) {
            session.startNewGame(seed: seed)
        } else {
            // 无效输入，使用随机种子
            session.startNewGame()
        }
        seedInput = ""
    }
}

#Preview {
    MainMenuView()
        .environment(GameSession())
}
