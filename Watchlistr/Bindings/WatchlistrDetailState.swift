//
//  WatchlistrDetailState.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 6/9/23.
//

import SwiftUI

//MovieDetailState
@MainActor
class MovieDetailState: ObservableObject {
    private let movieService: MovieService
    @Published private(set) var phase: DataFetchPhase<Movie?> = .empty
    var movie: Movie? {
        phase.value ?? nil
    }
    
    init(movieService: MovieService = MovieStore.shared) {
        self.movieService = movieService
    }
    
    func loadMovie(id: Int) async {
        if Task.isCancelled { return }
        
        phase = .empty
        
        do {
            let movie = try await self.movieService.fetchMovie(id: id)
            phase = .success(movie)
        } catch {
            phase = .failure(error)
        }
    }
}

//TVShowDetailState
@MainActor
class TVShowDetailState: ObservableObject {
    private let tvshowService: TVShowService
    @Published private(set) var phase: DataFetchPhase<TVShow?> = .empty
    var tvshow: TVShow? {
        phase.value ?? nil
    }
    
    init(tvshowService: TVShowService = TVShowStore.shared) {
        self.tvshowService = tvshowService
    }
    
    func loadTVShow(id: Int) async {
        if Task.isCancelled { return }
        
        phase = .empty
        
        do {
            let tvshow = try await self.tvshowService.fetchTVShow(id: id)
            phase = .success(tvshow)
        } catch {
            phase = .failure(error)
        }
    }
}
