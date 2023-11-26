//
//  GoogleAd.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/26/23.
//

import Foundation
import SwiftUI
import UIKit
import GoogleMobileAds

// MARK: UIViewRepresentable wrapper for AdMob banner view
struct AdBannerView: View {
    let adUnitID: String
    @Binding var shouldShowAd: Bool

    var body: some View {
        GeometryReader { geometry in
            if shouldShowAd {
                GADBannerViewController(adUnitID: adUnitID, size: CGSize(width: geometry.size.width, height: 50), shouldShowAd: $shouldShowAd)
                    .frame(width: geometry.size.width, height: 50)
            }
        }
    }
}

struct GADBannerViewController: UIViewControllerRepresentable {
    let adUnitID: String
    let size: CGSize
    @Binding var shouldShowAd: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(size))
        bannerView.adUnitID = adUnitID
        let viewController = UIViewController()
        viewController.view.addSubview(bannerView)
        bannerView.delegate = context.coordinator
        bannerView.rootViewController = viewController
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let request = GADRequest()
        request.scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        bannerView.load(request)

        return viewController
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GADBannerViewDelegate {
        var parent: GADBannerViewController

        init(_ parent: GADBannerViewController) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Ad did receive")
            parent.shouldShowAd = true
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Ad failed: \(error.localizedDescription)")
            parent.shouldShowAd = false
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
