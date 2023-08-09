//
//  AuthViewModel.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 8/8/23.
//

import Foundation

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        }
    }
    
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
    
    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
    }
}
