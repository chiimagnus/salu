//
//  ContentView.swift
//  SaluMacApp
//
//  Created by chii_magnus on 2026/1/14.
//

import SwiftUI
import GameCore

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller.fill")
                .imageScale(.large)
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            
            Text("Salu")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 验证 GameCore 导入成功
            Text("GameCore 已连接 ✓")
                .font(.headline)
                .foregroundStyle(.green)
            
            // 显示一张示例卡牌信息
            let strike = CardRegistry.require("strike")
            VStack(alignment: .leading, spacing: 4) {
                Text("示例卡牌: \(strike.name)")
                Text("费用: \(strike.cost) | 类型: \(strike.type.rawValue)")
                Text("效果: \(strike.rulesText)")
            }
            .font(.caption)
            .padding()
            .background(.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(32)
    }
}

#Preview {
    ContentView()
}
