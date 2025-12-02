import Foundation

final class RelayClient {
    static let shared = RelayClient()
    private init() {}

    // Tip “medija” – audio, slika, video, file (folder šalješ kao zip → file)
    enum MediaKind: String {
        case audio
        case image
        case video
        case file
    }

    /// Kasnije: ovdje ćeš se spajati na pravi server (WebSocket, HTTP…)
    func connect() {
        // stub
        print("RelayClient: connect() pozvan (stub)")
    }

    /// Jednostavan “ping” sobe.
    /// Trenutno je stub – glumi da je server živ nakon male pauze.
    func ping(roomId: String, completion: @escaping (Bool) -> Void) {
        print("RelayClient: ping(\(roomId))… (stub)")

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            // TODO: ovdje jednom ide pravi HTTP/WebSocket ping
            completion(true)
        }
    }

    /// Slanje šifriranih podataka za određeni room/conversation
    func send(data: Data, to conversationId: String) {
        // stub
        print("RelayClient: send \(data.count) bajtova za \(conversationId) (stub)")
    }

    /// Helper za slanje šifriranog teksta (već u Data obliku)
    func sendEncryptedText(_ data: Data, to conversationId: String) {
        send(data: data, to: conversationId)
    }

    /// Helper za slanje šifriranog binarnog payload-a (audio, slika, video, file…)
    func sendEncryptedMedia(_ data: Data,
                            kind: MediaKind,
                            to conversationId: String) {
        print("RelayClient: sendEncryptedMedia kind=\(kind.rawValue) size=\(data.count) for \(conversationId)")
        send(data: data, to: conversationId)
    }

    /// “Primanje” – kasnije će tu biti callback iz socketa; za sada samo closure
    func simulateIncomingMessage(text: String,
                                 conversationId: String,
                                 handler: (Message) -> Void) {
        let msg = Message(
            id: UUID(),
            conversationId: conversationId,
            direction: .incoming,
            timestamp: Date(),
            text: text
        )
        handler(msg)
    }
}
