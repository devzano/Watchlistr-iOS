//
//  TVShowTabView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct TVShowTabView: View {
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @StateObject var tvShowSearchState = TVShowSearchState()
    @StateObject var tvShowHomeState = TVShowHomeState()
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var body: some View {
        NavigationView {
            mainContentView
//                .onAppear {
//                    tabBarVisibilityManager.showTabBar()
//                }
            .toolbar {
                ToolbarItem(placement: .principal) { principalToolbarView }
                ToolbarItem(placement: .navigationBarTrailing) { trailingToolbarButton }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if isSearching {
            TVShowSearchView(tvShowSearchState: tvShowSearchState)
                .transition(.move(edge: .top))
        } else {
            TVShowListView(tvshowHomeState: tvShowHomeState)
        }
    }
    
    @ViewBuilder
    private var principalToolbarView: some View {
        if isSearching {
            SearchBarView(placeholder: "search tv show(s)", text: $tvShowSearchState.query)
                .focused($isSearchFieldFocused)
                .animation(.default, value: isSearching)
        } else {
            Text("TV Shows")
                .font(.largeTitle.bold())
        }
    }
    
    private var trailingToolbarButton: some View {
        Button(action: {
            isSearching.toggle()
            isSearchFieldFocused = true
        }) {
            Image(systemName: isSearching ? "tv" : "magnifyingglass")
                .foregroundColor(secondaryTextColor)
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
            .listRowInsets(.init(top: 5, leading: 0, bottom: 0, trailing: 0))
//            .listRowInsets(.init(top: 5, leading: 0, bottom: 25, trailing: 0))
            .listRowSeparator(.hidden)
        }
        .task { loadTVShows(invalidateCache: false) }
        .refreshable { loadTVShows(invalidateCache: true) }
        .overlay(DataFetchPhaseOverlayView(phase: tvshowHomeState.phase, retryAction: { loadTVShows(invalidateCache: true) }))
        .listStyle(.plain)
    }

    private func loadTVShows(invalidateCache: Bool) {
        Task {await tvshowHomeState.loadTVShowsFromAllEndpoints(invalidateCache: invalidateCache)}
    }
}

struct TVShowSearchView: View {
//    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @StateObject var tvShowSearchState = TVShowSearchState()

    var body: some View {
        List {
            ForEach(tvShowSearchState.tvShows) { tvshow in
                NavigationLink(destination: TVShowDetailView(tvShowID: tvshow.id, tvShowName: tvshow.name)) {
                    TVShowRowView(tvShow: tvshow).padding(.vertical, 8)
                }
            }
        }
        .overlay(overlayView)
        .onAppear {
            tvShowSearchState.startObserve()
//            tabBarVisibilityManager.hideTabBar()
        }
//        .onDisappear {
//            tabBarVisibilityManager.showTabBar()
//        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var overlayView: some View {
        switch tvShowSearchState.phase {
        case .empty:
            if tvShowSearchState.trimmedQuery.isEmpty {
                EmptyPlaceholderView(text: "", image: Image(systemName: "magnifyingglass"))
            } else {
                ProgressView()
            }
        case .success(let values) where values.isEmpty:
            EmptyPlaceholderView(text: "No TV Show(s) Found", image: Image(systemName: "tv"))
        case .failure(let error):
            RetryView(text: error.localizedDescription) {
                Task {
                    await tvShowSearchState.search(query: tvShowSearchState.query)
                }
            }
        default:
            EmptyView()
        }
    }
}

struct TVShowRowView: View {
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    let tvShow: TVShow
    static let thumbnailSize: CGSize = CGSize(width: 61, height: 92)

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            TVShowThumbnailView(tvShow: tvShow, thumbnailType: .poster(showName: false))
                .frame(width: Self.thumbnailSize.width, height: Self.thumbnailSize.height)
            tvShowDetails
        }
    }
    
    @ViewBuilder
    private var tvShowDetails: some View {
        VStack(alignment: .leading) {
            Text(tvShow.name)
                .font(.headline)
                .foregroundColor(secondaryTextColor)
            if !tvShow.ratingText.isEmpty {
                ratingAndAirView
            }
            Text(tvShow.overview)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundColor(primaryTextColor)
        }
    }
    
    private var ratingAndAirView: some View {
        HStack {
            if !tvShow.airText.isEmpty {
                Text(tvShow.airText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 10).fill(Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(LinearGradient(gradient: Gradient(colors: [secondaryTextColor, primaryTextColor]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                    )
                    .shadow(radius: 3)
            }

            Spacer()

            Text(tvShow.ratingText)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LinearGradient(gradient: Gradient(colors: [secondaryTextColor, primaryTextColor]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                )
                .shadow(radius: 3)
        }
    }

}

struct TVShowTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TVShowTabView()
                .environmentObject(AuthViewModel())
                .environmentObject(WatchlistState())
                .environmentObject(TabBarVisibilityManager())
        }
    }
}
