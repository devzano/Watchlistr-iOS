//
//  Keychain.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 10/4/23.
//

import Foundation
import Security

class KeychainWrapper {
    // Keychain setup constants
    private let service: String = Bundle.main.bundleIdentifier!
    private let accountEmail: String = "email"
    private let accountPassword: String = "password"
    
    // Save email to Keychain
    func saveEmail(email: String) -> Bool {
        guard let data = email.data(using: .utf8) else {
            return false
        }
        return save(data: data, account: accountEmail)
    }
    
    // Retrieve email from Keychain
    func retrieveEmail() -> String? {
        guard let data = retrieve(account: accountEmail) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    // Save password to Keychain
    func savePassword(password: String) -> Bool {
        guard let data = password.data(using: .utf8) else {
            return false
        }
        return save(data: data, account: accountPassword)
    }
    
    // Retrieve password from Keychain
    func retrievePassword() -> String? {
        guard let data = retrieve(account: accountPassword) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    // General save function
    private func save(data: Data, account: String) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ] as CFDictionary
        SecItemDelete(query)
        return SecItemAdd(query, nil) == noErr
    }
    
    // General retrieve function
    private func retrieve(account: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as CFDictionary
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        if status == noErr {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
}
