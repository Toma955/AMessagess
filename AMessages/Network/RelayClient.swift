import Foundation

/// Callback za primanje poruka preko Relay-a
typealias RelayMessageCallback = (Message, String) -> Void

final class RelayClient {
    static let shared = RelayClient()
    private init() {}

    // Tip "medija" – audio, slika, video, file (folder šalješ kao zip → file)
    enum MediaKind: String {
        case audio
        case image
        case video
        case file
    }
    
    /// Callback za primanje poruka
    private var messageCallback: RelayMessageCallback?
    
    /// WebSocket konekcija (za kasniju implementaciju)
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession = URLSession(configuration: .default)

    /// Postavi callback za primanje poruka
    func setMessageCallback(_ callback: @escaping RelayMessageCallback) {
        self.messageCallback = callback
    }
    
    /// Pozovi callback s primljenom porukom (koristi se iz WebSocket handlera)
    func notifyMessageReceived(_ message: Message, conversationId: String) {
        messageCallback?(message, conversationId)
    }

    /// Kasnije: ovdje ćeš se spajati na pravi server (WebSocket, HTTP…)
    func connect(serverURL: String? = nil) {
        // stub - kasnije će se spajati na WebSocket
        print("RelayClient: connect() pozvan (stub)")
        
        // TODO: Implementirati WebSocket konekciju
        // - Kreirati URLSessionWebSocketTask
        // - Postaviti receive loop
        // - Pozivati notifyMessageReceived kada stigne poruka
    }
    
    /// Zatvori konekciju
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
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

    /// "Primanje" – kasnije će tu biti callback iz socketa; za sada samo closure
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
    
    /// Simuliraj primanje poruke (za testiranje)
    /// U produkciji će ovo biti pozvano iz WebSocket receive handlera
    func handleIncomingMessage(text: String, conversationId: String) {
        let msg = Message(
            id: UUID(),
            conversationId: conversationId,
            direction: .incoming,
            timestamp: Date(),
            text: text
        )
        notifyMessageReceived(msg, conversationId: conversationId)
    }
}
