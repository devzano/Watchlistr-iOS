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

struct MovieWatchlistView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    @State private var searchQuery = ""
    @State private var setNotifForMovie: Date = Date()
    @State private var datePickerForMovie: Int?
    @State private var scheduledNotifications: [UNNotificationRequest] = []
    
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
                            WatchlistMovieRowView(movie: movie, isNotifiSet: isNotifiSetForMovieWatchlist(movie.id))
                        }
                        .contextMenu {
                            Button(action: {
                                withAnimation {
                                    watchlistState.toggleWatchedStatus(of: movie)
                                }
                            }) {
                                Text(movie.watched ? "Mark as Unwatched" : "Mark as Watched")
                                Image(systemName: movie.watched ? "checkmark.circle.fill" : "circle")
                            }
                            Button(action: {
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
                            }) {
                                Text("Set A Reminder")
                                Image(systemName: "clock")
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
                                            .foregroundColor(.white)
                                            .cornerRadius(8)

                                            Button(action: {
                                                if let currentUser = vm.currentUser {
                                                    scheduleCustomNotificationForMovie(movie: movie, at: setNotifForMovie, username: currentUser.username)
                                                    datePickerForMovie = nil
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
                        let moviesToDelete = indices.map { watchlistState.mWatchlist[$0] }
                        for movie in moviesToDelete {
                            watchlistState.removeMovieFromWatchlist(movie: movie)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Watchlist")
                .navigationBarTitleDisplayMode(.inline)
            }.onAppear {
                loadMovieWatchlistNotifis()
            }
        }
    }
    
    private func scheduleCustomNotificationForMovie(movie: MovieWatchlist, at date: Date, username: String) {
        let content = UNMutableNotificationContent()
        content.title = "Movie Reminder"
        content.body = "Don't forget to watch '\(movie.title)'!"
        content.sound = UNNotificationSound.default
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
                }
                self.loadMovieWatchlistNotifis()
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
        guard let currentUser = vm.currentUser else { return }
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            self.scheduledNotifications = requests.filter {
                $0.identifier.contains(currentUser.username) &&
                $0.identifier.hasPrefix("custom_reminder_movie_")
            }
        }
    }
}

struct WatchlistMovieRowView: View {
    var movie: MovieWatchlist
    var isNotifiSet: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                RemoteImage(url: movie.posterURL, placeholder: Image("PosterNotFound"))
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(movie.title)
                        .font(.headline)
                    
                    Text(movie.overview)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(3)
                }
            }
            .opacity(movie.watched ? 0.5 : 1.0)
            
            VStack (spacing: 5) {
                if movie.watched {
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

struct MovieWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieWatchlistView()
                .environmentObject(WatchlistState.sampleMovieWatchlist())
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
            backdropPath: "https://image.tmdb.org/t/p/w500/pvGuQ5wmkENGEvnKQRYv0eS8sOx.jpg",
            posterPath: "https://image.tmdb.org/t/p/w500/9B63hMwU6iICtNDTISCaZQ5US7R.jpg",
            overview: "In 1987, five young men, using brutally honest rhymes and hardcore beats, put their frustration and anger about life in the most dangerous place in America into the most powerful weapon they had: their music.  Taking us back to where it all began, Straight Outta Compton tells the true story of how these cultural rebels—armed only with their lyrics, swagger, bravado and raw talent—stood up to the authorities that meant to keep them down and formed the world’s most dangerous group, N.W.A.  And as they spoke the truth that no one had before and exposed life in the hood, their voice ignited a social revolution that is still reverberating today.",
            watched: false
        )
        let getRichOrDieTryin = MovieWatchlist(
            id: 10060,
            title: "Get Rich or Die Tryin'",
            backdropPath: "https://image.tmdb.org/t/p/w500/bxJmFRjwWnpoLFkp5OSzA7xfzn6.jpg",
            posterPath: "https://image.tmdb.org/t/p/w500/aaEJu8vFKtrAoSRtw3xjCf1aM5d.jpg",
            overview: "A tale of an inner city drug dealer who turns away from crime to pursue his passion, rap music.",
            watched: true
        )
        watchlist.mWatchlist = [straightOuttaCompton, getRichOrDieTryin]
        return watchlist
    }
}
