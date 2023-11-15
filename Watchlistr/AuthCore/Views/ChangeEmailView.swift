//
//  ChangeEmailView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/2/23.
//

import Foundation
import SwiftUI

struct ChangeEmailView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @State private var currentPassword = ""
    @State private var newEmail = ""
    @State private var confirmNewEmail = ""
    @State private var isChangingEmail = false

    var body: some View {
        ZStack {
            BackgroundImageView()
            VStack {
                Spacer()
                VStack(spacing: 24) {
                    AuthInputView(
                        text: $currentPassword,
                        title: "Current Password:",
                        placeholder: "Enter current password",
                        isSecureField: true
                    )
                    
                    AuthInputView(
                        text: $newEmail,
                        title: "New Email:",
                        placeholder: "Enter new email",
                        isSecureField: false
                    )
                    
                    AuthInputView(
                        text: $confirmNewEmail,
                        title: "Confirm New Email:",
                        placeholder: "Confirm new email",
                        isSecureField: false
                    )
                }
                
                if isChangingEmail{
                    ActivityIndicatorView()
                        .progressViewStyle(CircularProgressViewStyle())
                }

                ButtonView(action: {
                    isChangingEmail = true
                    Task {
                        do {
                            try await auth.changeEmail(currentPassword: currentPassword, newEmail: newEmail)
                            currentPassword = ""
                            newEmail = ""
                            confirmNewEmail = ""
                        } catch {
                            print("DEBUG: Failed to change email with error \(error.localizedDescription)")
                        }
                        isChangingEmail = false
                    }
                }, label: "Change Email", imageName: "arrow.right")
                .disabled(!formIsValid || isChangingEmail)
                .opacity((formIsValid && !isChangingEmail) ? 1.0 : 0.5)
                .padding(.top, 24)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .onAppear {
            tabBarVisibilityManager.hideTabBar()
        }
    }
}

extension ChangeEmailView: AuthFormProtocol {
    var formIsValid: Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
        return emailPredicate.evaluate(with: newEmail)
            && newEmail == confirmNewEmail
            && !currentPassword.isEmpty
    }
}

struct ChangeEmailView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeEmailView()
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
            .environmentObject(TabBarVisibilityManager())
    }
}
