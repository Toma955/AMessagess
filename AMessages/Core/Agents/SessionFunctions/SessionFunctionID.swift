// SessionFunctionID
// Popis svih funkcija koje DecisionTree može pozivati.
// Implementacije su u zasebnim *Functions.swift* datotekama.

import Foundation

enum SessionFunctionID {
    // Device basics
    case checkAppAlive
    case checkHasNetworkInterface
    case checkHasLocalIP

    // Local network
    case checkCanReachGateway
    case checkDnsWorks

    // Internet / server
    case checkCanReachRelayServer
    case checkTlsHandshake

    // P2P
    case checkP2PHandshake
    case forceSwitchToRelay

    // Security
    case securityValidateEndpointChange
}
