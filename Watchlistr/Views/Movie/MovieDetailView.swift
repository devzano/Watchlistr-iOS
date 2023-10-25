//
//  MovieDetailView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI
import SwiftMessages
import UserNotifications

struct MovieDetailView: View {
    let movieID: Int
    let movieTitle: String
    @EnvironmentObject var watchlistState: WatchlistState
    @StateObject private var movieDetailState = MovieDetailState()
    @StateObject private var movieImagesState = MovieImagesState()
    @StateObject private var movieWatchProviderState = MovieWatchProvidersState()
    @State private var selectedTrailerURL: URL?
    @State private var isAddedToWatchlist = false
    
    var body: some View {
        List {
            if let movie = movieDetailState.movie {
                if let movieImages = movieImagesState.movieImages, let backdrops = movieImages.backdrops, !backdrops.isEmpty {
                    MovieBackdropsView(backdrops: backdrops)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                }
                if let providers = movieWatchProviderState.movieWatchProviders {
                    HStack {
                        WatchProvidersView(watchProviders: providers)
                            .listRowSeparator(.hidden)
                        Spacer()
                        if !movie.ratingText.isEmpty {
                            VStack(alignment: .center) {
                                Text("Rating")
                                    .font(.headline)
                                Text("\(movie.ratingText)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                        }
                    }
                }
                MovieDetailListView(movie: movie, selectedTrailerURL: $selectedTrailerURL)
            }
        }
        .listStyle(.plain)
        .task {
            loadMovie()
        }
        .overlay(DataFetchPhaseOverlayView(
            phase: movieDetailState.phase,
            retryAction: loadMovie)
        )
        .sheet(item: $selectedTrailerURL) {SafariView(url: $0).edgesIgnoringSafeArea(.bottom)}
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(movieTitle)
                    .foregroundColor(.blue)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if isMovieInWatchlist {
                        removeFromWatchlist()
                    } else {
                        addMovieToWatchlist()
                    }
                }) {
                    if isMovieInWatchlist {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
    }

    private func loadMovie() {
        Task {
            await self.movieDetailState.loadMovie(id: self.movieID)
            await movieImagesState.loadMovieImages(id: movieID)
            await movieWatchProviderState.loadMovieWatchProviders(forMovie: movieID)
        }
    }
    
    private var isMovieInWatchlist: Bool {
        if let movie = movieDetailState.movie {
            return watchlistState.mWatchlist.contains { $0.id == movie.id }
        }
        return false
    }

    private func addMovieToWatchlist() {
        if !isMovieInWatchlist, let movie = movieDetailState.movie {
            watchlistState.addMovieToWatchlist(movie: movie)
            isAddedToWatchlist = true
        }
    }
    
    private func removeFromWatchlist() {
        if let movie = movieDetailState.movie,
           let existingMovieWatchlist = watchlistState.mWatchlist.first(where: { $0.id == movie.id }) {
            watchlistState.removeMovieFromWatchlist(movie: existingMovieWatchlist)
            isAddedToWatchlist = false
        }
    }
}

struct MovieDetailListView: View {
    let movie: Movie
    @Binding var selectedTrailerURL: URL?
    
    var body: some View {
        movieDescriptionSection.listRowSeparator(.visible)
        movieCastSection.listRowSeparator(.hidden)
        movieTrailerSection
    }
    
    private var movieDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(movieGenreYearDurationText)
                .font(.headline)
            Text(movie.overview)
                .foregroundColor(.blue)
        }
        .padding(.vertical)
    }
    
    private var movieGenreYearDurationText: String {
        "\(movie.genreText) · \(movie.releaseText) · \(movie.durationText)"
    }
    
    private var movieCastSection: some View {
        HStack(alignment: .top, spacing: 4) {
            if let cast = movie.cast, !cast.isEmpty {
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
            
            if let crew = movie.crew, !crew.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if let directors = movie.directors, !directors.isEmpty {
                        Text("Director(s):").font(.headline)
                        ForEach(directors.prefix(2)) { Text($0.name)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let producers = movie.producers, !producers.isEmpty {
                        Text("Producer(s):").font(.headline)
                            .padding(.top)
                        ForEach(producers.prefix(2)) { Text($0.name)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let screenwriters = movie.screenWriters, !screenwriters.isEmpty {
                        Text("Screenwriter(s):").font(.headline)
                            .padding(.top)
                        ForEach(screenwriters.prefix(2)) { Text($0.name)
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
    private var movieTrailerSection: some View {
        if let trailers = movie.youtubeTrailers, !trailers.isEmpty {
            VStack(alignment: .leading) {
                Text("Trailers").font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(trailers) { trailer in
                            Button(action: {
                                guard let url = trailer.youtubeURL else { return }
                                selectedTrailerURL = url
                            }) {
                                VStack {
                                    ZStack(alignment: .center) {
                                        RemoteImage(url: URL(string: "https://img.youtube.com/vi/\(trailer.key)/0.jpg")!, placeholder: nil)
                                            .frame(width: 120, height: 70)
                                            .clipped()
                                        Image(systemName: "play.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(Color(UIColor.systemIndigo))
                                    }
                                    Text(trailer.name)
                                        .foregroundColor(.accentColor)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 120, alignment: .center)
                                }
                            }.padding(.vertical, 8)
                        }
                    }
                }
            }.padding(.bottom)
        }
    }
}

struct MovieImagesView: View {
    let movieImages: MovieImages
    
    var body: some View {
        VStack {
            Text("Backdrops")
                .onAppear {
                    print(movieImages) // Debugging line
                }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(movieImages.backdrops ?? [], id: \.filePath) { imageDetail in 
                        RemoteImage(url: imageDetail.imageURL, placeholder: nil)
                            .frame(width: 120, height: 70)
                            .clipped()
                    }
                }
            }
            
            Text("Posters")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(movieImages.posters ?? [], id: \.filePath) { imageDetail in 
                        RemoteImage(url: imageDetail.imageURL, placeholder: nil)
                            .frame(width: 120, height: 70)
                            .clipped()
                    }
                }
            }
        }
    }
}

struct MovieBackdropsView: View {
    let backdrops: [MovieImages.ImageDetail]
    @State private var currentIndex: Int = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack {
            if let backdrop = backdrops[safe: currentIndex] {
                RemoteImage(url: backdrop.imageURL, placeholder: nil)
                    .frame(width: UIScreen.main.bounds.width, height: 250)
                    .clipped()
            }
        }.onAppear {
            startTimer()
        }.onDisappear {
            stopTimer()
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % backdrops.count
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct MovieDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieDetailView(
                movieID: 10060,
                movieTitle: "Get Rich or Die Tryin'"
            )
            .environmentObject(WatchlistState())
        }
    }
}
