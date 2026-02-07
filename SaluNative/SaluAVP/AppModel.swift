import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    static let controlPanelWindowID = "controlPanel"
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    var cardDisplayMode: CardDisplayMode = .modeC
}
