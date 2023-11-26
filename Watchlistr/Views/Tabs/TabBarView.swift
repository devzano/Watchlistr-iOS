//
//  TabBarView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/24/23.
//

import Foundation
import Combine
import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: Int
    @State private var shouldShowAd: Bool = true
    @State private var isKeyboardVisible = false
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var body: some View {
        let imageSize: CGFloat = 30
        
        if !isKeyboardVisible {
            VStack {
                if shouldShowAd {
                    AdBannerView(adUnitID: "ca-app-pub-7336849218717327/9064175686", shouldShowAd: $shouldShowAd) // AdBanner
                    //                    AdBannerView(adUnitID: "ca-app-pub-7336849218717327/4822326117", shouldShowAd: $shouldShowAd) // AdInterstitial
                    //                    AdBannerView(adUnitID: "ca-app-pub-3940256099942544/2435281174", shouldShowAd: $shouldShowAd) // Google Test Unit
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 10)
                        .shadow(radius: 5)
                }
                
                HStack {
                    Spacer()
                    Button(action: { self.selectedTab = 0 }) {
                        VStack {
                            Image(systemName: "film").font(.system(size: imageSize))
                        }
                    }
                    .padding()
                    .foregroundColor(selectedTab == 0 ? secondaryTextColor : primaryTextColor)
                    Spacer()
                    Button(action: { self.selectedTab = 1 }) {
                        VStack {
                            Image(systemName: "person.fill").font(.system(size: imageSize))
                        }
                    }
                    .padding()
                    .foregroundColor(selectedTab == 1 ? secondaryTextColor : primaryTextColor)
                    Spacer()
                    Button(action: { self.selectedTab = 2 }) {
                        VStack {
                            Image(systemName: "tv").font(.system(size: imageSize))
                        }
                    }
                    .padding()
                    .foregroundColor(selectedTab == 2 ? secondaryTextColor : primaryTextColor)
                    Spacer()
                }
                .frame(height: 30)
                .padding(.bottom, 0)
                .background(Color.clear)
            }.onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = true
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = false
                }
            }
        }
    }
}

#Preview {
    TabBarView(selectedTab: .constant(0))
        .environmentObject(WatchlistState())
        .environmentObject(AuthViewModel())
        .environmentObject(TabBarVisibilityManager())
}
