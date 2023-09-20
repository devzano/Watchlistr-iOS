//
//  ChangePassView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct ChangePassView: View {
    @State private var currPass = ""
    @State private var newPass = ""
    @State private var confNewPass = ""
    @State private var showPasswordRequirements = false
    @EnvironmentObject var vm: AuthViewModel
    
    var body: some View {
        ZStack {
            backgroundImage
            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .padding(.vertical, 50)
                
                VStack(spacing: 24) {
                    InputView(
                        text: $currPass,
                        title: "Current Password:",
                        placeholder: "enter current password",
                        isSecureField: true
                    )
                    
                    ZStack(alignment: .trailing) {
                        InputView(
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
                        InputView(
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
                
                ButtonView(action: {
                    Task {
                        do {
                            try await vm.changePass(currentPassword: currPass, newPassword: newPass)
                            currPass = ""
                            newPass = ""
                            confNewPass = ""
                        } catch {
                            print("DEBUG: Failed to change password with error \(error.localizedDescription)")
                        }
                    }
                }, label: "Change Password", imageName: "arrow.right")
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                .padding(.top, 24)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .onAppear {
            startImageTimer()
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
    

extension ChangePassView: AuthFormProtocol {
    var formIsValid: Bool {
        let capitalLetterCharacterSet = CharacterSet.uppercaseLetters
        let numberCharacterSet = CharacterSet.decimalDigits
        let specialCharacterSet = CharacterSet(charactersIn: "!@#$%^&*()_-+=<>?/")
        
        return !currPass.isEmpty
        && !newPass.isEmpty
        && newPass.count > 5
        && newPass.rangeOfCharacter(from: capitalLetterCharacterSet) != nil
        && newPass.rangeOfCharacter(from: numberCharacterSet) != nil
        && newPass.rangeOfCharacter(from: specialCharacterSet) != nil
        && newPass == confNewPass
    }
}

struct ChangePassView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePassView()
    }
}
