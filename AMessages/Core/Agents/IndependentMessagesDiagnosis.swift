// IndependentMessagesDiagnosis
// Definira stanja dijagnostike i evente koje agent i watchman koriste.

import Foundation

enum IndependentMessagesFaultLocation {
    case none
    case localDevice
    case localNetwork
    case internet
    case remoteSide
    case server
}

enum IndependentMessagesTopologyMode {
    case onDevice
    case lan
    case p2pInternet
}

enum IndependentMessagesTransportMode {
    case p2p
    case relay
}

/// Rezultat jedne dijagnostičke "runde" – ovo će čitati UI view model.
struct IndependentMessagesDiagnosisResult {

    var faultLocation: IndependentMessagesFaultLocation = .none
    var topologyMode: IndependentMessagesTopologyMode = .p2pInternet
    var transportMode: IndependentMessagesTransportMode = .p2p
    var isServerActive: Bool = false
    var humanSummary: String = "Nema aktivne dijagnostike."

    init() {}
}

/// Eventi koje Watchman šalje Agentu.
enum IndependentMessagesAgentEvent {
    case deliveryTimeout(messageId: String)
    case networkChanged
    case p2pTransportFailed
    case relayTransportFailed
    case manualTrigger

    /// Pomoćna funkcija za debug opis.
    func debugDescription() -> String {
        switch self {
        case .deliveryTimeout(let id): return "deliveryTimeout(\(id))"
        case .networkChanged: return "networkChanged"
        case .p2pTransportFailed: return "p2pTransportFailed"
        case .relayTransportFailed: return "relayTransportFailed"
        case .manualTrigger: return "manualTrigger"
        }
    }
}
