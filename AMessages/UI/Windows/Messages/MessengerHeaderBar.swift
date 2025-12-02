import SwiftUI

struct MessengerHeaderBar<BottomContent: View>: View {
    var title: String
    var isActive: Bool

    @Binding var selectedThemeIndex: Int

    var onClose: () -> Void = {}
    var onMinimize: () -> Void = {}
    var onSearch: () -> Void = {}
    var onQuickSettings: () -> Void = {}

    /// Ako je true – blok se malo proširi i prikaže bottomContent (postavke ili search)
    var showsBottomBar: Bool

    @ViewBuilder var bottomContent: () -> BottomContent

    private let fixedWidth: CGFloat = 420
    private let themeCount = 6

    init(
        title: String,
        isActive: Bool,
        selectedThemeIndex: Binding<Int>,
        onClose: @escaping () -> Void = {},
        onMinimize: @escaping () -> Void = {},
        onSearch: @escaping () -> Void = {},
        onQuickSettings: @escaping () -> Void = {},
        showsBottomBar: Bool = false,
        @ViewBuilder bottomContent: @escaping () -> BottomContent = { EmptyView() }
    ) {
        self.title = title
        self.isActive = isActive
        self._selectedThemeIndex = selectedThemeIndex
        self.onClose = onClose
        self.onMinimize = onMinimize
        self.onSearch = onSearch
        self.onQuickSettings = onQuickSettings
        self.showsBottomBar = showsBottomBar
        self.bottomContent = bottomContent
    }

    var body: some View {
        VStack(spacing: showsBottomBar ? 8 : 4) {
            // GORNJI RED – X, -, lampica, title, theme dots, search, settings
            HStack(spacing: 10) {
                // lijevo: X, -, lampica
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

                // title – sakrij kad su postavke ili search upaljeni
                if !showsBottomBar {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                // desno: theme dots + search + settings
                HStack(spacing: 8) {
                    // 6 tema – uvijek u istom redu s ikonicama
                    ForEach(0..<themeCount, id: \.self) { idx in
                        Button {
                            selectedThemeIndex = idx
                            print("🎨 [THEME] Odabran preset \(idx)")
                        } label: {
                            Circle()
                                .fill(themeColor(for: idx))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            idx == selectedThemeIndex
                                            ? Color.white.opacity(0.9)
                                            : Color.white.opacity(0.3),
                                            lineWidth: idx == selectedThemeIndex ? 2 : 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    Button(action: onQuickSettings) {
                        ZStack {
                            if showsBottomBar {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 22, height: 22)
                            }
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(showsBottomBar ? .black : .white)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // DONJI DIO – unutar istog crnog bloka
            if showsBottomBar {
                bottomContent()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, showsBottomBar ? 10 : 6)
        .frame(width: fixedWidth)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.90))
        )
        .buttonStyle(.plain)
    }

    private func themeColor(for index: Int) -> LinearGradient {
        switch index {
        case 0:
            return LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.85, blue: 0.45),
                    Color(red: 0.10, green: 0.55, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 1:
            return LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.70, blue: 0.90),
                    Color(red: 0.15, green: 0.40, blue: 0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [
                    Color(red: 0.60, green: 0.50, blue: 0.95),
                    Color(red: 0.40, green: 0.30, blue: 0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.80, blue: 0.45),
                    Color(red: 0.95, green: 0.55, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 4:
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.55, blue: 0.40),
                    Color(red: 0.85, green: 0.30, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.2, blue: 0.3),
                    Color(red: 0.6, green: 0.1, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
