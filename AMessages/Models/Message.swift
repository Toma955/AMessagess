import Foundation

enum MessageDirection: String, Codable {
    case incoming
    case outgoing
}

struct Message: Identifiable, Codable {
    let id: UUID
    let conversationId: String
    let direction: MessageDirection
    let timestamp: Date
    let text: String

    static func demo(conversationId: String) -> Message {
        Message(
            id: UUID(),
            conversationId: conversationId,
            direction: .incoming,
            timestamp: Date(),
            text: "Ovo je demo poruka."
        )
    }
}
