// IndependentMessagesAgent
// Glavni "agent" za Independent Messages – prima evente od Watchmana,
// te može dohvatiti osnovne mrežne podatke (privatna/javna IP, MAC gatewaya, port)
// i po potrebi vrtjeti dijagnostička stabla.
// Također može slati i primati poruke preko Relay-a i P2P transporta.

import Foundation
import CryptoKit

/// Callback za primanje poruka
typealias MessageReceivedCallback = (Message, MessageSource) -> Void

/// Izvor poruke (odakle je stigla)
enum MessageSource {
    case relay(conversationId: String)
    case p2p(peerId: String)
}

final class IndependentMessagesAgent {

    let context: IndependentMessagesAgentContext

    /// Helper koji s macOS-a čita lokalnu IP, gateway, MAC, javnu IP itd.
    private let networkInspector = DeviceNetworkInspector()
    
    /// Callback za primanje poruka
    private var messageReceivedCallback: MessageReceivedCallback?
    
    /// P2P transport za direktnu komunikaciju
    private var p2pTransport: P2PTransport?

    init(context: IndependentMessagesAgentContext) {
        self.context = context
        setupTransports()
    }
    
    /// Postavi transport slojeve i callback-e
    private func setupTransports() {
        // Inicijaliziraj P2P transport
        p2pTransport = P2PTransport()
        p2pTransport?.onMessageReceived = { [weak self] message, peerId in
            self?.handleReceivedMessage(message, source: .p2p(peerId: peerId))
        }
        
        // Postavi callback za RelayClient
        context.relayClient.setMessageCallback { [weak self] message, conversationId in
            self?.handleReceivedMessage(message, source: .relay(conversationId: conversationId))
        }
    }

    // MARK: - Event handling

    func handle(event: IndependentMessagesAgentEvent) {
        // TODO: kasnije ovdje pozvati TreeOfChoice i funkcije.
        print("[IndependentMessagesAgent] Received event: \(event)")
    }
    
    // MARK: - Message handling
    
    /// Postavi callback za primanje poruka
    func setMessageReceivedCallback(_ callback: @escaping MessageReceivedCallback) {
        self.messageReceivedCallback = callback
    }
    
    /// Rukuje primljenom porukom (poziva se iz transport slojeva)
    private func handleReceivedMessage(_ message: Message, source: MessageSource) {
        print("[IndependentMessagesAgent] Received message from \(source): \(message.text)")
        
        // Pozovi callback ako je postavljen
        messageReceivedCallback?(message, source)
        
        // Dodaj poruku u ConversationManager ako je potrebno
        // (možeš dodati logiku za automatsko dodavanje u razgovor)
    }
    
    // MARK: - Sending messages
    
    /// Pošalji poruku preko Relay servera
    /// - Parameters:
    ///   - text: Tekst poruke
    ///   - conversationId: ID razgovora/sobe
    ///   - masterKey: Master ključ za E2E enkripciju (opcionalno)
    func sendMessageViaRelay(
        _ text: String,
        conversationId: String,
        masterKey: SymmetricKey? = nil
    ) throws {
        print("[IndependentMessagesAgent] Sending via Relay: '\(text)' to \(conversationId)")
        
        if let masterKey = masterKey {
            // Koristi MessageTransportManager za E2E enkriptiranu poruku
            try MessageTransportManager.shared.sendEncryptedText(
                text,
                roomCode: conversationId,
                masterKey: masterKey
            )
        } else {
            // Pošalji plain tekst
            MessageTransportManager.shared.sendPlainText(text, conversationId: conversationId)
        }
        
        // Lokalno dodaj outgoing poruku
        let message = Message(
            id: UUID(),
            conversationId: conversationId,
            direction: .outgoing,
            timestamp: Date(),
            text: text
        )
        
        // Možeš dodati poruku u lokalni store ako želiš
        DispatchQueue.main.async {
            // context.conversationManager može imati metodu za dodavanje poruke
        }
    }
    
    /// Pošalji poruku direktno drugom agentu preko P2P transporta
    /// - Parameters:
    ///   - text: Tekst poruke
    ///   - peerId: ID drugog agenta
    ///   - peerAddress: IP adresa drugog agenta
    ///   - peerPort: Port na kojem drugi agent sluša
    ///   - masterKey: Master ključ za E2E enkripciju (opcionalno)
    func sendMessageViaP2P(
        _ text: String,
        peerId: String,
        peerAddress: String,
        peerPort: UInt16,
        masterKey: SymmetricKey? = nil
    ) throws {
        print("[IndependentMessagesAgent] Sending via P2P: '\(text)' to \(peerId) at \(peerAddress):\(peerPort)")
        
        var messageData = Data(text.utf8)
        
        // Ako imamo masterKey, enkriptiraj poruku
        if let masterKey = masterKey {
            // Koristi roomCode ili peerId kao salt za ratchet
            let roomCode = peerId // ili neki drugi identifikator
            var ratchet = MessageRatchetState.from(masterKey: masterKey, roomCode: roomCode)
            let msgKey = ratchet.nextEncryptionKey()
            let encrypted = try MessageCryptoService.encryptString(text, with: msgKey)
            messageData = Data(encrypted.utf8)
        }
        
        // Pošalji preko P2P transporta
        p2pTransport?.send(
            data: messageData,
            to: peerAddress,
            port: peerPort
        ) { [weak self] success, error in
            if success {
                print("[IndependentMessagesAgent] P2P message sent successfully")
            } else {
                print("[IndependentMessagesAgent] P2P message failed: \(error?.localizedDescription ?? "unknown error")")
                // Možeš emitirati event za Watchman
            }
        }
        
        // Lokalno dodaj outgoing poruku
        let message = Message(
            id: UUID(),
            conversationId: peerId,
            direction: .outgoing,
            timestamp: Date(),
            text: text
        )
    }
    
    /// Automatski odaberi transport (Relay ili P2P) na temelju dijagnostike
    /// - Parameters:
    ///   - text: Tekst poruke
    ///   - conversationId: ID razgovora
    ///   - peerId: ID drugog agenta (za P2P)
    ///   - masterKey: Master ključ za enkripciju
    func sendMessageAuto(
        _ text: String,
        conversationId: String,
        peerId: String? = nil,
        masterKey: SymmetricKey? = nil
    ) throws {
        // Provjeri dijagnostiku i odaberi najbolji transport
        let diagnosis = context.diagnosis
        
        switch diagnosis.transportMode {
        case .relay:
            // Koristi Relay
            try sendMessageViaRelay(text, conversationId: conversationId, masterKey: masterKey)
            
        case .p2p:
            // Pokušaj P2P ako imamo peerId i endpoint info
            if let peerId = peerId {
                // TODO: Dohvati peer endpoint iz context-a ili servera
                // Za sada koristimo Relay kao fallback
                try sendMessageViaRelay(text, conversationId: conversationId, masterKey: masterKey)
            } else {
                // Fallback na Relay ako nemamo P2P info
                try sendMessageViaRelay(text, conversationId: conversationId, masterKey: masterKey)
            }
        }
    }

    // MARK: - Debug helper

    /// Stari debug – ostavljam ga, ali dodajem i mrežni snapshot da se vidi realno stanje.
    func debugRunInitialDiagnosis() {
        print("[IndependentMessagesAgent] debugRunInitialDiagnosis() called")

        // 1) prvo pokaži kako radi tvoje demo stablo (hardkodirane vrijednosti)
        let result = DecisionTree.debugClassifyLink(
            aPrivate: "192.168.1.10",
            aPublic:  "93.137.10.10",
            aPort:    5000,
            bPrivate: "192.168.1.10",
            bPublic:  "93.137.10.10",
            bPort:    5000
        )

        print("💡 Demo LinkLocation =", result)

        // 2) zatim povuci stvarne podatke sa sustava preko DeviceNetworkInspector-a
        fetchLocalNetworkSnapshot(listeningPort: nil) { snapshot in
            print("🔎 Realni snapshot →", snapshot.debugSummary)
        }
    }

    // MARK: - Novi API: dohvat privatne/javne IP, MAC-a i porta

    /// Dohvaća kompletan snapshot (privatna IP, javna IP, gateway, MAC, port, itd.).
    /// Ovo je "glavna" funkcija – ostale tri su samo tanke pomoćne ovojnice.
    func fetchLocalNetworkSnapshot(
        listeningPort: UInt16?,
        completion: @escaping (NetworkEnvironmentSnapshot) -> Void
    ) {
        networkInspector.collectSnapshot(listeningPort: listeningPort) { snapshot in
            completion(snapshot)
        }
    }

    /// Dohvati PRIVATNU (LAN) IP adresu našeg uređaja, npr. 192.168.1.23
    func fetchPrivateIPAddress(
        listeningPort: UInt16? = nil,
        completion: @escaping (String?) -> Void
    ) {
        networkInspector.collectSnapshot(listeningPort: listeningPort) { snapshot in
            completion(snapshot.localIPAddress)
        }
    }

    /// Dohvati JAVNU (WAN) IP adresu koju vidi internet (preko HTTP upita / tvog servera).
    func fetchPublicIPAddress(
        listeningPort: UInt16? = nil,
        completion: @escaping (String?) -> Void
    ) {
        networkInspector.collectSnapshot(listeningPort: listeningPort) { snapshot in
            completion(snapshot.publicIPAddress)
        }
    }

    /// Dohvati MAC adresu GATEWAYA (routera) iz ARP tablice, npr. "00:11:22:33:44:55".
    func fetchGatewayMACAddress(
        listeningPort: UInt16? = nil,
        completion: @escaping (String?) -> Void
    ) {
        networkInspector.collectSnapshot(listeningPort: listeningPort) { snapshot in
            completion(snapshot.gatewayMACAddress)
        }
    }

    /// Dohvati port na kojem tvoja app sluša / radi P2P (ako ga proslijediš inspectoru).
    ///
    /// Napomena: DeviceNetworkInspector ne "otkriva" port sam – ti mu ga daš
    /// kroz `listeningPort` parametar, a on ga samo spakira u snapshot.
    func fetchListeningPort(
        listeningPort: UInt16?,
        completion: @escaping (UInt16?) -> Void
    ) {
        networkInspector.collectSnapshot(listeningPort: listeningPort) { snapshot in
            completion(snapshot.listeningPort)
        }
    }
    
    // MARK: - P2P Transport management
    
    /// Pokreni P2P listening na određenom portu
    /// - Parameters:
    ///   - port: Port na kojem će slušati (nil = automatski)
    ///   - completion: Callback s rezultatom (success, port)
    func startP2PListening(port: UInt16? = nil, completion: @escaping (Bool, UInt16?) -> Void) {
        p2pTransport?.startListening(port: port, completion: completion)
    }
    
    /// Zaustavi P2P listening
    func stopP2PListening() {
        p2pTransport?.stopListening()
    }
    
    /// Vrati port na kojem P2P sluša (ako je aktivan)
    func getP2PListeningPort() -> UInt16? {
        return p2pTransport?.getListeningPort()
    }
    
    // MARK: - System messages - Endpoint snapshot exchange
    
    /// Control channel za dohvaćanje mrežnih informacija
    private lazy var controlChannel: IndependentMessagesControlChannel = {
        IndependentMessagesControlChannel(agent: self, roomSessionManager: context.roomSessionManager)
    }()
    
    /// Pošalji vlastiti endpoint snapshot drugom agentu
    /// - Parameters:
    ///   - conversationId: ID razgovora/sobe
    ///   - peerId: ID drugog agenta (opcionalno)
    ///   - masterKey: Master ključ za enkripciju (opcionalno)
    func sendEndpointSnapshot(
        conversationId: String,
        peerId: String? = nil,
        masterKey: SymmetricKey? = nil
    ) {
        print("\n" + "=".repeating(60))
        print("[IndependentMessagesAgent] 📤 ŠALJEM ENDPOINT SNAPSHOT DRUGOJ STRANI")
        print("=".repeating(60))
        
        // Koristi ControlAPI za dohvaćanje mrežnih informacija
        controlChannel.fetchLocalEndpointSnapshot { [weak self] snapshot in
            guard let self = self else { return }
            
            // Kreiraj EndpointSnapshot s privatnom i javnom IP adresom
            let endpointSnapshot = EndpointSnapshot(
                peerId: peerId ?? self.context.roomSessionManager.roomCode ?? "unknown",
                localIPAddress: snapshot.localIPAddress,
                publicIPAddress: snapshot.publicIPAddress,
                listeningPort: snapshot.listeningPort,
                gatewayIPAddress: snapshot.gatewayIPAddress,
                gatewayMACAddress: snapshot.gatewayMACAddress,
                timestamp: Date()
            )
            
            // Ispiši u konzoli što šaljemo
            print("📤 ŠALJEM DRUGOJ STRANI:")
            print("   🏠 Privatna IP: \(snapshot.localIPAddress ?? "N/A")")
            print("   🌐 Javna IP: \(snapshot.publicIPAddress ?? "N/A")")
            print("   🔌 Port: \(snapshot.listeningPort.map(String.init) ?? "N/A")")
            print("=".repeating(60) + "\n")
            
            // Kreiraj SystemMessage
            let systemMessage = SystemMessage(
                type: .endpointSnapshot,
                snapshot: endpointSnapshot,
                peerId: peerId
            )
            
            // Enkodiraj u JSON
            guard let jsonData = try? JSONEncoder().encode(systemMessage),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("[IndependentMessagesAgent] ❌ Ne mogu enkodirati endpoint snapshot")
                return
            }
            
            // Pošalji preko Relay-a (RoomSessionManager)
            if let roomCode = self.context.roomSessionManager.roomCode {
                let systemPayload = "sys:\(jsonString)"
                
                // Ako imamo masterKey, enkriptiraj
                let finalMasterKey = masterKey ?? self.context.roomSessionManager.masterKey
                if let masterKey = finalMasterKey {
                    do {
                        var ratchet = MessageRatchetState.from(masterKey: masterKey, roomCode: roomCode)
                        let msgKey = ratchet.nextEncryptionKey()
                        let encrypted = try MessageCryptoService.encryptString(systemPayload, with: msgKey)
                        self.context.roomSessionManager.sendText(encrypted)
                    } catch {
                        print("[IndependentMessagesAgent] ❌ Greška pri enkripciji: \(error)")
                        self.context.roomSessionManager.sendText(systemPayload)
                    }
                } else {
                    self.context.roomSessionManager.sendText(systemPayload)
                }
            } else {
                print("[IndependentMessagesAgent] ❌ Nema roomCode-a, ne mogu poslati endpoint snapshot")
            }
        }
    }
    
    /// Rukuj primljenom sistemskom porukom
    /// - Parameter text: Tekst poruke (može biti enkriptiran)
    func handleSystemMessage(_ text: String, masterKey: SymmetricKey? = nil, roomCode: String? = nil) {
        // Provjeri je li sistemska poruka (ima prefiks "sys:")
        guard text.hasPrefix("sys:") else {
            return // Nije sistemska poruka
        }
        
        let jsonString = String(text.dropFirst(4)) // Ukloni "sys:" prefiks
        
        // Ako je enkriptirano, dekriptiraj
        var decryptedJson = jsonString
        if let masterKey = masterKey, let roomCode = roomCode {
            do {
                decryptedJson = try MessageCryptoService.decryptString(jsonString, with: masterKey)
            } catch {
                print("[IndependentMessagesAgent] ⚠️ Ne mogu dekriptirati sistemsku poruku, tretiram kao plain")
            }
        }
        
        // Dekodiraj JSON
        guard let jsonData = decryptedJson.data(using: .utf8),
              let systemMessage = try? JSONDecoder().decode(SystemMessage.self, from: jsonData) else {
            print("[IndependentMessagesAgent] ❌ Ne mogu dekodirati sistemsku poruku")
            return
        }
        
        // Rukuj različitim tipovima sistemskih poruka
        switch systemMessage.type {
        case .endpointSnapshot:
            if let snapshot = systemMessage.snapshot {
                handleReceivedEndpointSnapshot(snapshot)
                // Pošalji potvrdnu poruku da smo primili
                sendEndpointSnapshotAck(peerId: snapshot.peerId, roomCode: roomCode, masterKey: masterKey)
            }
        case .endpointSnapshotRequest:
            // Drugi agent traži naš endpoint snapshot - pošalji ga
            if let roomCode = roomCode {
                sendEndpointSnapshot(conversationId: roomCode, peerId: systemMessage.peerId, masterKey: masterKey)
            }
        case .endpointSnapshotAck:
            // Potvrda primitka endpoint snapshot-a
            print("\n" + "=".repeating(60))
            print("[IndependentMessagesAgent] ✅ POTVRDA: Druga strana je primila naš endpoint snapshot")
            print("   Peer ID: \(systemMessage.peerId ?? "unknown")")
            print("=".repeating(60) + "\n")
        case .ping:
            // Odgovori s pong (možeš implementirati kasnije)
            print("[IndependentMessagesAgent] 🏓 Primljen ping od \(systemMessage.peerId ?? "unknown")")
        case .pong:
            print("[IndependentMessagesAgent] 🏓 Primljen pong od \(systemMessage.peerId ?? "unknown")")
        }
    }
    
    /// Pošalji potvrdnu poruku da smo primili endpoint snapshot
    private func sendEndpointSnapshotAck(peerId: String, roomCode: String?, masterKey: SymmetricKey?) {
        print("\n" + "=".repeating(60))
        print("[IndependentMessagesAgent] 📤 ŠALJEM POTVRDU PRIMITKA ENDPOINT SNAPSHOT-A")
        print("=".repeating(60))
        
        let ackMessage = SystemMessage(
            type: .endpointSnapshotAck,
            snapshot: nil,
            peerId: peerId
        )
        
        guard let jsonData = try? JSONEncoder().encode(ackMessage),
              let jsonString = String(data: jsonData, encoding: .utf8),
              let roomCode = roomCode else {
            print("[IndependentMessagesAgent] ❌ Ne mogu enkodirati potvrdnu poruku")
            return
        }
        
        let systemPayload = "sys:\(jsonString)"
        
        // Ako imamo masterKey, enkriptiraj
        let finalMasterKey = masterKey ?? context.roomSessionManager.masterKey
        if let masterKey = finalMasterKey {
            do {
                var ratchet = MessageRatchetState.from(masterKey: masterKey, roomCode: roomCode)
                let msgKey = ratchet.nextEncryptionKey()
                let encrypted = try MessageCryptoService.encryptString(systemPayload, with: msgKey)
                context.roomSessionManager.sendText(encrypted)
                print("✅ Potvrda poslana (enkriptirana)")
            } catch {
                print("[IndependentMessagesAgent] ❌ Greška pri enkripciji potvrde: \(error)")
                context.roomSessionManager.sendText(systemPayload)
            }
        } else {
            context.roomSessionManager.sendText(systemPayload)
            print("✅ Potvrda poslana (plain)")
        }
        print("=".repeating(60) + "\n")
    }
    
    /// Rukuj primljenim endpoint snapshot-om od drugog agenta
    private func handleReceivedEndpointSnapshot(_ snapshot: EndpointSnapshot) {
        print("\n" + "=".repeating(60))
        print("📡 PRIMLJEN ENDPOINT SNAPSHOT OD DRUGOG AGENTA (KORISNIK B)")
        print("=".repeating(60))
        print("👤 Agent ID: \(snapshot.peerId)")
        print("🏠 Privatna IP: \(snapshot.localIPAddress ?? "N/A")")
        print("🌐 Javna IP: \(snapshot.publicIPAddress ?? "N/A")")
        print("🔌 Port: \(snapshot.listeningPort.map(String.init) ?? "N/A")")
        print("🚪 Gateway IP: \(snapshot.gatewayIPAddress ?? "N/A")")
        print("📡 Gateway MAC: \(snapshot.gatewayMACAddress ?? "N/A")")
        print("⏰ Vrijeme: \(snapshot.timestamp)")
        print("=".repeating(60))
        print("✅ Endpoint snapshot uspješno primljen - šaljem potvrdnu poruku...")
        print("=".repeating(60) + "\n")
    }
    
    /// Ispiši vlastite endpoint informacije u konzoli
    private func printLocalEndpointInfo(snapshot: NetworkEnvironmentSnapshot) {
        print("\n" + "=".repeating(60))
        print("📡 MOJ ENDPOINT SNAPSHOT (KORISNIK A)")
        print("=".repeating(60))
        print("🏠 Privatna IP: \(snapshot.localIPAddress ?? "N/A")")
        print("🌐 Javna IP: \(snapshot.publicIPAddress ?? "N/A")")
        print("🔌 Port: \(snapshot.listeningPort.map(String.init) ?? "N/A")")
        print("🚪 Gateway IP: \(snapshot.gatewayIPAddress ?? "N/A")")
        print("📡 Gateway MAC: \(snapshot.gatewayMACAddress ?? "N/A")")
        print("🌉 Interface: \(snapshot.interfaceName ?? "N/A")")
        print("=".repeating(60) + "\n")
    }
}

// MARK: - Helper extension za String
extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

