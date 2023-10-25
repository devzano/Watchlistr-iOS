//
//  TVShow.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation

struct TVShowResponse: Decodable {
    let results: [TVShow]
}

struct TVShow: Decodable, Identifiable, Hashable {
    static func == (lhs: TVShow, rhs: TVShow) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: Int
    let name: String
    let backdropPath: String?
    let posterPath: String?
    let overview: String
    let voteAverage: Double
    let voteCount: Int
    let episodeRunTime: [Int]?
    let firstAirDate: String?
    let seasons: [TVShowSeason]?
    let genres: [TVShowGenre]?
    let credits: TVShowCredit?
    let videos: TVShowVideoResponse?
    
    static private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm·dd·yyyy"
        return formatter
    }()
    
    static private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    var backdropURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(backdropPath ?? "")")!
    }
    
    var posterURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath ?? "")")!
    }
    
    var genreText: String {
        guard let genres = genres, !genres.isEmpty else {
            return ""
        }
        
        let genreNames = genres.map { $0.name }
        return genreNames.joined(separator: ", ")
    }

    var ratingText: String {
        let rating = Int(voteAverage)
        let ratingText = (0..<rating).reduce("") {(acc, _) -> String in
            return acc + "✪"
        }
        return ratingText
    }

    var scoreText: String {
        guard ratingText.count > 0 else {
            return ""
        }
        return "\(ratingText.count)/10"
    }

    var airText: String {
        guard let airDate = self.firstAirDate, let date = DateUtils.dateFormatter.date(from: airDate) else {
            return ""
        }
        return TVShow.yearFormatter.string(from: date)
    }
    
    var durationText: String {
        guard let episodeRunTimes = self.episodeRunTime, !episodeRunTimes.isEmpty else {
            return ""
        }
        
        let durations = episodeRunTimes.compactMap { duration -> String? in
            guard duration > 0 else {
                return nil
            }
            let timeInterval = TimeInterval(duration) * 60
            return TVShow.durationFormatter.string(from: timeInterval)
        }
        
        return durations.joined(separator: " - ")
    }
    
    var cast: [TVShowCast]? {
        credits?.cast
    }
    
    var crew: [TVShowCrew]? {
        credits?.crew
    }
    
    var producers: [TVShowCrew]? {
        crew?.filter {$0.job.lowercased() == "producer"}
    }
    
    var eProducers: [TVShowCrew]? {
        crew?.filter {$0.job.lowercased() == "executive producer"}
    }
    
    var youtubeTrailers: [TVShowVideo]? {
        videos?.results.filter {$0.youtubeURL != nil}
    }
}

struct TVShowSeriesImages: Decodable {
    let backdrops: [ImageDetail]?
    let posters: [ImageDetail]?
    
    struct ImageDetail: Decodable {
        let filePath: String
        
        var imageURL: URL {
            return URL(string: "https://image.tmdb.org/t/p/w500\(filePath)")!
        }
    }
}

struct TVShowSeason: Decodable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let episodeCount: Int
    let posterPath: String?
    let seasonNumber: Int
    
    var posterURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath ?? "")")!
    }
}

struct TVShowEpisode: Decodable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let episodeNumber: Int
    let seasonNumber: Int
    let stillPath: String?
    let airDate: String?

    var stillURL: URL {
        return URL(string: "https://image.tmdb.org/t/p/w500\(stillPath ?? "")")!
    }

    var airText: String {
        guard let airDate = self.airDate, let date = DateUtils.dateFormatter.date(from: airDate) else {
            return ""
        }
        return TVShowEpisode.yearFormatter.string(from: date)
    }

    static private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm·dd·yyyy"
        return formatter
    }()
}

struct EpisodesResponse: Decodable {
    let episodes: [TVShowEpisode]
}

struct TVShowGenre: Decodable {
    let name: String
}

struct TVShowCredit: Decodable {
    let cast: [TVShowCast]
    let crew: [TVShowCrew]
}

struct TVShowCast: Decodable, Identifiable {
    let id: Int
    let character: String
    let name: String
}

struct TVShowCrew: Decodable, Identifiable {
    let id: Int
    let job: String
    let name: String
}

struct TVShowVideoResponse: Decodable {
    let results: [TVShowVideo]
}

struct TVShowVideo: Decodable, Identifiable {
    let id: String
    let key: String
    let name: String
    let site: String
    
    var youtubeURL: URL? {
        guard site == "YouTube" else {
            return nil
        }
        return URL(string: "https://youtube.com/watch?v=\(key)")
    }
}
