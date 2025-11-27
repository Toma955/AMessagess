import SwiftUI

struct HistoryHeaderBar: View {
    var onClose: () -> Void = {}
    var onMinimize: () -> Void = {}
    var onSearch: () -> Void = {}
    var onQuickSettings: () -> Void = {}

    var body: some View {
        WindowHeaderBar(
            onClose: onClose,
            onMinimize: onMinimize,
            onSearch: onSearch,
            onQuickSettings: onQuickSettings
        )
    }
}
