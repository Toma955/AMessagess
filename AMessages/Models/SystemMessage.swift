import Foundation

/// Tip sistemske poruke
enum SystemMessageType: String, Codable {
    case endpointSnapshot = "endpoint_snapshot"      // Agent šalje svoj endpoint snapshot
    case endpointSnapshotRequest = "endpoint_request" // Zahtjev za endpoint snapshot
    case endpointSnapshotAck = "endpoint_snapshot_ack" // Potvrda primitka endpoint snapshot-a
    case ping = "ping"                                // Ping poruka
    case pong = "pong"                                // Pong odgovor
}

/// Endpoint snapshot - informacije o mrežnom endpointu agenta
struct EndpointSnapshot: Codable {
    let peerId: String                    // ID agenta
    let localIPAddress: String?          // Privatna IP adresa
    let publicIPAddress: String?         // Javna IP adresa
    let listeningPort: UInt16?           // Port na kojem sluša
    let gatewayIPAddress: String?        // Gateway IP
    let gatewayMACAddress: String?       // Gateway MAC
    let timestamp: Date                  // Vrijeme kada je snapshot napravljen
}

/// Sistemska poruka koja se razmjenjuje između agenata
struct SystemMessage: Codable {
    let type: SystemMessageType
    let snapshot: EndpointSnapshot?      // Ako je type == .endpointSnapshot
    let peerId: String?                  // ID agenta koji šalje/primljeni
    let timestamp: Date
    
    init(type: SystemMessageType, snapshot: EndpointSnapshot? = nil, peerId: String? = nil) {
        self.type = type
        self.snapshot = snapshot
        self.peerId = peerId
        self.timestamp = Date()
    }
}

