//
//  ProfileTabView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import FirebaseFirestore
import SwiftUI
import Photos
import UserNotifications
import SwiftMessages

struct ProfileTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var watchlistState: WatchlistState
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @StateObject private var imageLoader = ImageLoader()
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var profileImageUrl: URL?
    @State private var showingSignOutConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var isRequestingPermission = false
    @State private var pendingNotificationsCount: Int = 0
    let deviceType = UIDevice().type
    
    private func fetchUserProfileImage() {
        if let userId = auth.userSession?.uid {
            let userDoc = Firestore.firestore().collection("users").document(userId)
            userDoc.getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()
                    if let imageUrlString = data?["profileImageUrl"] as? String, let url = URL(string: imageUrlString) {
                        self.imageLoader.loadImage(with: url)
                    }
                } else {
                    print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func deleteAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        
        loadNotificationsCount()
    }
    
    private var creationDateText: String {
        if let creationDate = auth.currentUser?.creationDate {
            return creationDate.formatted(date: .abbreviated, time: .omitted)
        } else {
            return "N/A"
        }
    }
    
    private func loadNotificationsCount() {
        if let user = auth.currentUser {
            getPendingNotifications { requests in
                let userNotifications = requests.filter { $0.identifier.contains(user.username) }
                DispatchQueue.main.async {
                    self.pendingNotificationsCount = userNotifications.count
                }
            }
        }
    }
    
    private var watchedMoviesCount: Int {
        watchlistState.mWatchlist.filter { $0.watched }.count
    }

    private func totalWatchedEpisodesCount() -> Int {
        watchlistState.tvWatchlist.reduce(0) { total, tvShowWatchlist in
            total + tvShowWatchlist.watchedEpisodes.values.reduce(0) { $0 + $1.count }
        }
    }
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.systemIndigo]
    }

    func requestPhotoLibraryPermission() {
        guard !isRequestingPermission else { return }

        isRequestingPermission = true
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isRequestingPermission = false
                switch status {
                case .authorized, .limited:
                    self.isImagePickerPresented = true
                case .denied, .restricted:
                    showError(withTitle: "Permission Denied", message: "Please enable access to your photo library from the Settings app.")
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            if let user = auth.currentUser {
                List {
                    Group {
                        Section {
                            HStack {
                                ZStack {
                                    if imageLoader.isLoading {
                                        ActivityIndicatorView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .frame(width: 100, height: 100)
                                    } else if let userImage = imageLoader.image {
                                        Image(uiImage: userImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(
                                                    LinearGradient(gradient: Gradient(colors: [.blue, .indigo]), startPoint: .leading, endPoint: .trailing),
                                                    lineWidth: 1.5
                                                )
                                            )
                                            .shadow(radius: 4)
                                    } else {
                                        Circle()
                                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .indigo]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 100, height: 100)
                                        Text(user.initials)
                                            .font(.system(size: 42, weight: .bold))
                                            .foregroundColor(.white)
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 50))
                                            .padding(3)
                                            .opacity(0.3)
                                    }

                                    if isRequestingPermission {
                                        ActivityIndicatorView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .frame(width: 100, height: 100)
                                    }
                                }
                                .onTapGesture {
                                    requestPhotoLibraryPermission()
                                }
                                .disabled(isRequestingPermission)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 15) {
                                    UserInfoRow(iconName: "film", iconColor: .orange, text: "Watched: \(watchedMoviesCount)", textColor: .gray)
                                    UserInfoRow(iconName: "tv", iconColor: .mint, text: "Watched: \(totalWatchedEpisodesCount())", textColor: .gray)
                                    UserInfoRow(iconName: "bell.fill", iconColor: .green, text: "Scheduled: \(pendingNotificationsCount)", textColor: .gray)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .cornerRadius(10)
                            .shadow(radius: 3)
                            .sheet(isPresented: $isImagePickerPresented) {
                                ImagePicker(selectedImage: $selectedImage, profileImageUrl: $profileImageUrl, userId: user.id)
                            }
                        }
                        
                        Section("Watchlist") {
                            NavigationLink(destination: MovieWatchlistView()) {
                                SettingsRowView(
                                    imageName: "film",
                                    title: "Movies",
                                    tintColor: .orange
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
                                    tintColor: .mint
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
                            
                            if let currentUser = auth.currentUser {
                                NavigationLink(destination: ScheduledNotificationsView(username: currentUser.username)) {
                                    SettingsRowView(
                                        imageName: "bell.fill",
                                        title: "Notifications",
                                        tintColor: .green
                                    )
                                }.contextMenu {
                                    Button(action: {
                                        showingClearConfirmation = true
                                    }) {
                                        Text("Clear Notifications")
                                        Image(systemName: "trash.fill")
                                    }
                                }
                                .alert(isPresented: $showingClearConfirmation) {
                                    Alert(
                                        title: Text("Clear Notifications"),
                                        message: Text("Are you sure you want to clear your notifications? This action cannot be undone."),
                                        primaryButton: .destructive(Text("Clear"), action: {
                                            deleteAllNotifications()
                                        }),
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                        }.foregroundColor(.blue)
                        .listRowSeparator(.hidden)
                        
                        Section("General") {
                            HStack {
                                SettingsRowView(
                                    imageName: "person.fill",
                                    title: "Username",
                                    tintColor: Color(.systemIndigo)
                                )
                                Spacer()
                                Text(user.username)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                SettingsRowView(
                                    imageName: "envelope.fill",
                                    title: "Email",
                                    tintColor: Color(.systemBlue)
                                )
                                Spacer()
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                SettingsRowView(
                                    imageName: "calendar",
                                    title: "Joined",
                                    tintColor: Color(.systemPink)
                                )
                                Spacer()
                                Text(creationDateText)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
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
                        }.foregroundColor(.blue)
                        .listRowSeparator(.hidden)
                        
                        Section("Account") {
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
                                        auth.signOut()
                                    }),
                                    secondaryButton: .cancel()
                                )
                            }
                            
                            NavigationLink {
                                ChangePassView()
                            } label: {
                                SettingsRowView(
                                    imageName: "lock.circle.fill",
                                    title: "Change Password",
                                    tintColor: .yellow
                                )
                            }
                            
                            NavigationLink {
                                ChangeEmailView()
                            } label: {
                                SettingsRowView(
                                    imageName: "envelope.circle.fill",
                                    title: "Change Email",
                                    tintColor: .blue
                                )
                            }
                            
                            NavigationLink {
                                DeleteAccountView()
                            } label: {
                                SettingsRowView(
                                    imageName: "xmark.circle.fill",
                                    title: "Delete Account",
                                    tintColor: .red
                                )
                            }
                        }.foregroundColor(.blue)
                        .listRowSeparator(.hidden)
                    }
//                    .listRowInsets(.init(top: -5, leading: 12, bottom: -5, trailing: 12))
                    .onAppear {
                        loadNotificationsCount()
                        tabBarVisibilityManager.showTabBar()
                    }
                    .onChange(of: selectedImage) { _ in
                        if let selectedImage = selectedImage {
                            self.imageLoader.image = selectedImage
                        }
                    }
                }
                .navigationTitle("\(user.username)'s Profile")
            } else {
                VStack {
                    Text("Fetching Profile")
                    ActivityIndicatorView()
                        .scaledToFit()
                }.onAppear {
                    fetchUserProfileImage()
                }
            }
        }
    }
}

struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileTabView()
                .environmentObject(AuthViewModel())
                .environmentObject(WatchlistState())
                .environmentObject(TabBarVisibilityManager())
        }
    }
}
