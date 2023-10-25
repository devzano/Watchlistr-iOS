//
//  TVShowWatchlistView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/15/23.
//

import Foundation
import Combine
import SwiftUI
import UserNotifications
import SwiftMessages

struct TVShowWatchlistView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    @State private var searchQuery = ""
    @State private var setNotifForTVShow: Date = Date()
    @State private var datePickerForTVShow: Int?
    @State private var scheduledNotifications: [UNNotificationRequest] = []

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
                            WatchlistTVShowRowView(tvShow: tvShow, isNotifiSet: isNotifiSetForTVShowWatchlist(tvShow.id))
                        }
                        .contextMenu {
                            Button(action: {
                                withAnimation {
                                    watchlistState.toggleWatchedStatus(of: tvShow)
                                }
                            }) {
                                Text(tvShow.watched ? "Mark as Unwatched" : "Mark as Watched")
                                Image(systemName: tvShow.watched ? "checkmark.circle.fill" : "circle")
                            }
                            Button(action: {
                                requestNotificationPermission { granted in
                                    if granted {
                                        setNotifForTVShow = Date()
                                        datePickerForTVShow = tvShow.id
                                    } else {
                                        DispatchQueue.main.async {
                                            showError(withTitle: "Permission Denied",
                                                      message: "To enable notifications for Watchlistr, please navigate to your device's settings and grant permission.", duration: 5.0)
                                        }
                                    }
                                }
                            }) {
                                Text("Set A Reminder")
                                Image(systemName: "clock")
                            }
                        }
                        .overlay(
                            Group {
                                if datePickerForTVShow == tvShow.id {
                                    VStack {
                                        DatePicker("Choose a date and time", selection: $setNotifForTVShow, displayedComponents: [.date, .hourAndMinute])
                                        
                                        HStack {
                                            Button("Cancel") {
                                                datePickerForTVShow = nil
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.horizontal, 10)
                                            .background(Color.red.opacity(0.8))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            
                                            Button(action: {
                                                if let currentUser = vm.currentUser {
                                                    scheduleCustomNotificationForTVShow(tvShow: tvShow, at: setNotifForTVShow, username: currentUser.username)
                                                    datePickerForTVShow = nil
                                                }
                                            }) {
                                                Text("Set A Reminder")
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
                        ).listRowSeparator(.hidden)
                    }.onDelete { indices in
                        let tvShowsToDelete = indices.map { watchlistState.tvWatchlist[$0] }
                        for tvShow in tvShowsToDelete {
                            watchlistState.removeTVShowFromWatchlist(tvShow: tvShow)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Watchlist")
                .navigationBarTitleDisplayMode(.inline)
            }.onAppear {
                loadTVShowWatchlistNotifis()
            }
        }
    }
    
    private func scheduleCustomNotificationForTVShow(tvShow: TVShowWatchlist, at date: Date, username: String) {
        let content = UNMutableNotificationContent()
        content.title = "TV Show Reminder"
        content.body = "Don't forget to watch '\(tvShow.name)'!"
        content.sound = UNNotificationSound.default
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "custom_reminder_tv_show_\(username)_\(tvShow.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                showError(withTitle: "Error", message: "Failed to schedule notification: \(error.localizedDescription)")
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM, dd yyyy hh:mm a"
                let formattedDate = formatter.string(from: date)
                DispatchQueue.main.async {
                    showSuccess(withTitle: "Reminder", message: "'\(tvShow.name)' scheduled for '\(formattedDate)'", duration: 5.0)
                }
                self.loadTVShowWatchlistNotifis()
            }
        }
    }
    
    private func isNotifiSetForTVShowWatchlist(_ tvShowID: Int) -> Bool {
        for notification in scheduledNotifications {
            if notification.identifier.contains("\(tvShowID)") {
                return true
            }
        }
        return false
    }
    
    private func loadTVShowWatchlistNotifis() {
        guard let currentUser = vm.currentUser else { return }
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            self.scheduledNotifications = requests.filter {
                $0.identifier.contains(currentUser.username) &&
                $0.identifier.hasPrefix("custom_reminder_tv_show_")
            }
        }
    }
}

struct WatchlistTVShowRowView: View {
    var tvShow: TVShowWatchlist
    var isNotifiSet: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                RemoteImage(url: tvShow.posterURL, placeholder: Image("PosterNotFound"))
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(tvShow.name)
                        .font(.headline)
                    
                    Text(tvShow.overview)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(3)
                }
            }
            .opacity(tvShow.watched ? 0.5 : 1.0)
            
            VStack(spacing: 5) {
                if tvShow.watched {
                    Text("Watched!")
                        .font(.caption)
                        .padding(5)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                
                if isNotifiSet {
                    Text("Reminder Set!")
                        .font(.caption)
                        .padding(5)
                        .background(Color.yellow.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
            }
        }
    }
}

struct TVShowWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TVShowWatchlistView()
                .environmentObject(WatchlistState.sampleTVShowWatchlist())
        }
    }
}

extension WatchlistState {
    func toggleWatchedStatus(of tvShow: TVShowWatchlist) {
        if let index = tvWatchlist.firstIndex(where: { $0.id == tvShow.id }) {
            tvWatchlist[index].watched.toggle()
            watchedTVShowInFirestore(tvShow: tvWatchlist[index])
        }
    }
}

extension WatchlistState {
    static func sampleTVShowWatchlist() -> WatchlistState {
        let watchlist = WatchlistState()
        let breakingBad = TVShowWatchlist(
            id: 1396,
            name: "Breaking Bad",
            backdropPath: "https://image.tmdb.org/t/p/w500/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg",
            posterPath: "https://image.tmdb.org/t/p/w500/3xnWaLQjelJDDF7LT1WBo6f4BRe.jpg",
            overview: "When Walter White, a New Mexico chemistry teacher, is diagnosed with Stage III cancer and given a prognosis of only two years left to live. He becomes filled with a sense of fearlessness and an unrelenting desire to secure his family's financial future at any cost as he enters the dangerous world of drugs and crime.",
            watched: false
        )
        let gameOfThrones = TVShowWatchlist(
            id: 1399,
            name: "Game of Thrones",
            backdropPath: "https://image.tmdb.org/t/p/w500/2OMB0ynKlyIenMJWI2Dy9IWT4c.jpg",
            posterPath: "https://image.tmdb.org/t/p/w500/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg",
            overview: "Seven noble families fight for control of the mythical land of Westeros. Friction between the houses leads to full-scale war. All while a very ancient evil awakens in the farthest north. Amidst the war, a neglected military order of misfits, the Night's Watch, is all that stands between the realms of men and icy horrors beyond.",
            watched: true
        )
        watchlist.tvWatchlist = [breakingBad, gameOfThrones]
        return watchlist
    }
}
