// SessionFunctionRegistry
// Mapira SessionFunctionID na closure koji prima AgentContext i vraća Bool.
// Ovo je "adapter" između stabala (TreeOfChoice) i konkretnih funkcija.

import Foundation

final class SessionFunctionRegistry {

    typealias SessionFunction = (IndependentMessagesAgentContext) -> Bool

    private var functions: [SessionFunctionID: SessionFunction] = [:]

    init() {
        registerDefaultFunctions()
    }

    private func registerDefaultFunctions() {
        // Za sada stavljamo generičke placeholdere.
        functions[.checkAppAlive] = { _ in
            print("[Function] checkAppAlive (placeholder)")
            return true
        }

        functions[.checkHasNetworkInterface] = { _ in
            print("[Function] checkHasNetworkInterface (placeholder)")
            return true
        }

        functions[.checkHasLocalIP] = { _ in
            print("[Function] checkHasLocalIP (placeholder)")
            return true
        }

        functions[.checkCanReachGateway] = { _ in
            print("[Function] checkCanReachGateway (placeholder)")
            return true
        }

        functions[.checkDnsWorks] = { _ in
            print("[Function] checkDnsWorks (placeholder)")
            return true
        }

        functions[.checkCanReachRelayServer] = { _ in
            print("[Function] checkCanReachRelayServer (placeholder)")
            return true
        }

        functions[.checkTlsHandshake] = { _ in
            print("[Function] checkTlsHandshake (placeholder)")
            return true
        }

        functions[.checkP2PHandshake] = { _ in
            print("[Function] checkP2PHandshake (placeholder)")
            return true
        }

        functions[.forceSwitchToRelay] = { _ in
            print("[Function] forceSwitchToRelay (placeholder)")
            return true
        }

        functions[.securityValidateEndpointChange] = { _ in
            print("[Function] securityValidateEndpointChange (placeholder)")
            return true
        }
    }

    func function(for id: SessionFunctionID) -> SessionFunction? {
        functions[id]
    }

    /// Pomoćna funkcija za debug ispis registriranih funkcija.
    func debugPrintRegisteredFunctions() {
        print("[SessionFunctionRegistry] registered IDs = \(functions.keys)")
    }
}
