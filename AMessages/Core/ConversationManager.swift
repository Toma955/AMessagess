
import Foundation

final class ConversationManager: ObservableObject {
    @Published var conversations: [Conversation] = []

    init() {
        loadDemoConversations()
    }

    func loadDemoConversations() {
        conversations = [
            Conversation(
                id: "demo-1",
                title: "Demo razgovor",
                lastUpdated: Date()
            )
        ]
    }

    func addConversation(title: String) {
        let convo = Conversation(
            id: UUID().uuidString,
            title: title,
            lastUpdated: Date()
        )
        conversations.append(convo)
    }
}

