import SwiftUI
import GoogleMobileAds

@main
struct UnkoMeterApp: App {
    init() {
        MobileAds.shared.start { _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
