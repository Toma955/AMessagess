import Foundation
import Combine

/// Jedan "agent" za neovisne poruke (profil / način spajanja).
struct ConnectionAgent: Identifiable, Equatable {
    let id: UUID
    var name: String
    var details: String
    var iconSystemName: String
    var colorTag: String
    var roomCode: String

    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        iconSystemName: String = "personalhotspot",
        colorTag: String = "blue",
        roomCode: String = ""
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.iconSystemName = iconSystemName
        self.colorTag = colorTag
        self.roomCode = roomCode
    }

    /// Prazni agent za "New" gumbe
    static func empty() -> ConnectionAgent {
        ConnectionAgent(
            name: "Novi agent",
            details: "",
            iconSystemName: "personalhotspot",
            colorTag: "blue",
            roomCode: ""
        )
    }
}

/// Store za sve agente – koristi se u viewu i view modelu.
final class ConnectionAgentStore: ObservableObject {

    @Published var agents: [ConnectionAgent]
    @Published var selectedAgent: ConnectionAgent?

    init(agents: [ConnectionAgent] = []) {
        self.agents = agents
        self.selectedAgent = agents.first
    }

    func add(_ agent: ConnectionAgent) {
        agents.append(agent)
        if selectedAgent == nil {
            selectedAgent = agent
        }
    }

    func select(_ agent: ConnectionAgent) {
        selectedAgent = agent
    }

    /// Placeholder za kasnije – tu možeš updateat "lastUsedAt" ili slično.
    func markSelectedAsUsed() {
        guard let selected = selectedAgent else { return }
        print("[ConnectionAgentStore] markSelectedAsUsed: \(selected.name)")
    }
}
