//
//  KeychainService.swift
//  Nova
//
//  Created by Claude on 7/17/25.
//

import Foundation
import Security

/// Secure storage service using macOS Keychain
class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Constants
    
    private let serviceName = "com.nova.apikeys"
    private let accessGroup: String? = nil // Use default access group
    
    // MARK: - Public API
    
    /// Store an API key securely in the Keychain
    /// - Parameters:
    ///   - key: The API key value to store
    ///   - provider: The AI provider this key belongs to
    /// - Returns: True if successful, false otherwise
    func storeAPIKey(_ key: String, for provider: AIProvider) -> Bool {
        let account = provider.rawValue
        
        // Delete any existing item first
        deleteAPIKey(for: provider)
        
        // Create new keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: key.data(using: .utf8) ?? Data(),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("🔐 ✅ API key stored securely for \(provider.displayName)")
            return true
        } else {
            print("🔐 ❌ Failed to store API key for \(provider.displayName): \(status)")
            return false
        }
    }
    
    /// Retrieve an API key from the Keychain
    /// - Parameter provider: The AI provider to get the key for
    /// - Returns: The API key if found, empty string otherwise
    func getAPIKey(for provider: AIProvider) -> String {
        let account = provider.rawValue
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8) {
            return key
        } else if status != errSecItemNotFound {
            print("🔐 ❌ Failed to retrieve API key for \(provider.displayName): \(status)")
        }
        
        return ""
    }
    
    /// Check if an API key exists for a provider
    /// - Parameter provider: The AI provider to check
    /// - Returns: True if a key exists, false otherwise
    func hasAPIKey(for provider: AIProvider) -> Bool {
        let account = provider.rawValue
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Delete an API key from the Keychain
    /// - Parameter provider: The AI provider to delete the key for
    /// - Returns: True if successful or if no key existed, false on error
    func deleteAPIKey(for provider: AIProvider) -> Bool {
        let account = provider.rawValue
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            if status == errSecSuccess {
                print("🔐 ✅ API key deleted for \(provider.displayName)")
            }
            return true
        } else {
            print("🔐 ❌ Failed to delete API key for \(provider.displayName): \(status)")
            return false
        }
    }
    
    /// Get all providers that have API keys stored
    /// - Returns: Array of providers that have keys in the Keychain
    func getProvidersWithKeys() -> [AIProvider] {
        return AIProvider.allCases.filter { hasAPIKey(for: $0) }
    }
    
    /// Clear all stored API keys (for debugging/reset purposes)
    /// - Returns: True if successful, false otherwise
    func clearAllAPIKeys() -> Bool {
        var allSuccessful = true
        
        for provider in AIProvider.allCases {
            if !deleteAPIKey(for: provider) {
                allSuccessful = false
            }
        }
        
        return allSuccessful
    }
    
    // MARK: - Migration Support
    
    /// Migrate API keys from AppConfig to Keychain
    /// - Parameter appConfig: The AppConfig instance to migrate from
    /// - Returns: True if migration was successful, false otherwise
    func migrateFromAppConfig(_ appConfig: AppConfig) -> Bool {
        print("🔐 🔄 Starting API key migration to Keychain...")
        
        var migrationSuccessful = true
        var keysMigrated = 0
        
        // Migrate each provider's API key if it exists
        for provider in AIProvider.allCases where provider.requiresApiKey {
            let key = appConfig.getApiKey(for: provider)
            
            if !key.isEmpty {
                if storeAPIKey(key, for: provider) {
                    keysMigrated += 1
                    print("🔐 ✅ Migrated key for \(provider.displayName)")
                } else {
                    migrationSuccessful = false
                    print("🔐 ❌ Failed to migrate key for \(provider.displayName)")
                }
            }
        }
        
        if migrationSuccessful {
            print("🔐 ✅ Migration completed successfully. \(keysMigrated) keys migrated.")
        } else {
            print("🔐 ❌ Migration completed with errors.")
        }
        
        return migrationSuccessful
    }
}

// MARK: - Error Handling

extension KeychainService {
    /// Convert Security framework error codes to readable descriptions
    private func keychainErrorDescription(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecItemNotFound:
            return "Item not found"
        case errSecDuplicateItem:
            return "Duplicate item"
        case errSecParam:
            return "Invalid parameters"
        case errSecAllocate:
            return "Memory allocation failure"
        case errSecNotAvailable:
            return "Keychain not available"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecUserCanceled:
            return "User canceled operation"
        default:
            return "Unknown error (\(status))"
        }
    }
}