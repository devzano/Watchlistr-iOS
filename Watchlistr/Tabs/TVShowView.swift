//
//  TVShowView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/21/23.
//

import SwiftUI

struct TVShowTabView: View {
    var body: some View {
        NavigationView {TVShowHomeView()}
            .tabItem {Label("TV Shows", systemImage: "tv")}
            .tag(0)
    }
}

struct TVShowTabView_Previews: PreviewProvider {
    static var previews: some View {
        TVShowTabView()
    }
}
