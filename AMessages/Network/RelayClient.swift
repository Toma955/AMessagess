import Foundation

final class RelayClient {
    static let shared = RelayClient()
    private init() {}

    /// Kasnije: ovdje ćeš se spajati na pravi server (WebSocket, HTTP…)
    func connect() {
        // stub
        print("RelayClient: connect() pozvan (stub)")
    }

    /// Slanje šifriranih podataka za određeni conversationId
    func send(data: Data, to conversationId: String) {
        // stub
        print("RelayClient: send \(data.count) bajtova za \(conversationId) (stub)")
    }

    /// “Primanje” – kasnije će tu biti callback iz socketa; za sada samo closure
    func simulateIncomingMessage(text: String, conversationId: String, handler: (Message) -> Void) {
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
