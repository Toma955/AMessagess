//
//  CrytoService.swift
//  AMessages
//
//  Created by Toma Babić on 25.11.2025..
//

import Foundation

final class CryptoService {
    static let shared = CryptoService()

    private init() {}

    // za sada samo “fake” funkcije da postoje

    func deriveKey(from pin: String) -> Data {
        // kasnije: PBKDF2/Argon2
        return Data(pin.utf8)
    }

    func encryptDemo(text: String) -> Data {
        // kasnije: prava enkripcija
        return Data(text.utf8)
    }

    func decryptDemo(data: Data) -> String {
        String(data: data, encoding: .utf8) ?? ""
    }
}
