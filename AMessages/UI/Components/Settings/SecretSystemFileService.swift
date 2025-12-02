import Foundation
import CryptoKit

/// Greške za sistemske .secret datoteke
enum SecretSystemFileError: Error {
    case invalidFormat
    case invalidMagic
    case unsupportedVersion
    case fileTooShort
    case decryptionFailed
    case invalidPayload
}

/// Header / konstante za SISTEMSKE .secret datoteke
///
/// Format:
/// [0..3]   = "AMSS" (ASCII)
/// [4]      = version (UInt8)
/// [5..20]  = salt (16 B)
/// [21..]   = AES.GCM sealedBox.combined
struct SecretSystemFile {
    static let magic = "AMSS".data(using: .utf8)!   // A Messages System Secret
    static let version: UInt8 = 1
    static let saltLength = 16
}

/// Servis za kreiranje i validaciju *sistemskih* .secret datoteka.
///
/// Ne dira bilješke/povijest – to radi SecretNoteService.
/// Ovdje možeš spremati npr. konfiguracije, interne ključeve, meta podatke itd.
final class SecretSystemFileService {

    static let shared = SecretSystemFileService()
    private init() {}

    // MARK: - JAVNI API

    /// Brza provjera je li file uopće ima ispravan header za sistemski .secret.
    func isSystemSecretFile(url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        return Self.isSystemSecretFile(data: data)
    }

    /// Validira strukturu datoteke (magic, verzija, minimalna veličina).
    func validateFile(at url: URL) throws {
        let data = try Data(contentsOf: url)

        guard data.count > 4 + 1 + SecretSystemFile.saltLength else {
            throw SecretSystemFileError.fileTooShort
        }

        let magic = data.prefix(SecretSystemFile.magic.count)
        guard magic == SecretSystemFile.magic else {
            throw SecretSystemFileError.invalidMagic
        }

        let version = data[SecretSystemFile.magic.count]
        guard version == SecretSystemFile.version else {
            throw SecretSystemFileError.unsupportedVersion
        }
    }

    /// Kreira novu SISTEMSKU .secret datoteku sa zadanim payloadom (kao JSON).
    ///
    /// - parameter payload: npr. ["type": "systemProfile", "id": "abc123"]
    func createSystemSecretFile(
        payload: [String: String],
        to url: URL,
        masterKey: SymmetricKey
    ) throws {
        let jsonData = try JSONSerialization.data(
            withJSONObject: payload,
            options: [.sortedKeys]
        )

        let salt = randomBytes(count: SecretSystemFile.saltLength)
        let derivedKey = deriveKey(from: masterKey, salt: salt)

        let sealedBox = try AES.GCM.seal(jsonData, using: derivedKey)

        guard let combined = sealedBox.combined else {
            throw SecretSystemFileError.decryptionFailed
        }

        var fileData = Data()
        fileData.append(SecretSystemFile.magic)
        fileData.append(SecretSystemFile.version)
        fileData.append(salt)
        fileData.append(combined)

        try fileData.write(to: url, options: .atomic)
    }

    /// Učitaj SISTEMSKU .secret datoteku i vrati payload kao [String: String].
    func loadSystemSecretFile(
        from url: URL,
        masterKey: SymmetricKey
    ) throws -> [String: String] {
        let data = try Data(contentsOf: url)
        return try loadSystemSecretFile(from: data, masterKey: masterKey)
    }

    /// Povećaj/izmijeni payload i ponovno ga spremi u isti URL.
    func updateSystemSecretFile(
        at url: URL,
        transform: ([String: String]) -> [String: String],
        masterKey: SymmetricKey
    ) throws {
        let original = try loadSystemSecretFile(from: url, masterKey: masterKey)
        let updated = transform(original)
        try createSystemSecretFile(payload: updated, to: url, masterKey: masterKey)
    }

    // MARK: - INTERNAL (rad s Data umjesto URL-a)

    private static func isSystemSecretFile(data: Data) -> Bool {
        guard data.count >= SecretSystemFile.magic.count + 1 else { return false }
        let magic = data.prefix(SecretSystemFile.magic.count)
        return magic == SecretSystemFile.magic
    }

    private func loadSystemSecretFile(
        from data: Data,
        masterKey: SymmetricKey
    ) throws -> [String: String] {
        let headerSize = SecretSystemFile.magic.count + 1 + SecretSystemFile.saltLength
        guard data.count > headerSize else {
            throw SecretSystemFileError.fileTooShort
        }

        let magic = data.prefix(SecretSystemFile.magic.count)
        guard magic == SecretSystemFile.magic else {
            throw SecretSystemFileError.invalidMagic
        }

        let version = data[SecretSystemFile.magic.count]
        guard version == SecretSystemFile.version else {
            throw SecretSystemFileError.unsupportedVersion
        }

        let saltStart = SecretSystemFile.magic.count + 1
        let saltEnd = saltStart + SecretSystemFile.saltLength
        let salt = data[saltStart..<saltEnd]

        let sealedData = data[saltEnd...]

        let derivedKey = deriveKey(from: masterKey, salt: salt)

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: sealedData)
            let decrypted = try AES.GCM.open(sealedBox, using: derivedKey)

            let obj = try JSONSerialization.jsonObject(with: decrypted, options: [])
            guard let dict = obj as? [String: String] else {
                throw SecretSystemFileError.invalidPayload
            }
            return dict
        } catch {
            throw SecretSystemFileError.decryptionFailed
        }
    }

    // MARK: - KDF (derivacija ključa za SISTEMSKE datoteke)

    /// Derivacija ključa iz masterKey + salt, odvojena "domenskim" info stringom,
    /// da se razlikuje od drugih tipova šifriranih podataka.
    private func deriveKey(from masterKey: SymmetricKey, salt: Data) -> SymmetricKey {
        let info = "AMessages-SystemSecret".data(using: .utf8)!
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
        return derived
    }

    // MARK: - RNG helper

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
