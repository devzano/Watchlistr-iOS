//
//  WatchlistrApp.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI
import Firebase

struct DefaultTextColor: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.indigo)
    }
}

extension View {
    func defaultTextColor() -> some View {
        self.modifier(DefaultTextColor())
    }
}

@main
struct WatchlistrApp: App {
    @StateObject var vm = AuthViewModel()
    @StateObject var watchlistState = WatchlistState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = .systemIndigo
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environmentObject(watchlistState)
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
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            FirebaseApp.configure()
            return true
        }
    }
}
