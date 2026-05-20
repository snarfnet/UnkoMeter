import SwiftUI
import UIKit
import GoogleMobileAds

enum DeviceCheck {
    static var isNativePhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var isAdSDKReady = false

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        DispatchQueue.main.async {
            MobileAds.shared.start { _ in
                AppDelegate.isAdSDKReady = true
            }
        }
        return true
    }
}

@main
struct UnkoMeterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
