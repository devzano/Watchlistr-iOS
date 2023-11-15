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
    func fetchMovieImages(id: Int) async throws -> MovieImages
    func searchMovie(query: String) async throws -> [Movie]
}

enum MovieListEndpoint: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case nowPlaying
    case upcoming
    case mostRated
    case popular

    var description: String {
        switch self {
        case .nowPlaying: return "Now Playing"
        case .upcoming: return "Upcoming"
        case .mostRated: return "Most Rated"
        case .popular: return "Popular"
        }
    }
    
    var params: [String: String] {
        switch self {
        case .nowPlaying:
            let calendar = Calendar.current
            let now = Date()
            let currentYear = calendar.component(.year, from: now)
            let componentsForStartOfMonth = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: componentsForStartOfMonth)!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let firstDayOfMonth = dateFormatter.string(from: startOfMonth)
            let currentDate = dateFormatter.string(from: now)

            return [
                "with_release_type": "3",
                "primary_release_date.gte": firstDayOfMonth,
                "primary_release_date.lte": currentDate,
                "sort_by": "popularity.desc",
                "primary_release_year": "\(currentYear)",
                "include_adult": "false",
                "include_null_first_air_dates": "false"
            ]
        case .upcoming:
            let calendar = Calendar.current
            let now = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDay = dateFormatter.string(from: now)
            let componentsForEndOfMonth = DateComponents(month: 1, day: -1)
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: componentsForEndOfMonth, to: startOfMonth)!
            let lastDayOfMonth = dateFormatter.string(from: endOfMonth)
            
            return [
                "primary_release_date.gte": currentDay,
                "primary_release_date.lte": lastDayOfMonth,
                "sort_by": "popularity.desc",
                "include_adult": "false",
                "include_null_first_air_dates": "false"
            ]
        case .mostRated:
            return [
                "sort_by": "vote_count.desc",
                "include_adult": "false",
                "include_null_first_air_dates": "false"
            ]
        case .popular:
            return [
                "sort_by": "popularity.desc",
                "include_adult": "false",
                "include_null_first_air_dates": "false"
            ]
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
    func fetchExternalIDs(forSeries seriesID: Int) async throws -> TVShowExternalIDs
    func fetchTVShowSeriesImages(id: Int) async throws -> TVShowSeriesImages
    func searchTVShow(query: String) async throws -> [TVShow]
}

enum TVShowListEndpoint: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case airingToday
    case thisYear
    case popular
    case mostRated

    var description: String {
        switch self {
        case .airingToday: return "Airing Today"
        case .thisYear: return "This Year"
        case .mostRated: return "Most Rated"
        case .popular: return "Popular"
        }
    }

    var params: [String: String] {
        switch self {
        case .airingToday:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDate = dateFormatter.string(from: Date())
            
            return [
                "air_date.gte": currentDate,
                "air_date.lte": currentDate,
                "include_adult": "false",
                "include_null_first_air_dates": "false"
            ]
        case .thisYear:
            let currentYear = Calendar.current.component(.year, from: Date())
            
            return [
                "first_air_date_year": "\(currentYear)",
                "include_adult": "false",
                "include_null_first_air_dates": "false"
            ]
        case .mostRated:
            return [
                "sort_by": "vote_count.desc",
                "include_adult": "false",
                "include_null_first_air_dates": "false"
            ]
        case .popular:
            return [
                "sort_by": "popularity.desc",
                "include_adult": "false",
                "include_null_first_air_dates": "false"
            ]
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
