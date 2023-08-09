//
//  TVShowThumbnailView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/21/23.
//

import SwiftUI

enum TVShowThumbnailType {
    case poster(showName: Bool = true)
    case backdrop
}

struct TVShowThumbnailView: View {
    
    let tvshow: TVShow
    var thumbnailType: TVShowThumbnailType = .poster()
    @StateObject var imageLoader = ImageLoader()
    
    var body: some View {
        containerView
        .onAppear {
            switch thumbnailType {
            case .poster:
                imageLoader.loadImage(with: tvshow.posterURL)
            case .backdrop:
                imageLoader.loadImage(with: tvshow.backdropURL)
            }
        }
    }
    
    @ViewBuilder
    private var containerView: some View {
        if case .backdrop = thumbnailType {
            VStack(alignment: .leading, spacing: 8) {
                imageView
                Text(tvshow.name)
                    .font(.headline)
                    .lineLimit(1)
            }
        } else {
            imageView
        }
    }
    
    private var imageView: some View {
        ZStack {
            Color.gray.opacity(0.3)
            
            if case .poster(let showName) = thumbnailType, showName {
                Text(tvshow.name)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineLimit(4)
            }
            
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .layoutPriority(-1)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
            }
        }
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

struct TVShowPosterCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TVShowThumbnailView(tvshow: TVShow.stubbedTVShow, thumbnailType: .poster(showName: true))
                .frame(width: 204, height: 306)
            
            TVShowThumbnailView(tvshow: TVShow.stubbedTVShow, thumbnailType: .backdrop)
                .aspectRatio(16/9, contentMode: .fit)
                .frame(height: 160)
        }
    }
}
