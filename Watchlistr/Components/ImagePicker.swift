//
//  ImagePicker.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/5/23.
//

import FirebaseStorage
import FirebaseFirestore
import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var profileImageUrl: URL?
    @Environment(\.presentationMode) private var presentationMode
    var userId: String

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, userId: userId, profileImageUrl: $profileImageUrl)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        var userId: String
        var profileImage: Binding<URL?>

        init(_ parent: ImagePicker, userId: String, profileImageUrl: Binding<URL?>) {
            self.parent = parent
            self.userId = userId
            self.profileImage = profileImageUrl
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
                parent.presentationMode.wrappedValue.dismiss()
                return
            }
            
            uploadProfileImage(image, userId: userId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url):
                        self.parent.profileImageUrl = nil
                        self.parent.selectedImage = image
                        self.updateUserProfileImageUrl(userId: self.userId, url: url)
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }

        private func uploadProfileImage(_ image: UIImage, userId: String, completion: @escaping (Result<URL, Error>) -> Void) {
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
                        completion(.success(url))
                    } else if let error = error {
                        completion(.failure(error))
                    }
                }
            }
        }

        private func updateUserProfileImageUrl(userId: String, url: URL) {
            let userDoc = Firestore.firestore().collection("users").document(userId)
            userDoc.updateData(["profileImageUrl": url.absoluteString]) { error in
                if let error = error {
                    showError(withTitle: "Error", message: "Error updating profile picture: \(error)")
                } else {
                    showSuccess(withTitle: "Success", message: "Profile picture updated successfully!")
                }
            }
        }
    }
}

enum ImageUploadError: Error {
    case userNotLoggedIn
    case imageConversionError
}

extension ImageUploadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .userNotLoggedIn:
            return "User not logged in."
        case .imageConversionError:
            return "Unable to convert the image to a suitable format."
        }
    }
}
