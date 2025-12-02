import Foundation

// MARK: - Greške za settings profile datoteke

enum SettingsProfileFileError: Error {
    case invalidFormat
    case invalidMagic
    case unsupportedVersion
    case decodeFailed
    case encodeFailed
}

// MARK: - Format fajla
//
// [0..3]  = "AMSP" (ASCII)  -> A Messages Settings Profile
// [4]     = version (UInt8)
// [5..]   = JSON (UTF-8) AppSettingsProfile

struct SettingsProfileFile {
    static let magic = "AMSP".data(using: .utf8)!   // A Messages Settings Profile
    static let version: UInt8 = 1
}

// MARK: - Struktura korisničkih postavki koje želimo izvoziti/uvoziti

/// Ovo je "portable" snapshot postavki.
/// Kasnije ga možeš mapirati na ThemeManager, SessionManager itd.
struct AppSettingsProfile: Codable {
    /// Verzija formata (za buduće promjene)
    var formatVersion: Int = Int(SettingsProfileFile.version)

    /// Tema (AppThemeID.rawValue)
    var themeIDRaw: Int

    /// Jezik, npr. "hr", "en", "de", "fr"
    var languageCode: String

    /// Skaliranje teksta (1.0 = default)
    var fontScale: Double

    /// Opće UI skaliranje (gumbi, paneli)
    var uiScale: Double

    /// Jačina pozadinskih animacija (0–1)
    var backgroundAnimationIntensity: Double

    /// Widgeti / dodatci
    var islandEnabled: Bool
    var dockEnabled: Bool

    /// Možeš dodavati nova polja u budućnosti (uz paziti na kompatibilnost)
}

// MARK: - Servis za čitanje/pisanje settings fajlova

final class SettingsProfileFileService {

    static let shared = SettingsProfileFileService()
    private init() {}

    // MARK: - Public API

    /// Brza provjera je li fajl uopće settings profil (po headeru)
    func isSettingsProfileFile(url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        return Self.isSettingsProfileFile(data: data)
    }

    /// Učitaj AppSettingsProfile iz fajla (validira header + verziju)
    func loadProfile(from url: URL) throws -> AppSettingsProfile {
        let data = try Data(contentsOf: url)
        return try decodeProfile(from: data)
    }

    /// Spremi AppSettingsProfile u fajl, s headerom + JSON-om
    func saveProfile(_ profile: AppSettingsProfile, to url: URL) throws {
        let data = try encodeProfile(profile)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Internal (Data-based)

    private static func isSettingsProfileFile(data: Data) -> Bool {
        guard data.count >= SettingsProfileFile.magic.count + 1 else { return false }
        let magic = data.prefix(SettingsProfileFile.magic.count)
        return magic == SettingsProfileFile.magic
    }

    private func decodeProfile(from data: Data) throws -> AppSettingsProfile {
        let headerLen = SettingsProfileFile.magic.count + 1
        guard data.count > headerLen else {
            throw SettingsProfileFileError.invalidFormat
        }

        let magic = data.prefix(SettingsProfileFile.magic.count)
        guard magic == SettingsProfileFile.magic else {
            throw SettingsProfileFileError.invalidMagic
        }

        let version = data[SettingsProfileFile.magic.count]
        guard version == SettingsProfileFile.version else {
            throw SettingsProfileFileError.unsupportedVersion
        }

        let jsonData = data.suffix(from: headerLen)

        do {
            let profile = try JSONDecoder().decode(AppSettingsProfile.self, from: jsonData)
            return profile
        } catch {
            throw SettingsProfileFileError.decodeFailed
        }
    }

    private func encodeProfile(_ profile: AppSettingsProfile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData: Data
        do {
            jsonData = try encoder.encode(profile)
        } catch {
            throw SettingsProfileFileError.encodeFailed
        }

        var out = Data()
        out.append(SettingsProfileFile.magic)
        out.append(SettingsProfileFile.version)
        out.append(jsonData)
        return out
    }
}
