import Foundation
import CryptoKit
import Combine

// MARK: - Ratchet za LOG (samo za spremanje poruka na disk)

/// Jedan derivirani ključ za log poruku
private struct LogMessageKey {
    let key: SymmetricKey
    let counter: UInt64
}

/// Rotirajući (chain) ključevi za slanje i primanje.
/// Ovo koristimo SAMO za enkripciju logova na disku.
/// Ne dira transportnu enkripciju preko mreže.
private struct LogRatchetState {
    var rootKey: SymmetricKey
    var sendingChainKey: SymmetricKey
    var receivingChainKey: SymmetricKey
    var sendingCounter: UInt64 = 0
    var receivingCounter: UInt64 = 0

    /// Inicijalno stanje izvedeno iz masterKey-a + ID razgovora
    static func makeInitial(
        masterKey: SymmetricKey,
        conversationId: String
    ) -> LogRatchetState {

        let rootInfo = Data("AMessages-Log-Ratchet-Root".utf8)
        let sendInfo = Data("AMessages-Log-Ratchet-Send-\(conversationId)".utf8)
        let recvInfo = Data("AMessages-Log-Ratchet-Recv-\(conversationId)".utf8)

        let root = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: Data(),
            info: rootInfo,
            outputByteCount: 32
        )

        let send = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: root,
            salt: Data(),
            info: sendInfo,
            outputByteCount: 32
        )

        let recv = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: root,
            salt: Data(),
            info: recvInfo,
            outputByteCount: 32
        )

        return LogRatchetState(
            rootKey: root,
            sendingChainKey: send,
            receivingChainKey: recv,
            sendingCounter: 0,
            receivingCounter: 0
        )
    }

    /// Sljedeći ključ za SLANJE + povećani brojač
    mutating func nextSendingKey() -> LogMessageKey {
        let material = Data("send-\(sendingCounter)".utf8)
        let hmac = HMAC<SHA256>.authenticationCode(for: material, using: sendingChainKey)
        let newKey = SymmetricKey(data: Data(hmac))
        sendingChainKey = newKey
        sendingCounter += 1
        return LogMessageKey(key: newKey, counter: sendingCounter)
    }

    /// Sljedeći ključ za PRIMANJE + povećani brojač
    mutating func nextReceivingKey() -> LogMessageKey {
        let material = Data("recv-\(receivingCounter)".utf8)
        let hmac = HMAC<SHA256>.authenticationCode(for: material, using: receivingChainKey)
        let newKey = SymmetricKey(data: Data(hmac))
        receivingChainKey = newKey
        receivingCounter += 1
        return LogMessageKey(key: newKey, counter: receivingCounter)
    }
}

/// Kako izgleda jedan zapis u logu (rawData = JSON ovoga)
private struct EncryptedLogEnvelope: Codable {
    let direction: MessageDirection
    let counter: UInt64
    let combined: Data   // AES.GCM combined (nonce + ciphertext + tag)
}

// MARK: - RoomSessionManager

final class RoomSessionManager: ObservableObject {

    // PUBLIC state za UI
    @Published var messages: [Message] = []
    @Published var isSessionReady: Bool = false
    @Published var lastError: String? = nil

    // WS
    private var urlSession: URLSession = URLSession(configuration: .default)
    private var webSocketTask: URLSessionWebSocketTask?

    // join state
    var roomCode: String?  // Promijenjeno u public da agent može pristupiti
    private var pendingJoinCompletion: ((Bool, String?) -> Void)?

    // reference na SessionManager radi masterKey-a i serverAddress-a
    private weak var sessionRef: SessionManager?
    
    // Callback za sistemske poruke (za agent integraciju)
    var systemMessageHandler: ((String) -> Void)?
    
    // Getter za masterKey (za agent)
    var masterKey: SymmetricKey? {
        return sessionRef?.masterKey
    }

    // ratchet za log (disk)
    private var logRatchetState: LogRatchetState?

    // E2E transport root key (za poruke preko mreže)
    private var transportRootKey: SymmetricKey?
    private var sendCounter: UInt64 = 0   // index za naše poslane poruke

    // helper: ID za log (koristimo kod sobe)
    private var conversationId: String {
        roomCode ?? "unknown-room"
    }

    deinit {
        close()
    }

    // MARK: - JOIN

    /// Spoji se na sobu (join) i čekaj `session_ready`.
    func joinRoom(
        code: String,
        using session: SessionManager,
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("🧵 [ROOM] joinRoom(\(code)) – start")

        guard code.count == 16 else {
            completion(false, "Kod mora imati 16 znakova.")
            return
        }

        sessionRef = session
        pendingJoinCompletion = completion
        lastError = nil
        isSessionReady = false
        roomCode = code

        logRatchetState = nil   // reset ratcheta za novi razgovor
        transportRootKey = nil
        sendCounter = 0

        // Inicijaliziraj E2E transport root ključ (ako imamo masterKey)
        if let mk = session.masterKey {
            let salt = Data("AMessages-Transport-\(code)".utf8)
            let info = Data("AMessages-Transport-Root".utf8)
            let root = HKDF<SHA256>.deriveKey(
                inputKeyMaterial: mk,
                salt: salt,
                info: info,
                outputByteCount: 32
            )
            transportRootKey = root
            print("🔐 [ROOM] transportRootKey inicijaliziran.")
        } else {
            print("⚠️ [ROOM] Nema masterKey-a – poruke će ići u čistom tekstu.")
        }

        guard let wsURL = makeWebSocketURL(from: session.serverAddress) else {
            print("🧵 [ROOM] Neispravan serverAddress: \(session.serverAddress)")
            completion(false, "Neispravna adresa servera.")
            return
        }

        print("🧵 [ROOM] Spajam se na WS: \(wsURL.absoluteString)")

        webSocketTask = urlSession.webSocketTask(with: wsURL)
        webSocketTask?.resume()

        // start receive loop
        listenForMessages()

        // pošalji JOIN
        let joinPayload: [String: Any] = [
            "t": "join",
            "code": code,
            "mode": "direct"
        ]

        sendJSON(joinPayload) { [weak self] error in
            if let error = error {
                print("🧵 [ROOM] JOIN send error:", error)
                self?.finishJoin(success: false, errorText: "Ne mogu poslati join: \(error.localizedDescription)")
            } else {
                print("🧵 [ROOM] JOIN frame poslan.")
            }
        }
    }

    // MARK: - Slanje tekst poruke (E2E)

    func sendText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let code = roomCode else {
            print("🧵 [ROOM] sendText: nema roomCode-a")
            return
        }

        print("💬 [ROOM] sendText -> '\(trimmed)'")

        var bodyToSend = trimmed
        var indexToSend: UInt64? = nil
        var encLabel: String? = nil

        // Ako imamo transportRootKey → E2E enkripcija
        if let root = transportRootKey {
            sendCounter += 1
            indexToSend = sendCounter
            do {
                let msgKey = try deriveTransportKey(rootKey: root, index: sendCounter)
                let encrypted = try MessageCryptoService.encryptString(trimmed, with: msgKey)
                bodyToSend = encrypted
                encLabel = "aesgcm-hkdf-v1"
                print("🔐 [ROOM] Poruka enkriptirana za index=\(sendCounter)")
            } catch {
                print("❌ [ROOM] Greška pri E2E enkripciji – šaljem plain. Error:", error)
                indexToSend = nil
                encLabel = nil
                bodyToSend = trimmed
            }
        }

        var payload: [String: Any] = [
            "t": "msg",
            "code": code,
            "body": bodyToSend
        ]

        if let idx = indexToSend {
            payload["k"] = idx        // message index
        }
        if let enc = encLabel {
            payload["enc"] = enc      // oznaka algoritma
        }

        sendJSON(payload) { [weak self] error in
            if let error = error {
                print("💬 [ROOM] sendText error:", error)
            } else {
                print("💬 [ROOM] sendText OK")
            }
        }

        // lokalno dodaj outgoing poruku (plaintext) + log
        let msg = Message(
            id: UUID(),
            conversationId: code,
            direction: .outgoing,
            timestamp: Date(),
            text: trimmed
        )

        DispatchQueue.main.async {
            self.messages.append(msg)
        }

        appendToLog(message: msg)
    }

    // MARK: - Zatvaranje

    func close() {
        print("🧵 [ROOM] close() – zatvaram WS, čistim state.")
        pendingJoinCompletion = nil
        logRatchetState = nil
        transportRootKey = nil
        sendCounter = 0

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    // MARK: - Private: URL helper

    private func makeWebSocketURL(from serverAddress: String) -> URL? {
        // ako nema ništa u postavkama → default
        let base = serverAddress.isEmpty
        ? "https://amessagesserver.onrender.com"
        : serverAddress

        guard let httpURL = URL(string: base) else {
            return nil
        }

        var comps = URLComponents()
        comps.scheme = (httpURL.scheme == "https") ? "wss" : "ws"
        comps.host = httpURL.host
        comps.port = httpURL.port
        comps.path = httpURL.path.isEmpty ? "/" : httpURL.path

        return comps.url
    }

    // MARK: - Private: slanje JSON-a

    private func sendJSON(_ json: [String: Any],
                          completion: ((Error?) -> Void)? = nil) {
        guard let ws = webSocketTask else {
            completion?(NSError(domain: "RoomSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nema WS taska"]))
            return
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let text = String(data: data, encoding: .utf8) else {
                completion?(NSError(domain: "RoomSession", code: -2, userInfo: [NSLocalizedDescriptionKey: "Ne mogu napraviti string iz JSON-a"]))
                return
            }

            print("📤 [ROOM] SEND:", text)

            ws.send(.string(text)) { error in
                if let error = error {
                    print("📤 [ROOM] send error:", error)
                }
                completion?(error)
            }
        } catch {
            print("📤 [ROOM] JSON serialization error:", error)
            completion?(error)
        }
    }

    // MARK: - Receive petlja

    private func listenForMessages() {
        guard let ws = webSocketTask else { return }

        ws.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("📥 [ROOM] receive error:", error)
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                }
                // ako smo još u join fazi → fail
                if self.pendingJoinCompletion != nil {
                    self.finishJoin(success: false, errorText: error.localizedDescription)
                }
            case .success(let message):
                self.handle(message)
                // nastavi slušat
                self.listenForMessages()
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            print("📥 [ROOM] RX string:", text)
            handleIncomingText(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                print("📥 [ROOM] RX data->string:", text)
                handleIncomingText(text)
            } else {
                print("📥 [ROOM] RX binarno, ignoriram.")
            }
        @unknown default:
            print("📥 [ROOM] RX unknown message type")
        }
    }

    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        let jsonObj = (try? JSONSerialization.jsonObject(with: data, options: [])) as Any
        guard let dict = jsonObj as? [String: Any] else {
            print("📥 [ROOM] Nije validan JSON.")
            return
        }

        guard let type = dict["t"] as? String else {
            print("📥 [ROOM] Nema 't' field-a.")
            return
        }

        switch type {
        case "joined":
            print("✅ [ROOM] joined confirmed")
            // ništa posebno – čekamo session_ready

        case "session_ready":
            print("✅ [ROOM] session_ready – razgovor može krenuti")
            DispatchQueue.main.async {
                self.isSessionReady = true
            }
            finishJoin(success: true, errorText: nil)

            // sistemska poruka za UI
            if let code = roomCode {
                let msg = Message(
                    id: UUID(),
                    conversationId: code,
                    direction: .incoming, // ili .system ako imaš taj case
                    timestamp: Date(),
                    text: "Druga strana je spojena. Možete početi razgovor."
                )
                DispatchQueue.main.async {
                    self.messages.append(msg)
                }
                appendToLog(message: msg)
                
                // Obavijesti sistem message handler da se konekcija uspostavila
                // Ovo će triggerati slanje endpoint snapshot-a u agentu
                if let handler = self.systemMessageHandler {
                    print("📡 [ROOM] Šaljem signal 'connection_established' agentu")
                    // Pošalji signal da se konekcija uspostavila (može agent reagirati)
                    handler("connection_established:\(code)")
                } else {
                    print("⚠️ [ROOM] systemMessageHandler nije postavljen - endpoint snapshot se neće poslati")
                }
            }

        case "msg":
            handleIncomingChat(dict: dict)

        case "extend_request":
            print("⏳ [ROOM] extend_request:", dict)

        case "extended":
            print("⏳ [ROOM] extended:", dict)

        case "expired":
            print("⛔️ [ROOM] expired:", dict)
            DispatchQueue.main.async {
                self.isSessionReady = false
                self.lastError = "Razgovor je istekao."
            }

        case "error":
            handleServerError(dict: dict)

        case "pong":
            print("🏓 [ROOM] pong:", dict)

        default:
            print("📥 [ROOM] Nepoznat 't': \(type)")
        }
    }

    private func handleIncomingChat(dict: [String: Any]) {
        guard
            let code = dict["code"] as? String,
            let body = dict["body"] as? String
        else {
            print("📥 [ROOM] msg: nedostaju code/body")
            return
        }

        let enc = dict["enc"] as? String
        let kAny = dict["k"]

        var plainText = body

        if enc == "aesgcm-hkdf-v1",
           let root = transportRootKey {

            var index: UInt64?

            if let n = kAny as? NSNumber {
                index = UInt64(truncating: n)
            } else if let i = kAny as? Int {
                index = UInt64(i)
            }

            if let idx = index {
                do {
                    let msgKey = try deriveTransportKey(rootKey: root, index: idx)
                    let decrypted = try MessageCryptoService.decryptString(body, with: msgKey)
                    plainText = decrypted
                    print("🔐 [ROOM] Dekriptirana poruka za index=\(idx)")
                } catch {
                    print("❌ [ROOM] Greška pri dekripciji E2E poruke:", error)
                    plainText = "[DECRYPT ERROR]"
                }
            } else {
                print("⚠️ [ROOM] enc=\(enc ?? "") ali nema valjanog 'k' – tretiram kao plain.")
            }
        } else {
            if enc != nil {
                print("⚠️ [ROOM] enc=\(enc ?? "nil") ali nema transportRootKey. Tretiram body kao plain.")
            }
        }

        // Provjeri je li sistemska poruka (ima prefiks "sys:")
        // Može biti enkriptirana, pa provjeravamo nakon dekripcije
        if plainText.hasPrefix("sys:") {
            // Proslijedi sistemsku poruku agentu
            systemMessageHandler?(plainText)
            return // Ne dodaj sistemsku poruku u normalne poruke
        }
        
        // Također provjeri je li možda enkriptirana sistemska poruka
        // (ako je enkriptirana, plainText će biti base64, ali možemo provjeriti strukturu)
        // Za sada ćemo ostaviti da agent provjerava sve primljene poruke
        
        let msg = Message(
            id: UUID(),
            conversationId: code,
            direction: .incoming,
            timestamp: Date(),
            text: plainText
        )

        DispatchQueue.main.async {
            self.messages.append(msg)
        }
        appendToLog(message: msg)
        
        // Obavijesti RelayClient o primljenoj poruci (za agent integraciju)
        RelayClient.shared.handleIncomingMessage(text: plainText, conversationId: code)
    }

    private func handleServerError(dict: [String: Any]) {
        let reason = dict["reason"] as? String ?? "error"
        let message = dict["message"] as? String ?? "Greška s poslužitelja."

        let full = "[\(reason)] \(message)"
        print("❌ [ROOM] SERVER ERROR:", full)

        DispatchQueue.main.async {
            self.lastError = full
        }

        // ako smo još u join fazi → fail join
        if pendingJoinCompletion != nil {
            finishJoin(success: false, errorText: full)
        } else if let code = roomCode {
            // sistemska poruka u razgovor (incoming)
            let msg = Message(
                id: UUID(),
                conversationId: code,
                direction: .incoming,
                timestamp: Date(),
                text: full
            )
            DispatchQueue.main.async {
                self.messages.append(msg)
            }
            appendToLog(message: msg)
        }
    }

    private func finishJoin(success: Bool, errorText: String?) {
        if let cb = pendingJoinCompletion {
            DispatchQueue.main.async {
                cb(success, errorText)
            }
        }
        pendingJoinCompletion = nil
        if !success, let err = errorText {
            DispatchQueue.main.async {
                self.lastError = err
            }
        }
    }

    // MARK: - E2E: derivacija transport ključa po poruci

    private func deriveTransportKey(rootKey: SymmetricKey, index: UInt64) throws -> SymmetricKey {
        var idxBE = index.bigEndian
        let idxData = Data(bytes: &idxBE, count: MemoryLayout<UInt64>.size)
        let info = Data("AMessages-Transport-Msg".utf8) + idxData

        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: rootKey,
            salt: Data(),
            info: info,
            outputByteCount: 32
        )
        return key
    }

    // MARK: - Logiranje poruka s rotirajućim ključem (disk)

    private func appendToLog(message: Message) {
        guard let roomId = roomCode else { return }

        let payload: Data

        if let masterKey = sessionRef?.masterKey {
            do {
                payload = try encryptForLog(
                    text: message.text,
                    direction: message.direction,
                    masterKey: masterKey,
                    conversationId: roomId
                )
            } catch {
                print("💾 [LOG] Enkripcija loga nije uspjela, spremam plain. Error:", error)
                payload = Data(message.text.utf8)
            }
        } else {
            // nema masterKey-a → spremi plain (npr. app u demo modu)
            payload = Data(message.text.utf8)
        }

        let entry = LogEntry(
            id: UUID(),
            conversationId: roomId,
            rawData: payload,
            createdAt: message.timestamp
        )

        LogStorage.shared.append(entry, to: roomId)
    }

    private func encryptForLog(
        text: String,
        direction: MessageDirection,
        masterKey: SymmetricKey,
        conversationId: String
    ) throws -> Data {

        if logRatchetState == nil {
            print("🔑 [LOG] init ratchet state for conversation:", conversationId)
            logRatchetState = LogRatchetState.makeInitial(
                masterKey: masterKey,
                conversationId: conversationId
            )
        }

        guard var state = logRatchetState else {
            throw NSError(domain: "RoomSession", code: -10, userInfo: [NSLocalizedDescriptionKey: "Nema ratchet state-a"])
        }

        let mk: LogMessageKey
        switch direction {
        case .outgoing:
            mk = state.nextSendingKey()
        default:
            // sve ostalo (incoming i bilo što što dodaš kasnije)
            mk = state.nextReceivingKey()
        }

        // spremi natrag mutirani state
        logRatchetState = state

        let data = Data(text.utf8)
        let sealed = try AES.GCM.seal(data, using: mk.key)
        guard let combined = sealed.combined else {
            throw NSError(domain: "RoomSession", code: -11, userInfo: [NSLocalizedDescriptionKey: "Nema combined AES.GCM outputa"])
        }

        let env = EncryptedLogEnvelope(
            direction: direction,
            counter: mk.counter,
            combined: combined
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(env)

        // Ako se masterKey promijeni (krivi PIN) → logRatchetState
        // će generirati sasvim druge ključeve → AES.GCM.open će bacati error
        // ili ćeš dobiti “smeće” – baš ono što želiš kao “decoy”.
        return encoded
    }
}
