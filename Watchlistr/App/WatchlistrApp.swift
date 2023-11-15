//
//  WatchlistrApp.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI
import Firebase

@main
struct WatchlistrApp: App {
    @StateObject var auth = AuthViewModel()
    @StateObject var watchlistState = WatchlistState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var tabBarVisibilityManager = TabBarVisibilityManager()
    let deviceType = UIDevice().type

    init() {
        UITabBar.appearance().unselectedItemTintColor = .systemIndigo
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
                .defaultTextColor()
                .onReceive(NotificationCenter.default.publisher(for: .userDidLogOut)) { _ in
                    watchlistState.reset()
                }
                .onReceive(NotificationCenter.default.publisher(for: .userDidLogIn)) { _ in
                    watchlistState.fetchWatchlist()
                }
        }
    }
}

extension WatchlistrApp {
    final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
        func application(_ application: UIApplication,
                         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            FirebaseApp.configure()
            
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            return true
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.banner, .sound])
        }
    }
}
