import SwiftUI
import AppTrackingTransparency

@main
struct UnkoMeterApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            ATTrackingManager.requestTrackingAuthorization { _ in }
                        }
                    }
                }
        }
    }
}
