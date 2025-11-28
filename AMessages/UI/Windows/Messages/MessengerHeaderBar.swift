import SwiftUI

struct MessengerHeaderBar<BottomContent: View>: View {
    var title: String
    var isActive: Bool

    var onClose: () -> Void = {}
    var onMinimize: () -> Void = {}
    var onSearch: () -> Void = {}
    var onQuickSettings: () -> Void = {}

    /// Treba li prikazati donji "prošireni" dio (search + quick settings)
    var showsBottomBar: Bool

    @ViewBuilder var bottomContent: () -> BottomContent

    private let fixedWidth: CGFloat = 420

    init(
        title: String,
        isActive: Bool,
        onClose: @escaping () -> Void = {},
        onMinimize: @escaping () -> Void = {},
        onSearch: @escaping () -> Void = {},
        onQuickSettings: @escaping () -> Void = {},
        showsBottomBar: Bool = false,
        @ViewBuilder bottomContent: @escaping () -> BottomContent = { EmptyView() }
    ) {
        self.title = title
        self.isActive = isActive
        self.onClose = onClose
        self.onMinimize = onMinimize
        self.onSearch = onSearch
        self.onQuickSettings = onQuickSettings
        self.showsBottomBar = showsBottomBar
        self.bottomContent = bottomContent
    }

    var body: some View {
        VStack(spacing: 6) {
            // Gornji red – X, -, lampica, title centriran, search, quick settings
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Button(action: onMinimize) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Circle()
                        .fill(isActive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                }

                Spacer()

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 10) {
                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Button(action: onQuickSettings) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }

            // Donji red – search + quick settings, u istom bloku
            if showsBottomBar {
                bottomContent()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .frame(width: fixedWidth)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.10, blue: 0.14),
                            Color(red: 0.05, green: 0.05, blue: 0.09)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 10)
        )
        .buttonStyle(.plain)
    }
}
