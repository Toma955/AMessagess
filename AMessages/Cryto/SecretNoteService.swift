import Foundation
import CryptoKit

enum SecretNoteError: Error {
    case invalidFormat
    case invalidMagic
    case unsupportedVersion
    case fileTooShort
    case decryptionFailed
}

struct SecretNoteFile {
    static let magic = "AMSN".data(using: .utf8)!   // AMessages Notes
    static let version: UInt8 = 1
    static let saltLength = 16
    static let nonceLength = 12     // AES.GCM nonce
    static let tagLength = 16       // AES.GCM tag
}

/// Servis za *.secret datoteke za bilješke / povijest.
/// Radi isključivo s masterKey-em iz SessionManager-a.
final class SecretNoteService {

    // MARK: - PUBLIC API

    /// Spremi tekst bilješke u .secret fajl (šifrirano masterKey-em)
    func saveNote(
        text: String,
        to url: URL,
        masterKey: SymmetricKey
    ) throws {
        let noteData = Data(text.utf8)

        let salt = randomBytes(count: SecretNoteFile.saltLength)
        let nonceBytes = randomBytes(count: SecretNoteFile.nonceLength)
        let nonce = try AES.GCM.Nonce(data: nonceBytes)

        // izvedeni ključ iz masterKey + salt
        let key = deriveKey(from: masterKey, salt: salt)

        let sealed = try AES.GCM.seal(noteData, using: key, nonce: nonce)

        // layout:
        // [magic(4)][version(1)][salt(16)][nonce(12)][cipher...][tag(16)]
        var out = Data()
        out.append(SecretNoteFile.magic)
        out.append(SecretNoteFile.version)
        out.append(salt)
        out.append(nonceBytes)
        out.append(sealed.ciphertext)
        out.append(sealed.tag)

        try out.write(to: url, options: .atomic)
    }

    /// Učitaj i dešifriraj .secret fajl u tekst bilješke
    func loadNote(
        from url: URL,
        masterKey: SymmetricKey
    ) throws -> String {
        let data = try Data(contentsOf: url)
        let noteData = try decryptNote(data: data, masterKey: masterKey)

        guard let text = String(data: noteData, encoding: .utf8) else {
            throw SecretNoteError.decryptionFailed
        }
        return text
    }

    // MARK: - DEKRIPCIJA

    private func decryptNote(
        data: Data,
        masterKey: SymmetricKey
    ) throws -> Data {
        let minLen = SecretNoteFile.magic.count
            + 1
            + SecretNoteFile.saltLength
            + SecretNoteFile.nonceLength
            + SecretNoteFile.tagLength

        guard data.count >= minLen else {
            throw SecretNoteError.fileTooShort
        }

        var offset = 0

        let magic = data.subdata(in: offset..<offset+SecretNoteFile.magic.count)
        offset += SecretNoteFile.magic.count

        guard magic == SecretNoteFile.magic else {
            throw SecretNoteError.invalidMagic
        }

        let version = data[offset]
        offset += 1

        guard version == SecretNoteFile.version else {
            throw SecretNoteError.unsupportedVersion
        }

        let salt = data.subdata(in: offset..<offset+SecretNoteFile.saltLength)
        offset += SecretNoteFile.saltLength

        let nonceData = data.subdata(in: offset..<offset+SecretNoteFile.nonceLength)
        offset += SecretNoteFile.nonceLength

        let remaining = data.count - offset
        guard remaining > SecretNoteFile.tagLength else {
            throw SecretNoteError.fileTooShort
        }

        let cipher = data.subdata(in: offset..<data.count - SecretNoteFile.tagLength)
        let tag = data.suffix(SecretNoteFile.tagLength)

        let key = deriveKey(from: masterKey, salt: salt)
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: cipher,
            tag: tag
        )

        do {
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw SecretNoteError.decryptionFailed
        }
    }

    // MARK: - KEY DERIVACIJA

    private func deriveKey(
        from masterKey: SymmetricKey,
        salt: Data
    ) -> SymmetricKey {
        let info = Data("AMessages-NoteKey".utf8)

        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
        return derived
    }

    // MARK: - HELPER

    private func randomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)

        if status != errSecSuccess {
            // fallback – ne ruši app ako RNG zakaže
            print("Upozorenje: SecRandomCopyBytes nije uspio, koristim arc4random_buf fallback.")
            arc4random_buf(&bytes, count)
        }

        return Data(bytes)
    }
}
