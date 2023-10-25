//
//  WatchlistrDetailState.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
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

@MainActor
class MovieWatchProvidersState: ObservableObject {
    @Published var movieWatchProviders: WatchProvidersResponse?
    @Published var phase: DataFetchPhase = .empty
    
    enum DataFetchPhase {
        case empty
        case loading
        case success
        case failure
    }
    
    func loadMovieWatchProviders(forMovie movieID: Int) async {
        self.phase = .loading
        
        do {
            let providers = try await MovieStore.shared.fetchMovieWatchProviders(forMovie: movieID)
            self.movieWatchProviders = providers
            self.phase = .success
        } catch {
            self.phase = .failure
        }
    }
}

@MainActor
class MovieImagesState: ObservableObject {
    private let movieService: MovieService
    @Published private(set) var phase: DataFetchPhase<MovieImages?> = .empty
    
    var movieImages: MovieImages? {
        phase.value ?? nil
    }
    
    init(movieService: MovieService = MovieStore.shared) {
        self.movieService = movieService
    }
    
    func loadMovieImages(id: Int) async {
        if Task.isCancelled { return }
        
        phase = .empty
        
        do {
            let movieImages = try await self.movieService.fetchMovieImages(id: id)
            phase = .success(movieImages)
        } catch {
            phase = .failure(error)
        }
    }
}

//TVShowDetailState
@MainActor
class TVShowDetailState: ObservableObject {
    private let tvShowService: TVShowService
    @Published private(set) var phase: DataFetchPhase<TVShow?> = .empty
    
    var tvShow: TVShow? {
        phase.value ?? nil
    }
    
    init(tvshowService: TVShowService = TVShowStore.shared) {
        self.tvShowService = tvshowService
    }
    
    func loadTVShow(id: Int) async {
        if Task.isCancelled { return }
        
        phase = .empty
        
        do {
            let tvshow = try await self.tvShowService.fetchTVShow(id: id)
            phase = .success(tvshow)
        } catch {
            phase = .failure(error)
        }
    }
}

@MainActor
class TVShowWatchProvidersState: ObservableObject {
    @Published var tvShowWatchProviders: WatchProvidersResponse?
    @Published var phase: DataFetchPhase = .empty
    
    enum DataFetchPhase {
        case empty
        case loading
        case success
        case failure
    }
    
    func loadTVShowWatchProviders(forTVShow tvShowID: Int, wpSeason: Int) async {
        self.phase = .loading

        do {
            let providers = try await TVShowStore.shared.fetchWatchProviders(forTVShow: tvShowID, wpSeason: 1)
            self.tvShowWatchProviders = providers
            self.phase = .success
        } catch {
            self.phase = .failure
        }
    }
}

@MainActor
class TVShowSeriesImagesState: ObservableObject {
    private let tvShowService: TVShowService
    @Published private(set) var phase: DataFetchPhase<TVShowSeriesImages?> = .empty
    
    var tvShowSeriesImages: TVShowSeriesImages? {
        phase.value ?? nil
    }
    
    init(tvShowService: TVShowService = TVShowStore.shared) {
        self.tvShowService = tvShowService
    }
    
    func loadTVShowSeriesImages(id: Int) async {
        if Task.isCancelled { return }
        
        phase = .empty
        
        do {
            let seriesImages = try await self.tvShowService.fetchTVShowSeriesImages(id: id)
            phase = .success(seriesImages)
        } catch {
            phase = .failure(error)
        }
    }
}
