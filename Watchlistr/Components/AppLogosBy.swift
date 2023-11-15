//
//  AppLogosByView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 10/29/23.
//

import Foundation
import SwiftUI

struct AppLogosByView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            VStack {
                Text("Developed by")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                if colorScheme == .light {
                    Image("DevzanoMAC(dark)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                } else {
                    Image("DevzanoMAC(light)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                }
            }

            Spacer()

            VStack {
                Text("Powered by")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                HStack {
                    Image("TMDB")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                    if colorScheme == .light {
                        Image("tvdb(dark)")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                    } else {
                        Image("tvdb(light)")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                    }
                }
            }
        }
        .padding(.horizontal)
        .safeAreaInset(edge: .bottom) {
            if #available(iOS 16.0, *) {
                Color.clear.frame(height: 20)
            } else {
                Color.clear.frame(height: 60)
            }
        }
    }
}




