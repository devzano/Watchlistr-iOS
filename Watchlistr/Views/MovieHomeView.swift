//
//  MovieListView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/18/23.
//

import SwiftUI

struct MovieHomeView: View {
    @State private var isSearching = false
    @ObservedObject var movieSearchState = MovieSearchState()
    @StateObject private var movieHomeState = MovieHomeState()

    var body: some View {
        VStack {
            if isSearching {
                MovieSearchView(movieSearchState: movieSearchState)
                    .transition(.move(edge: .top))
            } else {
                MovieListView(movieHomeState: movieHomeState)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isSearching {
                    SearchBarView(placeholder: "search movie(s)", text: $movieSearchState.query)
                        .animation(.default, value: isSearching)
                } else {
                    Text("Movies")
                        .font(.largeTitle.bold())
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isSearching.toggle()
                }) {
                    Image(systemName: isSearching ? "film" : "magnifyingglass")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct MovieListView: View {
    @ObservedObject var movieHomeState: MovieHomeState

    var body: some View {
        List {
            ForEach(movieHomeState.sections) { section in
                MovieThumbnailCarouselView(title: section.title, movies: section.movies, thumbnailType: section.thumbnailType)
            }
            .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowSeparator(.hidden)
        }
        .task { loadMovies(invalidateCache: false) }
        .refreshable { loadMovies(invalidateCache: true) }
        .overlay(DataFetchPhaseOverlayView(phase: movieHomeState.phase, retryAction: { loadMovies(invalidateCache: true)}))
        .listStyle(.plain)
    }

    private func loadMovies(invalidateCache: Bool) {
        Task { await movieHomeState.loadMoviesFromAllEndpoints(invalidateCache: invalidateCache) }
    }
}

struct MovieSearchView: View {
    @ObservedObject var movieSearchState: MovieSearchState

    var body: some View {
        List {
            ForEach(movieSearchState.movies) { movie in
                NavigationLink(destination: MovieDetailView(movieId: movie.id, movieTitle: movie.title)) {
                    MovieRowView(movie: movie).padding(.vertical, 8)
                }
            }
        }
        .overlay(overlayView)
        .onAppear { movieSearchState.startObserve() }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var overlayView: some View {
        switch movieSearchState.phase {
        case .empty:
            if movieSearchState.trimmedQuery.isEmpty {
                EmptyPlaceholderView(text: "", image: Image(systemName: "magnifyingglass"))
            } else {
                ProgressView()
            }
        case .success(let values) where values.isEmpty:
            EmptyPlaceholderView(text: "No Movie(s) Found", image: Image(systemName: "film"))
        case .failure(let error):
            RetryView(text: error.localizedDescription) {
                Task {
                    await movieSearchState.search(query: movieSearchState.query)
                }
            }
        default:
            EmptyView()
        }
    }
}

struct MovieRowView: View {
    let movie: Movie

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            MovieThumbnailView(movie: movie, thumbnailType: .poster(showTitle: false))
                .frame(width: 61, height: 92)
            VStack(alignment: .leading) {
                Text(movie.title)
                    .font(.headline)
                Text(movie.releaseText)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Text(movie.overview)
                    .font(.subheadline)
                    .lineLimit(3)
                Text(movie.ratingText)
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct MovieHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieHomeView()
        }
    }
}
