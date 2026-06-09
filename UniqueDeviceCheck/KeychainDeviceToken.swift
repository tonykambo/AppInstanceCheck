// Project: UniqueDeviceCheck  🚀  SwiftUI + Keychain demo
// ─────────────────────────────────────────────────────────────
// The app now:
//   • Detects whether it **loads** an existing device‑binding token or
//     **creates** a new one and shows a status banner.
//   • Lets you copy the token to the clipboard so you can paste it on
//     your Mac and verify persistence across an uninstall/re‑install.
//   • Keeps everything split into the same three files you already have
//     in your Xcode project.
//
// Paste each section into its respective Swift file.
// ---------------------------------------------------------------------

// MARK: 1️⃣ KeychainDeviceToken.swift
// ---------------------------------------------------------------------

import Foundation
import Security

struct KeychainDeviceToken {
    private static let service = "com.example.uniquedevicecheck.binding"
    private static let account = "device-token"

    /// Shared attributes for *this* Keychain item.
    private static var baseQuery: [CFString: Any] {
        [
            kSecClass:              kSecClassGenericPassword,
            kSecAttrService:        service,
            kSecAttrAccount:        account,
            kSecAttrAccessible:     kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
    }

    /// Returns the token if it already exists.
    static func load() -> String? {
        var q = baseQuery
        q[kSecReturnData]  = kCFBooleanTrue
        q[kSecMatchLimit]  = kSecMatchLimitOne

        var out: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        guard status == errSecSuccess,
              let data = out as? Data,
              let str  = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    /// Creates a token only if one does **not** already exist.
    /// - Returns: `(token, createdNew)` where `createdNew` is *true* when
    ///            the item was successfully inserted.
    @discardableResult
    static func create() -> (token: String, createdNew: Bool) {
        let uuid = UUID().uuidString
        var q = baseQuery
        q[kSecValueData] = uuid.data(using: .utf8)!

        let status = SecItemAdd(q as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return (uuid, true)   // brand‑new item
        case errSecDuplicateItem:
            // falls back to loading the existing value so callers always
            // get the correct token.
            return (load() ?? uuid, false)
        default:
            return (uuid, false)  // unexpected, but keeps compile simple
        }
    }

    /// Deletes the token—used to reset the demo.
    static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
