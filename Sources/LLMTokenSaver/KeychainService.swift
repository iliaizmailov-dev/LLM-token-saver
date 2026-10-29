import Foundation
import Security

enum KeychainService {

    private static let service =
        "LLMTokenSaver"

    private static let apiKeyAccount =
        "OpenAIAPIKey"

    static func saveAPIKey(
        _ apiKey: String
    ) throws {

        let data = Data(
            apiKey.utf8
        )

        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                apiKeyAccount
        ]

        SecItemDelete(
            query as CFDictionary
        )

        var newItem = query

        newItem[
            kSecValueData as String
        ] = data

        newItem[
            kSecAttrAccessible as String
        ] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status =
            SecItemAdd(
                newItem as CFDictionary,
                nil
            )

        guard status == errSecSuccess else {
            throw KeychainError
                .saveFailed(status)
        }
    }

    static func loadAPIKey() throws -> String? {

        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                apiKeyAccount,

            kSecReturnData as String:
                true,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status =
            SecItemCopyMatching(
                query as CFDictionary,
                &result
            )

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError
                .loadFailed(status)
        }

        guard
            let data = result as? Data,
            let apiKey = String(
                data: data,
                encoding: .utf8
            )
        else {
            throw KeychainError
                .invalidData
        }

        return apiKey
    }

    static func deleteAPIKey() throws {

        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                apiKeyAccount
        ]

        let status =
            SecItemDelete(
                query as CFDictionary
            )

        guard
            status == errSecSuccess ||
            status == errSecItemNotFound
        else {
            throw KeychainError
                .deleteFailed(status)
        }
    }
}

enum KeychainError:
    LocalizedError {

    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData

    var errorDescription: String? {

        switch self {

        case .saveFailed(let status):
            return
                "Не удалось сохранить API Key. " +
                "Keychain status: \(status)"

        case .loadFailed(let status):
            return
                "Не удалось прочитать API Key. " +
                "Keychain status: \(status)"

        case .deleteFailed(let status):
            return
                "Не удалось удалить API Key. " +
                "Keychain status: \(status)"

        case .invalidData:
            return
                "Некорректные данные API Key " +
                "в Keychain."
        }
    }
}
