//
//  WatchlistrApp.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI
import Firebase
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "9279d05aaca0f38b5740572b17ae0ace", //iPhone 15
            "6ee504ee7750aea70ad6ef10a5ec09e5", //iPhone 12
            "7d4ebd112238d3f9cdd89764347d8e48"  //iPad Air 2
        ]
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

@main
struct WatchlistrApp: App {
    @StateObject var auth = AuthViewModel()
    @StateObject var watchlistState = WatchlistState()
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var tabBarVisibilityManager = TabBarVisibilityManager()
    let deviceType = UIDevice().type

    init() {
        let loadedColor = ColorManager.shared.retrievePrimaryColor()
        _primaryTextColor = State(initialValue: loadedColor)
        let uiColor = UIColor(loadedColor)
        UITabBar.appearance().unselectedItemTintColor = uiColor
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("Running on: \(deviceType)")
                }
                .environmentObject(auth)
                .environmentObject(watchlistState)
                .environmentObject(tabBarVisibilityManager)
                .defaultTextColor(primaryTextColor)
                .onReceive(NotificationCenter.default.publisher(for: .userDidLogOut)) { _ in
                    watchlistState.reset()
                }
                .onReceive(NotificationCenter.default.publisher(for: .userDidLogIn)) { _ in
                    watchlistState.fetchWatchlist()
                }
        }
    }
}
