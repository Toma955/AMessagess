import Foundation
import CryptoKit

/// Jednostavan manager za slanje poruka preko RelayClient-a.
/// Za sada je lagani wrapper oko postojećeg RelayClient stuba.
final class MessageTransportManager {

    static let shared = MessageTransportManager()

    private let relay = RelayClient.shared

    private init() {}

    // MARK: - Plain text (bez E2E)

    /// Pošalji plain tekst (bez dodatne enkripcije) u zadani razgovor.
    func sendPlainText(_ text: String, conversationId: String) {
        let data = Data(text.utf8)
        relay.sendEncryptedText(data, to: conversationId)
    }

    // MARK: - E2E enkripcija (demo)

    /// Pošalji enkriptiranu poruku koristeći MessageRatchetState.
    /// Ovdje je samo primjer – ratchet se lokalno inicijalizira za svaki poziv.
    func sendEncryptedText(
        _ text: String,
        roomCode: String,
        masterKey: SymmetricKey
    ) throws {
        // Inicijaliziraj ratchet iz masterKey + roomCode
        var ratchet = MessageRatchetState.from(masterKey: masterKey, roomCode: roomCode)

        // Izvedi ključ za ovu poruku
        let msgKey = ratchet.nextEncryptionKey()

        // Enkriptiraj tekst
        let cipherBase64 = try MessageCryptoService.encryptString(text, with: msgKey)

        // Pretvori u Data i pošalji preko RelayClient-a
        let data = Data(cipherBase64.utf8)
        relay.sendEncryptedText(data, to: roomCode)
    }
}
