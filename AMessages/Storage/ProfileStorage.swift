import Foundation

final class ProfileStorage {
    static let shared = ProfileStorage()
    private init() {}

    /// Čita raw data profil datoteke (za sad bez dekripcije)
    func loadProfileData(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    /// Sprema raw data u profil datoteku (za kasnije ako bude trebalo)
    func saveProfileData(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}
