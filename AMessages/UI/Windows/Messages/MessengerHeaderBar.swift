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

    /// Flag – prikaz krugova za teme (umjesto naslova)
    @State private var showThemePicker: Bool = false

    /// NOVO – stanje expand/collapse za ConnectionIndicator
    @State private var isConnectionIndicatorExpanded: Bool = false

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
            // GORNJI RED – X, -, lampica, SREDINA (title / krugovi), desno search + settings + indikator
            HStack(spacing: 10) {
                // Lijevo: X, -, lampica
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

                // SREDINA – ili naslov ili theme krugovi
                Spacer()

                Group {
                    if showThemePicker {
                        themePicker
                    } else if !showsBottomBar {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: 220)

                Spacer()

                // Desno: search + settings + CONNECTION INDICATOR
                HStack(spacing: 8) {
                    // SEARCH
                    Button {
                        // kad ideš u search – sakrij krugove
                        showThemePicker = false
                        onSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    // SETTINGS – pali/gasi prikaz krugova u sredini
                    Button {
                        showThemePicker.toggle()
                        onQuickSettings()
                    } label: {
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

                    // NOVO: indikator veze kao child unutar headera
                    ConnectionIndicator(
                        mode: isActive ? .server : .notConnected,
                        isExpanded: $isConnectionIndicatorExpanded
                    ) {
                        // kasnije ovdje možeš otvoriti topologiju / dijagnostiku
                    }
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

    // MARK: - Theme picker – KRUGOVI U SREDINI

    private var themePicker: some View {
        HStack(spacing: 8) {
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
        }
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
