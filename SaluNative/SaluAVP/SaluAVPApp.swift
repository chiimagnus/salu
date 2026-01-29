//
//  SaluAVPApp.swift
//  SaluAVP
//
//  Created by chii_magnus on 2026/1/29.
//

import SwiftUI

@main
struct SaluAVPApp: App {

    @State private var appModel = AppModel()
    @State private var runSession = RunSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(runSession)
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .environment(runSession)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
