//
//  RemoteImageView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/21/23.
//

import SwiftUI

struct RemoteImage: View {
    let url: URL
    var placeholder: Image? = Image(systemName: "photo")
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure(_):
                placeholder?
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

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
