//
//  ChangePassView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation
import SwiftUI

struct ChangePassView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
    @State private var currPass = ""
    @State private var newPass = ""
    @State private var confNewPass = ""
    @State private var showPasswordRequirements = false
    @State private var isChangingPassword = false
    
    var body: some View {
        ZStack {
            BackgroundImageView()
            VStack {
                Spacer()
                VStack(spacing: 24) {
                    AuthInputView(
                        text: $currPass,
                        title: "Current Password:",
                        placeholder: "enter current password",
                        isSecureField: true
                    )
                    
                    ZStack(alignment: .trailing) {
                        AuthInputView(
                            text: $newPass,
                            title: "New Password:",
                            placeholder: "enter new password",
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
                        AuthInputView(
                            text: $confNewPass,
                            title: "Confirm New Password:",
                            placeholder: "confirm new password",
                            isSecureField: true
                        )
                        
                        if !newPass.isEmpty && !confNewPass.isEmpty {
                            if newPass == confNewPass {
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
                }
                
                if isChangingPassword {
                    ActivityIndicatorView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                ButtonView(action: {
                    isChangingPassword = true
                    Task {
                        do {
                            try await auth.changePass(currentPassword: currPass, newPassword: newPass)
                            currPass = ""
                            newPass = ""
                            confNewPass = ""
                        } catch {
                            print("DEBUG: Failed to change password with error \(error.localizedDescription)")
                        }
                        isChangingPassword = false
                    }
                }, label: "Change Password", imageName: "arrow.right")
                .disabled(!formIsValid || isChangingPassword)
                .opacity((formIsValid && !isChangingPassword) ? 1.0 : 0.5)
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
    

extension ChangePassView: AuthFormProtocol {
    var formIsValid: Bool {
        let capitalLetterCharacterSet = CharacterSet.uppercaseLetters
        let numberCharacterSet = CharacterSet.decimalDigits
        let specialCharacterSet = CharacterSet(charactersIn: "!@#$%^&*()_-+=[]{}|:;\"'<>,.?/~`")
        
        return !currPass.isEmpty
        && !newPass.isEmpty
        && newPass.count >= 6
        && newPass.rangeOfCharacter(from: capitalLetterCharacterSet) != nil
        && newPass.rangeOfCharacter(from: numberCharacterSet) != nil
        && newPass.rangeOfCharacter(from: specialCharacterSet) != nil
        && newPass == confNewPass
    }
}

struct ChangePassView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePassView()
            .environmentObject(AuthViewModel())
            .environmentObject(WatchlistState())
            .environmentObject(TabBarVisibilityManager())
    }
}
