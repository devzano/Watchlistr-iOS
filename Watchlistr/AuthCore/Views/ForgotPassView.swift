//
//  ForgotPassView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import SwiftUI

struct ForgotPassView: View {
    @State private var email = ""
    @State private var isSendingEmail = false

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: AuthViewModel
    
    var body: some View {
        ZStack {
            backgroundImage
            VStack {
                VStack(spacing: 8) {
                    welcomeMessage
                    Button(action: {
                        dismiss()
                    }) {
                        Image("Logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 120)
                    }
                }.padding(.vertical, 50)
                
                VStack(spacing: 24) {
                    InputView(
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
                
                ButtonView(action: {
                    isSendingEmail = true
                    Task {
                        await vm.sendResetPasswordEmail(forEmail: email)
                        isSendingEmail = false
                        email = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }, label: "Send Link", imageName: "arrow.right")
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                .padding(.top, 24)
                
                Spacer()
            }.padding(.bottom, 30)
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
    }
}
