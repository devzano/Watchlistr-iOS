//
//  MovieWatchlistView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/15/23.
//

import SwiftUI
import Combine

struct MovieWatchlistView: View {
    @EnvironmentObject var watchlistState: WatchlistState
    @State private var searchQuery = ""
    
    var filteredMovies: [MovieWatchlist] {
        if searchQuery.isEmpty {
            return watchlistState.mWatchlist
        } else {
            return watchlistState.searchWatchlistMovies(query: searchQuery)
        }
    }
    
    var body: some View {
        if watchlistState.mWatchlist.isEmpty {
            EmptyPlaceholderView(text: "Your watchlist is empty.", image: Image(systemName: "film"))
                .navigationTitle("Watchlist")
        } else {
            VStack(spacing: 0) {
                SearchBarView(placeholder: "search", text: $searchQuery)
                List {
                    ForEach(filteredMovies) { movie in
                        NavigationLink(destination: MovieDetailView(movieID: movie.id, movieTitle: movie.title)) {
                            HStack {
                                AsyncImage(url: movie.posterURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(8)
                                } placeholder: {
                                    Image("PosterNotFound")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(8)
                                }
                                VStack(alignment: .leading) {
                                    Text(movie.title)
                                        .font(.headline)
                                    
                                    Text(movie.overview)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .lineLimit(3)
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                    }.onDelete { indices in
                        let moviesToDelete = indices.map { watchlistState.mWatchlist[$0] }
                        for movie in moviesToDelete {
                            watchlistState.removeMovieFromWatchlist(movie: movie)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Watchlist")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct MovieWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        MovieWatchlistView()
            .environmentObject(WatchlistState())
    }
}
