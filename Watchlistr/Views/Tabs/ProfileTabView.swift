//
//  ProfileTabView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct ProfileTabView: View {
    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingClearConfirmation = false
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    
    var body: some View {
        NavigationView {
            if let user = vm.currentUser {
                List {
                    Section {
                        HStack {
                            Text(user.initials)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 72, height: 72)
                                .background(Color(.systemIndigo))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.top, 4)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    
                    Section("Watchlist") {
                        NavigationLink(destination: MovieWatchlistView()) {
                            SettingsRowView(
                                imageName: "film",
                                title: "Movies",
                                tintColor: .blue
                            )
                        }
                        .contextMenu {
                            Button(action: {
                                showingClearConfirmation = true
                            }) {
                                Text("Clear Watchlist")
                                Image(systemName: "trash.fill")
                            }
                        }
                        .alert(isPresented: $showingClearConfirmation) {
                            Alert(
                                title: Text("Clear Watchlist"),
                                message: Text("Are you sure you want to clear your watchlist? This action cannot be undone."),
                                primaryButton: .destructive(Text("Clear"), action: {
                                    watchlistState.clearMovieWatchlist()
                                }),
                                secondaryButton: .cancel()
                            )
                        }
                        
                        NavigationLink(destination: TVShowWatchlistView()) {
                            SettingsRowView(
                                imageName: "tv",
                                title: "TV Shows",
                                tintColor: .blue
                            )
                        }
                        .contextMenu {
                            Button(action: {
                                showingClearConfirmation = true
                            }) {
                                Text("Clear Watchlist")
                                Image(systemName: "trash.fill")
                            }
                        }
                        .alert(isPresented: $showingClearConfirmation) {
                            Alert(
                                title: Text("Clear Watchlist"),
                                message: Text("Are you sure you want to clear your watchlist? This action cannot be undone."),
                                primaryButton: .destructive(Text("Clear"), action: {
                                    watchlistState.clearTVShowWatchlist()
                                }),
                                secondaryButton: .cancel()
                            )
                        }
                    }
                    
                    Section("General") {
                        HStack {
                            SettingsRowView(
                                imageName: "gear",
                                title: "Version",
                                tintColor: Color(.systemGray)
                            )
                            Spacer()
                            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                Text(appVersion)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Section("Account") {
                        NavigationLink {
                            ChangePassView()
                        } label: {
                            SettingsRowView(
                                imageName: "lock.circle.fill",
                                title: "Change Password",
                                tintColor: .yellow
                            )
                        }
                        
                        Button {
                            showingSignOutConfirmation = true
                        } label: {
                            SettingsRowView(
                                imageName: "arrow.left.circle.fill",
                                title: "Sign Out",
                                tintColor: .red
                            )
                        }.alert(isPresented: $showingSignOutConfirmation) {
                            Alert(
                                title: Text("Sign Out"),
                                message: Text("Are you sure you want to sign out?"),
                                primaryButton: .destructive(Text("Sign Out"), action: {
                                    vm.signOut()
                                }),
                                secondaryButton: .cancel()
                            )
                        }
                        
                        Button {
                            showingDeleteConfirmation = true
                        } label: {
                            SettingsRowView(
                                imageName: "xmark.circle.fill",
                                title: "Delete Account",
                                tintColor: .red
                            )
                        }.alert(isPresented: $showingDeleteConfirmation) {
                            Alert(
                                title: Text("Delete Account"),
                                message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete"), action: {
                                    Task {
                                        await vm.deleteAccount()
                                    }
                                }),
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }.navigationTitle("Watchlistr Profile")
            }
        }
    }
}

struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileTabView()
        }
        .environmentObject(AuthViewModel())
    }
}
