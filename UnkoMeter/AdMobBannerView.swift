import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: View {
    @ObservedObject private var startup = AdMobStartup.shared

    var body: some View {
        GeometryReader { proxy in
            if startup.isReady, proxy.size.width > 0 {
                BannerAdContainer(
                    adUnitID: "ca-app-pub-9404799280370656/3282368527",
                    adSize: largeAnchoredAdaptiveBanner(width: proxy.size.width)
                )
            }
        }
        .frame(height: startup.isReady ? 60 : 0)
        .frame(maxWidth: .infinity)
        .task { startup.requestTrackingAndStart() }
    }
}

private struct BannerAdContainer: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.backgroundColor = .clear
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
