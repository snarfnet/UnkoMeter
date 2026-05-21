import SwiftUI
import UIKit
import GoogleMobileAds
import AppTrackingTransparency

@MainActor
final class AdMobStartup: ObservableObject {
    static let shared = AdMobStartup()
    @Published private(set) var isReady = false
    private var didRequest = false

    func requestTrackingAndStart() {
        guard !isReady, !didRequest else { return }
        didRequest = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if #available(iOS 14, *) {
                _ = await ATTrackingManager.requestTrackingAuthorization()
            }
            await MobileAds.shared.start()
            isReady = true
        }
    }
}

@main
struct UnkoMeterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
