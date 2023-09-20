//
//  WatchlistrServices.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation

//MovieService
protocol MovieService {
    func fetchMovies(from endpoint: MovieListEndpoint) async throws -> [Movie]
    func fetchMovie(id: Int) async throws -> Movie
    func searchMovie(query: String) async throws -> [Movie]
}

enum MovieListEndpoint: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case nowPlaying = "now_playing"
    case upcoming
    case topRated = "top_rated"
    case popular

    var description: String {
        switch self {
        case .nowPlaying: return "Now Playing"
        case .upcoming: return "Upcoming"
        case .topRated: return "Top Rated"
        case .popular: return "Popular"
        }
    }
}

enum MovieError: Error, CustomNSError {
    case apiError
    case invalidEndpoint
    case invalidResponse
    case noData
    case serializationError

    var localizedDescription: String {
        switch self {
        case .apiError: return "Failed To Fetch Data"
        case .invalidEndpoint: return "Invalid Endpoint"
        case .invalidResponse: return "Invalid Response"
        case .noData: return "No Data Found"
        case .serializationError: return "Failed To Decode Data"
        }
    }

    var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }
}

//TVShowService
protocol TVShowService {
    func fetchTVShows(from endpoint: TVShowListEndpoint) async throws -> [TVShow]
    func fetchTVShow(id: Int) async throws -> TVShow
    func searchTVShow(query: String) async throws -> [TVShow]
}

enum TVShowListEndpoint: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case airingToday = "airing_today"
    case onTheAir = "on_the_air"
    case topRated = "top_rated"
    case popular

    var description: String {
        switch self {
        case .airingToday: return "Airing Today"
        case .onTheAir: return "On The Air"
        case .topRated: return "Top Rated"
        case .popular: return "Popular"
        }
    }
}

enum TVShowError: Error, CustomNSError {
    case apiError
    case invalidEndpoint
    case invalidResponse
    case noData
    case serializationError

    var localizedDescription: String {
        switch self {
        case .apiError: return "Failed To Fetch Data"
        case .invalidEndpoint: return "Invalid Endpoint"
        case .invalidResponse: return "Invalid Response"
        case .noData: return "No Data Found"
        case .serializationError: return "Failed To Decode Data"
        }
    }

    var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }
}
