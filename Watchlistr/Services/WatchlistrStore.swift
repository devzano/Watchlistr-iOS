//
//  WatchlistrStore.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation

//MovieStore
class MovieStore: MovieService {
    static let shared = MovieStore()
    private init() {}

    private let apiKey = ["INSERT_API_KEY"]
    private let baseAPIURL = "https://api.themoviedb.org/3"
    private let urlSession = URLSession.shared
    private let jsonDecoder = DateUtils.jsonDecoder

    func fetchMovies(from endpoint: MovieListEndpoint) async throws -> [Movie] {
        guard let url = URL(string: "\(baseAPIURL)/discover/movie") else {
            throw MovieError.invalidEndpoint
        }

        var defaultParams = endpoint.params
        defaultParams["language"] = "en-US"
        defaultParams["with_original_language"] = "en"
        defaultParams["with_origin_country"] = "US"

        let movieResponse: MovieResponse = try await self.loadURLAndDecode(url: url, params: defaultParams)
        return movieResponse.results
    }

    func fetchMovie(id: Int) async throws -> Movie {
        guard let url = URL(string: "\(baseAPIURL)/movie/\(id)") else {
            throw MovieError.invalidEndpoint
        }

        return try await self.loadURLAndDecode(url: url, params: [
            "append_to_response": "videos,credits",
        ])
    }

    func fetchMovieImages(id: Int) async throws -> MovieImages {
        guard let url = URL(string: "\(baseAPIURL)/movie/\(id)/images") else {
            throw MovieError.invalidEndpoint
        }
        return try await self.loadURLAndDecode(url: url, params: [
            "include_image_language": "en,null"
        ])
    }

    func searchMovie(query: String) async throws -> [Movie] {
        guard let url = URL(string: "\(baseAPIURL)/search/movie") else {
            throw MovieError.invalidEndpoint
        }

        let movieResponse: MovieResponse = try await self.loadURLAndDecode(url: url, params: [
            "language": "en-US",
            "include_adult": "false",
            "region": "US",
            "query": query
        ])

        return movieResponse.results
    }

    func fetchMovieWatchProviders(forMovie movieID: Int) async throws -> WatchProvidersResponse {
        guard let url = URL(string: "\(baseAPIURL)/movie/\(movieID)/watch/providers") else {
            throw MovieError.invalidEndpoint
        }

        return try await self.loadURLAndDecode(url: url)
    }

    private func loadURLAndDecode<D: Decodable>(url: URL, params: [String: String]? = nil) async throws -> D {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw MovieError.invalidEndpoint
        }

        var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]

        if let params = params {
            queryItems.append(contentsOf: params.map { URLQueryItem(name: $0.key, value: $0.value) })
        }

        urlComponents.queryItems = queryItems

        guard let finalURL = urlComponents.url else {
            throw MovieError.invalidEndpoint
        }

        let (data, response) = try await urlSession.data(from: finalURL)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MovieError.invalidResponse
        }

        return try self.jsonDecoder.decode(D.self, from: data)
    }
}

//TVShowStore
class TVShowStore: TVShowService {
    static let shared = TVShowStore()
    private init() {}

    private let apiKey = ["INSERT_API_KEY"]
    private let baseAPIURL = "https://api.themoviedb.org/3"
    private let urlSession = URLSession.shared
    private let jsonDecoder = DateUtils.jsonDecoder

    func fetchTVShows(from endpoint: TVShowListEndpoint) async throws -> [TVShow] {
        guard let url = URL(string: "\(baseAPIURL)/discover/tv") else {
            throw TVShowError.invalidEndpoint
        }

        var defaultParams = endpoint.params
        defaultParams["language"] = "en-US"
        defaultParams["with_original_language"] = "en"
        defaultParams["with_origin_country"] = "US"

        let tvshowResponse: TVShowResponse = try await self.loadURLAndDecode(url: url, params: defaultParams)
        return tvshowResponse.results
    }

    func fetchTVShow(id: Int) async throws -> TVShow {
        guard let url = URL(string: "\(baseAPIURL)/tv/\(id)") else {
            throw TVShowError.invalidEndpoint
        }

        return try await self.loadURLAndDecode(url: url, params: [
            "append_to_response": "videos,credits"
        ])
    }

    func fetchTVShowSeriesImages(id: Int) async throws -> TVShowSeriesImages {
        guard let url = URL(string: "\(baseAPIURL)/tv/\(id)/images") else {
            throw TVShowError.invalidEndpoint
        }
        return try await self.loadURLAndDecode(url: url, params: [
            "include_image_language": "en,null"
        ])
    }

    func searchTVShow(query: String) async throws -> [TVShow] {
        guard let url = URL(string: "\(baseAPIURL)/search/tv") else {
            throw TVShowError.invalidEndpoint
        }

        let tvshowResponse: TVShowResponse = try await self.loadURLAndDecode(url: url, params: [
            "language": "en-US",
            "include_adult": "false",
            "query": query
        ])

        return tvshowResponse.results
    }

    func fetchSeasons(forTVShow tvShowID: Int) async throws -> [TVShowSeason] {
        guard let url = URL(string: "\(baseAPIURL)/tv/\(tvShowID)/season") else {
            throw TVShowError.invalidEndpoint
        }
        return try await self.loadURLAndDecode(url: url)
    }

    func fetchEpisodes(forTVShow tvShowID: Int, seasonNumber: Int) async throws -> EpisodesResponse {
        guard let url = URL(string: "\(baseAPIURL)/tv/\(tvShowID)/season/\(seasonNumber)") else {
            throw TVShowError.invalidEndpoint
        }
        return try await self.loadURLAndDecode(url: url)
    }

    func fetchExternalIDs(forSeries seriesID: Int) async throws -> TVShowExternalIDs {
        guard let url = URL(string: "\(baseAPIURL)/tv/\(seriesID)/external_ids") else {
            throw TVShowError.invalidEndpoint
        }
        return try await self.loadURLAndDecode(url: url)
    }

    func fetchWatchProviders(forTVShow tvShowID: Int, wpSeason: Int) async throws -> WatchProvidersResponse {
        guard let url = URL(string: "\(baseAPIURL)/tv/\(tvShowID)/season/\(wpSeason)/watch/providers") else {
            throw TVShowError.invalidEndpoint
        }

        return try await self.loadURLAndDecode(url: url)
    }

    private func loadURLAndDecode<D: Decodable>(url: URL, params: [String: String]? = nil) async throws -> D {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TVShowError.invalidEndpoint
        }

        var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]

        if let params = params {
            queryItems.append(contentsOf: params.map { URLQueryItem(name: $0.key, value: $0.value) })
        }

        urlComponents.queryItems = queryItems

        guard let finalURL = urlComponents.url else {
            throw TVShowError.invalidEndpoint
        }

        let (data, response) = try await urlSession.data(from: finalURL)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw TVShowError.invalidResponse
        }

        return try self.jsonDecoder.decode(D.self, from: data)
    }
}

@MainActor
class TVDBService: ObservableObject {
    let baseURL = "https://api4.thetvdb.com/v4"
    var jwtToken: String?

    func fetchTVDBToken(apiKey: String) async throws -> String {
        let url = URL(string: "\(baseURL)/login")!

        let body = [
            "apikey": apiKey
        ]

        let requestData = try! JSONEncoder().encode(body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)

        let response = try JSONDecoder().decode(TVDBResponse.self, from: data)
        self.jwtToken = response.data.token
        return response.data.token
    }

    func fetchSeriesInfo(seriesID: Int) async throws -> TVDBSeriesInfo {
        guard let token = jwtToken else {
            throw NSError(domain: "TVDBServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "JWT token not found. Authenticate first."])
        }
        let url = URL(string: "\(baseURL)/series/\(seriesID)/extended")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TVDBSeriesInfo.self, from: data)
    }
}

@MainActor
class TVDBServiceState: ObservableObject {
    @Published var airsTime: String?
    @Published var airsDays: [String]?

    func fetchAirsTimeAndDays(forSeriesID seriesID: Int, withAPIKey apiKey: String) async {
        do {
            let tvdbService = TVDBService()
            _ = try await tvdbService.fetchTVDBToken(apiKey: apiKey)
            let seriesInfo = try await tvdbService.fetchSeriesInfo(seriesID: seriesID)
            airsTime = seriesInfo.data.airsTime
            var days: [String] = []
            let airs = seriesInfo.data.airsDays
            if airs.sunday { days.append("Sunday") }
            if airs.monday { days.append("Monday") }
            if airs.tuesday { days.append("Tuesday") }
            if airs.wednesday { days.append("Wednesday") }
            if airs.thursday { days.append("Thursday") }
            if airs.friday { days.append("Friday") }
            if airs.saturday { days.append("Saturday") }
            airsDays = days
        } catch {
            print("Failed to fetch airsTime and days: \(error)")
        }
    }
}
