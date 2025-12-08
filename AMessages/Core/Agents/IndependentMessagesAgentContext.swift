// IndependentMessagesAgentContext
// Drži reference na postojeće managere (RoomSession, RelayClient, ConversationManager)
// i interno stanje koje agent i funkcije koriste.

import Foundation

final class IndependentMessagesAgentContext {

    // Ove tipove već imaš u projektu.
    let roomSessionManager: RoomSessionManager
    let relayClient: RelayClient
    let conversationManager: ConversationManager

    // Stanje dijagnostike
    var diagnosis: IndependentMessagesDiagnosisResult = IndependentMessagesDiagnosisResult()

    init(roomSessionManager: RoomSessionManager,
         relayClient: RelayClient,
         conversationManager: ConversationManager) {
        self.roomSessionManager = roomSessionManager
        self.relayClient = relayClient
        self.conversationManager = conversationManager
    }

    /// Pomoćna funkcija za debug ispise.
    func debugPrintContextSummary() {
        print("[AgentContext] faultLocation = \(diagnosis.faultLocation), mode = \(diagnosis.topologyMode), transport = \(diagnosis.transportMode)")
    }
}
