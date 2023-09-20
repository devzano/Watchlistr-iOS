//
//  MovieDetailView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct MovieDetailView: View {
    
    let movieID: Int
    let movieTitle: String
    @StateObject private var movieDetailState = MovieDetailState()
    @State private var selectedTrailerURL: URL?
    
    @EnvironmentObject var watchlistState: WatchlistState
    @State private var isAddedToWatchlist = false
    @StateObject private var movieWatchProviderState = MovieWatchProvidersState()
    
    var body: some View {
        List {
            if let movie = movieDetailState.movie {
                MovieDetailImage(imageURL: movie.backdropURL)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                if let providers = movieWatchProviderState.movieWatchProviders {
                    HStack {
                        WatchProvidersView(watchProviders: providers)
                            .listRowSeparator(.hidden)
                        Spacer()
                        if !movie.ratingText.isEmpty {
                            VStack(alignment: .center) {
                                Text("Rating")
                                    .font(.headline)
                                Text("\(movie.ratingText)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)   
                            }
                        }
                    }
                }
                MovieDetailListView(movie: movie, selectedTrailerURL: $selectedTrailerURL)
            }
        }
        .listStyle(.plain)
        .task {
            loadMovie()
        }
        .overlay(DataFetchPhaseOverlayView(
            phase: movieDetailState.phase,
            retryAction: loadMovie)
        )
        .sheet(item: $selectedTrailerURL) {SafariView(url: $0).edgesIgnoringSafeArea(.bottom)}
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(movieTitle)
                    .foregroundColor(.blue)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if isMovieInWatchlist {
                        removeFromWatchlist()
                    } else {
                        addMovieToWatchlist()
                    }
                }) {
                    if isMovieInWatchlist {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
    }

    private func loadMovie() {
        Task {
            await self.movieDetailState.loadMovie(id: self.movieID)
            await movieWatchProviderState.loadMovieWatchProviders(forMovie: movieID)
        }
    }
    
    private var isMovieInWatchlist: Bool {
        if let movie = movieDetailState.movie {
            return watchlistState.mWatchlist.contains { $0.id == movie.id }
        }
        return false
    }

    private func addMovieToWatchlist() {
        if !isMovieInWatchlist, let movie = movieDetailState.movie {
            watchlistState.addMovieToWatchlist(movie: movie)
            isAddedToWatchlist = true
        }
    }
    
    private func removeFromWatchlist() {
        if let movie = movieDetailState.movie,
           let existingMovieWatchlist = watchlistState.mWatchlist.first(where: { $0.id == movie.id }) {
            watchlistState.removeMovieFromWatchlist(movie: existingMovieWatchlist)
            isAddedToWatchlist = false
        }
    }
}

struct MovieDetailListView: View {
    
    let movie: Movie
    @Binding var selectedTrailerURL: URL?
    
    var body: some View {
        movieDescriptionSection.listRowSeparator(.visible)
        movieCastSection.listRowSeparator(.hidden)
        movieTrailerSection
    }
    
    private var movieDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(movieGenreYearDurationText)
                .font(.headline)
            Text(movie.overview)
                .foregroundColor(.blue)
        }
        .padding(.vertical)
    }
    
    private var movieGenreYearDurationText: String {
        "\(movie.genreText) · \(movie.releaseText) · \(movie.durationText)"
    }
    
    private var movieCastSection: some View {
        HStack(alignment: .top, spacing: 4) {
            if let cast = movie.cast, !cast.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starring:").font(.headline)
                    ForEach(cast.prefix(9)) { Text($0.name)
                        + Text(" as ") +
                        Text("'\($0.character)'")
                            .foregroundColor(.blue)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            
            if let crew = movie.crew, !crew.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if let directors = movie.directors, !directors.isEmpty {
                        Text("Director(s):").font(.headline)
                        ForEach(directors.prefix(2)) { Text($0.name)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let producers = movie.producers, !producers.isEmpty {
                        Text("Producer(s):").font(.headline)
                            .padding(.top)
                        ForEach(producers.prefix(2)) { Text($0.name)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let screenwriters = movie.screenWriters, !screenwriters.isEmpty {
                        Text("Screenwriter(s):").font(.headline)
                            .padding(.top)
                        ForEach(screenwriters.prefix(2)) { Text($0.name)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    private var movieTrailerSection: some View {
        if let trailers = movie.youtubeTrailers, !trailers.isEmpty {
            Text("Trailers").font(.headline)
            ForEach(trailers) { trailer in
                Button(action: {
                    guard let url = trailer.youtubeURL else { return }
                    selectedTrailerURL = url
                }) {
                    HStack {
                        Text(trailer.name)
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
            }
        }
    }
}

struct MovieDetailImage: View {
    
    @StateObject private var imageLoader = ImageLoader()
    let imageURL: URL
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .onAppear { imageLoader.loadImage(with: imageURL) }
    }
}

struct MovieDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieDetailView(movieID: Movie.stubbedMovie.id, movieTitle: "Bloodshot")
        }
    }
}
