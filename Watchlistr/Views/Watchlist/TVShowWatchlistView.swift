//
//  TVShowWatchlistView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/15/23.
//

import SwiftUI
import Combine

struct TVShowWatchlistView: View {
    @EnvironmentObject var watchlistState: WatchlistState
    @State private var searchQuery = ""
    
    var filteredTVShows: [TVShowWatchlist] {
        if searchQuery.isEmpty {
            return watchlistState.tvWatchlist
        } else {
            return watchlistState.searchWatchlistTVShows(query: searchQuery)
        }
    }
    
    var body: some View {
        if watchlistState.tvWatchlist.isEmpty {
            EmptyPlaceholderView(text: "Your watchlist is empty.", image: Image(systemName: "tv"))
                .navigationTitle("Watchlist")
        } else {
            VStack(spacing: 0) {
                SearchBarView(placeholder: "search", text: $searchQuery)
                List {
                    ForEach(filteredTVShows) { tvShow in
                        NavigationLink(destination: TVShowDetailView(tvShowID: tvShow.id, tvShowName: tvShow.name)) {
                            HStack {
                                AsyncImage(url: tvShow.posterURL) { image in
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
                                    Text(tvShow.name)
                                        .font(.headline)
                                    
                                    Text(tvShow.overview)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .lineLimit(3)
                                }
                            }
                        }.listRowSeparator(.hidden)
                    }
                    .onDelete { indices in
                        let tvShowsToDelete = indices.map { watchlistState.tvWatchlist[$0] }
                        for tvShow in tvShowsToDelete {
                            watchlistState.removeTVShowFromWatchlist(tvShow: tvShow)
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

struct TVShowWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        TVShowWatchlistView()
            .environmentObject(WatchlistState())
    }
}
