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
    @StateObject private var tvdbServiceState = TVDBServiceState()
    @State private var selectedTrailerURL: URL? //
    @State private var embedURL: URL? //
    @State private var wpSeasonNumber = 1
    @State private var isAddedToWatchlist = false
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
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
                        if tvShow.ratingText != "NR" {
                            VStack(alignment: .center) {
                                Text("Rating")
                                    .font(.headline)
                                Text(tvShow.ratingText)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 17)
                                    .padding(.vertical, 10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(LinearGradient(gradient: Gradient(colors: [secondaryTextColor, primaryTextColor]), startPoint: .leading, endPoint: .trailing), lineWidth: 3)
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                        } else {
                            VStack(alignment: .center) {
                                Text("Rating")
                                    .font(.headline)
                                Text("NR")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 17)
                                    .padding(.vertical, 10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(LinearGradient(gradient: Gradient(colors: [secondaryTextColor, primaryTextColor]), startPoint: .leading, endPoint: .trailing), lineWidth: 3)
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                }
                
                TVShowDetailListView(
                    tvShow: tvShow,
                    selectedTrailerURL: $selectedTrailerURL,
                    airsTime: tvdbServiceState.airsTime,
                    airsDays: tvdbServiceState.airsDays
                )
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
                    .foregroundColor(primaryTextColor)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    //
                    if let url = embedURL {
                        Button(action: {
                            selectedTrailerURL = url
                        }) {
                            Image(systemName: "play.circle")
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    
                    Button(action: {
                        if isTVShowInWatchlist {
                            removeFromWatchlist()
                        } else {
                            addTVShowToWatchlist()
                        }
                    }) {
                        if isTVShowInWatchlist {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(primaryTextColor)
                        } else {
                            Image(systemName: "plus.circle")
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                }
            }
        }
    }
    
    private func loadTVShow() {
        Task {
            if case .success(_) = tvShowDetailState.phase {
                return
            }
            
            await self.tvShowDetailState.loadTVShow(id: self.tvShowID)
            await tvShowSeriesImagesState.loadTVShowSeriesImages(id: tvShowID)
            await tvShowWatchProvidersState.loadTVShowWatchProviders(forTVShow: tvShowID, wpSeason: wpSeasonNumber)
            if let tvdbID = tvShowDetailState.externalIDs?.tvdbId {
                await tvdbServiceState.fetchAirsTimeAndDays(forSeriesID: tvdbID, withAPIKey: "\(Constants.tvdbAPIKey)")
            }
            //
            if let url = URL(string: "https://vidsrc.xyz/embed/tv?tmdb=\(tvShowID)") {
                self.embedURL = url
            }
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
    let airsTime: String?
    let airsDays: [String]?
    @State private var selectedSeasonIndex = 0
    @State private var selectedSeason: TVShowSeason?
    @State private var episodes: [TVShowEpisode] = []
    @EnvironmentObject var watchlistState: WatchlistState
    @StateObject private var tvdbServiceState = TVDBServiceState()
    @State private var isDataLoaded = false
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var body: some View {
        tvShowDescriptionSection.listRowSeparator(.visible)
        tvShowCastSection.listRowSeparator(.hidden)
        tvShowSeasonsSection
        tvShowTrailerSection
    }
    
    private var tvShowDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let airsInfo = formattedAirsInfoText {
                HStack {
                    Text("Genre: ").foregroundColor(secondaryTextColor)
                    + Text(tvShow.genreText)
                    + Text(" · Airs: ").foregroundColor(secondaryTextColor)
                    + Text(airsInfo)
                    + Text(" · Duration: ").foregroundColor(secondaryTextColor)
                    + Text(tvShow.durationText)
                }.font(.subheadline)
            } else {
                HStack {
                    Text("Genre: ").foregroundColor(secondaryTextColor)
                    + Text(tvShow.genreText)
                    + Text(" · Duration: ").foregroundColor(secondaryTextColor)
                    + Text(tvShow.durationText)
                }.font(.subheadline)
            }

            Text("Synopsis:")
                .font(.caption)
                .padding(.top, 5)

            Text(tvShow.overview)
                .foregroundColor(secondaryTextColor)
                .padding(.top, -8)
        }
    }

    private var formattedAirsInfoText: String? {
        guard let airsTime = airsTime, let airsDays = airsDays, !airsDays.isEmpty else {
            return nil
        }
        
        let formattedTime = DateUtils.convertTo12HourFormat(airsTime) ?? airsTime
        return "\(airsDays.joined(separator: ", ")) at \(formattedTime)"
    }

    private func loadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isDataLoaded = true
        }
    }
    
    private var tvShowCastSection: some View {
        HStack(alignment: .top, spacing: 4) {
            if let cast = tvShow.cast, !cast.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starring:").font(.headline)
                    ForEach(cast.prefix(9)) {
                        Text($0.name).foregroundColor(secondaryTextColor)
                        + Text(" as ")
                        + Text("\"")
                        + Text("\($0.character)").foregroundColor(secondaryTextColor)
                        + Text("\"")
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            
            if let crew = tvShow.crew, !crew.isEmpty, hasProducersOrExecutiveProducers(crew: crew) {
                VStack(alignment: .leading, spacing: 4) {
                    if let producers = tvShow.producers, !producers.isEmpty {
                        Text("Producer(s):").font(.headline)
                            .padding(.top)
                        ForEach(producers.prefix(2)) { Text($0.name)
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    
                    if let eProducers = tvShow.eProducers, !eProducers.isEmpty {
                        Text("Executive Producer(s):").font(.headline)
                            .padding(.top)
                        ForEach(eProducers.prefix(2)) { Text($0.name)
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical)
    }

    private func hasProducersOrExecutiveProducers(crew: [TVShowCrew]) -> Bool {
        let producersExist = tvShow.producers != nil && !tvShow.producers!.isEmpty
        let executiveProducersExist = tvShow.eProducers != nil && !tvShow.eProducers!.isEmpty
        return producersExist || executiveProducersExist
    }
    
    @ViewBuilder
    private var tvShowSeasonsSection: some View {
        if let seasons = tvShow.seasons, !seasons.isEmpty {
            Section(header: Text("Seasons:").font(.headline)) {
                ForEach(seasons) { season in
                    NavigationLink(destination: EpisodesListView(tvShowID: tvShow.id, tvShowName: tvShow.name, season: season, airsTime: airsTime, airsDays: airsDays).environmentObject(watchlistState)) {
                        HStack {
                            Text(season.name)
                                .foregroundColor(secondaryTextColor)
                            Spacer()

                            if watchlistState.watchedEpisodesCountForSeason(tvShowID: tvShow.id, seasonNumber: season.seasonNumber) == season.episodeCount {
                                Text("Watched!")
                                    .font(.caption)
                                    .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.primary)
                                    .cornerRadius(5)
                            }
                            Text("\(season.episodeCount) episodes")
                                .foregroundColor(primaryTextColor.opacity(0.5))
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
                                            .foregroundColor(primaryTextColor)
                                    }
                                    Text(trailer.name)
                                        .foregroundColor(secondaryTextColor)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 120, alignment: .center)
                                }
                            }
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
    }
}

struct TVShowBackdropsView: View {
    let backdrops: [TVShowSeriesImages.ImageDetail]
    @State private var currentIndex: Int = 0

    var body: some View {
        VStack {
            if let backdrop = backdrops[safe: currentIndex] {
                RemoteImage(url: backdrop.imageURL, placeholder: nil)
                    .frame(width: UIScreen.main.bounds.width, height: 250)
                    .clipped()
            }
        }.onAppear {
            SharedTimer.shared.startTimer {
                withAnimation {
                    currentIndex = (currentIndex + 1) % backdrops.count
                }
            }
        }.onDisappear {
            SharedTimer.shared.stopTimer()
        }
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
