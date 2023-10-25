//
//  Stubs.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation

//MovieStub
extension Movie {
    
    static var stubbedMovies: [Movie] {
        let response: MovieResponse? = try? Bundle.main.loadAndDecodeMovieJSON(filename: "movie_list")
        return response!.results
    }
    
    static var stubbedMovie: Movie {
        stubbedMovies[0]
    }
}

extension Bundle {
    
    func loadAndDecodeMovieJSON<D: Decodable>(filename: String) throws -> D? {
        guard let url = self.url(forResource: filename, withExtension: "json") else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let jsonDecoder = DateUtils.jsonDecoder
        let decodedModel = try jsonDecoder.decode(D.self, from: data)
        
        return decodedModel
    }
}

extension MovieSection {
    
    static var stubs: [MovieSection] {
        
        let stubbedMovies = Movie.stubbedMovies
        
        return MovieListEndpoint.allCases.map {
            MovieSection(movies: stubbedMovies.shuffled(), endpoint: $0)
        }
    }
}

//TVShowStub
extension TVShow {
    
    static var stubbedTVShows: [TVShow] {
        let response: TVShowResponse? = try? Bundle.main.loadAndDecodeTVShowJSON(filename: "tvshow_list")
        return response!.results
    }
    
    static var stubbedTVShow: TVShow {
        stubbedTVShows[0]
    }
}

extension Bundle {
    
    func loadAndDecodeTVShowJSON<D: Decodable>(filename: String) throws -> D? {
        guard let url = self.url(forResource: filename, withExtension: "json") else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let jsonDecoder = DateUtils.jsonDecoder
        let decodedModel = try jsonDecoder.decode(D.self, from: data)
        
        return decodedModel
    }
}

extension TVShowSection {
    
    static var stubs: [TVShowSection] {
        
        let stubbedTVShows = TVShow.stubbedTVShows
        
        return TVShowListEndpoint.allCases.map {
            TVShowSection(tvshows: stubbedTVShows.shuffled(), endpoint: $0)
        }
    }
}
