//
//  IndependentMessagesControlAPI.swift
//  AMessages
//
//  Skeleton za sistemske kontrolne poruke između A ↔ server ↔ B.
//  Sve funkcije su trenutno "void" s TODO komentarima – kasnije će
//  stvarno slati/primati SystemMessage poruke preko tvog transporta.
//

import Foundation

// MARK: - Callback tipovi za asinkrone operacije

typealias EndpointSnapshotCallback = (NetworkEnvironmentSnapshot) -> Void
typealias IPAddressCallback = (String?) -> Void
typealias PortCallback = (UInt16?) -> Void
typealias BooleanCallback = (Bool) -> Void
typealias StringCallback = (String?) -> Void

// MARK: - Control API za sistemske poruke (skelet)

/// Apstraktni API koji Agent/Watchman može koristiti za slanje sistemskih poruka.
/// Ovdje samo definiramo *što* želimo moći raditi, bez implementacije.
protocol IndependentMessagesControlAPI {

    // MARK: A ➜ Server – pitanja o B strani (endpoint info)

    /// Pošalji serveru zahtjev:
    /// "Daj mi zadnji poznati snapshot za B (privatna/javna IP, port itd.)".
    func requestPeerEndpointSnapshot(peerId: String)

    /// Pošalji serveru zahtjev:
    /// "Koja je javna IP adresa B strane?" (ako treba samo public IP).
    func requestPeerPublicAddress(peerId: String)

    /// Pošalji serveru zahtjev:
    /// "Pošalji B korisniku poruku da mi javi na kojem portu sluša."
    func requestPeerPortViaServer(peerId: String)

    // MARK: A ➜ Server – health / ping

    /// Kaže serveru:
    /// "Molim te, pingaj B stranu i javi mi je li živa."
    func requestServerToPingPeer(peerId: String)

    /// Kaže serveru:
    /// "Pingaj mene" – koristimo za RTT i provjeru je li veza do servera zdrava.
    func requestServerPingMe()

    /// Kaže serveru:
    /// "Koja je MOJA javna IP adresa?" – server gleda remote endpoint socketa.
    func requestMyPublicAddress()

    // MARK: A ➜ Server – sinkronizacija poruka

    /// Pošalji serveru zahtjev:
    /// "Pošalji mi sve poruke koje su nastale nakon zadanog vremena."
    /// Ako je since == nil, može značiti "pošalji sve koje imaš za ovu sesiju".
    func requestMessagesSync(since: Date?)

    /// Obavijest serveru:
    /// "Zadnja poslana poruka (messageId) NIJE isporučena B strani."
    /// Server može pokušati resend, logirati problem, promijeniti transport, itd.
    func notifyLastMessageUndelivered(messageId: String)

    /// Pošalji serveru zahtjev:
    /// "Molim te ponovno pošalji poruku s ovim ID-em (messageId)."
    func requestResendMessage(messageId: String)

    // MARK: A ➜ B (preko servera kao relay – control poruke)

    /// Pošalji B strani sistemski ping (A želi znati je li B živ).
    /// Iako ide preko servera, semantički je "A ➜ B ping".
    func sendPingToPeer(peerId: String)

    /// Pošalji B strani "ARP probu" (logička ARP razmjena, ne pravi ARP paket).
    /// Koristi se za provjeru: jesmo li možda u istoj LAN mreži.
    func sendArpProbeToPeer(peerId: String)

    /// Direktno pitaj B stranu:
    /// "Na kojem portu slušaš za P2P / direct poruke?"
    func requestPeerPortDirect(peerId: String)

    // MARK: Lokalni testovi na ovom Mac-u

    /// Lokalni self-check:
    /// "Je li localhost / ova aplikacija živa?" – može samo updateati neki health flag.
    func checkLocalhostAlive()

    /// Provjera je li neki IP u LAN-u "živ":
    /// npr. ping ili ARP provjera na zadani ipAddress.
    func checkArpReachability(ipAddress: String)

    /// Lokalni ARP announcement:
    /// "Objavi moj IP/MAC u lokalnoj mreži" (logički, ne nužno pravi ARP paket).
    func broadcastLocalArpAnnouncement()

    // MARK: Slanje vlastitog stanja serveru

    /// Šalje serveru snapshot ovoga uređaja:
    /// privatna IP, javna IP (ako znamo), port, deviceId...
    /// U ovoj verziji skeletona nema parametara – kasnije ćeš iznutra
    /// pozvati svoj DeviceNetworkInspector i složiti payload.
    func sendLocalEndpointSnapshot()
    
    // MARK: - Lokalno dohvaćanje mrežnih informacija
    
    /// Dohvati kompletan endpoint snapshot (privatna IP, javna IP, gateway, MAC, port, itd.)
    /// - Parameter completion: Callback s NetworkEnvironmentSnapshot
    func fetchLocalEndpointSnapshot(completion: @escaping EndpointSnapshotCallback)
    
    /// Dohvati privatnu (LAN) IP adresu ovog uređaja
    /// - Parameter completion: Callback s privatnom IP adresom (npr. "192.168.1.23")
    func fetchPrivateIPAddress(completion: @escaping IPAddressCallback)
    
    /// Dohvati javnu (WAN) IP adresu ovog uređaja
    /// - Parameter completion: Callback s javnom IP adresom (npr. "93.137.10.10")
    func fetchPublicIPAddress(completion: @escaping IPAddressCallback)
    
    /// Dohvati port na kojem aplikacija sluša (P2P/Relay)
    /// - Parameter completion: Callback s portom (npr. 5000)
    func fetchListeningPort(completion: @escaping PortCallback)
    
    /// Dohvati gateway IP adresu (router)
    /// - Parameter completion: Callback s gateway IP adresom (npr. "192.168.1.1")
    func fetchGatewayIPAddress(completion: @escaping StringCallback)
    
    /// Dohvati MAC adresu gatewaya (routera)
    /// - Parameter completion: Callback s MAC adresom (npr. "00:11:22:33:44:55")
    func fetchGatewayMACAddress(completion: @escaping StringCallback)
    
    /// Dohvati naziv aktivnog mrežnog sučelja (npr. "en0", "en1")
    /// - Parameter completion: Callback s nazivom sučelja
    func fetchInterfaceName(completion: @escaping StringCallback)
    
    /// Dohvati sve mrežne informacije odjednom i ispiši u konzoli
    /// - Parameter completion: Callback s kompletnim snapshot-om
    func fetchAndPrintAllNetworkInfo(completion: @escaping EndpointSnapshotCallback)
}

// MARK: - Prazna implementacija (stub) za kasnije popunjavanje

/// Konkretna implementacija kontrolnog kanala.
/// Ovdje će kasnije biti referenca na stvarni transport (WebSocket, RelayClient, itd.).
final class IndependentMessagesControlChannel: IndependentMessagesControlAPI {

    // Reference na transport i agent za dohvaćanje mrežnih informacija
    private let networkInspector = DeviceNetworkInspector()
    private weak var agent: IndependentMessagesAgent?
    private weak var roomSessionManager: RoomSessionManager?
    
    init(agent: IndependentMessagesAgent? = nil, roomSessionManager: RoomSessionManager? = nil) {
        self.agent = agent
        self.roomSessionManager = roomSessionManager
    }

    // MARK: A ➜ Server – pitanja o B strani (endpoint info)

    func requestPeerEndpointSnapshot(peerId: String) {
        print("[ControlChannel] 📤 Zahtjev za endpoint snapshot od peer-a: \(peerId)")
        // TODO: Implementirati kada server podrži
        // 1) složi SystemMessage tipa .endpointSnapshotRequest
        // 2) payload može biti JSON s { "peerId": peerId }
        // 3) pošalji preko servera preko RoomSessionManager-a
        if let roomCode = roomSessionManager?.roomCode {
            let systemMessage = SystemMessage(
                type: .endpointSnapshotRequest,
                snapshot: nil,
                peerId: peerId
            )
            if let jsonData = try? JSONEncoder().encode(systemMessage),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let payload = "sys:\(jsonString)"
                roomSessionManager?.sendText(payload)
            }
        }
    }

    func requestPeerPublicAddress(peerId: String) {
        print("[ControlChannel] 📤 Zahtjev za javnu IP adresu peer-a: \(peerId)")
        // TODO: Implementirati kada server podrži
        // Server vraća poruku s javnom IP adresom B strane.
        requestPeerEndpointSnapshot(peerId: peerId) // Za sada koristimo endpoint snapshot
    }

    func requestPeerPortViaServer(peerId: String) {
        print("[ControlChannel] 📤 Zahtjev za port peer-a: \(peerId)")
        // TODO: Implementirati kada server podrži
        // Server proslijedi B strani, B odgovori s portom.
        requestPeerEndpointSnapshot(peerId: peerId) // Za sada koristimo endpoint snapshot
    }

    // MARK: A ➜ Server – health / ping

    func requestServerToPingPeer(peerId: String) {
        print("[ControlChannel] 📤 Zahtjev serveru da pinga peer-a: \(peerId)")
        // TODO: Implementirati kada server podrži
        // Server napravi ping B strani i vrati rezultat A-u.
        // Za sada samo logiramo
    }

    func requestServerPingMe() {
        print("[ControlChannel] 📤 Zahtjev serveru da pinga mene (RTT check)")
        // TODO: Implementirati kada server podrži
        // Koristimo za RTT i health check.
        // Za sada samo logiramo
    }

    func requestMyPublicAddress() {
        print("[ControlChannel] 📤 Zahtjev serveru za moju javnu IP adresu")
        // Umjesto servera, koristimo lokalno dohvaćanje
        fetchPublicIPAddress { publicIP in
            if let ip = publicIP {
                print("[ControlChannel] 🌐 Moja javna IP adresa: \(ip)")
            } else {
                print("[ControlChannel] ⚠️ Ne mogu dohvatiti javnu IP adresu")
            }
        }
    }

    // MARK: A ➜ Server – sinkronizacija poruka

    func requestMessagesSync(since: Date?) {
        // TODO:
        // SystemMessage s op: .messagesSyncRequest
        // payload može sadržavati since timestamp (ISO8601 string).
        // Server vraća jednu ili više poruka s op: .messagesSyncChunk.
    }

    func notifyLastMessageUndelivered(messageId: String) {
        // TODO:
        // SystemMessage s op: .lastMessageUndelivered
        // payload: { "messageId": messageId }
        // Server može logirati incident, probati promijeniti transport, itd.
    }

    func requestResendMessage(messageId: String) {
        // TODO:
        // SystemMessage s op: .resendMessageRequest
        // payload: { "messageId": messageId }
        // Server vraća .resendMessageAck ili ponovno pošalje user-poruku.
    }

    // MARK: A ➜ B (preko servera – control poruke)

    func sendPingToPeer(peerId: String) {
        // TODO:
        // SystemMessage s op: .ping, payload { "mode": "peer-to-peer", "peerId": peerId }
        // Server samo relay-a poruku prema B.
    }

    func sendArpProbeToPeer(peerId: String) {
        // TODO:
        // SystemMessage s op: .arpProbe, payload { "peerId": peerId }
        // B strana može odgovoriti .arpProbeResult s lokalnim info (priv IP itd.).
    }

    func requestPeerPortDirect(peerId: String) {
        // TODO:
        // SystemMessage s op: .peerPortDirectRequest
        // Server relay-a poruku do B; B šalje .peerPortDirectResult.
    }

    // MARK: Lokalni testovi na ovom Mac-u

    func checkLocalhostAlive() {
        // Provjeri je li localhost dostupan
        // Pokušaj ping prema 127.0.0.1
        let task = Process()
        task.launchPath = "/sbin/ping"
        task.arguments = ["-c", "1", "-W", "1000", "127.0.0.1"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("[ControlChannel] ✅ Localhost je živ (127.0.0.1)")
            } else {
                print("[ControlChannel] ⚠️ Localhost ping nije uspio")
            }
        } catch {
            print("[ControlChannel] ❌ Greška pri provjeri localhost-a: \(error)")
        }
    }

    func checkArpReachability(ipAddress: String) {
        // Provjeri je li IP adresa dostupna preko ARP tablice
        let task = Process()
        task.launchPath = "/usr/sbin/arp"
        task.arguments = ["-n", ipAddress]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                if output.contains(ipAddress) {
                    print("[ControlChannel] ✅ IP \(ipAddress) je u ARP tablici")
                    print("[ControlChannel] ARP output: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                } else {
                    print("[ControlChannel] ⚠️ IP \(ipAddress) nije u ARP tablici")
                }
            } else {
                print("[ControlChannel] ⚠️ IP \(ipAddress) nije dostupan preko ARP-a")
            }
        } catch {
            print("[ControlChannel] ❌ Greška pri provjeri ARP-a za \(ipAddress): \(error)")
        }
    }

    func broadcastLocalArpAnnouncement() {
        // Dohvati lokalnu IP i ispiši je (logički ARP announcement)
        fetchPrivateIPAddress { localIP in
            if let ip = localIP {
                print("[ControlChannel] 📢 ARP Announcement: Moja lokalna IP je \(ip)")
                print("[ControlChannel] 📢 Ovo je logički announcement - u produkciji bi se poslala sistemska poruka")
            } else {
                print("[ControlChannel] ⚠️ Ne mogu dohvatiti lokalnu IP za ARP announcement")
            }
        }
    }

    // MARK: Slanje vlastitog stanja serveru

    func sendLocalEndpointSnapshot() {
        // Koristi agent ako je dostupan, inače koristi direktno networkInspector
        if let agent = agent {
            // Agent ima metodu sendEndpointSnapshot koja već radi sve ovo
            if let roomCode = roomSessionManager?.roomCode {
                agent.sendEndpointSnapshot(conversationId: roomCode)
            } else {
                print("[ControlChannel] ⚠️ Nema roomCode-a, ne mogu poslati endpoint snapshot")
            }
        } else {
            // Fallback: dohvati snapshot i pošalji preko RoomSessionManager-a ako je dostupan
            fetchLocalEndpointSnapshot { snapshot in
                print("[ControlChannel] 📤 Endpoint snapshot dohvaćen, ali nema agenta za slanje")
                // Možeš dodati logiku za slanje preko RoomSessionManager-a ako je potrebno
            }
        }
    }
    
    // MARK: - Lokalno dohvaćanje mrežnih informacija
    
    func fetchLocalEndpointSnapshot(completion: @escaping EndpointSnapshotCallback) {
        // Dohvati port iz agenta ako je dostupan
        let listeningPort = agent?.getP2PListeningPort()
        
        networkInspector.collectSnapshot(listeningPort: listeningPort) { snapshot in
            completion(snapshot)
        }
    }
    
    func fetchPrivateIPAddress(completion: @escaping IPAddressCallback) {
        fetchLocalEndpointSnapshot { snapshot in
            completion(snapshot.localIPAddress)
        }
    }
    
    func fetchPublicIPAddress(completion: @escaping IPAddressCallback) {
        fetchLocalEndpointSnapshot { snapshot in
            completion(snapshot.publicIPAddress)
        }
    }
    
    func fetchListeningPort(completion: @escaping PortCallback) {
        // Prvo pokušaj dohvatiti iz agenta (P2P port)
        if let agentPort = agent?.getP2PListeningPort() {
            completion(agentPort)
            return
        }
        
        // Ako agent nema port, dohvati iz snapshot-a
        fetchLocalEndpointSnapshot { snapshot in
            completion(snapshot.listeningPort)
        }
    }
    
    func fetchGatewayIPAddress(completion: @escaping StringCallback) {
        fetchLocalEndpointSnapshot { snapshot in
            completion(snapshot.gatewayIPAddress)
        }
    }
    
    func fetchGatewayMACAddress(completion: @escaping StringCallback) {
        fetchLocalEndpointSnapshot { snapshot in
            completion(snapshot.gatewayMACAddress)
        }
    }
    
    func fetchInterfaceName(completion: @escaping StringCallback) {
        fetchLocalEndpointSnapshot { snapshot in
            completion(snapshot.interfaceName)
        }
    }
    
    func fetchAndPrintAllNetworkInfo(completion: @escaping EndpointSnapshotCallback) {
        fetchLocalEndpointSnapshot { snapshot in
            print("\n" + "=".repeating(60))
            print("📡 KOMPLETNE MREŽNE INFORMACIJE")
            print("=".repeating(60))
            print("🏠 Privatna IP: \(snapshot.localIPAddress ?? "N/A")")
            print("🌐 Javna IP: \(snapshot.publicIPAddress ?? "N/A")")
            print("🔌 Port: \(snapshot.listeningPort.map(String.init) ?? "N/A")")
            print("🚪 Gateway IP: \(snapshot.gatewayIPAddress ?? "N/A")")
            print("📡 Gateway MAC: \(snapshot.gatewayMACAddress ?? "N/A")")
            print("🌉 Interface: \(snapshot.interfaceName ?? "N/A")")
            print("📋 Interface opis: \(snapshot.interfaceKindDescription ?? "N/A")")
            print("=".repeating(60) + "\n")
            completion(snapshot)
        }
    }
}
