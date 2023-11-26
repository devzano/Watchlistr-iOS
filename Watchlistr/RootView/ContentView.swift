//
//  ContentView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @State private var selectedTab: Int = 1
    @State private var movieTabView = MovieTabView()
    @State private var profileTabView = ProfileTabView()
    @State private var tvShowTabView = TVShowTabView()
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var body: some View {
        Group {
            if auth.userSession != nil {
                VStack {
                    if selectedTab == 0 {
                        movieTabView
                    } else if selectedTab == 1 {
                        profileTabView
                    } else if selectedTab == 2 {
                        tvShowTabView
                    }
                    
                    TabBarView(selectedTab: $selectedTab).accentColor(secondaryTextColor)
                }
            } else {
                LoginView()
            }
        }.accentColor(secondaryTextColor)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
            .environmentObject(TabBarVisibilityManager())
    }
}

class TabBarVisibilityManager: ObservableObject {
    @Published var isTabBarHidden: Bool = false

    func hideTabBar() {
        isTabBarHidden = true
    }

    func showTabBar() {
        isTabBarHidden = false
    }
}
