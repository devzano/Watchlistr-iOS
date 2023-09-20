//
//  TVShowThumbnailCarouselView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct TVShowThumbnailCarouselView: View {
    
    let name: String
    let tvShows: [TVShow]
    var thumbnailType : TVShowThumbnailType = .poster()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(name)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .foregroundColor(.blue)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(self.tvShows) { tvShow in
                        NavigationLink(destination: TVShowDetailView(tvShowID: tvShow.id, tvShowName: tvShow.name)){
                            TVShowThumbnailView(tvShow: tvShow, thumbnailType: thumbnailType)
                                .tvShowThumbnailViewFrame(thumbnailType: thumbnailType)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
}

fileprivate extension View {
    @ViewBuilder
    func tvShowThumbnailViewFrame(thumbnailType: TVShowThumbnailType) -> some View {
        switch thumbnailType {
        case .poster:
            self.frame(width: 204, height: 306)
        case .backdrop:
            self.aspectRatio(16/9, contentMode: .fit)
                .frame(height: 160)
        }
    }
}

struct TVShowPosterCarouselView_Previews: PreviewProvider {
    
    static let stubbedTVShows = TVShow.stubbedTVShows
    
    static var previews: some View {
        Group {
            TVShowThumbnailCarouselView(name: "Popular", tvShows: stubbedTVShows, thumbnailType: .poster(showName: true))
            TVShowThumbnailCarouselView(name: "Popular", tvShows: stubbedTVShows, thumbnailType: .backdrop)
        }
    }
}
