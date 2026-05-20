import GoogleMobileAds
import SwiftUI
import UIKit

struct AdMobBannerView: UIViewControllerRepresentable {
    private let adUnitID = "ca-app-pub-9404799280370656/3282368527"

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = controller
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        controller.view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
        ])

        bannerView.load(Request())
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
