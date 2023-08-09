//
//  TVShowHomeView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/21/23.
//

import SwiftUI

struct TVShowHomeView: View {
    @State private var isSearching = false
    @ObservedObject var tvshowSearchState = TVShowSearchState()
    @StateObject private var tvshowHomeState = TVShowHomeState()

    var body: some View {
        VStack {
            if isSearching {
                TVShowSearchView(tvshowSearchState: tvshowSearchState)
                    .transition(.move(edge: .top))
            } else {
                TVShowListView(tvshowHomeState: tvshowHomeState)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isSearching {
                    SearchBarView(placeholder: "search tv show(s)", text: $tvshowSearchState.query)
                        .animation(.default, value: isSearching)
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
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct TVShowListView: View {
    @ObservedObject var tvshowHomeState: TVShowHomeState

    var body: some View {
        List {
            ForEach(tvshowHomeState.sections) { section in
                TVShowThumbnailCarouselView(name: section.name, tvshows: section.tvshows, thumbnailType: section.thumbnailType)
            }
            .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowSeparator(.hidden)
        }
        .task { loadTVShows(invalidateCache: false) }
        .refreshable { loadTVShows(invalidateCache: true) }
        .overlay(DataFetchPhaseOverlayView(phase: tvshowHomeState.phase, retryAction: { loadTVShows(invalidateCache: true)}))
        .listStyle(.plain)
    }

    private func loadTVShows(invalidateCache: Bool) {
        Task { await tvshowHomeState.loadTVShowsFromAllEndpoints(invalidateCache: invalidateCache) }
    }
}

struct TVShowSearchView: View {
    @ObservedObject var tvshowSearchState: TVShowSearchState

    var body: some View {
        List {
            ForEach(tvshowSearchState.tvshows) { tvshow in
                NavigationLink(destination: TVShowDetailView(tvshowId: tvshow.id, tvshowName: tvshow.name)) {
                    TVShowRowView(tvshow: tvshow).padding(.vertical, 8)
                }
            }
        }
        .overlay(overlayView)
        .onAppear { tvshowSearchState.startObserve() }
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
            TVShowThumbnailView(tvshow: tvshow, thumbnailType: .poster(showName: false))
                .frame(width: 61, height: 92)
            VStack(alignment: .leading) {
                Text(tvshow.name)
                    .font(.headline)
                Text(tvshow.airText)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Text(tvshow.overview)
                    .font(.subheadline)
                    .lineLimit(3)
                Text(tvshow.ratingText)
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct TVShowHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TVShowHomeView()
        }
    }
}
