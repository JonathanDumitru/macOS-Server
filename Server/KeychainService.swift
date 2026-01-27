//
//  KeychainService.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import Security

// MARK: - Server Credentials

struct ServerCredentials: Codable, Equatable {
    var username: String
    var password: String
    var privateKey: String?
    var privateKeyPassphrase: String?
    var authType: AuthenticationType

    enum AuthenticationType: String, Codable, CaseIterable {
        case password = "Password"
        case privateKey = "Private Key"
        case privateKeyWithPassphrase = "Private Key + Passphrase"

        var icon: String {
            switch self {
            case .password: return "key.fill"
            case .privateKey: return "doc.text.fill"
            case .privateKeyWithPassphrase: return "lock.doc.fill"
            }
        }
    }

    init(
        username: String = "",
        password: String = "",
        privateKey: String? = nil,
        privateKeyPassphrase: String? = nil,
        authType: AuthenticationType = .password
    ) {
        self.username = username
        self.password = password
        self.privateKey = privateKey
        self.privateKeyPassphrase = privateKeyPassphrase
        self.authType = authType
    }

    var isValid: Bool {
        guard !username.isEmpty else { return false }

        switch authType {
        case .password:
            return !password.isEmpty
        case .privateKey:
            return privateKey != nil && !privateKey!.isEmpty
        case .privateKeyWithPassphrase:
            return privateKey != nil && !privateKey!.isEmpty && privateKeyPassphrase != nil
        }
    }
}

// MARK: - Keychain Service

class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.servermonitor.credentials"

    private init() {}

    // MARK: - Save Credentials

    /// Save credentials for a server
    func saveCredentials(_ credentials: ServerCredentials, forServerID serverID: String) throws {
        let data = try JSONEncoder().encode(credentials)

        // Delete existing item if present
        try? deleteCredentials(forServerID: serverID)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: serverID,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: - Load Credentials

    /// Load credentials for a server
    func loadCredentials(forServerID serverID: String) throws -> ServerCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: serverID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.loadFailed(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return try JSONDecoder().decode(ServerCredentials.self, from: data)
    }

    // MARK: - Delete Credentials

    /// Delete credentials for a server
    func deleteCredentials(forServerID serverID: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: serverID
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    // MARK: - Check if Credentials Exist

    /// Check if credentials exist for a server
    func hasCredentials(forServerID serverID: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: serverID,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Update Credentials

    /// Update existing credentials
    func updateCredentials(_ credentials: ServerCredentials, forServerID serverID: String) throws {
        let data = try JSONEncoder().encode(credentials)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: serverID
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                // Item doesn't exist, create it
                try saveCredentials(credentials, forServerID: serverID)
            } else {
                throw KeychainError.updateFailed(status)
            }
        }
    }

    // MARK: - List All Server IDs with Credentials

    /// Get all server IDs that have stored credentials
    func getAllServerIDsWithCredentials() throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return []
            }
            throw KeychainError.loadFailed(status)
        }

        guard let items = result as? [[String: Any]] else {
            return []
        }

        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }

    // MARK: - Clear All Credentials

    /// Delete all stored credentials (use with caution)
    func clearAllCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case updateFailed(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save credentials: \(securityErrorMessage(for: status))"
        case .loadFailed(let status):
            return "Failed to load credentials: \(securityErrorMessage(for: status))"
        case .deleteFailed(let status):
            return "Failed to delete credentials: \(securityErrorMessage(for: status))"
        case .updateFailed(let status):
            return "Failed to update credentials: \(securityErrorMessage(for: status))"
        case .invalidData:
            return "Invalid credential data"
        }
    }

    private func securityErrorMessage(for status: OSStatus) -> String {
        if let message = SecCopyErrorMessageString(status, nil) as String? {
            return message
        }
        return "Error code: \(status)"
    }
}
