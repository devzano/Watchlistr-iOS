//
//  WatchlistrStore.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 6/9/23.
//

import Foundation

//MovieStore
class MovieStore: MovieService {
    static let shared = MovieStore()
    private init() {}

    private let apiKey = "92d4fa842063577e07342a78969bf283"
    private let baseAPIURL = "https://api.themoviedb.org/3"
    private let urlSession = URLSession.shared
    private let jsonDecoder = Utils.jsonDecoder

    func fetchMovies(from endpoint: MovieListEndpoint) async throws -> [Movie] {
        guard let url = URL(string: "\(baseAPIURL)/movie/\(endpoint.rawValue)") else {
            throw MovieError.invalidEndpoint
        }

        let movieResponse: MovieResponse = try await self.loadURLAndDecode(url: url, params: [
            "region": "US"
        ])

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
import Foundation

class TVShowStore: TVShowService {
    static let shared = TVShowStore()
    private init() {}
    
    private let apiKey = "92d4fa842063577e07342a78969bf283"
    private let baseAPIURL = "https://api.themoviedb.org/3"
    private let urlSession = URLSession.shared
    private let jsonDecoder = Utils.jsonDecoder
    
    func fetchTVShows(from endpoint: TVShowListEndpoint) async throws -> [TVShow] {
        guard let url = URL(string: "\(baseAPIURL)/tv/\(endpoint.rawValue)") else {
            throw TVShowError.invalidEndpoint
        }
        
        let tvshowResponse: TVShowResponse = try await self.loadURLAndDecode(url: url, params: [
            "language": "en-US",
            "with_original_language": "en",
            "with_origin_country": "US",
        ])
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
