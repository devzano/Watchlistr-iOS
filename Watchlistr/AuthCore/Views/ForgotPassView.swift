//
//  ForgotPassView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct ForgotPassView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var isSendingEmail = false
    
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
                        text: $email,
                        title: "Email Address",
                        placeholder: "name@example.com"
                    ).autocapitalization(.none)
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 3) {
                            Text("Back to")
                            Text("Login")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                if isSendingEmail {
                    ActivityIndicatorView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                ButtonView(action: {
                    isSendingEmail = true
                    Task {
                        await auth.sendResetPasswordEmail(forEmail: email)
                        isSendingEmail = false
                        email = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }, label: "Send Link", imageName: "arrow.right")
                .disabled(!formIsValid || isSendingEmail)
                .opacity((formIsValid && !isSendingEmail) ? 1.0 : 0.5)
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

extension ForgotPassView: AuthFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
            && email.contains("@")
            && email.contains(".")
    }
}

struct ForgotPassView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPassView()
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
            .environmentObject(TabBarVisibilityManager())
    }
}
