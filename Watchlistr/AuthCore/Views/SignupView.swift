//
//  SignupView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confPass = ""
    @State private var showPasswordRequirements = false
    @State private var isSigningUp = false
    @State private var primaryTextColor = ColorManager.shared.retrievePrimaryColor()
    @State private var secondaryTextColor = ColorManager.shared.retrieveSecondaryColor()
    
    var body: some View {
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
                        text: $username,
                        title: "Username:",
                        placeholder: "username"
                    ).autocapitalization(.none)
                    
                    AuthInputView(
                        text: $email,
                        title: "Email Address:",
                        placeholder: "name@example.com"
                    ).autocapitalization(.none)
                    
                    ZStack(alignment: .trailing) {
                        AuthInputView(
                            text: $password,
                            title: "Password:",
                            placeholder: "enter a password",
                            isSecureField: true
                        )
                        
                        if !showPasswordRequirements {
                            Image(systemName: "info.circle")
                                .imageScale(.medium)
                                .foregroundColor(.red)
                                .padding(.trailing, 8)
                                .onTapGesture {
                                    showPasswordRequirements.toggle()
                                }
                        }
                        
                        if showPasswordRequirements {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach([
                                    "At least 6 characters",
                                    "A capital letter",
                                    "1 number",
                                    "1 special character"
                                ], id: \.self) { requirement in
                                    HStack(alignment: .center, spacing: 6) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(primaryTextColor)
                                            .frame(width: 12, height: 12)
                                        Text(requirement)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(12)
                            .background(secondaryTextColor.opacity(0.2))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .onTapGesture {
                                showPasswordRequirements.toggle()
                            }
                            .transition(.opacity)
                        }
                    }
                    ZStack(alignment: .trailing) {
                        AuthInputView(
                            text: $confPass,
                            title: "Confirm Password:",
                            placeholder: "confirm password",
                            isSecureField: true
                        )
                        
                        if !password.isEmpty && !confPass.isEmpty {
                            if password == confPass {
                                Image(systemName: "checkmark.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(Color(.systemGreen))
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(Color(.systemRed))
                            }
                        }
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 3) {
                            Text("Already have an account?")
                            Text("Login")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                if isSigningUp {
                    ActivityIndicatorView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                ButtonView(action: {
                    isSigningUp = true
                    Task {
                        do {
                            try await auth.createUser(withEmail: email, password: password, username: username)
                        } catch {
                            isSigningUp = false
                        }
                        isSigningUp = false
                    }
                }, label: "Signup", imageName: "arrow.right")
                .disabled(!formIsValid || isSigningUp)
                .opacity((formIsValid && !isSigningUp) ? 1.0 : 0.5)
                .padding(.top, 24)
                
                Spacer()
                AppLogosByView()
                    .padding(.bottom, 30)
            }
        }
    }
    
    private var welcomeMessage: some View {
        Text("Welcome to Watchlistr!")
            .font(.largeTitle)
    }
}

extension SignupView: AuthFormProtocol {
    var formIsValid: Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
        let capitalLetterCharacterSet = CharacterSet.uppercaseLetters
        let numberCharacterSet = CharacterSet.decimalDigits
        let specialCharacterSet = CharacterSet(charactersIn: "!@#$%^&*()_-+=[]{}|:;\"'<>,.?/~`")
        
        return emailPredicate.evaluate(with: email)
            && !password.isEmpty
            && password.count >= 6
            && password.rangeOfCharacter(from: capitalLetterCharacterSet) != nil
            && password.rangeOfCharacter(from: numberCharacterSet) != nil
            && password.rangeOfCharacter(from: specialCharacterSet) != nil
            && password == confPass
            && !username.isEmpty
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
            .environmentObject(TabBarVisibilityManager())
    }
}
