import Foundation

/// Jedan "agent" za neovisne poruke.
/// Može predstavljati poseban profil, sobu ili način rada.
struct ConnectionAgent: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var details: String
    var iconSystemName: String
    var colorTag: String   // npr. "green", "blue", "orange" – UI će to kasnije interpretirati
    var roomCode: String   // 16-znakovni kod sobe (kao kod običnih poruka)
    var isFavorite: Bool
    var createdAt: Date
    var lastUsedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        iconSystemName: String = "person.crop.circle",
        colorTag: String = "blue",
        roomCode: String = "",
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.iconSystemName = iconSystemName
        self.colorTag = colorTag
        self.roomCode = roomCode
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    /// Prazan template za "novog" agenta
    static func empty() -> ConnectionAgent {
        ConnectionAgent(
            name: "Novi agent",
            details: "",
            iconSystemName: "person.crop.circle",
            colorTag: "blue",
            roomCode: "",
            isFavorite: false
        )
    }
}

/// Store / manager za sve agente.
/// Ovaj objekt možeš držati npr. u `SessionManager` ili kao poseban @StateObject u windowu.
final class ConnectionAgentStore: ObservableObject {
    @Published var agents: [ConnectionAgent]
    @Published var selectedAgentID: UUID?

    init(agents: [ConnectionAgent] = []) {
        self.agents = agents

        // Ako postoji barem jedan agent, selektiraj prvog
        if let firstID = agents.first?.id {
            self.selectedAgentID = firstID
        }
    }

    var selectedAgent: ConnectionAgent? {
        get {
            guard let id = selectedAgentID else { return nil }
            return agents.first(where: { $0.id == id })
        }
        set {
            if let newValue = newValue {
                selectedAgentID = newValue.id
            } else {
                selectedAgentID = nil
            }
        }
    }

    // MARK: - CRUD

    func add(_ agent: ConnectionAgent) {
        agents.append(agent)
        selectedAgentID = agent.id
    }

    func update(_ agent: ConnectionAgent) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[index] = agent
        }
    }

    func delete(_ agent: ConnectionAgent) {
        agents.removeAll { $0.id == agent.id }
        if selectedAgentID == agent.id {
            selectedAgentID = agents.first?.id
        }
    }

    func select(_ agent: ConnectionAgent) {
        selectedAgentID = agent.id
    }

    func select(id: UUID?) {
        selectedAgentID = id
    }

    // MARK: - Helper

    /// Osvježi lastUsedAt za aktivnog agenta (npr. kad se spojiš na sobu)
    func markSelectedAsUsed() {
        guard let currentID = selectedAgentID,
              let index = agents.firstIndex(where: { $0.id == currentID }) else {
            return
        }
        var updated = agents[index]
        updated.lastUsedAt = Date()
        agents[index] = updated
    }
}
