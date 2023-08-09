//
//  ContentView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/17/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        UITabBar.appearance().backgroundColor = UIColor.clear
        UITabBar.appearance().unselectedItemTintColor = .systemBlue
    }
    
    var body: some View {
        TabView {
            HomeView(authViewModel: authViewModel)
                .tabItem {Label("Home", systemImage: "house")}
                .tag(0)
            
            MovieTabView()
                .tabItem {Label("Movies", systemImage: "film")}
                .tag(1)
                .disabled(!authViewModel.isLoggedIn)
            
            TVShowTabView()
                .tabItem {Label("TV Shows", systemImage: "tv")}
                .tag(2)
                .disabled(!authViewModel.isLoggedIn)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
