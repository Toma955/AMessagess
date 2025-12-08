//
//  P2PTransport.swift
//  AMessages
//
//  Created by Toma Babić on 02.12.2025..
//

import Foundation
import Network

/// P2P Transport za direktnu komunikaciju između agenata
final class P2PTransport {
    
    /// Callback za primanje poruka: (Message, peerId)
    var onMessageReceived: ((Message, String) -> Void)?
    
    /// UDP connection za slanje/primanje
    private var udpConnection: NWConnection?
    
    /// UDP listener za primanje poruka
    private var udpListener: NWListener?
    
    /// Port na kojem slušamo
    private var listeningPort: UInt16?
    
    /// Aktivni peer connections (za kasnije TCP opcije)
    private var peerConnections: [String: NWConnection] = [:]
    
    init() {
        // Inicijalizacija - listener će biti pokrenut kada se pozove startListening
    }
    
    deinit {
        stopListening()
        disconnectAll()
    }
    
    // MARK: - Listening
    
    /// Pokreni slušanje na određenom portu
    /// - Parameter port: Port na kojem će slušati (nil = automatski)
    func startListening(port: UInt16? = nil, completion: @escaping (Bool, UInt16?) -> Void) {
        let actualPort = port ?? 0 // 0 = automatski port
        
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        
        let listener: NWListener
        do {
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: UInt16(actualPort)) ?? 0)
        } catch {
            print("[P2PTransport] Failed to create listener: \(error)")
            completion(false, nil)
            return
        }
        
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                if let port = listener.port?.rawValue {
                    print("[P2PTransport] Listening on port \(port)")
                    self.listeningPort = UInt16(port)
                    completion(true, UInt16(port))
                } else {
                    completion(false, nil)
                }
            case .failed(let error):
                print("[P2PTransport] Listener failed: \(error)")
                completion(false, nil)
            case .cancelled:
                print("[P2PTransport] Listener cancelled")
                completion(false, nil)
            default:
                break
            }
        }
        
        listener.start(queue: .global())
        self.udpListener = listener
    }
    
    /// Zaustavi slušanje
    func stopListening() {
        udpListener?.cancel()
        udpListener = nil
        listeningPort = nil
    }
    
    // MARK: - Sending
    
    /// Pošalji podatke preko UDP-a
    /// - Parameters:
    ///   - data: Podaci za slanje
    ///   - address: IP adresa primaoca
    ///   - port: Port primaoca
    ///   - completion: Callback s rezultatom (success, error)
    func send(
        data: Data,
        to address: String,
        port: UInt16,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        // NWEndpoint.Host može biti inicijaliziran direktno
        // Ako adresa nije valjana, možemo provjeriti kasnije ili koristiti try-catch
        let host = NWEndpoint.Host(address)
        
        let portValue = NWEndpoint.Port(rawValue: UInt16(port)) ?? NWEndpoint.Port(integerLiteral: 0)
        let endpoint = NWEndpoint.hostPort(host: host, port: portValue)
        
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        
        let connection = NWConnection(to: endpoint, using: params)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.send(content: data, completion: .contentProcessed { error in
                    if let error = error {
                        print("[P2PTransport] Send error: \(error)")
                        completion(false, error)
                    } else {
                        print("[P2PTransport] Data sent successfully to \(address):\(port)")
                        completion(true, nil)
                    }
                    connection.cancel()
                })
            case .failed(let error):
                print("[P2PTransport] Connection failed: \(error)")
                completion(false, error)
                connection.cancel()
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    // MARK: - Receiving
    
    /// Rukuje novom konekcijom (za UDP, ovo se poziva za svaki paket)
    private func handleNewConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receive(on: connection)
            case .failed(let error):
                print("[P2PTransport] Connection failed: \(error)")
                connection.cancel()
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    /// Primaj podatke na konekciji
    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, context, isComplete, error in
            if let error = error {
                print("[P2PTransport] Receive error: \(error)")
                connection.cancel()
                return
            }
            
            guard let data = data, !data.isEmpty else {
                // Nastavi slušati
                self?.receive(on: connection)
                return
            }
            
            // Pokušaj dekodirati poruku
            self?.handleReceivedData(data, from: connection)
            
            // Nastavi slušati
            self?.receive(on: connection)
        }
    }
    
    /// Rukuje primljenim podacima
    private func handleReceivedData(_ data: Data, from connection: NWConnection) {
        // Pokušaj dekodirati kao Message
        // Za sada pretpostavljamo da je to plain tekst ili enkriptirani tekst
        if let text = String(data: data, encoding: .utf8) {
            // Kreiraj Message objekt
            // Peer ID ćemo dobiti iz connection endpoint-a ili iz poruke
            let peerId = connection.currentPath?.remoteEndpoint?.debugDescription ?? "unknown"
            
            let message = Message(
                id: UUID(),
                conversationId: peerId, // ili neki drugi identifikator
                direction: .incoming,
                timestamp: Date(),
                text: text
            )
            
            // Pozovi callback
            onMessageReceived?(message, peerId)
        } else {
            print("[P2PTransport] Received non-UTF8 data, ignoring")
        }
    }
    
    // MARK: - Connection management
    
    /// Prekini sve konekcije
    private func disconnectAll() {
        peerConnections.values.forEach { $0.cancel() }
        peerConnections.removeAll()
        udpConnection?.cancel()
        udpConnection = nil
    }
    
    /// Vrati port na kojem slušamo (ako je aktivan)
    func getListeningPort() -> UInt16? {
        return listeningPort
    }
}

