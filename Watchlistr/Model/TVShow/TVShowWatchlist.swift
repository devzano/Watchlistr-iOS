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
    var watchedEpisodes: [Int: [Int]] = [:]
    
    var posterURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath ?? "")")!
    }
    
    var backdropURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(backdropPath ?? "")")!
    }
    
    mutating func watchEpisode(seasonNumber: Int, episodeID: Int) {
        watchedEpisodes[seasonNumber, default: []].append(episodeID)
    }
    
    func isEpisodeWatched(seasonNumber: Int, episodeID: Int) -> Bool {
        return watchedEpisodes[seasonNumber]?.contains(episodeID) ?? false
    }
    
    func watchedEpisodesCountForSeason(seasonNumber: Int) -> Int {
        return watchedEpisodes[seasonNumber]?.count ?? 0
    }
}
