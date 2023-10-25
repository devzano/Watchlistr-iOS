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
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    let tvShowID: Int
    let tvShowName: String
    let season: TVShowSeason
    @State private var episodes: [TVShowEpisode] = []
    @State private var showingDatePickers: [Int: Bool] = [:]
    @State private var setNotifi: Date = Date()
    @State private var releaseNotif: Date = Date()
    @State private var episodesWithReminders: Set<Int> = []
    @State private var scheduledNotifications: [UNNotificationRequest] = []

    var body: some View {
        List(episodes) { episode in
            VStack(alignment: .leading) {
                ZStack {
                    RemoteImage(url: episode.stillURL, placeholder: Image("ImageNotFound"))
                        .frame(width: 350, height: 250)
                        .cornerRadius(8)
                        .opacity(watchlistState.isEpisodeWatched(tvShowID: tvShowID, episodeID: episode.id) ? 0.5 : 1.0)
                    
                    VStack(spacing: 10) {
                        if watchlistState.isEpisodeWatched(tvShowID: tvShowID, episodeID: episode.id) {
                            Text("Watched!")
                                .font(.caption)
                                .padding(5)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        
                        if isNotificationSetForEpisode(episode.id) {
                            Text("Reminder Set!")
                                .font(.caption)
                                .padding(5)
                                .background(Color.yellow.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                    }
                }
                
                HStack {
                    Text(episode.name)
                        .font(.headline)
                        .layoutPriority(1)
                    
                    Spacer()
                    
                    Text(episode.airText)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Text(episode.overview)
                    .foregroundColor(.secondary)
            }
            .contextMenu {
                Button(action: {
                    watchlistState.toggleEpisodeWatchStatus(tvShowID: tvShowID, episodeID: episode.id)
                }) {
                    Text(watchlistState.isEpisodeWatched(tvShowID: tvShowID, episodeID: episode.id) ? "Mark as Unwatched" : "Mark as Watched")
                    Image(systemName: watchlistState.isEpisodeWatched(tvShowID: tvShowID, episodeID: episode.id) ? "checkmark.circle.fill" : "circle")
                }
                
                if !isEpisodeAlreadyAired(episode: episode) {
                    Button(action: {
                        requestNotificationPermission { granted in
                            if granted {
                                setNotifi = Date()
                                showingDatePickers[episode.id] = true
                            } else {
                                DispatchQueue.main.async {
                                    showError(withTitle: "Permission Denied",
                                              message: "To enable notifications for Watchlistr, please navigate to your device's settings and grant permission.", duration: 5.0)
                                }
                            }
                        }
                    }) {
                        Text("Remind Me On Release")
                        Image(systemName: "bell")
                    }
                } else {
                    Button(action: {
                        requestNotificationPermission { granted in
                            if granted {
                                setNotifi = Date()
                                showingDatePickers[episode.id] = true
                            } else {
                                DispatchQueue.main.async {
                                    showError(withTitle: "Permission Denied",
                                              message: "To enable notifications for Watchlistr, please navigate to your device's settings and grant permission.", duration: 5.0)
                                }
                            }
                        }
                    }) {
                        Text(isEpisodeAlreadyAired(episode: episode) ? "Set A Reminder" : "Remind Me On Release")
                        Image(systemName: isEpisodeAlreadyAired(episode: episode) ? "clock" : "bell")
                    }
                }
            }
            .overlay(
                Group {
                    if showingDatePickers[episode.id] ?? false {
                        VStack {
                            DatePicker("Choose a date and time", selection: $setNotifi, displayedComponents: [.date, .hourAndMinute])
                            HStack {
                                Button("Cancel") {
                                    showingDatePickers[episode.id] = false
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 10)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)

                                Button("Set A Reminder") {
                                    if let currentUser = vm.currentUser {
                                        scheduleCustomNotification(for: episode, at: setNotifi, username: currentUser.username) {
                                            self.loadScheduledNotifications()
                                            showingDatePickers[episode.id] = false
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 10)
                                .background(Color.yellow.opacity(0.8))
                                .foregroundColor(.white)
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
        .navigationTitle("Episodes list for \(season.name)")
        .onAppear {
            loadEpisodes()
            loadScheduledNotifications()
        }
    }
    
    private func isEpisodeAlreadyAired(episode: TVShowEpisode) -> Bool {
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let airDate = episode.airDate, let episodeDate = localDateFormatter.date(from: airDate) else {
            print("Failed to get episodeDate from airDate: \(episode.airDate ?? "nil")")
            return false
        }
        
        return episodeDate < Date()
    }

    private func scheduleCustomNotification(for episode: TVShowEpisode, at date: Date, username: String, completion: @escaping () -> Void) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder for: \(tvShowName)"
        content.body = "Episode '\(episode.name)' awaits your viewing!"
        content.sound = UNNotificationSound.default
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "custom_reminder_\(username)_\(episode.id)", content: content, trigger: trigger)
        
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
            completion()
        }
    }

    private func scheduleNotification(for episode: TVShowEpisode, username: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Episode: \(tvShowName)"
        content.body = "Check out the latest episode: '\(episode.name)'!"
        content.sound = UNNotificationSound.default
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let airDate = episode.airDate, let episodeDate = localDateFormatter.date(from: airDate) else {
            DispatchQueue.main.async {
                showError(withTitle: "Warning", message: "Failed to get episodeDate from airDate: \(episode.airDate ?? "no dates found")")
            }
            return
        }

        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: releaseNotif)
            
        var components = Calendar.current.dateComponents([.year, .month, .day], from: episodeDate)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder_\(username)_\(episode.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    showError(withTitle: "Error", message: "Failed to schedule notification: \(error.localizedDescription)")
                }
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM, dd yyyy hh:mm a"
                let formattedEpisodeDate = formatter.string(from: episodeDate)
                DispatchQueue.main.async {
                    showSuccess(withTitle: "Reminder", message: "'\(tvShowName)' episode '\(episode.name)' scheduled for '\(formattedEpisodeDate)'", duration: 5.0)
                }
            }
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
        guard let currentUser = vm.currentUser else { return }
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
            } catch {
                showError(message: "Error loading episodes: \(error)")
            }
        }
    }
}

struct EpisodesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EpisodesListView(
                tvShowID: 1396,
                tvShowName: "Breaking Bad",
                season: mockSeason
            )
            .environmentObject(WatchlistState())
        }
    }
    
    static var mockSeason: TVShowSeason {
        TVShowSeason(
            id: 1,
            name: "Season 1",
            overview: "A mock overview for Season 1 of Breaking Bad.", episodeCount: 10,
            posterPath: nil,
            seasonNumber: 1
        )
    }
}

