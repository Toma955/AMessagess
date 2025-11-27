import SwiftUI

struct MessengerHeaderBar: View {
    var title: String
    var isActive: Bool

    var onClose: () -> Void = {}
    var onMinimize: () -> Void = {}
    var onSearch: () -> Void = {}
    var onQuickSettings: () -> Void = {}

    var body: some View {
        WindowHeaderBar(
            title: title,
            statusColor: isActive ? .green : .red,
            onClose: onClose,
            onMinimize: onMinimize,
            onSearch: onSearch,
            onQuickSettings: onQuickSettings
        )
    }
}
