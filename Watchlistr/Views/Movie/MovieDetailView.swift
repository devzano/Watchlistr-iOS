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
    @State private var movieSources: [MovieSource] = [] //
    @State private var selectedTrailerURL: URL? //
    @State private var isAddedToWatchlist = false
    @State private var embedURL: URL? //
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
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
                        if movie.ratingText != "NR" {
                            VStack(alignment: .center) {
                                Text("Rating")
                                    .font(.headline)
                                Text(movie.ratingText)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 17)
                                    .padding(.vertical, 10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(LinearGradient(gradient: Gradient(colors: [secondaryTextColor, primaryTextColor]), startPoint: .leading, endPoint: .trailing), lineWidth: 3)
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                        } else {
                            VStack(alignment: .center) {
                                Text("Rating")
                                    .font(.headline)
                                Text("NR")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 17)
                                    .padding(.vertical, 10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(LinearGradient(gradient: Gradient(colors: [secondaryTextColor, primaryTextColor]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                }
                MovieDetailListView(
                    movie: movie,
                    selectedURL: $selectedTrailerURL,
                    selectedEmbedURL: $embedURL
                )
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
                    .foregroundColor(primaryTextColor)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    //
                    Menu {
                        ForEach(movieSources, id: \.url) { source in
                            Button(action: {
                                selectedTrailerURL = source.url
                            }) {
                                Text(source.name)
                                Image(systemName: "film")
                            }
                        }
                    } label: {
                        Image(systemName: "play.circle")
                            .foregroundColor(secondaryTextColor)
                    }

                    Button(action: {
                        if isMovieInWatchlist {
                            removeFromWatchlist()
                        } else {
                            addMovieToWatchlist()
                        }
                    }) {
                        if isMovieInWatchlist {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(primaryTextColor)
                        } else {
                            Image(systemName: "plus.circle")
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                }
            }
        }
    }

    private func loadMovie() {
        Task {
            if case .success(_) = movieDetailState.phase {
                return
            }

            await movieDetailState.loadMovie(id: movieID)
            await movieImagesState.loadMovieImages(id: movieID)
            await movieWatchProviderState.loadMovieWatchProviders(forMovie: movieID)
            
            //
            movieSources.removeAll()

            if let vidsrc = URL(string: "https://vidsrc.xyz/embed/movie?tmdb=\(movieID)") {
                movieSources.append(MovieSource(name: "VIDSRC", url: vidsrc))
            }
            if let supemb = URL(string: "https://multiembed.mov/?video_id=\(movieID)&tmdb=1") {
                movieSources.append(MovieSource(name: "SuperEmbed", url: supemb))
            }
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
    @Binding var selectedURL: URL?
    @Binding var selectedEmbedURL: URL?
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var body: some View {
        movieDescriptionSection.listRowSeparator(.visible)
        movieCastSection.listRowSeparator(.hidden)
        movieTrailerSection
    }
    
    private var movieDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Genre: ").foregroundColor(secondaryTextColor)
                + Text(movie.genreText)
                + Text(" · Released: ").foregroundColor(secondaryTextColor)
                + Text(movie.releaseText)
                + Text(" · Duration: ").foregroundColor(secondaryTextColor)
                + Text(movie.durationText)
            }.font(.subheadline)

            Text("Synopsis:")
                .font(.caption)
                .padding(.top, 5)

            Text(movie.overview)
                .foregroundColor(secondaryTextColor)
                .padding(.top, -8)
        }
    }
    
    private var movieCastSection: some View {
        HStack(alignment: .top, spacing: 4) {
            if let cast = movie.cast, !cast.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starring:").font(.headline)
                    ForEach(cast.prefix(9)) {
                        Text($0.name).foregroundColor(secondaryTextColor)
                        + Text(" as ")
                        + Text("\"")
                        + Text("\($0.character)").foregroundColor(secondaryTextColor)
                        + Text("\"")
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            
            if let crew = movie.crew, !crew.isEmpty, hasKeyCrewMembers(crew: crew) {
                VStack(alignment: .leading, spacing: 4) {
                    if let directors = movie.directors, !directors.isEmpty {
                        Text("Director(s):").font(.headline)
                        ForEach(directors.prefix(2)) { Text($0.name).foregroundColor(secondaryTextColor) }
                    }
                    
                    if let producers = movie.producers, !producers.isEmpty {
                        Text("Producer(s):").font(.headline).padding(.top)
                        ForEach(producers.prefix(2)) { Text($0.name).foregroundColor(secondaryTextColor) }
                    }
                    
                    if let screenwriters = movie.screenWriters, !screenwriters.isEmpty {
                        Text("Screenwriter(s):").font(.headline).padding(.top)
                        ForEach(screenwriters.prefix(2)) { Text($0.name).foregroundColor(secondaryTextColor) }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical)
    }

    private func hasKeyCrewMembers(crew: [MovieCrew]) -> Bool {
        let directorsExist = movie.directors != nil && !movie.directors!.isEmpty
        let producersExist = movie.producers != nil && !movie.producers!.isEmpty
        let screenwritersExist = movie.screenWriters != nil && !movie.screenWriters!.isEmpty
        return directorsExist || producersExist || screenwritersExist
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
                                selectedURL = url
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
                                            .foregroundColor(primaryTextColor)
                                    }
                                    Text(trailer.name)
                                        .foregroundColor(secondaryTextColor)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 120, alignment: .center)
                                }
                            }
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
    }
}

struct MovieBackdropsView: View {
    let backdrops: [MovieImages.ImageDetail]
    @State private var currentIndex: Int = 0

    var body: some View {
        VStack {
            if let backdrop = backdrops[safe: currentIndex] {
                RemoteImage(url: backdrop.imageURL, placeholder: nil)
                    .frame(width: UIScreen.main.bounds.width, height: 250)
                    .clipped()
            }
        }.onAppear {
            SharedTimer.shared.startTimer {
                withAnimation {
                    currentIndex = (currentIndex + 1) % backdrops.count
                }
            }
        }.onDisappear {
            SharedTimer.shared.stopTimer()
        }
    }
}

//
struct MovieSource {
    let name: String
    let url: URL
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
