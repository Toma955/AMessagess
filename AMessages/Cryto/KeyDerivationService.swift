import Foundation
import CryptoKit

enum KeyDerivationError: Error {
    case fileMissing
    case invalidPin
    case readFailed
}

struct KeyDerivationService {

    /// Glavna funkcija: iz datoteke + PIN-a derivira 256-bitni simetrični ključ
    static func deriveMasterKey(profileURL: URL?, pin: String) throws -> SymmetricKey {
        guard let url = profileURL else {
            throw KeyDerivationError.fileMissing
        }

        guard pin.count == 12 else {
            throw KeyDerivationError.invalidPin
        }

        let fileData: Data
        do {
            fileData = try Data(contentsOf: url)
        } catch {
            throw KeyDerivationError.readFailed
        }

        // 1) Hash cijele datoteke (bilo kojeg tipa) → 32 bajta
        let fileHash = Data(SHA256.hash(data: fileData))

        // 2) Spoji fileHash + PIN u jedan buffer
        var combined = Data()
        combined.append(fileHash)
        combined.append(Data(pin.utf8))

        // 3) "KDF light": nekoliko rundi SHA256 da malo istegnemo lozinku
        var stretched = combined
        let rounds = 10_000   // možeš kasnije dignut ako želiš sporije
        for _ in 0..<rounds {
            stretched = Data(SHA256.hash(data: stretched))
        }

        // 4) Od finalnog hasha napravimo SymmetricKey (256 bita)
        let masterKey = SymmetricKey(data: stretched)
        return masterKey
    }
}

