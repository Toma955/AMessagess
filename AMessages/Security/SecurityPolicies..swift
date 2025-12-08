// SecurityPolicies
// Konfiguracija i pragovi (thresholdi) za sigurnosnu logiku.

import Foundation

struct SecurityPolicies {

    var maxEndpointChangesPerSession: Int = 5
    var maxFailedHandshakes: Int = 3

    static var `default`: SecurityPolicies {
        SecurityPolicies()
    }

    func debugPrintPolicies() {
        print("[SecurityPolicies] endpointChanges=\(maxEndpointChangesPerSession), failedHandshakes=\(maxFailedHandshakes)")
    }
}
