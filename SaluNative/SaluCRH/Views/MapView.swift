import SwiftUI
import GameCore

/// 地图视图 - 显示冒险地图和玩家状态
struct MapView: View {
    @Environment(GameSession.self) private var session
    
    private var language: GameLanguage { .zhHans }
    
    var body: some View {
        if let run = session.runState {
            HStack(spacing: 0) {
                // 左侧：玩家状态栏
                playerStatusBar(run: run)
                
                Divider()
                
                // 中间：地图
                mapContent(run: run)
                
                Divider()
                
                // 右侧：资源信息
                resourceBar(run: run)
            }
        } else {
            // 没有进行中的冒险
            VStack {
                Text("没有进行中的冒险")
                Button("返回主菜单") {
                    session.navigateToMainMenu()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - 玩家状态栏
    
    private func playerStatusBar(run: RunState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("玩家")
                .font(.headline)
            
            // HP
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("\(run.player.currentHP)/\(run.player.maxHP)")
            }
            
            // 金币
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.yellow)
                Text("\(run.gold)")
            }
            
            Divider()
            
            // 遗物
            Text("遗物")
                .font(.headline)
            
            if run.relicManager.all.isEmpty {
                Text("无")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(run.relicManager.all, id: \.rawValue) { relicId in
                    let def = RelicRegistry.require(relicId)
                    Text(def.name.resolved(for: language))
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // 放弃冒险按钮
            Button("放弃冒险", role: .destructive) {
                session.abandonRun()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 180)
    }
    
    // MARK: - 地图内容
    
    private func mapContent(run: RunState) -> some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("第 \(run.floor) 章")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("种子: \(run.seed)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            Divider()
            
            // 地图节点
            ScrollView {
                mapNodes(run: run)
            }
        }
        .frame(minWidth: 400)
    }
    
    private func mapNodes(run: RunState) -> some View {
        VStack(spacing: 8) {
            // 按层级分组显示节点
            let nodesByRow = Dictionary(grouping: run.map) { $0.row }
            let maxRow = nodesByRow.keys.max() ?? 0
            
            ForEach((0...maxRow).reversed(), id: \.self) { row in
                if let nodesInRow = nodesByRow[row] {
                    HStack(spacing: 16) {
                        ForEach(nodesInRow, id: \.id) { node in
                            nodeButton(node: node, run: run)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
    }
    
    private func nodeButton(node: MapNode, run: RunState) -> some View {
        let isAccessible = run.accessibleNodes.contains { $0.id == node.id }
        let isCurrent = run.currentNodeId == node.id
        let isCompleted = node.isCompleted
        
        return Button {
            if isAccessible {
                session.enterNode(node)
            }
        } label: {
            VStack(spacing: 4) {
                // 节点图标
                Image(systemName: nodeIcon(for: node.roomType))
                    .font(.title2)
                
                // 节点类型名称
                Text(nodeTypeName(for: node.roomType))
                    .font(.caption)
            }
            .frame(width: 60, height: 60)
            .background(nodeBackground(isAccessible: isAccessible, isCurrent: isCurrent, isCompleted: isCompleted))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAccessible)
        .opacity(isCompleted ? 0.5 : 1.0)
    }
    
    // MARK: - 资源栏
    
    private func resourceBar(run: RunState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("牌组")
                .font(.headline)
            
            Text("\(run.deck.count) 张")
                .font(.body)
            
            Divider()
            
            Text("消耗品")
                .font(.headline)

            let consumableCards = run.deck.filter { card in
                guard let def = CardRegistry.get(card.cardId) else { return false }
                return def.type == .consumable
            }

            if consumableCards.isEmpty {
                Text("无")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(consumableCards, id: \.id) { card in
                    let def = CardRegistry.require(card.cardId)
                    Text(def.name.resolved(for: language))
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 150)
    }
    
    // MARK: - 辅助方法
    
    private func nodeIcon(for type: RoomType) -> String {
        switch type {
        case .start: return "flag.fill"
        case .battle: return "person.fill"
        case .elite: return "person.2.fill"
        case .boss: return "crown.fill"
        case .rest: return "bed.double.fill"
        case .shop: return "cart.fill"
        case .event: return "questionmark.circle.fill"
        }
    }
    
    private func nodeTypeName(for type: RoomType) -> String {
        switch type {
        case .start: return "起点"
        case .battle: return "战斗"
        case .elite: return "精英"
        case .boss: return "Boss"
        case .rest: return "休息"
        case .shop: return "商店"
        case .event: return "事件"
        }
    }
    
    private func nodeBackground(isAccessible: Bool, isCurrent: Bool, isCompleted: Bool) -> Color {
        if isCompleted {
            return .gray.opacity(0.3)
        } else if isCurrent {
            return .blue.opacity(0.3)
        } else if isAccessible {
            return .green.opacity(0.3)
        } else {
            return .secondary.opacity(0.1)
        }
    }
}

#Preview {
    let session = GameSession()
    session.startNewGame(seed: 12345)
    return MapView()
        .environment(session)
}
