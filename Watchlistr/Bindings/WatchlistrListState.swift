//
//  WatchlistrListState.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

//MovieListState
@MainActor
class MovieListState: ObservableObject {
    @Published var movies: [Movie]?
    @Published var isLoading = false
    @Published var error: NSError?
    
    private let movieService: MovieService
    
    init(movieService: MovieService = MovieStore.shared) {
        self.movieService = movieService
    }
    
    func loadMovies(with endpoint: MovieListEndpoint) async {
        self.movies = nil
        self.isLoading = true
        
        do {
            let movies = try await movieService.fetchMovies(from: endpoint)
            self.isLoading = false
            self.movies = movies
        } catch {
            self.isLoading = false
            self.error = error as NSError
        }
    }
}

//TVShowListState
@MainActor
class TVShowListState: ObservableObject {
    @Published var tvshows: [TVShow]?
    @Published var isLoading = false
    @Published var error: NSError?
    
    private let tvshowService: TVShowService
    
    init(tvshowService: TVShowService = TVShowStore.shared) {
        self.tvshowService = tvshowService
    }
    
    func loadTVShows(with endpoint: TVShowListEndpoint) async {
        self.tvshows = nil
        self.isLoading = true
        
        do {
            let tvshows = try await tvshowService.fetchTVShows(from: endpoint)
            self.isLoading = false
            self.tvshows = tvshows
        } catch {
            self.isLoading = false
            self.error = error as NSError
        }
    }
}
