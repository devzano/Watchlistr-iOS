//
//  TVShowDetailView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct TVShowDetailView: View {
    
    let tvShowID: Int
    let tvShowName: String
    @StateObject private var tvShowDetailState = TVShowDetailState()
    @State private var selectedTrailerURL: URL?
    @State private var wpSeasonNumber = 1
    
    @EnvironmentObject var watchlistState: WatchlistState
    @State private var isAddedToWatchlist = false
    @StateObject private var tvShowWatchProvidersState = TVShowWatchProvidersState()

    var body: some View {
        List {
            if let tvShow = tvShowDetailState.tvShow {
                TVShowDetailImage(imageURL: tvShow.backdropURL)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                if let providers = tvShowWatchProvidersState.tvShowWatchProviders {
                    HStack {
                        WatchProvidersView(watchProviders: providers)
                            .listRowSeparator(.hidden)
                        Spacer()
                        if !tvShow.ratingText.isEmpty {
                            VStack(alignment: .center) {
                                Text("Rating")
                                    .font(.headline)
                                Text("\(tvShow.ratingText)")
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
                TVShowDetailListView(tvShow: tvShow, selectedTrailerURL: $selectedTrailerURL)
            }
        }
        .listStyle(.plain)
        .task {
            loadTVShow()
        }
        .overlay(DataFetchPhaseOverlayView(
            phase: tvShowDetailState.phase,
            retryAction: loadTVShow)
        )
        .sheet(item: $selectedTrailerURL) { SafariView(url: $0).edgesIgnoringSafeArea(.bottom)}
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(tvShowName)
                    .foregroundColor(.blue)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if isTVShowInWatchlist {
                        removeFromWatchlist()
                    } else {
                        addTVShowToWatchlist()
                    }
                }) {
                    if isTVShowInWatchlist {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
    }
    
    private func loadTVShow() {
        Task {
            await self.tvShowDetailState.loadTVShow(id: self.tvShowID)
            await tvShowWatchProvidersState.loadTVShowWatchProviders(forTVShow: tvShowID, wpSeason: wpSeasonNumber)
        }
    }
    
    private var isTVShowInWatchlist: Bool {
        if let tvShow = tvShowDetailState.tvShow {
            return watchlistState.tvWatchlist.contains { $0.id == tvShow.id }
        }
        return false
    }

    private func addTVShowToWatchlist() {
        if !isTVShowInWatchlist, let tvShow = tvShowDetailState.tvShow {
            watchlistState.addTVShowToWatchlist(tvShow: tvShow)
            isAddedToWatchlist = true
        }
    }
    
    private func removeFromWatchlist() {
        if let tvShow = tvShowDetailState.tvShow,
           let existingTVShowWatchlist = watchlistState.tvWatchlist.first(where: { $0.id == tvShow.id }) {
            watchlistState.removeTVShowFromWatchlist(tvShow: existingTVShowWatchlist)
            isAddedToWatchlist = false
        }
    }
}

struct TVShowDetailListView: View {
    let tvShow: TVShow
    @Binding var selectedTrailerURL: URL?
    @State private var selectedSeasonIndex = 0

    var body: some View {
        tvShowDescriptionSection.listRowSeparator(.visible)
        tvShowCastSection.listRowSeparator(.hidden)
        tvShowTrailerSection
    }
    
    private var tvShowDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tvShowGenreYearDurationText)
                .font(.headline)
            Text(tvShow.overview)
                .foregroundColor(.blue)
        }
        .padding(.vertical)
    }
    
    private var tvShowGenreYearDurationText: String {
        "\(tvShow.genreText) · \(tvShow.airText) · \(tvShow.durationText)"
    }
    
    private var tvShowCastSection: some View {
        HStack(alignment: .top, spacing: 4) {
            if let cast = tvShow.cast, !cast.isEmpty {
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
            if let crew = tvShow.crew, !crew.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    
                    if let producers = tvShow.producers, !producers.isEmpty {
                        Text("Producer(s):").font(.headline)
                            .padding(.top)
                        ForEach(producers.prefix(2)) { Text($0.name)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let eProducers = tvShow.eProducers, !eProducers.isEmpty {
                        Text("Executive Producer(s):").font(.headline)
                            .padding(.top)
                        ForEach(eProducers.prefix(2)) { Text($0.name)
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
    private var tvShowTrailerSection: some View {
        if let trailers = tvShow.youtubeTrailers, !trailers.isEmpty {
            Text("Trailers").font(.headline)
            ForEach(trailers) { trailer in
                Button(action: {
                    guard let url = trailer.youtubeURL else { return }
                    selectedTrailerURL = url
                }) {
                    HStack {
                        Text(trailer.name)
                            .foregroundColor(.accentColor)
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(Color(UIColor.systemIndigo))
                    }
                }
            }
        }
    }
}

struct TVShowDetailImage: View {
    
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
        .onAppear {imageLoader.loadImage(with: imageURL)}
    }
}

struct TVShowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TVShowDetailView(tvShowID: TVShow.stubbedTVShow.id, tvShowName: "Superman")
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
