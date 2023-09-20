//
//  RemoteImageView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/21/23.
//

import SwiftUI

struct RemoteImage: View {
    let url: URL
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure(_):
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .empty:
                ActivityIndicatorView()
            @unknown default:
                EmptyView()
            }
        }
    }
}
