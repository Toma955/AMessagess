import SwiftUI

/// Bazični header za prozor
struct WindowHeaderBar: View {
    /// Naslov prozora / razgovora
    var title: String? = nil

    /// Opcionalna boja status točkice (ako je želiš koristiti)
    var statusColor: Color? = nil   // npr. .green ili .red

    var onClose: () -> Void = {}
    var onMinimize: () -> Void = {}
    var onSearch: () -> Void = {}
    var onQuickSettings: () -> Void = {}

    private let fixedWidth: CGFloat = 420

    // MARK: - Lokalno stanje UI-ja (search / theme picker)

    @State private var isSearching: Bool = false
    @State private var isShowingThemes: Bool = false
    @State private var searchText: String = ""
    @State private var isEditingTitle: Bool = false
    @State private var internalTitle: String = ""

    // Tema se čita / sprema preko SessionManagera (kao i dosad)
    @EnvironmentObject var session: SessionManager

    // Trenutni theme ID iz SessionManagera.selectedTheme
    private var currentThemeId: AppThemeID {
        if let raw = Int(session.selectedTheme) {
            return AppThemeID.fromStored(raw)
        } else {
            return .onlineGreen
        }
    }

    var body: some View {
        ZStack {
            // Pozadina headera
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black)

            // Lijevi i desni gumbi
            HStack(spacing: 16) {
                // Lijevo: X + minus
                HStack(spacing: 10) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.25))
                    }

                    Button(action: onMinimize) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.25, green: 0.9, blue: 0.4))
                    }
                }

                Spacer()

                // Desno: search + quick settings
                HStack(spacing: 14) {
                    // SEARCH gumb
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching.toggle()
                            if isSearching {
                                // kad ide u search mode → ugasi theme picker
                                isShowingThemes = false
                                isEditingTitle = false
                            } else {
                                searchText = ""
                            }
                        }
                        onSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isSearching ? .blue : .white)
                    }

                    // SETTINGS / THEME PICKER gumb
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            isShowingThemes.toggle()
                            if isShowingThemes {
                                // kad otvaraš theme picker → ugasi search & edit title
                                isSearching = false
                                isEditingTitle = false
                            }
                        }
                        onQuickSettings()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isShowingThemes ? .orange : .white)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)

            // SREDINA – naslov / search / theme picker
            centerContent
                .padding(.horizontal, 80) // da ne uđe u lijeve/desne gumbe
        }
        .frame(width: fixedWidth, height: 40)
        .buttonStyle(.plain)
        .onAppear {
            internalTitle = title ?? ""
        }
    }

    // MARK: - Središnji sadržaj

    @ViewBuilder
    private var centerContent: some View {
        if isSearching {
            searchField
        } else if isShowingThemes {
            themePicker
        } else if isEditingTitle {
            titleEditor
        } else {
            titleLabel
        }
    }

    // Normalan naslov u sredini
    private var titleLabel: some View {
        HStack(spacing: 6) {
            if let statusColor {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }

            Text(internalTitle.isEmpty ? (title ?? "Razgovor") : internalTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditingTitle = true
            }
        }
    }

    // Uređivanje naslova (lokalno – vizualno)
    private var titleEditor: some View {
        TextField("Naslov", text: $internalTitle)
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.12))
            )
            .onSubmit {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditingTitle = false
                }
            }
    }

    // Search polje – pojavljuje se umjesto naslova
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            TextField("Pretraži…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.14))
        )
    }

    // Theme picker – krugovi se prikazuju SAMO kad je settings aktivan
    private var themePicker: some View {
        HStack(spacing: 6) {
            ForEach(AppThemeID.allCases) { id in
                let isSelected = (id == currentThemeId)

                Circle()
                    .fill(id.theme.highlightGradient)
                    .frame(width: isSelected ? 16 : 13,
                           height: isSelected ? 16 : 13)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isSelected ? 0.9 : 0.0), lineWidth: 1.5)
                    )
                    .shadow(radius: isSelected ? 4 : 0)
                    .onTapGesture {
                        // spremi izbor u SessionManageru kao rawValue
                        session.selectedTheme = String(id.rawValue)
                    }
            }
        }
    }
}
