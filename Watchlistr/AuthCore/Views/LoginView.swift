//
//  LoginView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI
import SwiftMessages

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    private let keychain = KeychainWrapper()
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundImageView()
                VStack {
                    VStack {
                        welcomeMessage
                            .padding(.top, 100)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 24) {
                        AuthInputView(
                            text: $email,
                            title: "Email Address:",
                            placeholder: "enter your email"
                        ).autocapitalization(.none)
                        
                        AuthInputView(
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
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 22)
                    
                    
                    if isLoggingIn {
                        ActivityIndicatorView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    ButtonView(action: {
                        loginAction()
                    }, label: "Login", imageName: "arrow.right")
                    .disabled(!formIsValid || isLoggingIn)
                    .opacity(formIsValid && !isLoggingIn ? 1.0 : 0.5)
                    .padding(.top, 24)
                    
                    Spacer()
                    AppLogosByView()
                        .padding(.bottom, 30)
                }
            }
            .onAppear {
                loadCredentialsFromKeychain()
            }
        }
    }
    
    private func loginAction() {
        isLoggingIn = true
        Task {
            do {
                try await auth.signIn(withEmail: email, password: password)
                let emailSaved = keychain.saveEmail(email: email)
                let passwordSaved = keychain.savePassword(password: password)
                
                if !emailSaved || !passwordSaved {
                    showMessage(withTitle: "Error", message: "Failed to save credentials. Please retry.", theme: .error)
                }
            } catch {
                showMessage(withTitle: "Error", message: "Failed to login: \(error.localizedDescription)", theme: .error)
            }
            isLoggingIn = false
        }
    }
    
    private func loadCredentialsFromKeychain() {
        if let savedEmail = keychain.retrieveEmail() {
            email = savedEmail
        }
        if let savedPassword = keychain.retrievePassword() {
            password = savedPassword
        }
    }
    
    private var welcomeMessage: some View {
        Text("Welcome to Watchlistr!")
            .font(.largeTitle)
    }
}

extension LoginView: AuthFormProtocol {
    var formIsValid: Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
        
        return emailPredicate.evaluate(with: email)
            && !password.isEmpty
            && password.count >= 6
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
            .environmentObject(TabBarVisibilityManager())
    }
}
