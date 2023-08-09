//
//  TVShowDetailView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/21/23.
//

import SwiftUI

struct TVShowDetailView: View {
    
    let tvshowId: Int
    let tvshowName: String
    @StateObject private var tvshowDetailState = TVShowDetailState()
    @State private var selectedTrailerURL: URL?
    
    var body: some View {
        List {
            if let tvshow = tvshowDetailState.tvshow {
                TVShowDetailImage(imageURL: tvshow.backdropURL)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                
                TVShowDetailListView(tvshow: tvshow, selectedTrailerURL: $selectedTrailerURL)
            }
        }
        .listStyle(.plain)
        .task {
            loadTVShow()
        }
        .overlay(DataFetchPhaseOverlayView(
            phase: tvshowDetailState.phase,
            retryAction: loadTVShow)
        )
        .sheet(item: $selectedTrailerURL) { SafariView(url: $0).edgesIgnoringSafeArea(.bottom)}
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(tvshowName)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func loadTVShow() {
        Task { await self.tvshowDetailState.loadTVShow(id: self.tvshowId) }
    }
}

struct TVShowDetailListView: View {
    
    let tvshow: TVShow
    @Binding var selectedTrailerURL: URL?
    
    var body: some View {
        tvshowDescriptionSection.listRowSeparator(.visible)
        tvshowCastSection.listRowSeparator(.hidden)
        tvshowTrailerSection
    }
    
    private var tvshowDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tvshowGenreYearDurationText)
                .font(.headline)
            Text(tvshow.overview)
                .foregroundColor(.blue)
            HStack {
                if !tvshow.ratingText.isEmpty {
                    Text(tvshow.ratingText).foregroundColor(.yellow)
                }
                Text(tvshow.scoreText)
            }
        }
        .padding(.vertical)
    }
    
    private var tvshowCastSection: some View {
        HStack(alignment: .top, spacing: 4) {
            if let cast = tvshow.cast, !cast.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starring:").font(.headline)
                    ForEach(cast.prefix(9)) { Text($0.name)
                        + Text(" as ") +
                        Text("'\($0.character)'")
                            .foregroundColor(.blue)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            if let crew = tvshow.crew, !crew.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    
                    if let producers = tvshow.producers, !producers.isEmpty {
                        Text("Producer(s):").font(.headline)
                            .padding(.top)
                        ForEach(producers.prefix(2)) { Text($0.name)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let eProducers = tvshow.eProducers, !eProducers.isEmpty {
                        Text("Executive Producer(s):").font(.headline)
                            .padding(.top)
                        ForEach(eProducers.prefix(2)) { Text($0.name)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    private var tvshowTrailerSection: some View {
        if let trailers = tvshow.youtubeTrailers, !trailers.isEmpty {
            Text("Trailers").font(.headline)
            ForEach(trailers) { trailer in
                Button(action: {
                    guard let url = trailer.youtubeURL else { return }
                    selectedTrailerURL = url
                }) {
                    HStack {
                        Text(trailer.name)
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
            }
        }
    }
    
    private var tvshowGenreYearDurationText: String {
        "\(tvshow.genreText) · \(tvshow.airText) · \(tvshow.durationText)"
    }
}

struct TVShowDetailImage: View {
    
    @StateObject private var imageLoader = ImageLoader()
    let imageURL: URL
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .onAppear { imageLoader.loadImage(with: imageURL) }
    }
}

struct TVShowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TVShowDetailView(tvshowId: TVShow.stubbedTVShow.id, tvshowName: "Superman")
        }
    }
}
