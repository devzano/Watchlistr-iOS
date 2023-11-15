//
//  MovieTabView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct MovieTabView: View {
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @StateObject var movieSearchState = MovieSearchState()
    @StateObject var movieHomeState = MovieHomeState()
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationView {
            mainContentView
//                .onAppear {
//                    tabBarVisibilityManager.showTabBar()
//                }
            .toolbar {
                ToolbarItem(placement: .principal) { principalToolbarView }
                ToolbarItem(placement: .navigationBarTrailing) { trailingToolbarButton }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if isSearching {
            MovieSearchView(movieSearchState: movieSearchState)
                .transition(.move(edge: .top))
        } else {
            MovieListView(movieHomeState: movieHomeState)
        }
    }
    
    @ViewBuilder
    private var principalToolbarView: some View {
        if isSearching {
            SearchBarView(placeholder: "search movie(s)", text: $movieSearchState.query)
                .focused($isSearchFieldFocused)
                .animation(.default, value: isSearching)
        } else {
            Text("Movies")
                .font(.largeTitle.bold())
        }
    }
    
    private var trailingToolbarButton: some View {
        Button(action: {
            isSearching.toggle()
            isSearchFieldFocused = true
        }) {
            Image(systemName: isSearching ? "film" : "magnifyingglass")
        }
    }
}

struct MovieListView: View {
    @ObservedObject var movieHomeState: MovieHomeState

    var body: some View {
        List {
            ForEach(movieHomeState.sections) { section in
                MovieThumbnailCarouselView(title: section.title, movies: section.movies, thumbnailType: section.thumbnailType)
            }
            .listRowInsets(.init(top: 5, leading: 0, bottom: 0, trailing: 0))
//            .listRowInsets(.init(top: 5, leading: 0, bottom: 25, trailing: 0))
            .listRowSeparator(.hidden)
        }
        .task {loadMovies(invalidateCache: false)}
        .refreshable {loadMovies(invalidateCache: true)}
        .overlay(DataFetchPhaseOverlayView(phase: movieHomeState.phase, retryAction: {loadMovies(invalidateCache: true)}))
        .listStyle(.plain)
    }

    private func loadMovies(invalidateCache: Bool) {
        Task { await movieHomeState.loadMoviesFromAllEndpoints(invalidateCache: invalidateCache) }
    }
}

struct MovieSearchView: View {
//    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @StateObject var movieSearchState = MovieSearchState()
    
    var body: some View {
        List {
            ForEach(movieSearchState.movies) { movie in
                NavigationLink(destination: MovieDetailView(movieID: movie.id, movieTitle: movie.title)) {
                    MovieRowView(movie: movie).padding(.vertical, 8)
                }
            }
        }
        .overlay(overlayView)
        .onAppear {
            movieSearchState.startObserve()
//            tabBarVisibilityManager.hideTabBar()
        }
//        .onDisappear {
//            tabBarVisibilityManager.showTabBar()
//        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var overlayView: some View {
        switch movieSearchState.phase {
        case .empty:
            if movieSearchState.trimmedQuery.isEmpty {
                EmptyPlaceholderView(text: "", image: Image(systemName: "magnifyingglass"))
            } else {
                ActivityIndicatorView()
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
    static let thumbnailSize: CGSize = CGSize(width: 61, height: 92)

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            MovieThumbnailView(movie: movie, thumbnailType: .poster(showTitle: false))
                .frame(width: Self.thumbnailSize.width, height: Self.thumbnailSize.height)
            movieDetails
        }
    }
    
    @ViewBuilder
    private var movieDetails: some View {
        VStack(alignment: .leading) {
            Text(movie.title)
                .font(.headline)
                .foregroundColor(.blue)
            if !movie.ratingText.isEmpty {
                ratingAndReleaseView
            }
            Text(movie.overview)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundColor(.indigo)
        }
    }
    
    private var ratingAndReleaseView: some View {
        HStack {
            if !movie.releaseText.isEmpty {
                Text(movie.releaseText)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 10).fill(Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(LinearGradient(gradient: Gradient(colors: [.blue, .indigo]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                    )
                    .shadow(radius: 3)
            }

            Spacer()

            Text(movie.ratingText)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LinearGradient(gradient: Gradient(colors: [.blue, .indigo]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                )
                .shadow(radius: 3)
        }
    }
}

struct MovieTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieTabView()
                .environmentObject(AuthViewModel())
                .environmentObject(WatchlistState())
                .environmentObject(TabBarVisibilityManager())
        }
    }
}
