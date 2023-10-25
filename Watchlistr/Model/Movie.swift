//
//  Movie.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation

struct MovieResponse: Decodable {
    let results: [Movie]
}

struct Movie: Decodable, Identifiable, Hashable, Equatable {
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: Int
    let title: String
    let backdropPath: String?
    let posterPath: String?
    let overview: String
    let voteAverage: Double
    let voteCount: Int
    let runtime: Int?
    let releaseDate: String?
    
    let genres: [MovieGenre]?
    let credits: MovieCredit?
    let videos: MovieVideoResponse?
    
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
    
    var releaseText: String {
        guard let releaseDate = self.releaseDate, let date = DateUtils.dateFormatter.date(from: releaseDate) else {
            return ""
        }
        return Movie.yearFormatter.string(from: date)
    }
    
    var durationText: String {
        guard let runtime = self.runtime, runtime > 0 else {
            return ""
        }
        return Movie.durationFormatter.string(from: TimeInterval(runtime) * 60) ?? ""
    }
    
    var cast: [MovieCast]? {
        credits?.cast
    }
    
    var crew: [MovieCrew]? {
        credits?.crew
    }
    
    var directors: [MovieCrew]? {
        crew?.filter {$0.job.lowercased() == "director"}
    }
    
    var producers: [MovieCrew]? {
        crew?.filter {$0.job.lowercased() == "producer"}
    }
    
    var screenWriters: [MovieCrew]? {
        crew?.filter {$0.job.lowercased() == "story"}
    }
    
    var youtubeTrailers: [MovieVideo]? {
        videos?.results.filter {$0.youtubeURL != nil}
    }
}

struct MovieImages: Decodable {
    let backdrops: [ImageDetail]?
    let posters: [ImageDetail]?
    
    struct ImageDetail: Decodable {
        let filePath: String
        
        var imageURL: URL {
            return URL(string: "https://image.tmdb.org/t/p/w500\(filePath)")!
        }
    }
}

struct MovieGenre: Decodable {
    let name: String
}

struct MovieCredit: Decodable {
    let cast: [MovieCast]
    let crew: [MovieCrew]
}

struct MovieCast: Decodable, Identifiable {
    let id: Int
    let character: String
    let name: String
}

struct MovieCrew: Decodable, Identifiable {
    let id: Int
    let job: String
    let name: String
}

struct MovieVideoResponse: Decodable {
    let results: [MovieVideo]
}

struct MovieVideo: Decodable, Identifiable {
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
