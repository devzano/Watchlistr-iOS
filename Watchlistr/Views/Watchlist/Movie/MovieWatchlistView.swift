//
//  MovieWatchlistView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/15/23.
//

import Foundation
import Combine
import SwiftUI
import UserNotifications
import SwiftMessages

struct MovieSortOptions {
    var alphabetical: Bool = false
    var reverseAlphabetical: Bool = false
    var watched: Bool = false
    var reminded: Bool = false
}

struct MovieWatchlistView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @State private var searchQuery = ""
    @State private var setNotifForMovie: Date = Date()
    @State private var datePickerForMovie: Int?
    @State private var scheduledNotifications: [UNNotificationRequest] = []
    @State private var sortOrder = MovieSortOptions()
    @State private var sortHasPriority: Bool = true
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var filteredMovies: [MovieWatchlist] {
        if searchQuery.isEmpty {
            return watchlistState.mWatchlist
        } else {
            return watchlistState.searchWatchlistMovies(query: searchQuery)
        }
    }
    
    private func applyMovieSort() {
        watchlistState.mWatchlist.sort { firstMovie, secondMovie in
            if sortHasPriority {
                if sortOrder.watched {
                    if firstMovie.watched != secondMovie.watched {
                        return firstMovie.watched && !secondMovie.watched
                    }
                }

                if sortOrder.reminded {
                    let firstIsReminded = isNotifiSetForMovieWatchlist(firstMovie.id)
                    let secondIsReminded = isNotifiSetForMovieWatchlist(secondMovie.id)
                    if firstIsReminded != secondIsReminded {
                        return firstIsReminded && !secondIsReminded
                    }
                }
            } else {
                if sortOrder.reminded {
                    let firstIsReminded = isNotifiSetForMovieWatchlist(firstMovie.id)
                    let secondIsReminded = isNotifiSetForMovieWatchlist(secondMovie.id)
                    if firstIsReminded != secondIsReminded {
                        return firstIsReminded && !secondIsReminded
                    }
                }

                if sortOrder.watched {
                    if firstMovie.watched != secondMovie.watched {
                        return firstMovie.watched && !secondMovie.watched
                    }
                }
            }

            if sortOrder.alphabetical {
                return firstMovie.title < secondMovie.title
            } else if sortOrder.reverseAlphabetical {
                return firstMovie.title > secondMovie.title
            }

            return firstMovie.id < secondMovie.id
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if watchlistState.mWatchlist.isEmpty {
                EmptyPlaceholderView(text: "All your favorite movies will be listed here. Start adding!", image: Image(systemName: "film"))
                    .navigationTitle("Watchlist")
            } else {
                SearchBarView(placeholder: "search", text: $searchQuery)
                List {
                    ForEach(filteredMovies) { movie in
                        NavigationLink(destination: MovieDetailView(movieID: movie.id, movieTitle: movie.title)) {
                            WatchlistMovieRowView(movie: movie, isNotifiSet: isNotifiSetForMovieWatchlist(movie.id))
                        }
                        .contextMenu {
                            Button(action: {
                                withAnimation {
                                    watchlistState.toggleWatchedStatus(of: movie)
                                    applyMovieSort()
                                }
                            }) {
                                Text(movie.watched ? "Watched!" : "Watched")
                                Image(systemName: movie.watched ? "checkmark.circle.fill" : "circle")
                            }
                            
                            if isNotifiSetForMovieWatchlist(movie.id) {
                                Text("Reminder Set!")
                                    .foregroundColor(.gray)
                            } else {
                                Button(action: {
                                    if !isMovieAlreadyReleased(movie: movie) {
                                        if !isNotifiSetForMovieWatchlist(movie.id) {
                                            requestNotificationPermission { granted in
                                                if granted {
                                                    scheduleNotification(for: movie, username: auth.currentUser?.username ?? "default")
                                                } else {
                                                    DispatchQueue.main.async {
                                                        showError(withTitle: "Permission Denied",
                                                                  message: "To enable notifications for Watchlistr, please navigate to your device's settings and grant permission.", duration: 5.0)
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        if !isNotifiSetForMovieWatchlist(movie.id) {
                                            if datePickerForMovie == movie.id {
                                                datePickerForMovie = nil
                                                return
                                            }
                                            requestNotificationPermission { granted in
                                                if granted {
                                                    setNotifForMovie = Date()
                                                    datePickerForMovie = movie.id
                                                } else {
                                                    DispatchQueue.main.async {
                                                        showError(withTitle: "Permission Denied",
                                                                  message: "To enable notifications for Watchlistr, please navigate to your device's settings and grant permission.", duration: 5.0)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    applyMovieSort()
                                }) {
                                    HStack {
                                        Image(systemName: isMovieAlreadyReleased(movie: movie) ? "clock" : "bell")
                                        Text(isNotifiSetForMovieWatchlist(movie.id) ? "Reminded!" : (isMovieAlreadyReleased(movie: movie) ? "Set A Reminder" : "Remind Me On Release"))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(5)
                                    .background(Color.yellow.opacity(0.7))
                                    .cornerRadius(5)
                                    .opacity(isNotifiSetForMovieWatchlist(movie.id) ? 0.5 : 1.0)
                                    .disabled(isNotifiSetForMovieWatchlist(movie.id))
                                }.buttonStyle(.borderless)
                            }
                        }
                        .overlay(
                            Group {
                                if datePickerForMovie == movie.id {
                                    VStack {
                                        DatePicker("Choose a date and time", selection: $setNotifForMovie, displayedComponents: [.date, .hourAndMinute])
                                        
                                        HStack {
                                            Button("Cancel") {
                                                datePickerForMovie = nil
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.horizontal, 10)
                                            .background(Color.red.opacity(0.8))
                                            .foregroundColor(.primary)
                                            .cornerRadius(8)
                                            
                                            Button(action: {
                                                if let currentUser = auth.currentUser {
                                                    scheduleCustomNotificationForMovie(movie: movie, at: setNotifForMovie, username: currentUser.username)
                                                    datePickerForMovie = nil
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
                        let moviesToDelete = indices.map { watchlistState.mWatchlist[$0] }
                        for movie in moviesToDelete {
                            watchlistState.removeMovieFromWatchlist(movie: movie)
                        }
                    }
                    .onMove(perform: moveMovie)
                }
                .listStyle(PlainListStyle())
                .onAppear {
                    loadMovieWatchlistNotifis()
                    sortOrder.alphabetical = UserDefaults.standard.bool(forKey: "sortMovieAlphabetical")
                    sortOrder.reverseAlphabetical = UserDefaults.standard.bool(forKey: "sortMovieReverseAlphabetical")
                    sortOrder.watched = UserDefaults.standard.bool(forKey: "sortMovieWatched")
                    sortOrder.reminded = UserDefaults.standard.bool(forKey: "sortMovieReminded")
                    applyMovieSort()
                }
            }
        }
        .navigationBarItems(trailing: Menu {
            Button(action: {
                sortHasPriority.toggle()
                applyMovieSort()
            }) {
                Label(sortHasPriority ? "Priority: Watched" : "Priority: Reminded", systemImage: sortHasPriority ? "eye" : "bell")
            }
            
            Button(action: {
                sortOrder.alphabetical.toggle()
                UserDefaults.standard.set(sortOrder.alphabetical, forKey: "sortMovieAlphabetical")
                applyMovieSort()
            }) {
                let sortImageName = sortOrder.alphabetical ? "text.line.last.and.arrowtriangle.forward" : "text.line.first.and.arrowtriangle.forward"
                let sortName = sortOrder.alphabetical ? "Sort Z-A" : "Sort A-Z"
                Label(sortName, systemImage: sortImageName)
            }

            Button(action: {
                sortOrder.watched.toggle()
                UserDefaults.standard.set(sortOrder.watched, forKey: "sortMovieWatched")
                applyMovieSort()
            }) {
                let sortImageName = sortOrder.watched ? "eye.slash.circle.fill" : "eye.circle.fill"
                Label("Sort by Watched", systemImage: sortImageName)
            }

            Button(action: {
                sortOrder.reminded.toggle()
                UserDefaults.standard.set(sortOrder.reminded, forKey: "sortMovieReminded")
                applyMovieSort()
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
    
    private func moveMovie(from source: IndexSet, to destination: Int) {
        watchlistState.mWatchlist.move(fromOffsets: source, toOffset: destination)
        watchlistState.saveMovieWatchlistOrder()
    }
    
    private func isMovieAlreadyReleased(movie: MovieWatchlist) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let releaseDate = movie.releaseDate, let movieReleaseDate = dateFormatter.date(from: releaseDate) else {
            print("Failed to get movieReleaseDate from releaseDate: \(movie.title)")
            return false
        }
        
        return movieReleaseDate < Date()
    }
    
    private func scheduleCustomNotificationForMovie(movie: MovieWatchlist, at date: Date, username: String) {
        let content = UNMutableNotificationContent()
        content.title = "Movie Reminder"
        content.body = "Don't forget to watch '\(movie.title)'!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "digital-beeping.caf"))
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "custom_reminder_movie_\(username)_\(movie.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                showError(withTitle: "Error", message: "Failed to schedule notification: \(error.localizedDescription)")
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM, dd yyyy hh:mm a"
                let formattedDate = formatter.string(from: date)
                DispatchQueue.main.async {
                    showSuccess(withTitle: "Reminder", message: "'\(movie.title)' scheduled for '\(formattedDate)'", duration: 5.0)
                    applyMovieSort()
                }
                self.loadMovieWatchlistNotifis()
            }
        }
    }
    
    private func scheduleNotification(for movie: MovieWatchlist, username: String) {
        let content = UNMutableNotificationContent()
        content.title = "Movie Reminder"
        content.body = "Don't forget to watch '\(movie.title)'!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "digital-beeping.caf"))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let releaseDate = movie.releaseDate, let movieReleaseDate = dateFormatter.date(from: releaseDate) {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: movieReleaseDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "reminder_movie_\(username)_\(movie.id)", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        showError(withTitle: "Error", message: "Failed to schedule notification: \(error.localizedDescription)")
                    }
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM, dd yyyy"
                    let formattedReleaseDate = formatter.string(from: movieReleaseDate)
                    DispatchQueue.main.async {
                        showSuccess(withTitle: "Reminder Set", message: "'\(movie.title)' scheduled for its release date '\(formattedReleaseDate)'", duration: 5.0)
                        applyMovieSort()
                    }
                }
                loadMovieWatchlistNotifis()
            }
        } else {
            DispatchQueue.main.async {
                showError(withTitle: "Date Not Found", message: "Please set a custom reminder for '\(movie.title)'.")
                self.datePickerForMovie = movie.id
            }
        }
    }
    
    private func isNotifiSetForMovieWatchlist(_ movieID: Int) -> Bool {
        for notification in scheduledNotifications {
            if notification.identifier.contains("\(movieID)") {
                return true
            }
        }
        return false
    }
    
    private func loadMovieWatchlistNotifis() {
        guard let currentUser = auth.currentUser else { return }
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.scheduledNotifications = requests.filter {
                    $0.identifier.contains(currentUser.username) &&
                    ($0.identifier.hasPrefix("reminder_") || $0.identifier.hasPrefix("custom_reminder_"))
                }
                self.applyMovieSort()
            }
        }
    }

}

struct MovieWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieWatchlistView()
                .environmentObject(WatchlistState.sampleMovieWatchlist())
                .environmentObject(AuthViewModel())
                .environmentObject(TabBarVisibilityManager())
        }
    }
}

extension WatchlistState {
    func toggleWatchedStatus(of movie: MovieWatchlist) {
        if let index = mWatchlist.firstIndex(where: { $0.id == movie.id }) {
            mWatchlist[index].watched.toggle()
            watchedMovieInFirestore(movie: mWatchlist[index])
        }
    }
}

extension WatchlistState {
    static func sampleMovieWatchlist() -> WatchlistState {
        let watchlist = WatchlistState()
        let straightOuttaCompton = MovieWatchlist(
            id: 277216,
            title: "Straight Outta Compton",
            releaseDate: "2015-08-11",
            backdropPath: "https://image.tmdb.org/t/p/w500/pvGuQ5wmkENGEvnKQRYv0eS8sOx.jpg",
            posterPath: "https://image.tmdb.org/t/p/w500/9B63hMwU6iICtNDTISCaZQ5US7R.jpg",
            overview: "In 1987, five young men, using brutally honest rhymes and hardcore beats, put their frustration and anger about life in the most dangerous place in America into the most powerful weapon they had: their music.  Taking us back to where it all began, Straight Outta Compton tells the true story of how these cultural rebels—armed only with their lyrics, swagger, bravado and raw talent—stood up to the authorities that meant to keep them down and formed the world’s most dangerous group, N.W.A.  And as they spoke the truth that no one had before and exposed life in the hood, their voice ignited a social revolution that is still reverberating today.",
            watched: false
        )
        let getRichOrDieTryin = MovieWatchlist(
            id: 10060,
            title: "Get Rich or Die Tryin'",
            releaseDate: "2005-11-09",
            backdropPath: "https://image.tmdb.org/t/p/w500/bxJmFRjwWnpoLFkp5OSzA7xfzn6.jpg",
            posterPath: "https://image.tmdb.org/t/p/w500/aaEJu8vFKtrAoSRtw3xjCf1aM5d.jpg",
            overview: "A tale of an inner city drug dealer who turns away from crime to pursue his passion, rap music.",
            watched: true
        )
        watchlist.mWatchlist = [straightOuttaCompton, getRichOrDieTryin]
        return watchlist
    }
}
