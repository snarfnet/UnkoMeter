import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-9404799280370656/3282368527"

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.backgroundColor = .clear
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
