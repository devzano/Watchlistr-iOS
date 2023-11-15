//
//  MovieThumbnailCarouselView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct MovieThumbnailCarouselView: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let movies: [Movie]
    var thumbnailType: MovieThumbnailType = .poster()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .foregroundColor(.blue)
                .shadow(radius: 3)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(self.movies) { movie in
                        NavigationLink(destination: MovieDetailView(movieID: movie.id, movieTitle: movie.title)) {
                            MovieThumbnailView(movie: movie, thumbnailType: thumbnailType)
                                .movieThumbnailViewFrame(thumbnailType: thumbnailType)
                                .shadow(radius: 6)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }.background(LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? [Color.black.opacity(0.7), Color.gray.opacity(0.3)] : [Color.gray.opacity(0.3), Color.black.opacity(0.7)]), startPoint: .top, endPoint: .bottom)).cornerRadius(15)
    }
}

fileprivate extension View {
    @ViewBuilder
    func movieThumbnailViewFrame(thumbnailType: MovieThumbnailType) -> some View {
        switch thumbnailType {
        case .poster:
            self.frame(width: 204, height: 306)
        case .backdrop:
            self.aspectRatio(16/9, contentMode: .fit)
                .frame(height: 160)
        }
    }
}

struct MoviePosterCarouselView_Previews: PreviewProvider {
    static let stubbedMovies = Movie.stubbedMovies
    
    static var previews: some View {
        Group {
            MovieThumbnailCarouselView(title: "Popular", movies: stubbedMovies, thumbnailType: .poster(showTitle: true))
            MovieThumbnailCarouselView(title: "Popular", movies: stubbedMovies, thumbnailType: .backdrop)
        }
    }
}
