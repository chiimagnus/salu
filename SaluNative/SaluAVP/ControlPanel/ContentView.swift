//
//  ContentView.swift
//  SaluAVP
//
//  Created by chii_magnus on 2026/1/29.
//

import SwiftUI
import RealityKit
import RealityKitContent
import GameCore

struct ContentView: View {

    @Environment(RunSession.self) private var runSession
    @State private var enlarge = false

    var body: some View {
        @Bindable var runSession = runSession

        RealityView { content in
            // Add the initial RealityKit content
            if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                content.add(scene)
            }
        } update: { content in
            // Update the RealityKit content when SwiftUI state changes
            if let scene = content.entities.first {
                let uniformScale: Float = enlarge ? 1.4 : 1.0
                scene.transform.scale = [uniformScale, uniformScale, uniformScale]
            }
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
            enlarge.toggle()
        })
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                VStack (spacing: 12) {
                    HStack(spacing: 8) {
                        TextField("Seed (UInt64)", text: $runSession.seedText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)

                        Button("New Run") {
                            runSession.startNewRun()
                        }
                        .fontWeight(.semibold)
                    }

                    if let error = runSession.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let run = runSession.runState {
                        Text("Run: Act \(run.floor)/\(run.maxFloor)  HP \(run.player.currentHP)/\(run.player.maxHP)  Nodes \(run.accessibleNodes.count)")
                            .font(.caption)
                    }

                    Button {
                        enlarge.toggle()
                    } label: {
                        Text(enlarge ? "Reduce RealityView Content" : "Enlarge RealityView Content")
                    }
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)

                    ToggleImmersiveSpaceButton()
                }
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(AppModel())
}
