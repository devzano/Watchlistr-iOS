//
//  WatchlistrSections.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 6/9/23.
//

import Foundation

//MovieSection
struct MovieSection: Identifiable {
    let id = UUID()
    let movies: [Movie]
    let endpoint: MovieListEndpoint
    
    var title: String {
        endpoint.description
    }
    
    var thumbnailType: MovieThumbnailType {
        endpoint.thumbnailType
    }
}

fileprivate extension MovieListEndpoint {
    
    var thumbnailType: MovieThumbnailType {
        switch self {
        case .nowPlaying:
            return .poster()
        default:
            return .backdrop
        }
    }
}

//TVShowSection
struct TVShowSection: Identifiable {
    let id = UUID()
    let tvshows: [TVShow]
    let endpoint: TVShowListEndpoint
    
    var name: String {
        endpoint.description
    }
    
    var thumbnailType: TVShowThumbnailType {
        endpoint.thumbnailType
    }
}

fileprivate extension TVShowListEndpoint {
    
    var thumbnailType: TVShowThumbnailType {
        switch self {
        case .airingToday:
            return .poster()
        default:
            return .backdrop
        }
    }
}
