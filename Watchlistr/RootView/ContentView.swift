//
//  ContentView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    
    var body: some View {
        Group {
            if vm.userSession != nil {
                TabView {
                    MovieTabView()
                        .tabItem {Label("Movies", systemImage: "film")}
                        .tag(0)
                    
                    TVShowTabView()
                        .tabItem {Label("TV Shows", systemImage: "tv")}
                        .tag(1)
                    
                    ProfileTabView()
                        .tabItem{Label("Profile", systemImage: "person")}
                        .tag(2)
                }
            } else {
                LoginView()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
    }
}
