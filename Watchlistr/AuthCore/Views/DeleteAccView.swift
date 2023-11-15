//
//  DeleteAccountView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/10/23.
//

import Foundation
import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @State private var currentPassword = ""
    @State private var isDeletingAccount = false

    var body: some View {
        ZStack {
            BackgroundImageView()
            VStack {
                Spacer()
                
                VStack(spacing: 24) {
                    Text("Warning: Deleting your account will remove all watchlist data & can not be undone.")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                        .padding()
                    AuthInputView(
                        text: $currentPassword,
                        title: "Current Password:",
                        placeholder: "Enter current password",
                        isSecureField: true
                    )
                }
                
                if isDeletingAccount {
                    ActivityIndicatorView()
                        .progressViewStyle(CircularProgressViewStyle())
                }

                ButtonView(action: {
                    isDeletingAccount = true
                    Task {
                        await auth.deleteAccount(currentPassword: currentPassword)
                        
                        isDeletingAccount = false
                    }
                }, label: "Delete Account", imageName: "trash")
                .disabled(currentPassword.isEmpty || isDeletingAccount)
                .opacity((!currentPassword.isEmpty && !isDeletingAccount) ? 1.0 : 0.5)
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

extension DeleteAccountView: AuthFormProtocol {
    var formIsValid: Bool {
        !currentPassword.isEmpty
    }
}

struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteAccountView()
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
            .environmentObject(TabBarVisibilityManager())
    }
}
