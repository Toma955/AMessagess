// DeviceBasicsFunctions
// Ovdje će kasnije doći konkretne implementacije basic checkova
// (app alive, mrežni interfejs, lokalna IP, ...).

import Foundation

struct DeviceBasicsFunctions {

    static func example(_ context: IndependentMessagesAgentContext) -> Bool {
        print("[DeviceBasicsFunctions] example() called, context = \(context)")
        return true
    }
}
