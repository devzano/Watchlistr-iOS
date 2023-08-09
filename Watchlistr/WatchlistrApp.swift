//
//  WatchlistrApp.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/17/23.
//

import SwiftUI

struct DefaultTextColor: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.indigo)
    }
}

extension View {
    func defaultTextColor() -> some View {
        self.modifier(DefaultTextColor())
    }
}

@main
struct WatchlistrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .defaultTextColor()
        }
    }
}
