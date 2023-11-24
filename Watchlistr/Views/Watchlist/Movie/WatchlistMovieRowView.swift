//
//  WatchlistMovieRowView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 10/31/23.
//

import Foundation
import SwiftUI

struct WatchlistMovieRowView: View {
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
        @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    var movie: MovieWatchlist
    var isNotifiSet: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                RemoteImage(url: movie.posterURL, placeholder: Image("PosterNotFound"))
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(movie.title)
                        .font(.headline)
                    
                    Text(movie.overview)
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(3)
                }
            }
            .opacity(movie.watched ? 0.5 : 1.0)
            
            VStack (spacing: 5) {
                if movie.watched {
                    Text("Watched!")
                        .font(.caption)
                        .padding(5)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.primary)
                        .cornerRadius(5)
                }
                
                if isNotifiSet {
                    Text("Reminder Set!")
                        .font(.caption)
                        .padding(5)
                        .background(Color.yellow.opacity(0.8))
                        .foregroundColor(.primary)
                        .cornerRadius(5)
                }
            }
        }
    }
}
