//
//  EpisodeListView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 10/21/23.
//

import Foundation
import Combine
import SwiftUI
import UserNotifications
import SwiftMessages

struct EpisodesListView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    @State private var episodes: [TVShowEpisode] = []
    @State private var allWatched: Bool = false
    @State private var showingDatePickers: [Int: Bool] = [:]
    @State private var setNotifi: Date = Date()
    @State private var episodesWithReminders: Set<Int> = []
    @State private var scheduledNotifications: [UNNotificationRequest] = []
    @State private var showingActionSheetForEpisodeID: Int? = nil
    @State private var embedURL: URL?
    @State private var episodeSources: [Int: [EpisodeSource]] = [:] //
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
        
    let tvShowID: Int
    let tvShowName: String
    let season: TVShowSeason
    let airsTime: String?
    let airsDays: [String]?
    
    var body: some View {
        List(episodes) { episode in
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                Text(episode.name)
                    .font(.headline)
                    .foregroundColor(secondaryTextColor)

                ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
                    RemoteImage(url: episode.stillURL, placeholder: Image("ImageNotFound"))
                        .frame(width: 350, height: 250)
                        .cornerRadius(8)
                        .opacity(watchlistState.isEpisodeWatched(tvShowID: tvShowID, seasonNumber: season.seasonNumber, episodeID: episode.id) ? 0.5 : 1.0)
                    
                    HStack(spacing: 10) {
                        if watchlistState.isEpisodeWatched(tvShowID: tvShowID, seasonNumber: season.seasonNumber, episodeID: episode.id) {
                            Text("Watched!")
                                .font(.caption)
                                .padding(5)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.primary)
                                .cornerRadius(5)
                        }
                        
                        if isNotificationSetForEpisode(episode.id) {
                            Text("Reminder Set!")
                                .font(.caption)
                                .padding(5)
                                .background(Color.yellow.opacity(0.8))
                                .foregroundColor(.primary)
                                .cornerRadius(5)
                        }
                    }
                    .padding(.trailing)
                }

                VStack(alignment: .leading) {
                    HStack {
                        if let airsTime = airsTime, let airsDays = airsDays {
                            let formattedTime = DateUtils.convertTo12HourFormat(airsTime) ?? airsTime
                            Text(isEpisodeAlreadyAired(episode: episode, airsTime: airsTime) ? "Aired \(airsDays.joined(separator: ", ")) at: \(formattedTime)" : "Airs on \(airsDays.joined(separator: ", ")) at: \(formattedTime)")
                                .font(.footnote)
                                .foregroundColor(secondaryTextColor.opacity(0.7))
                        }
                        Spacer()
                        Text(episode.airText)
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor)
                    }
                    
                    Text(episode.overview)
                        .foregroundColor(primaryTextColor.opacity(0.5))
                }
                
                HStack {
                    Button(action: {
                        watchlistState.toggleEpisodeWatchStatus(tvShowID: tvShowID, seasonNumber: season.seasonNumber, episodeID: episode.id)
                    }) {
                        HStack {
                            Image(systemName: watchlistState.isEpisodeWatched(tvShowID: tvShowID, seasonNumber: season.seasonNumber, episodeID: episode.id) ? "checkmark.circle.fill" : "circle")
                            Text(watchlistState.isEpisodeWatched(tvShowID: tvShowID, seasonNumber: season.seasonNumber, episodeID: episode.id) ? "Watched!" : "Watched")
                        }
                        .foregroundColor(.primary)
                        .padding(5)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(5)
                    }.buttonStyle(.borderless)
                    
                    //
                    Spacer()
                    Menu {
                        ForEach(episodeSources[episode.id] ?? [], id: \.url) { source in
                            Button(action: {
                                embedURL = source.url
                            }) {
                                Text(source.name)
                                Image(systemName: "tv")
                            }
                        }
                    } label: {
                        Label("Play", systemImage: "play.circle")
                    }
                    .foregroundColor(.primary)
                    .padding(5)
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(5)
                    
                    Spacer()
                    
                    Button(action: {
                        if !isNotificationSetForEpisode(episode.id) {
                            if isEpisodeAlreadyAired(episode: episode, airsTime: airsTime) {
                                self.setNotifi = Date()
                                self.showingDatePickers[episode.id] = true
                            } else {
                                self.showingActionSheetForEpisodeID = episode.id
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "bell")
                            Text(isNotificationSetForEpisode(episode.id) ? "Reminded!" : "Remind Me")
                        }
                        .foregroundColor(.primary)
                        .padding(5)
                        .background(Color.yellow.opacity(0.7))
                        .cornerRadius(5)
                        .opacity(isNotificationSetForEpisode(episode.id) ? 0.5 : 1.0)
                        .disabled(isNotificationSetForEpisode(episode.id))
                    }
                    .buttonStyle(.borderless)
                    .actionSheet(isPresented: .constant(self.showingActionSheetForEpisodeID == episode.id && !isEpisodeAlreadyAired(episode: episode, airsTime: airsTime))) {
                        ActionSheet(title: Text("Set Notification"), message: Text("Choose A Reminder Option"), buttons: [
                            .default(Text("On Release Date")) {
                                self.scheduleNotification(for: episode, username: auth.currentUser?.username ?? "default")
                            },
                            .default(Text("Custom Reminder")) {
                                self.setNotifi = Date()
                                self.showingDatePickers[episode.id] = true
                                self.showingActionSheetForEpisodeID = nil
                            },
                            .cancel {
                                self.showingActionSheetForEpisodeID = nil
                            }
                        ])
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
//            .listRowSeparator(.hidden)
            .overlay(
                Group {
                    if showingDatePickers[episode.id] ?? false {
                        VStack {
                            DatePicker("Choose a date and time", selection: $setNotifi, displayedComponents: [.date, .hourAndMinute])
                            HStack {
                                Button("Cancel") {
                                    self.showingDatePickers[episode.id] = false
                                    self.showingActionSheetForEpisodeID = nil
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 10)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                                
                                Button("Set") {
                                    if let currentUser = auth.currentUser {
                                        scheduleCustomNotification(for: episode, at: setNotifi, username: currentUser.username) {
                                            self.loadScheduledNotifications()
                                            self.showingDatePickers[episode.id] = false
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 10)
                                .background(Color.yellow.opacity(0.8))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    }

                }
            )
        }
        .sheet(item: $embedURL) { SafariView(url: $0).edgesIgnoringSafeArea(.bottom) }
        .navigationTitle("Episodes list for \(season.name)")
        .navigationBarItems(trailing: Button(action: {
                markAllEpisodesAsWatched()
        }) {
            Image(systemName: allWatched ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(.red)
        })
        .onAppear {
            loadEpisodes()
            loadScheduledNotifications()
        }
    }
    
    //
    private func getVIDSRCEpisodeEmbedURL(for episode: TVShowEpisode) -> URL? {
        let baseURL = "https://vidsrc.xyz/embed/tv"
        let showIdentifier = "\(tvShowID)"
        let seasonNumber = episode.seasonNumber
        let episodeNumber = episode.episodeNumber
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "tmdb", value: showIdentifier),
            URLQueryItem(name: "season", value: "\(seasonNumber)"),
            URLQueryItem(name: "episode", value: "\(episodeNumber)")
        ]
        
        return components?.url
    }
    //
    private func getSuperEmbedEpisodeEmbedURL(for episode: TVShowEpisode) -> URL? {
        let baseURL = "https://multiembed.mov/"
        let showIdentifier = "\(tvShowID)"
        let seasonNumber = episode.seasonNumber
        let episodeNumber = episode.episodeNumber
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "video_id", value: showIdentifier),
            URLQueryItem(name: "tmdb", value: "1"),
            URLQueryItem(name: "s", value: "\(seasonNumber)"),
            URLQueryItem(name: "e", value: "\(episodeNumber)")
        ]
        
        return components?.url
    }
    
    private func markAllEpisodesAsWatched() {
        allWatched.toggle()
        
        for episode in episodes {
            if watchlistState.isEpisodeWatched(tvShowID: tvShowID, seasonNumber: season.seasonNumber, episodeID: episode.id) != allWatched {
                watchlistState.toggleEpisodeWatchStatus(tvShowID: tvShowID, seasonNumber: season.seasonNumber, episodeID: episode.id)
            }
        }
    }
    
    private func isEpisodeAlreadyAired(episode: TVShowEpisode, airsTime: String?) -> Bool {
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let airDate = episode.airDate, let episodeDate = localDateFormatter.date(from: airDate) else {
            print("Failed to get info for: \(episode.name)")
            return false
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let airTime = airsTime ?? "00:00"
        guard let airDateTime = timeFormatter.date(from: airTime) else {
            print("Failed to parse airsTime: \(airTime)")
            return false
        }
        
        var combinedComponents = Calendar.current.dateComponents([.year, .month, .day], from: episodeDate)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: airDateTime)
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        guard let fullAirDateTime = Calendar.current.date(from: combinedComponents) else {
            print("Failed to combine air date and time")
            return false
        }
        
        return fullAirDateTime < Date()
    }

    private func scheduleCustomNotification(for episode: TVShowEpisode, at date: Date, username: String, completion: @escaping () -> Void) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder for: \(tvShowName)"
        content.body = "Episode '\(episode.name)' awaits your viewing!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "digital-beeping.caf"))
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "custom_reminder_tv_show_\(username)_\(episode.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    showError(withTitle: "Error", message: "Failed to schedule notification: \(error.localizedDescription)")
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM, dd yyyy hh:mm a"
                let formattedDate = formatter.string(from: date)
                DispatchQueue.main.async {
                    showSuccess(withTitle: "Reminder", message: "'\(tvShowName)' episode '\(episode.name)' scheduled for '\(formattedDate)'", duration: 5.0)
                }
            }
            loadScheduledNotifications()
            completion()
        }
    }

    private func scheduleNotification(for episode: TVShowEpisode, username: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Episode: \(tvShowName)"
        content.body = "Check out the latest episode: '\(episode.name)'!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "digital-beeping.caf"))
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let airDate = episode.airDate, let episodeDate = localDateFormatter.date(from: airDate) else {
            DispatchQueue.main.async {
                showError(withTitle: "Date Not Found", message: "Failed to get date. Please set a custom reminder date for '\(tvShowName): \(episode.name)'.")
                self.showingDatePickers[episode.id] = true
            }
            return
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
       
        guard let parsedAirsTime = timeFormatter.date(from: airsTime ?? "") else {
            DispatchQueue.main.async {
                showError(withTitle: "Time Not Found", message: "Failed to get air time. Please set a custom reminder date for '\(tvShowName): \(episode.name)'.")
                self.showingDatePickers[episode.id] = true
            }
            return
        }
        
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: parsedAirsTime)
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: episodeDate)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder_tv_show_\(username)_\(episode.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    showError(withTitle: "Error", message: "Failed to schedule notification: \(error.localizedDescription)")
                }
            } else {
                let formattedTime = DateUtils.convertTo12HourFormat(airsTime ?? "") ?? airsTime
                DispatchQueue.main.async {
                    showSuccess(withTitle: "Reminder", message: "'\(tvShowName)' episode '\(episode.name)' scheduled for \(formattedTime ?? "Unknown Time")", duration: 5.0)
                }
            }
            loadScheduledNotifications()
        }
    }
    
    private func isNotificationSetForEpisode(_ episodeID: Int) -> Bool {
        for notification in scheduledNotifications {
            if notification.identifier.contains("\(episodeID)") {
                return true
            }
        }
        return false
    }
    
    private func loadScheduledNotifications() {
        guard let currentUser = auth.currentUser else { return }
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            self.scheduledNotifications = requests.filter {
                $0.identifier.contains(currentUser.username) &&
                ($0.identifier.hasPrefix("reminder_") || $0.identifier.hasPrefix("custom_reminder_"))
            }
        }
    }
    
    private func loadEpisodes() {
        Task {
            do {
                let episodesResponse = try await TVShowStore.shared.fetchEpisodes(forTVShow: tvShowID, seasonNumber: season.seasonNumber)
                self.episodes = episodesResponse.episodes
                allWatched = episodes.allSatisfy { watchlistState.isEpisodeWatched(tvShowID: tvShowID, seasonNumber: season.seasonNumber, episodeID: $0.id) }
                //
                episodes.forEach { episode in
                    var sources: [EpisodeSource] = []
                    if let vidsrcURL = getVIDSRCEpisodeEmbedURL(for: episode) {
                        sources.append(EpisodeSource(name: "VIDSRC", url: vidsrcURL))
                    }
                    if let superEmbedURL = getSuperEmbedEpisodeEmbedURL(for: episode) {
                        sources.append(EpisodeSource(name: "SuperEmbed", url: superEmbedURL))
                    }
                    episodeSources[episode.id] = sources
                }
            } catch {
                showError(message: "Error loading episodes: \(error)")
            }
        }
    }

}

//
struct EpisodeSource {
    let name: String
    let url: URL
}

struct EpisodesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EpisodesListView(
                tvShowID: 1396,
                tvShowName: "Breaking Bad",
                season: mockSeason,
                airsTime: "21:00",
                airsDays: [""]
            )
            .environmentObject(WatchlistState())
            .environmentObject(AuthViewModel())
            .environmentObject(TabBarVisibilityManager())
        }
    }
    
    static var mockSeason: TVShowSeason {
        TVShowSeason(
            id: 1,
            name: "Season 1",
            overview: "A mock overview for Season 1 of Breaking Bad.",
            episodeCount: 10,
            seasonNumber: 1
        )
    }
}
