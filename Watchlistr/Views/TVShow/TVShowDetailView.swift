//
//  TVShowDetailView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI
import SwiftMessages
import UserNotifications

struct TVShowDetailView: View {
    let tvShowID: Int
    let tvShowName: String
    @EnvironmentObject var watchlistState: WatchlistState
    @StateObject private var tvShowDetailState = TVShowDetailState()
    @StateObject private var tvShowSeriesImagesState = TVShowSeriesImagesState()
    @StateObject private var tvShowWatchProvidersState = TVShowWatchProvidersState()
    @State private var selectedTrailerURL: URL?
    @State private var wpSeasonNumber = 1
    @State private var isAddedToWatchlist = false

    var body: some View {
        List {
            if let tvShow = tvShowDetailState.tvShow {
                if let seriesImages = tvShowSeriesImagesState.tvShowSeriesImages, let backdrops = seriesImages.backdrops, !backdrops.isEmpty {
                        TVShowBackdropsView(backdrops: backdrops)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
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
            await tvShowSeriesImagesState.loadTVShowSeriesImages(id: tvShowID)
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
    @State private var selectedSeason: TVShowSeason?
    @State private var episodes: [TVShowEpisode] = []
    @EnvironmentObject var watchlistState: WatchlistState

    var body: some View {
        tvShowDescriptionSection.listRowSeparator(.visible)
        tvShowCastSection.listRowSeparator(.hidden)
        tvShowSeasonsSection
        tvShowTrailerSection
    }
    
    private var tvShowDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tvShowGenreYearDurationText)
                .font(.headline)
            Text(tvShow.overview)
                .foregroundColor(.blue)
        }.padding(.vertical)
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
                }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                
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
                }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }.padding(.vertical)
    }
    
    @ViewBuilder
    private var tvShowSeasonsSection: some View {
        if let seasons = tvShow.seasons, !seasons.isEmpty {
            Section(header: Text("Seasons:").font(.headline)) {
                ForEach(seasons) { season in
                    NavigationLink(destination: EpisodesListView(tvShowID: tvShow.id, tvShowName: tvShow.name, season: season).environmentObject(watchlistState)) {
                        HStack {
                            Text(season.name).foregroundColor(.blue)
                            Spacer()
                            Text("\(season.episodeCount) episodes")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var tvShowTrailerSection: some View {
        if let trailers = tvShow.youtubeTrailers, !trailers.isEmpty {
            VStack(alignment: .leading) {
                Text("Trailers").font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(trailers) { trailer in
                            Button(action: {
                                guard let url = trailer.youtubeURL else { return }
                                selectedTrailerURL = url
                            }) {
                                VStack {
                                    ZStack(alignment: .center) {
                                        RemoteImage(url: URL(string: "https://img.youtube.com/vi/\(trailer.key)/0.jpg")!, placeholder: nil)
                                            .frame(width: 120, height: 70)
                                            .clipped()
                                        Image(systemName: "play.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(Color(UIColor.systemIndigo))
                                    }
                                    Text(trailer.name)
                                        .foregroundColor(.accentColor)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 120, alignment: .center)
                                }
                            }.padding(.vertical, 8)
                        }
                    }
                }
            }.padding(.bottom)
        }
    }
}

struct TVShowSeriesImagesView: View {
    let seriesImages: TVShowSeriesImages

    var body: some View {
        VStack {
            Text("Backdrops")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(seriesImages.backdrops ?? [], id: \.filePath) { imageDetail in
                        RemoteImage(url: imageDetail.imageURL, placeholder: nil)
                            .frame(width: 120, height: 70)
                            .clipped()
                    }
                }
            }

            Text("Posters")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(seriesImages.posters ?? [], id: \.filePath) { imageDetail in
                        RemoteImage(url: imageDetail.imageURL, placeholder: nil)
                            .frame(width: 120, height: 70)
                            .clipped()
                    }
                }
            }
        }
    }
}

struct TVShowBackdropsView: View {
    let backdrops: [TVShowSeriesImages.ImageDetail]
    @State private var currentIndex: Int = 0
    @State private var timer: Timer? = nil

    var body: some View {
        VStack {
            if let backdrop = backdrops[safe: currentIndex] {
                RemoteImage(url: backdrop.imageURL, placeholder: nil)
                    .frame(width: UIScreen.main.bounds.width, height: 250)
                    .clipped()
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % backdrops.count
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct TVShowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TVShowDetailView(
                tvShowID: 1396,
                tvShowName: "Breaking Bad"
            )
            .environmentObject(WatchlistState())
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
