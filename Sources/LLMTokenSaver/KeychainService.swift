import Foundation
import Security

enum KeychainService {

    private static let service = "LLMTokenSaver"

    private static let openAIAPIKeyAccount = "OpenAIAPIKey"
    private static let copilotAPIKeyAccount = "GitHubCopilotAPIKey"

    static func saveAPIKey(
        _ apiKey: String,
        for provider: LLMProvider
    ) throws {

        let account = provider == .openAI ? openAIAPIKeyAccount : copilotAPIKeyAccount

        let data = Data(apiKey.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(newItem as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func loadAPIKey(
        for provider: LLMProvider
    ) throws -> String? {

        let account = provider == .openAI ? openAIAPIKeyAccount : copilotAPIKeyAccount

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.loadFailed(status)
        }

        guard
            let data = result as? Data,
            let apiKey = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.invalidData
        }

        return apiKey
    }

    static func deleteAPIKey(
        for provider: LLMProvider
    ) throws {

        let account = provider == .openAI ? openAIAPIKeyAccount : copilotAPIKeyAccount

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    static func saveAPIKey(_ apiKey: String) throws {
        try saveAPIKey(apiKey, for: .openAI)
    }

    static func loadAPIKey() throws -> String? {
        try loadAPIKey(for: .openAI)
    }

    static func deleteAPIKey() throws {
        try deleteAPIKey(for: .openAI)
    }
}

enum KeychainError: LocalizedError {

    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Не удалось сохранить API Key. Keychain status: \(status)"
        case .loadFailed(let status):
            return "Не удалось прочитать API Key. Keychain status: \(status)"
        case .deleteFailed(let status):
            return "Не удалось удалить API Key. Keychain status: \(status)"
        case .invalidData:
            return "Некорректные данные API Key в Keychain."
        }
    }
}
