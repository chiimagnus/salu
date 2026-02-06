import SwiftUI

@main
struct SaluAVPApp: App {

    @State private var appModel = AppModel()
    @State private var runSession = RunSession()

    var body: some Scene {
        WindowGroup(id: AppModel.controlPanelWindowID) {
            ControlPanelView()
                .environment(appModel)
                .environment(runSession)
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveRootView()
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
