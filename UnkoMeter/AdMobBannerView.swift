import GoogleMobileAds
import SwiftUI
import UIKit

struct AdMobBannerView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-9404799280370656/3282368527"

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        context.coordinator.bannerView = bannerView
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let bannerView = context.coordinator.bannerView else { return }
        guard !context.coordinator.didLoad else { return }

        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow?
            .rootViewController

        guard let rootVC else { return }
        bannerView.rootViewController = rootVC
        bannerView.load(Request())
        context.coordinator.didLoad = true
    }

    final class Coordinator {
        var bannerView: BannerView?
        var didLoad = false
    }
}
