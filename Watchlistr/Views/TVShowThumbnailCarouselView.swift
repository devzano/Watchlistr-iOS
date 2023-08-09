//
//  TVShowThumbnailCarouselView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/21/23.
//

import SwiftUI

struct TVShowThumbnailCarouselView: View {
    
    let name: String
    let tvshows: [TVShow]
    var thumbnailType : TVShowThumbnailType = .poster()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(name)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(self.tvshows) { tvshow in
                        NavigationLink(destination: TVShowDetailView(tvshowId: tvshow.id, tvshowName: tvshow.name)){
                            TVShowThumbnailView(tvshow: tvshow, thumbnailType: thumbnailType)
                                .tvshowThumbnailViewFrame(thumbnailType: thumbnailType)
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
    func tvshowThumbnailViewFrame(thumbnailType: TVShowThumbnailType) -> some View {
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
            TVShowThumbnailCarouselView(name: "Popular", tvshows: stubbedTVShows, thumbnailType: .poster(showName: true))
            TVShowThumbnailCarouselView(name: "Popular", tvshows: stubbedTVShows, thumbnailType: .backdrop)
        }
    }
}
