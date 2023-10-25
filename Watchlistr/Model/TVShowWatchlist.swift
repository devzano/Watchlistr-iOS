//
//  TVShowWatchlist.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/15/23.
//

import Foundation

struct TVShowWatchlist: Identifiable, Codable {
    let id: Int
    let name: String
    let backdropPath: String?
    let posterPath: String?
    let overview: String
    var watched: Bool
    var watchedEpisodes: [Int] = []
    var posterURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath ?? "")")!
    }
    var backdropURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(backdropPath ?? "")")!
    }
}
