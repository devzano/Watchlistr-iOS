//
//  LoginView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @EnvironmentObject var vm: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundImage
                VStack {
                    VStack(spacing: 8) {
                        welcomeMessage
                        Image("Logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 120)
                    }.padding(.vertical, 50)
                    VStack(spacing: 24) {
                        InputView(
                            text: $email,
                            title: "Email Address:",
                            placeholder: "enter your email"
                        ).autocapitalization(.none)
                        
                        InputView(
                            text: $password,
                            title: "Password:",
                            placeholder: "enter your password",
                            isSecureField: true
                        )
                        
                        HStack {
                            NavigationLink(destination: SignupView().navigationBarBackButtonHidden(true)) {
                                HStack(spacing: 3) {
                                    Text("Don't have an account?")
                                    Text("Signup")
                                        .fontWeight(.bold)
                                }
                                .font(.system(size: 14))
                            }
                            Spacer()
                            NavigationLink {
                                ForgotPassView().navigationBarBackButtonHidden(true)
                            } label: {
                                Text("Forgot Password?")
                                    .fontWeight(.bold)
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 22)
                    
                    ButtonView(action: {
                        isLoggingIn = true
                        Task {
                            do {
                                try await vm.signIn(withEmail: email, password: password)
                            } catch {
                                isLoggingIn = false
                            }
                            isLoggingIn = false
                        }
                    }, label: "Login", imageName: "arrow.right")
                    .disabled(!formIsValid)
                    .opacity(formIsValid && !isLoggingIn ? 1.0 : 0.5)
                    .padding(.top, 24)
                    
                    if isLoggingIn {
                        ActivityIndicatorView()
                        Text("Logging In...")
                    }
                    
                    Spacer()
                }
            }
            .onAppear {
                startImageTimer()
            }
        }
    }
    
    private var welcomeMessage: some View {
        Text("Welcome to Watchlistr!")
            .font(.largeTitle)
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
    
    private let backgroundImages = ["BackgroundView", "BackgroundView1", "BackgroundView2"]
    @State private var currentImageIndex = 0
    private let imageChangeInterval: TimeInterval = 10
    
    private func startImageTimer() {
        _ = Timer.scheduledTimer(withTimeInterval: imageChangeInterval, repeats: true) { timer in
            withAnimation {
                currentImageIndex = (currentImageIndex + 1) % backgroundImages.count
            }
        }
    }
}

extension LoginView: AuthFormProtocol {
    var formIsValid: Bool {
        
        return !email.isEmpty
        && email.contains("@")
        && email.contains(".")
        && !password.isEmpty
        && password.count > 5
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
