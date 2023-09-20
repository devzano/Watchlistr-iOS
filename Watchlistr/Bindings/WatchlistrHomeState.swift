//
//  WatchlistrHomeState.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation

//MovieHomeState
@MainActor
class MovieHomeState: ObservableObject {
    
    @Published private(set) var phase: DataFetchPhase<[MovieSection]> = .empty
    private let movieService: MovieService = MovieStore.shared
    
    var sections: [MovieSection] {
        phase.value ?? []
    }
    
    func loadMoviesFromAllEndpoints(invalidateCache: Bool) async {
        if Task.isCancelled { return }
        if case .success = phase, !invalidateCache {
            return
        }
        phase = .empty
        do {
            let sections = try await fetchMoviesFromEndpoints()
            if Task.isCancelled { return }
            phase = .success(sections)
        } catch {
            if Task.isCancelled { return }
            phase = .failure(error)
        }
    }
    
    private func fetchMoviesFromEndpoints(
        _ endpoints: [MovieListEndpoint] = MovieListEndpoint.allCases) async throws -> [MovieSection] {
        let results: [Result<MovieSection, Error>] = await withTaskGroup(of: Result<MovieSection, Error>.self) { group in
            for endpoint in endpoints {
                group.addTask { await self.fetchMoviesFromEndpoint(endpoint) }
            }
            var results = [Result<MovieSection, Error>]()
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        var movieSections = [MovieSection]()
        var errors = [Error]()
        
        results.forEach { result in
            switch result {
            case .success(let movieSection):
                movieSections.append(movieSection)
            case .failure(let error):
                errors.append(error)
            }
        }
        
        if errors.count == results.count, let error = errors.first {
            throw error
        }

        return movieSections.sorted { $0.endpoint.sortIndex < $1.endpoint.sortIndex }
    }
    
    
    private func fetchMoviesFromEndpoint(_ endpoint: MovieListEndpoint) async -> Result<MovieSection, Error> {
        do {
            let movies = try await movieService.fetchMovies(from: endpoint)
            return .success(.init(
                movies: movies,
                endpoint: endpoint)
            )
        } catch {
            return .failure(error)
        }
    }
}

fileprivate extension MovieListEndpoint {
    
    var sortIndex: Int {
        switch self {
        case .nowPlaying:
            return 0
        case .upcoming:
            return 1
        case .topRated:
            return 2
        case .popular:
            return 3
        }
    }
}

//TVShowHomeState
@MainActor
class TVShowHomeState: ObservableObject {
    
    @Published private(set) var phase: DataFetchPhase<[TVShowSection]> = .empty
    private let tvshowService: TVShowService = TVShowStore.shared
    
    var sections: [TVShowSection] {
        phase.value ?? []
    }
    
    func loadTVShowsFromAllEndpoints(invalidateCache: Bool) async {
        if Task.isCancelled { return }
        if case .success = phase, !invalidateCache {
            return
        }
        phase = .empty
        do {
            let sections = try await fetchTVShowsFromEndpoints()
            if Task.isCancelled { return }
            phase = .success(sections)
        } catch {
            if Task.isCancelled { return }
            phase = .failure(error)
        }
    }
    
    private func fetchTVShowsFromEndpoints(
        _ endpoints: [TVShowListEndpoint] = TVShowListEndpoint.allCases) async throws -> [TVShowSection] {
        let results: [Result<TVShowSection, Error>] = await withTaskGroup(of: Result<TVShowSection, Error>.self) { group in
            for endpoint in endpoints {
                group.addTask { await self.fetchTVShowsFromEndpoint(endpoint) }
            }
            var results = [Result<TVShowSection, Error>]()
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        var tvshowSections = [TVShowSection]()
        var errors = [Error]()
        
        results.forEach { result in
            switch result {
            case .success(let tvshowSection):
                tvshowSections.append(tvshowSection)
            case .failure(let error):
                errors.append(error)
            }
        }
        
        if errors.count == results.count, let error = errors.first {
            throw error
        }

        return tvshowSections.sorted { $0.endpoint.sortIndex < $1.endpoint.sortIndex }
    }
    
    
    private func fetchTVShowsFromEndpoint(_ endpoint: TVShowListEndpoint) async -> Result<TVShowSection, Error> {
        do {
            let tvshows = try await tvshowService.fetchTVShows(from: endpoint)
            return .success(.init(
                tvshows: tvshows,
                endpoint: endpoint)
            )
        } catch {
            return .failure(error)
        }
    }
}

fileprivate extension TVShowListEndpoint {
    
    var sortIndex: Int {
        switch self {
        case .airingToday:
            return 0
        case .onTheAir:
            return 1
        case .topRated:
            return 2
        case .popular:
            return 3
        }
    }
}

