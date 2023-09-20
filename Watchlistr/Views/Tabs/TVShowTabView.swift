//
//  TVShowTabView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct TVShowTabView: View {
    @State private var isSearching = false
    @ObservedObject var tvShowSearchState = TVShowSearchState()
    @StateObject private var tvShowHomeState = TVShowHomeState()
    
    var body: some View {
        NavigationView {
            VStack {
                if isSearching {
                    TVShowSearchView(tvshowSearchState: tvShowSearchState)
                        .transition(.move(edge: .top))
                } else {
                    TVShowListView(tvshowHomeState: tvShowHomeState)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if isSearching {
                        SearchBarView(placeholder: "search tv show(s)", text: $tvShowSearchState.query)
                            .animation(.default, value: isSearching)
                            .foregroundColor(.blue)
                    } else {
                        Text("TV Shows")
                            .font(.largeTitle.bold())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSearching.toggle()
                    }) {
                        Image(systemName: isSearching ? "tv" : "magnifyingglass")
                    }
                }
            }.navigationBarTitleDisplayMode(.inline)
        }
    }
}


struct TVShowListView: View {
    @ObservedObject var tvshowHomeState: TVShowHomeState

    var body: some View {
        List {
            ForEach(tvshowHomeState.sections) { section in
                TVShowThumbnailCarouselView(name: section.name, tvShows: section.tvshows, thumbnailType: section.thumbnailType)
            }
            .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowSeparator(.hidden)
        }
        .task {loadTVShows(invalidateCache: false)}
        .refreshable {loadTVShows(invalidateCache: true)}
        .overlay(DataFetchPhaseOverlayView(phase: tvshowHomeState.phase, retryAction: {loadTVShows(invalidateCache: true)}))
        .listStyle(.plain)
    }

    private func loadTVShows(invalidateCache: Bool) {
        Task {await tvshowHomeState.loadTVShowsFromAllEndpoints(invalidateCache: invalidateCache)}
    }
}

struct TVShowSearchView: View {
    @StateObject var tvshowSearchState = TVShowSearchState()

    var body: some View {
        List {
            ForEach(tvshowSearchState.tvShows) { tvshow in
                NavigationLink(destination: TVShowDetailView(tvShowID: tvshow.id, tvShowName: tvshow.name)) {
                    TVShowRowView(tvshow: tvshow).padding(.vertical, 8)
                }
            }
        }
        .overlay(overlayView)
        .onAppear {tvshowSearchState.startObserve()}
        .listStyle(.plain)
    }

    @ViewBuilder
    private var overlayView: some View {
        switch tvshowSearchState.phase {
        case .empty:
            if tvshowSearchState.trimmedQuery.isEmpty {
                EmptyPlaceholderView(text: "", image: Image(systemName: "magnifyingglass"))
            } else {
                ProgressView()
            }
        case .success(let values) where values.isEmpty:
            EmptyPlaceholderView(text: "No TV Show(s) Found", image: Image(systemName: "tv"))
        case .failure(let error):
            RetryView(text: error.localizedDescription) {
                Task {
                    await tvshowSearchState.search(query: tvshowSearchState.query)
                }
            }
        default:
            EmptyView()
        }
    }
}

struct TVShowRowView: View {
    let tvshow: TVShow

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            TVShowThumbnailView(tvShow: tvshow, thumbnailType: .poster(showName: false))
                .frame(width: 61, height: 92)
            VStack(alignment: .leading) {
                Text(tvshow.name)
                    .font(.headline)
                    .foregroundColor(.blue)
                if !tvshow.ratingText.isEmpty {
                    HStack {
                        Text(tvshow.ratingText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Text(tvshow.airText)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                Text(tvshow.overview)
                    .font(.subheadline)
                    .lineLimit(3)
            }
        }
    }
}

struct TVShowTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TVShowTabView()
        }
    }
}
