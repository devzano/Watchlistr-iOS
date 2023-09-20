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

        let movieWatchlist = MovieWatchlist(id: movie.id, title: movie.title, backdropPath: movie.backdropPath, posterPath: movie.posterPath, overview: movie.overview)

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
                print("Error encoding movie: \(error)")
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
            print("Error encoding movie: \(error)")
        }
    }
    
    func addTVShowToWatchlist(tvShow: TVShow) {
        guard let userID = self.userID else { return }

        let tvShowWatchlist = TVShowWatchlist(id: tvShow.id, name: tvShow.name, backdropPath: tvShow.backdropPath, posterPath: tvShow.posterPath, overview: tvShow.overview)

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
                print("Error encoding TV show: \(error)")
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
            print("Error encoding TV show: \(error)")
        }
    }

    
    func fetchWatchlist() {
        guard let userID = self.userID else { return }
        
        let db = Firestore.firestore()
        db.collection("watchlists").document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
                do {
                    if let moviesData = document.get("movies") as? [[String: Any]] {
                        self.mWatchlist = try moviesData.map {
                            try JSONSerialization.data(withJSONObject: $0, options: [])
                        }.map {
                            try JSONDecoder().decode(MovieWatchlist.self, from: $0)
                        }
                    }
                    
                    if let tvShowsData = document.get("tvShows") as? [[String: Any]] {
                        self.tvWatchlist = try tvShowsData.map {
                            try JSONSerialization.data(withJSONObject: $0, options: [])
                        }.map {
                            try JSONDecoder().decode(TVShowWatchlist.self, from: $0)
                        }
                    }
                } catch {
                    print("Error decoding watchlist: \(error)")
                }
            } else {
                print("Document does not exist")
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
                print("Error clearing watchlist: \(error)")
            } else {
                print("Watchlist cleared successfully")
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
                print("Error clearing watchlist: \(error)")
            } else {
                print("Watchlist cleared successfully")
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
