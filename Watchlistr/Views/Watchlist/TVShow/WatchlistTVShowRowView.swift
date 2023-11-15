//
//  WatchlistTVShowRowView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 10/31/23.
//

import Foundation
import SwiftUI

struct WatchlistTVShowRowView: View {
    var tvShow: TVShowWatchlist
    var isNotifiSet: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                RemoteImage(url: tvShow.posterURL, placeholder: Image("PosterNotFound"))
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(tvShow.name)
                        .font(.headline)
                    
                    Text(tvShow.overview)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(3)
                }
            }
            .opacity(tvShow.watched ? 0.5 : 1.0)
            
            VStack(spacing: 5) {
                if tvShow.watched {
                    Text("Watched!")
                        .font(.caption)
                        .padding(5)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                
                if isNotifiSet {
                    Text("Reminder Set!")
                        .font(.caption)
                        .padding(5)
                        .background(Color.yellow.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
            }
        }
    }
}
