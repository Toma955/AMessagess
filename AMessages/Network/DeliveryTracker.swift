// DeliveryTracker
// Prati poruke po messageId (SEND vs DELIVERED vs READ).
// Watchman će koristiti ove informacije za timeout detekciju.

import Foundation

final class DeliveryTracker {

    struct Entry {
        let messageId: String
        let timestamp: Date
    }

    private(set) var pending: [String: Entry] = [:]

    func trackSent(messageId: String) {
        pending[messageId] = Entry(messageId: messageId, timestamp: Date())
        print("[DeliveryTracker] trackSent(\(messageId))")
    }

    func trackDelivered(messageId: String) {
        pending.removeValue(forKey: messageId)
        print("[DeliveryTracker] trackDelivered(\(messageId))")
    }

    /// Pomoćna funkcija za debug.
    func debugPrintPending() {
        print("[DeliveryTracker] pending = \(pending.keys)")
    }
}
