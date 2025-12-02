import Foundation
import CryptoKit

/// Drži stanje lanca ključeva za jednu stranu (send ili receive)
struct MessageRatchetState {
    private(set) var chainKey: SymmetricKey

    init(chainKey: SymmetricKey) {
        self.chainKey = chainKey
    }

    /// Inicijalizacija iz masterKey + roomCode
    /// (isti kod na obje strane → dobiju isti početni chainKey)
    static func from(masterKey: SymmetricKey, roomCode: String) -> MessageRatchetState {
        let saltData = Data("room:\(roomCode)".utf8)
        let infoData = Data("msg_root".utf8)

        let rootKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: saltData,
            info: infoData,
            outputByteCount: 32
        )

        return MessageRatchetState(chainKey: rootKey)
    }

    /// Svaki poziv vraća NOVI ključ za jednu poruku i rotira chainKey naprijed
    mutating func nextEncryptionKey() -> SymmetricKey {
        let stepData = Data("chain_step".utf8)
        let newChainMac = HMAC<SHA256>.authenticationCode(
            for: stepData,
            using: chainKey
        )
        let newChainKey = SymmetricKey(data: Data(newChainMac))

        let msgData = Data("msg_key".utf8)
        let msgMac = HMAC<SHA256>.authenticationCode(
            for: msgData,
            using: newChainKey
        )
        let msgKey = SymmetricKey(data: Data(msgMac))

        self.chainKey = newChainKey
        return msgKey
    }
}
