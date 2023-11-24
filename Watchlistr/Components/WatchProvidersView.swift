//
//  WatchProvidersView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/21/23.
//

import SwiftUI

struct WatchProvidersView: View {
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    let watchProviders: WatchProvidersResponse
    
    var combinedProviders: [Provider] {
        let streamingProviders = watchProviders.results["US"]?.flatrate ?? []
        let buyingProviders = watchProviders.results["US"]?.buy ?? []
        let allProviders = streamingProviders + buyingProviders
        var seen = Set<String>()
        return allProviders.filter {seen.insert($0.uniqueId).inserted}
    }
    
    func providerLink(with originalLink: String) -> URL? {
        guard var components = URLComponents(string: originalLink) else { return nil }
        if let existingLocaleIndex = components.queryItems?.firstIndex(where: {$0.name == "locale"}) {
            components.queryItems?[existingLocaleIndex].value = "US"
        } else {
            let localeQueryItem = URLQueryItem(name: "locale", value: "US")
            components.queryItems = (components.queryItems ?? []) + [localeQueryItem]
        }
        if components.path.contains("/season/1/") {
            components.path = components.path.replacingOccurrences(of: "/season/1/", with: "/")
        }
        return components.url
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if !combinedProviders.isEmpty {
                Text("Available On")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(combinedProviders, id: \.uniqueId) { provider in
                            if let link = watchProviders.results["US"]?.link,
                               let url = providerLink(with: link) {
                                Link(destination: url) {
                                    ProviderLogoView(logoPath: provider.logoPath)
                                    Text(provider.providerName)
                                        .foregroundColor(secondaryTextColor)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No streams available yet!")
                    .font(.headline)
                    .foregroundColor(secondaryTextColor)
            }
        }
    }
}

extension URL: Identifiable {
    public var id: Self { self }
}

extension Provider {
    var uniqueId: String {
        "\(providerId)-\(providerName)"
    }
}

struct ProviderLogoView: View {
    let logoPath: String
    @StateObject private var imageLoader = ImageLoader()
    
    var body: some View {
        if let image = imageLoader.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .cornerRadius(10)
                .onAppear(perform: loadImage)
        } else {
            Rectangle()
                .fill(Color.gray)
                .frame(width: 50, height: 50)
                .cornerRadius(10)
                .onAppear(perform: loadImage)
        }
    }
    
    func loadImage() {
        let imageUrlString = "https://image.tmdb.org/t/p/w92\(logoPath)"
        if let url = URL(string: imageUrlString) {
            imageLoader.loadImage(with: url)
        }
    }
}
