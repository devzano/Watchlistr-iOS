//
//  AuthViewModel.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/14/23.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol AuthFormProtocol {
    var formIsValid: Bool {get}
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    init () {
        self.userSession = Auth.auth().currentUser
        Task {
            await fetchUser()
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let res = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = res.user
            await fetchUser()
        } catch {
            showAlert(title: "Login Failed", message: error.localizedDescription)
        }
    }
    
    func createUser(withEmail email: String, password: String, username: String) async throws {
        do {
            let res = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = res.user
            let user = User(id: res.user.uid, username: username, email: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch {
            showAlert(title: "User Creation Failed", message: error.localizedDescription)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            NotificationCenter.default.post(name: .userDidLogOut, object: nil)
        } catch {
            showAlert(title: "Logout Failed", message: error.localizedDescription)
        }
    }
    
    func deleteAccount() async {
        do {
            guard let user = Auth.auth().currentUser else {return}
            try await Firestore.firestore().collection("users").document(user.uid).delete()
            try await user.delete()
            signOut()
        } catch {
            showAlert(title: "Account Deletion Failed", message: error.localizedDescription)
        }
    }
    
    func changePass(currentPassword: String, newPassword: String) async throws {
        do {
            guard let user = Auth.auth().currentUser else {return}
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
            showAlert(title: "Password Changed", message: "Password changed successfully.")
        } catch {
            showAlert(title: "Password Change Failed", message: error.localizedDescription)
            throw error
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else {
            showAlert(title: "Error Fetching User.", message: "Please try again later.")
            return
        }
        self.currentUser = try? snapshot.data(as: User.self)
        NotificationCenter.default.post(name: .userDidLogIn, object: nil)
    }
    
    func sendResetPasswordEmail(forEmail email: String) async {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                showAlert(title: "Password Reset Email Sent", message: "An email with instructions has been sent to \(email).")
            } catch {
                showAlert(title: "Error Sending Email", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
}

extension Notification.Name {
    static let userDidLogOut = Notification.Name("UserDidLogOut")
}

extension Notification.Name {
    static let userDidLogIn = Notification.Name("UserDidLogIn")
}
