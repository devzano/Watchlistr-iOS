//
//  WatchProviders.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/21/23.
//

import Foundation

struct WatchProvidersResponse: Codable {
    let results: [String: CountryWatchProviders]
}

struct CountryWatchProviders: Codable {
    let link: String?
    let flatrate: [Provider]?
    let rent: [Provider]?
    let buy: [Provider]?
}

struct Provider: Codable {
    let displayPriority: Int
    let logoPath: String
    let providerId: Int
    let providerName: String
}
