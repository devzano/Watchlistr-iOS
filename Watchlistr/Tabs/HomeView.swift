//
//  HomeView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 5/21/23.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    let backgroundImages = ["BackgroundView", "BackgroundView1", "BackgroundView2"]
    @State private var currentImageIndex = 0
    private let imageChangeInterval: TimeInterval = 5
    @ObservedObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggedIn = false

    var body: some View {
        NavigationView {
            ZStack {
                backgroundImage
                VStack {
                    if authViewModel.isLoggedIn {
                        welcomeMessage
                    } else {
                        loginFields
                    }
                }
                .navigationBarItems(trailing: authViewModel.isLoggedIn ? logoutButton : nil)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    username = authViewModel.username
                    startImageTimer()
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Watchlistr")
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
        }
    }

    private var backgroundImage: some View {
        Image(backgroundImages[currentImageIndex])
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .clipped()
            .opacity(0.15)
            .edgesIgnoringSafeArea(.all)
    }

    private var welcomeMessage: some View {
        Text("Welcome, \(username)!")
            .font(.largeTitle)
    }

    private var loginFields: some View {
        VStack {
            TextField("Username", text: $username)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .padding(.horizontal)
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .padding(.horizontal)
            Button("Login") {
                authViewModel.isLoggedIn = true
            }
            .padding()
            .background(Color.indigo)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    private var logoutButton: some View {
        Button(action: {
            authViewModel.isLoggedIn = false
            username = ""
            password = ""
        }) {
            Text("Logout")
                .foregroundColor(.red)
        }
    }

    private func startImageTimer() {
        _ = Timer.scheduledTimer(withTimeInterval: imageChangeInterval, repeats: true) { timer in
            withAnimation {
                currentImageIndex = (currentImageIndex + 1) % backgroundImages.count
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(authViewModel: AuthViewModel())
    }
}
