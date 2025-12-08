// SecurityFunctions
// Tanki "wrapper" prema SecurityManageru – ovdje se kasnije rade provjere
// endpoint promjena, MITM zaštite i anti-abuse logike.

import Foundation

struct SecurityFunctions {

    static func validateEndpointChange(_ context: IndependentMessagesAgentContext) -> Bool {
        // TODO: kasnije pozvati SecurityManager
        print("[SecurityFunctions] validateEndpointChange (placeholder)")
        return true
    }
}
