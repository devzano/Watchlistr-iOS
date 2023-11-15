//
//  WatchlistState.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/15/23.
//

import SwiftUI
import Combine
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftMessages

class WatchlistState: ObservableObject {
    @ObservedObject var vm = AuthViewModel()
    @Published var mWatchlist: [MovieWatchlist] = []
    @Published var tvWatchlist: [TVShowWatchlist] = []
    @Published var filteredMovies: [MovieWatchlist] = []
    @Published var filteredTVShows: [TVShowWatchlist] = []
    @Published var watchlistPhase: DataFetchPhase<Void> = .empty
    
    var userID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        Task {
            fetchWatchlist()
        }
    }
    
    func reset() {
        self.mWatchlist = []
        self.tvWatchlist = []
    }
    
    func addMovieToWatchlist(movie: Movie) {
        guard let userID = self.userID else { return }

        let movieWatchlist = MovieWatchlist(
            id: movie.id,
            title: movie.title,
            releaseDate: movie.releaseDate,
            backdropPath: movie.backdropPath,
            posterPath: movie.posterPath,
            overview: movie.overview,
            watched: false)
        DispatchQueue.main.async {
            self.mWatchlist.append(movieWatchlist)
            self.watchlistPhase = .success(())
        }

        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)

        docRef.getDocument { (document, error) in
            do {
                let movieData = try movieWatchlist.toFirestoreData()
                if let document = document, document.exists {
                    docRef.updateData([
                        "movies": FieldValue.arrayUnion([movieData])
                    ])
                } else {
                    docRef.setData([
                        "movies": [movieData]
                    ])
                }
            } catch {
                showError(message: "Error adding movie to watchlist: \(error.localizedDescription)")
            }
        }
    }
    
    func removeMovieFromWatchlist(movie: MovieWatchlist) {
        guard let userID = self.userID else { return }
        
        mWatchlist.removeAll { $0.id == movie.id }
        
        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)
        
        do {
            let movieData = try movie.toFirestoreData()
            docRef.updateData([
                "movies": FieldValue.arrayRemove([movieData])
            ])
        } catch {
            showError(message: "Error removing movie to watchlist: \(error.localizedDescription)")
        }
    }
    
    func addTVShowToWatchlist(tvShow: TVShow) {
        guard let userID = self.userID else { return }

        let tvShowWatchlist = TVShowWatchlist(
            id: tvShow.id,
            name: tvShow.name,
            backdropPath: tvShow.backdropPath,
            posterPath: tvShow.posterPath,
            overview: tvShow.overview,
            watched: false)

        DispatchQueue.main.async {
            self.tvWatchlist.append(tvShowWatchlist)
            self.watchlistPhase = .success(())
        }

        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)

        docRef.getDocument { (document, error) in
            do {
                let tvShowData = try tvShowWatchlist.toFirestoreData()
                if let document = document, document.exists {
                    docRef.updateData([
                        "tvShows": FieldValue.arrayUnion([tvShowData])
                    ])
                } else {
                    docRef.setData([
                        "tvShows": [tvShowData]
                    ])
                }
            } catch {
                showError(message: "Error adding TV show to watchlist: \(error.localizedDescription)")
            }
        }
    }
    
    func removeTVShowFromWatchlist(tvShow: TVShowWatchlist) {
        guard let userID = self.userID else { return }
        
        tvWatchlist.removeAll { $0.id == tvShow.id }
        
        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)
        
        do {
            let tvShowData = try tvShow.toFirestoreData()
            docRef.updateData([
                "tvShows": FieldValue.arrayRemove([tvShowData])
            ])
        } catch {
            showError(message: "Error removing TV show to watchlist: \(error.localizedDescription)")
        }
    }

    
    func fetchWatchlist() {
        guard let userID = self.userID else { return }
        
        let db = Firestore.firestore()
        db.collection("watchlists").document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
                var isEmpty = true
                
                do {
                    if let moviesData = document.get("movies") as? [[String: Any]], !moviesData.isEmpty {
                        self.mWatchlist = try moviesData.map {
                            try JSONSerialization.data(withJSONObject: $0, options: [])
                        }.map {
                            try JSONDecoder().decode(MovieWatchlist.self, from: $0)
                        }
                        isEmpty = false
                    }
                    
                    if let tvShowsData = document.get("tvShows") as? [[String: Any]], !tvShowsData.isEmpty {
                        self.tvWatchlist = try tvShowsData.map {
                            try JSONSerialization.data(withJSONObject: $0, options: [])
                        }.map {
                            try JSONDecoder().decode(TVShowWatchlist.self, from: $0)
                        }
                        isEmpty = false
                    }
                    
                    if isEmpty {
                        showMessage(withTitle: "Watchlists", message: "No media in your watchlists. Add movies or shows to track them!", theme: .info, duration: 3.0)
                    }
                } catch {
                    showError(message: "Error decoding watchlist: \(error.localizedDescription)")
                }
            } else {
                showMessage(withTitle: "Watchlists", message: "No media in your watchlists. Add movies or shows to track them!", theme: .info, duration: 5.0)
            }
        }
    }
    
    func clearMovieWatchlist() {
        guard let userID = self.userID else { return }
        mWatchlist.removeAll()
        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)
        docRef.updateData([
            "movies": FieldValue.delete()
        ]) { error in
            if let error = error {
                showError(message: "Error clearing watchlist: \(error.localizedDescription)")
            } else {
                showSuccess(message: "Watchlist cleared successfully")
            }
        }
    }
    
    func clearTVShowWatchlist() {
        guard let userID = self.userID else { return }
        tvWatchlist.removeAll()
        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)
        docRef.updateData([
            "tvShows": FieldValue.delete()
        ]) { error in
            if let error = error {
                showError(message: "Error clearing watchlist: \(error.localizedDescription)")
            } else {
                showSuccess(message: "Watchlist cleared successfully")
            }
        }
    }
    
    func searchWatchlistMovies(query: String) -> [MovieWatchlist] {
        return mWatchlist.filter { $0.title.lowercased().contains(query.lowercased()) }
    }
        
    func searchWatchlistTVShows(query: String) -> [TVShowWatchlist] {
        return tvWatchlist.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
    
    func updateFilteredLists(query: String) {
        filteredMovies = searchWatchlistMovies(query: query)
        filteredTVShows = searchWatchlistTVShows(query: query)
    }
    
    func watchedMovieInFirestore(movie: MovieWatchlist) {
        guard let userID = self.userID else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if var movies = document.get("movies") as? [[String: Any]] {
                    if let index = movies.firstIndex(where: { ($0["id"] as? Int) == movie.id }) {
                        do {
                            let movieData = try movie.toFirestoreData()
                            movies[index] = movieData
                            docRef.updateData([
                                "movies": movies
                            ])
                        } catch {
                            showError(message: "Error encoding movie: \(error)")
                        }
                    }
                }
            }
        }
    }

    func watchedTVShowInFirestore(tvShow: TVShowWatchlist) {
        guard let userID = self.userID else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if var tvShows = document.get("tvShows") as? [[String: Any]] {
                    if let index = tvShows.firstIndex(where: { ($0["id"] as? Int) == tvShow.id }) {
                        do {
                            let tvShowData = try tvShow.toFirestoreData()
                            tvShows[index] = tvShowData
                            docRef.updateData([
                                "tvShows": tvShows
                            ])
                        } catch {
                            showError(message: "Error encoding TV show: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func toggleEpisodeWatchStatus(tvShowID: Int, seasonNumber: Int, episodeID: Int) {
        if let index = tvWatchlist.firstIndex(where: { $0.id == tvShowID }) {
            var tvShow = tvWatchlist[index]
            var watchedEpisodesForSeason = tvShow.watchedEpisodes[seasonNumber, default: []]
            
            if watchedEpisodesForSeason.contains(episodeID) {
                watchedEpisodesForSeason.removeAll { $0 == episodeID }
            } else {
                watchedEpisodesForSeason.append(episodeID)
            }
            
            tvShow.watchedEpisodes[seasonNumber] = watchedEpisodesForSeason
            tvWatchlist[index] = tvShow
            watchedTVShowInFirestore(tvShow: tvShow)
        } else {
            showError(message: "TV Show not found in watchlist!")
        }
    }

    func isEpisodeWatched(tvShowID: Int, seasonNumber: Int, episodeID: Int) -> Bool {
        if let tvShow = tvWatchlist.first(where: { $0.id == tvShowID }) {
            return tvShow.watchedEpisodes[seasonNumber]?.contains(episodeID) ?? false
        }
        return false
    }

    func watchedEpisodesCountForTVShow(tvShowID: Int) -> Int {
        guard let tvShow = tvWatchlist.first(where: { $0.id == tvShowID }) else {
            return 0
        }
        return tvShow.watchedEpisodes.values.reduce(0) { $0 + $1.count }
    }

    func totalWatchedEpisodesCount() -> Int {
        tvWatchlist.reduce(0) { $0 + $1.watchedEpisodes.values.reduce(0) { $0 + $1.count } }
    }

    
    func watchedEpisodesCountForSeason(tvShowID: Int, seasonNumber: Int) -> Int {
        guard let tvShow = tvWatchlist.first(where: { $0.id == tvShowID }) else {
            return 0
        }
        return tvShow.watchedEpisodesCountForSeason(seasonNumber: seasonNumber)
    }

    func saveMovieWatchlistOrder() {
        guard let userID = self.userID else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)
        
        do {
            let moviesData = try self.mWatchlist.map { try $0.toFirestoreData() }
            docRef.updateData([
                "movies": moviesData
            ]) { error in
                if let error = error {
                    showError(message: "Error saving movie watchlist order: \(error.localizedDescription)")
                }
            }
        } catch {
            showError(message: "Error encoding movies: \(error.localizedDescription)")
        }
    }

    func saveTVShowWatchlistOrder() {
        guard let userID = self.userID else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("watchlists").document(userID)
        
        do {
            let tvShowsData = try self.tvWatchlist.map { try $0.toFirestoreData() }
            docRef.updateData([
                "tvShows": tvShowsData
            ]) { error in
                if let error = error {
                    showError(message: "Error saving TV show watchlist order: \(error.localizedDescription)")
                }
            }
        } catch {
            showError(message: "Error encoding TV shows: \(error.localizedDescription)")
        }
    }

}

extension MovieWatchlist {
    func toFirestoreData() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let dict = json as? [String: Any] {
            return dict
        } else {
            throw NSError()
        }
    }
}

extension TVShowWatchlist {
    func toFirestoreData() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let dict = json as? [String: Any] {
            return dict
        } else {
            throw NSError()
        }
    }
}
