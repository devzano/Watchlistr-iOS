//
//  WatchlistrSearchState.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 6/9/23.
//

import SwiftUI
import Combine
import Foundation

//MovieSearchState
@MainActor
class MovieSearchState: ObservableObject {
    
    @Published var query = ""
    @Published private(set) var phase: DataFetchPhase<[Movie]> = .empty
    
    private var cancellables = Set<AnyCancellable>()
    private let movieService: MovieService
    
    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var movies: [Movie] {
        phase.value ?? []
    }
    
    init(movieService: MovieService = MovieStore.shared) {
        self.movieService = movieService
    }
    
    func startObserve() {
        guard cancellables.isEmpty else { return }
        
        $query
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sink { [weak self] _ in
                self?.phase = .empty
            }
            .store(in: &cancellables)
        
        $query
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { query in
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.search(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    func search(query: String) async {
        if Task.isCancelled { return }
        
        phase = .empty
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            return
        }
        
        do {
            let movies = try await movieService.searchMovie(query: trimmedQuery)
            if Task.isCancelled { return }
            guard trimmedQuery == self.trimmedQuery else { return }
            phase = .success(movies)
        } catch {
            if Task.isCancelled { return }
            guard trimmedQuery == self.trimmedQuery else { return }
            phase = .failure(error)
        }
    }
}

//TVShowSearchState
@MainActor
class TVShowSearchState: ObservableObject {
    
    @Published var query = ""
    @Published private(set) var phase: DataFetchPhase<[TVShow]> = .empty
    
    private var cancellables = Set<AnyCancellable>()
    private let tvshowService: TVShowService
    
    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var tvshows: [TVShow] {
        phase.value ?? []
    }
    
    init(tvshowService: TVShowService = TVShowStore.shared) {
        self.tvshowService = tvshowService
    }
    
    func startObserve() {
        guard cancellables.isEmpty else { return }
        
        $query
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sink { [weak self] _ in
                self?.phase = .empty
            }
            .store(in: &cancellables)
        
        $query
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { query in
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.search(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    func search(query: String) async {
        if Task.isCancelled { return }
        
        phase = .empty
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            return
        }
        
        do {
            let tvshows = try await tvshowService.searchTVShow(query: trimmedQuery)
            if Task.isCancelled { return }
            guard trimmedQuery == self.trimmedQuery else { return }
            phase = .success(tvshows)
        } catch {
            if Task.isCancelled { return }
            guard trimmedQuery == self.trimmedQuery else { return }
            phase = .failure(error)
        }
    }
}
