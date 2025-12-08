final class IndependentMessagesWatchman {

    private let context: IndependentMessagesAgentContext
    private var agent: IndependentMessagesAgent?

    init(context: IndependentMessagesAgentContext) {
        self.context = context
    }

    func start() {
        print("[Watchman] start()")

        // Watchman je taj koji "diže" agenta
        if agent == nil {
            let ag = IndependentMessagesAgent(context: context)
            self.agent = ag

            // za sada samo debug
            ag.debugRunInitialDiagnosis()
            
            // Postavi callback za sistemske poruke u RoomSessionManager-u
            context.roomSessionManager.systemMessageHandler = { [weak ag] systemMessageText in
                print("[Watchman] 📨 Primljen sistem message: \(systemMessageText.prefix(50))...")
                
                // Provjeri je li signal za uspostavu konekcije
                if systemMessageText.hasPrefix("connection_established:") {
                    let roomCode = String(systemMessageText.dropFirst("connection_established:".count))
                    print("[Watchman] 🔗 Konekcija uspostavljena za room: \(roomCode)")
                    // Automatski pošalji endpoint snapshot kada se konekcija uspostavi
                    ag?.sendEndpointSnapshot(conversationId: roomCode)
                } else {
                    // Rukuj normalnom sistemskom porukom
                    let masterKey = ag?.context.roomSessionManager.masterKey
                    let roomCode = ag?.context.roomSessionManager.roomCode
                    ag?.handleSystemMessage(systemMessageText, masterKey: masterKey, roomCode: roomCode)
                }
            }
            
            print("[Watchman] ✅ systemMessageHandler postavljen")
        }

        // TODO: kasnije se pretplatiti na RelayClient / RoomSessionManager evente.
    }

    func stop() {
        print("[Watchman] stop()")
        agent = nil
    }

    /// Pomoćna funkcija za ručno testiranje eventa.
    func simulateDeliveryTimeout() {
        agent?.handle(event: .deliveryTimeout(messageId: "test-message-id"))
    }
}
