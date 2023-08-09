//
//  MovieView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/21/23.
//

import SwiftUI

struct MovieTabView: View {
    var body: some View {
        NavigationView {MovieHomeView()}
            .tabItem {Label("Movies", systemImage: "film")}
            .tag(0)
    }
}

struct MovieTabView_Previews: PreviewProvider {
    static var previews: some View {
        MovieTabView()
    }
}
