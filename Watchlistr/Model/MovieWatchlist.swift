//
//  MovieWatchlist.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/15/23.
//

import Foundation

struct MovieWatchlist: Identifiable, Codable {
    let id: Int
    let title: String
    let backdropPath: String?
    let posterPath: String?
    let overview: String
    
    var posterURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath ?? "")")!
    }
    
    var backdropURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(backdropPath ?? "")")!
    }
}
