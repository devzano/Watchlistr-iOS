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

struct TVShowSortOptions {
    var alphabetical: Bool = false
    var reverseAlphabetical: Bool = false
    var watched: Bool = false
    var reminded: Bool = false
}

struct TVShowWatchlistView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @State private var searchQuery = ""
    @State private var setNotifForTVShow: Date = Date()
    @State private var datePickerForTVShow: Int?
    @State private var scheduledNotifications: [UNNotificationRequest] = []
    @State private var sortOrder = TVShowSortOptions()
    @State private var sortHasPriority: Bool = true
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var filteredTVShows: [TVShowWatchlist] {
        if searchQuery.isEmpty {
            return watchlistState.tvWatchlist
        } else {
            return watchlistState.searchWatchlistTVShows(query: searchQuery)
        }
    }
    
    private func applyTVShowSort() {
        watchlistState.tvWatchlist.sort { firstTVShow, secondTVShow in
            if sortHasPriority {
                if sortOrder.watched {
                    if firstTVShow.watched != secondTVShow.watched {
                        return firstTVShow.watched && !secondTVShow.watched
                    }
                }

                if sortOrder.reminded {
                    let firstIsReminded = isNotifiSetForTVShowWatchlist(firstTVShow.id)
                    let secondIsReminded = isNotifiSetForTVShowWatchlist(secondTVShow.id)
                    if firstIsReminded != secondIsReminded {
                        return firstIsReminded && !secondIsReminded
                    }
                }
            } else {
                if sortOrder.reminded {
                    let firstIsReminded = isNotifiSetForTVShowWatchlist(firstTVShow.id)
                    let secondIsReminded = isNotifiSetForTVShowWatchlist(secondTVShow.id)
                    if firstIsReminded != secondIsReminded {
                        return firstIsReminded && !secondIsReminded
                    }
                }

                if sortOrder.watched {
                    if firstTVShow.watched != secondTVShow.watched {
                        return firstTVShow.watched && !secondTVShow.watched
                    }
                }
            }

            if sortOrder.alphabetical {
                return firstTVShow.name < secondTVShow.name
            } else if sortOrder.reverseAlphabetical {
                return firstTVShow.name > secondTVShow.name
            }

            return firstTVShow.id < secondTVShow.id
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if watchlistState.tvWatchlist.isEmpty {
                EmptyPlaceholderView(text: "All your favorite shows will be listed here. Start adding!", image: Image(systemName: "tv"))
                    .navigationTitle("Watchlist")
            } else {
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
                                    applyTVShowSort()
                                }
                            }) {
                                Text(tvShow.watched ? "Watched!" : "Watched")
                                Image(systemName: tvShow.watched ? "checkmark.circle.fill" : "circle")
                            }
                            
                            if isNotifiSetForTVShowWatchlist(tvShow.id) {
                                Text("Reminder Set!")
                                    .foregroundColor(.gray)
                            } else {
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
                                    applyTVShowSort()
                                }) {
                                    Text("Set A Reminder")
                                    Image(systemName: "clock")
                                }
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
                                            .foregroundColor(.primary)
                                            .cornerRadius(8)
                                            
                                            Button(action: {
                                                if let currentUser = auth.currentUser {
                                                    scheduleCustomNotificationForTVShow(tvShow: tvShow, at: setNotifForTVShow, username: currentUser.username)
                                                    datePickerForTVShow = nil
                                                }
                                            }) {
                                                Text("Set")
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
                        ).listRowSeparator(.hidden)
                    }
                    .onDelete { indices in
                        let tvShowsToDelete = indices.map { watchlistState.tvWatchlist[$0] }
                        for tvShow in tvShowsToDelete {
                            watchlistState.removeTVShowFromWatchlist(tvShow: tvShow)
                        }
                    }
                    .onMove(perform: moveTVShow)
                }
                .listStyle(PlainListStyle())
                .onAppear {
                    loadTVShowWatchlistNotifis()
                    sortOrder.alphabetical = UserDefaults.standard.bool(forKey: "sortTVShowAlphabetical")
                    sortOrder.reverseAlphabetical = UserDefaults.standard.bool(forKey: "sortTVShowReverseAlphabetical")
                    sortOrder.watched = UserDefaults.standard.bool(forKey: "sortTVShowWatched")
                    sortOrder.reminded = UserDefaults.standard.bool(forKey: "sortTVShowReminded")
                    applyTVShowSort()
                }
            }
        }
        .navigationBarItems(trailing: Menu {
            Button(action: {
                sortHasPriority.toggle()
                applyTVShowSort()
            }) {
                Label(sortHasPriority ? "Priority: Watched" : "Priority: Reminded", systemImage: sortHasPriority ? "eye" : "bell")
            }
            
            Button(action: {
                sortOrder.alphabetical.toggle()
                UserDefaults.standard.set(sortOrder.alphabetical, forKey: "sortTVShowAlphabetical")
                applyTVShowSort()
            }) {
                let sortImageName = sortOrder.alphabetical ? "text.line.last.and.arrowtriangle.forward" : "text.line.first.and.arrowtriangle.forward"
                let sortName = sortOrder.alphabetical ? "Sort Z-A" : "Sort A-Z"
                Label(sortName, systemImage: sortImageName)
            }

            Button(action: {
                sortOrder.watched.toggle()
                UserDefaults.standard.set(sortOrder.watched, forKey: "sortTVShowWatched")
                applyTVShowSort()
            }) {
                let sortImageName = sortOrder.watched ? "eye.slash.circle.fill" : "eye.circle.fill"
                Label("Sort by Watched", systemImage: sortImageName)
            }

            Button(action: {
                sortOrder.reminded.toggle()
                UserDefaults.standard.set(sortOrder.reminded, forKey: "sortTVShowReminded")
                applyTVShowSort()
            }) {
                let sortImageName = sortOrder.reminded ? "bell.slash.circle.fill" : "bell.circle.fill"
                Label("Sort by Reminded", systemImage: sortImageName)
            }
        } label: {
            Image(systemName: "ellipsis.circle").foregroundColor(secondaryTextColor)
        }.buttonStyle(.borderless))
        .navigationTitle("Watchlist")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func moveTVShow(from source: IndexSet, to destination: Int) {
        watchlistState.tvWatchlist.move(fromOffsets: source, toOffset: destination)
        watchlistState.saveTVShowWatchlistOrder()
    }
    
    private func scheduleCustomNotificationForTVShow(tvShow: TVShowWatchlist, at date: Date, username: String) {
        let content = UNMutableNotificationContent()
        content.title = "TV Show Reminder"
        content.body = "Don't forget to watch '\(tvShow.name)'!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "digital-beeping.caf"))
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
                    applyTVShowSort()
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
        guard let currentUser = auth.currentUser else { return }
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.scheduledNotifications = requests.filter {
                    $0.identifier.contains(currentUser.username) &&
                    ($0.identifier.hasPrefix("reminder_") || $0.identifier.hasPrefix("custom_reminder_"))
                }
                self.applyTVShowSort()
            }
        }
    }
}

struct TVShowWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TVShowWatchlistView()
                .environmentObject(WatchlistState.sampleTVShowWatchlist())
                .environmentObject(AuthViewModel())
                .environmentObject(TabBarVisibilityManager())
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
