//
//  SignupView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct SignupView: View {
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confPass = ""
    @State private var showPasswordRequirements = false
    @State private var isSigningUp = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: AuthViewModel
    
    var body: some View {
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
                        text: $username,
                        title: "Username:",
                        placeholder: "username"
                    ).autocapitalization(.none)
                    InputView(
                        text: $email,
                        title: "Email Address:",
                        placeholder: "name@example.com"
                    ).autocapitalization(.none)
                    ZStack(alignment: .trailing) {
                        InputView(
                            text: $password,
                            title: "Password:",
                            placeholder: "enter a password",
                            isSecureField: true
                        )
                        
                        if !showPasswordRequirements {
                            Image(systemName: "info.circle")
                                .imageScale(.medium)
                                .foregroundColor(.indigo)
                                .padding(.trailing, 8)
                                .onTapGesture {
                                    showPasswordRequirements.toggle()
                                }
                        }
                        
                        if showPasswordRequirements {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach([
                                    "• At least 6 characters",
                                    "• A capital letter",
                                    "• 1 number",
                                    "• 1 special character"
                                ], id: \.self) { requirement in
                                    HStack(alignment: .center, spacing: 6) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.indigo)
                                            .frame(width: 12, height: 12)
                                        Text(requirement)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .onTapGesture {
                                showPasswordRequirements.toggle()
                            }
                            .transition(.opacity)
                        }
                    }
                    ZStack(alignment: .trailing) {
                        InputView(
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
                
                ButtonView(action: {
                    isSigningUp = true
                    Task {
                        do {
                            try await vm.createUser(withEmail: email, password: password, username: username)
                        } catch {
                            isSigningUp = false
                        }
                        isSigningUp = false
                    }
                }, label: "Signup", imageName: "arrow.right")
                .disabled(!formIsValid)
                .opacity(formIsValid && !isSigningUp ? 1.0 : 0.5)
                .padding(.top, 24)
                
                if isSigningUp {
                    ActivityIndicatorView()
                    Text("Signing Up...")
                }
                
                Spacer()
            }
        }
        .onAppear {
            startImageTimer()
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

extension SignupView: AuthFormProtocol {
    var formIsValid: Bool {
        let capitalLetterCharacterSet = CharacterSet.uppercaseLetters
        let numberCharacterSet = CharacterSet.decimalDigits
        let specialCharacterSet = CharacterSet(charactersIn: "!@#$%^&*()_-+=<>?/")
        
        return !email.isEmpty
        && email.contains("@")
        && email.contains(".")
        && !password.isEmpty
        && password.count > 5
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
    }
}
