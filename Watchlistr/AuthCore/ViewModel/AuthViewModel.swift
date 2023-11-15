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
import FirebaseStorage
import SwiftMessages

protocol AuthFormProtocol {
    var formIsValid: Bool {get}
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: Firebase.User?
    @Published var currentUser: User?
    
    init () {
        self.userSession = Auth.auth().currentUser
        Task {
            await fetchUser()
        }
    }
    
    func createUser(withEmail email: String, password: String, username: String) async throws {
        do {
            let res = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = res.user
            let user = User(id: res.user.uid, username: username, email: email, creationDate: res.user.metadata.creationDate)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch {
            showMessage(withTitle: "User Creation Failed", message: error.localizedDescription, theme: .error)
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else {
            showMessage(withTitle: "Error Fetching User.", message: "Please try again later.", theme: .error)
            return
        }
        if var currentUser = try? snapshot.data(as: User.self) {
            let creationDate = Auth.auth().currentUser?.metadata.creationDate
            currentUser.creationDate = creationDate
            self.currentUser = currentUser
        }
        NotificationCenter.default.post(name: .userDidLogIn, object: nil)
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let res = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = res.user
            await fetchUser()
        } catch {
            showMessage(withTitle: "Error Signing In", message: error.localizedDescription, theme: .error)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            NotificationCenter.default.post(name: .userDidLogOut, object: nil)
        } catch {
            showMessage(withTitle: "Logout Failed", message: error.localizedDescription, theme: .error)
        }
    }
    
    func deleteAccount(currentPassword: String) async {
        do {
            guard let user = Auth.auth().currentUser else { return }
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
            try await user.reauthenticate(with: credential)

            try await withCheckedThrowingContinuation { continuation in
                deleteUserProfileImage(userId: user.uid) { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: ())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            let watchlistData = Firestore.firestore().collection("watchlists").document(user.uid)
            try await watchlistData.delete()
            let userData = Firestore.firestore().collection("users").document(user.uid)
            try await userData.delete()

            try await user.delete()
            signOut()
            showSuccess(withTitle: "Account Deleted", message: "Your account and all associated data have been successfully deleted.")
        } catch {
            showMessage(withTitle: "Account Deletion Failed", message: error.localizedDescription, theme: .error)
        }
    }
    
    func changePass(currentPassword: String, newPassword: String) async throws {
        do {
            guard let user = Auth.auth().currentUser else {return}
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
            showMessage(withTitle: "Success", message: "Password changed successfully.", theme: .success)
        } catch {
            showMessage(withTitle: "Password Change Failed", message: error.localizedDescription, theme: .error)
            throw error
        }
    }
    
    func changeEmail(currentPassword: String, newEmail: String) async throws {
        do {
            guard let user = Auth.auth().currentUser else { return }
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
            try await user.reauthenticate(with: credential)
            try await user.updateEmail(to: newEmail)
            try await Firestore.firestore().collection("users").document(user.uid).updateData(["email": newEmail])
            showMessage(withTitle: "Success", message: "Email changed successfully to \(newEmail).", theme: .success)
            
        } catch {
            showMessage(withTitle: "Email Change Failed", message: error.localizedDescription, theme: .error)
            throw error
        }
    }
    
    func sendResetPasswordEmail(forEmail email: String) async {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                showMessage(withTitle: "Success", message: "An email with instructions has been sent to \(email).", theme: .success)
            } catch {
                showMessage(withTitle: "Error Sending Email", message: error.localizedDescription, theme: .error)
            }
        }
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userSession?.uid else {
            completion(.failure(ImageUploadError.userNotLoggedIn))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.4) else {
            completion(.failure(ImageUploadError.imageConversionError))
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let url = url {
                    self.updateUserProfileImageUrl(userId: userId, url: url, completion: completion)
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        }
    }

    func updateUserProfileImageUrl(userId: String, url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let userDoc = Firestore.firestore().collection("users").document(userId)
        userDoc.updateData(["profileImageUrl": url.absoluteString]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private func deleteUserProfileImage(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        storageRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

extension Notification.Name {
    static let userDidLogOut = Notification.Name("UserDidLogOut")
}

extension Notification.Name {
    static let userDidLogIn = Notification.Name("UserDidLogIn")
}
