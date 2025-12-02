import SwiftUI
import CryptoKit
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct SettingsCreateFilesView: View {
    @EnvironmentObject var session: SessionManager
    @ObservedObject private var localization = Localization.shared

    // Status poruka za sistemske .secret datoteke
    @State private var systemSecretStatus: String = ""
    @State private var systemSecretStatusColor: Color = .white.opacity(0.7)

    // Drag & drop highlight
    #if os(macOS)
    @State private var isDroppingSystemSecret: Bool = false
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Glavni naslov – sad lokaliziran
                Text(localization.text(.settingsFiles))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                // MARK: - Zadane mape
                defaultFoldersSection

                Divider().background(Color.white.opacity(0.15))

                // MARK: - Sistemske .secret datoteke
                systemSecretSection
            }
            .padding(18)
        }
    }

    // MARK: - Zadane mape

    private var defaultFoldersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Zadane mape")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Toggle(isOn: $session.rememberDefaultFolders) {
                Text("Pamti zadane mape za bilješke i povijest")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))

            Text("Ako je uključeno, aplikacija pamti zadnju mapu koju si odabrao za bilješke i povijest razgovora.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 6) {
                folderRow(
                    title: "Mapa za bilješke",
                    path: session.notesDefaultFolderPath,
                    action: { pickDefaultFolder(forNotes: true) }
                )

                folderRow(
                    title: "Mapa za povijest razgovora",
                    path: session.historyDefaultFolderPath,
                    action: { pickDefaultFolder(forNotes: false) }
                )
            }
            .padding(.top, 4)
        }
    }

    private func folderRow(title: String, path: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                Text(path.isEmpty ? "Nije odabrano" : path)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            #if os(macOS)
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 12, weight: .bold))
                    Text("Promijeni…")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
            #else
            Text("Dostupno samo na macOS-u")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
            #endif
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Sistemske .secret datoteke

    private var systemSecretSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sistemske .secret datoteke")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("Ovdje možeš kreirati i provjeriti posebne .secret datoteke koje aplikacija koristi za sistemske/funkcijske podatke. Format je odvojen od običnih bilješki.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            #if os(macOS)
            HStack(spacing: 10) {
                Button {
                    createSystemSecretFileViaPanel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.rectangle.on.folder")
                            .font(.system(size: 13, weight: .bold))
                        Text("Kreiraj sistemsku .secret datoteku…")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.green.opacity(0.35))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    validateSystemSecretFileViaPanel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 13, weight: .bold))
                        Text("Provjeri postojeću .secret datoteku…")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.blue.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
            }

            // Drag & Drop okvir za .secret datoteke
            VStack(spacing: 6) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.system(size: 20, weight: .semibold))
                Text("Povuci .secret datoteku ovdje")
                    .font(.system(size: 11, weight: .semibold))
                Text("File će se automatski provjeriti i očitati metapodatke.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isDroppingSystemSecret
                        ? Color.green.opacity(0.9)
                        : Color.white.opacity(0.25),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
            )
            .onDrop(
                of: [UTType.fileURL],
                isTargeted: $isDroppingSystemSecret,
                perform: handleSystemSecretDrop(providers:)
            )

            if !systemSecretStatus.isEmpty {
                Text(systemSecretStatus)
                    .font(.system(size: 11))
                    .foregroundColor(systemSecretStatusColor)
                    .padding(.top, 4)
            }
            #else
            Text("Upravljanje sistemskim .secret datotekama je dostupno samo na macOS-u.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
            #endif
        }
    }

    // MARK: - macOS helperi

    #if os(macOS)
    private func pickDefaultFolder(forNotes: Bool) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = forNotes ? "Odaberi mapu za bilješke" : "Odaberi mapu za povijest razgovora"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    if forNotes {
                        session.notesDefaultFolderPath = url.path
                    } else {
                        session.historyDefaultFolderPath = url.path
                    }
                }
            }
        }
    }

    private func createSystemSecretFileViaPanel() {
        guard let masterKey = session.masterKey else {
            systemSecretStatus = "Prvo otključaj aplikaciju (master ključ nije dostupan)."
            systemSecretStatusColor = .red.opacity(0.8)
            return
        }

        let panel = NSSavePanel()
        panel.allowedFileTypes = ["secret"]
        panel.canCreateDirectories = true
        panel.title = "Spremi sistemsku .secret datoteku"
        panel.nameFieldStringValue = "system.secret"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let formatter = ISO8601DateFormatter()
                        let payload: [String: String] = [
                            "type": "system",
                            "id": UUID().uuidString,
                            "createdAt": formatter.string(from: Date())
                        ]

                        try SecretSystemFileService.shared.createSystemSecretFile(
                            payload: payload,
                            to: url,
                            masterKey: masterKey
                        )

                        DispatchQueue.main.async {
                            systemSecretStatus = "Sistemska .secret datoteka je uspješno kreirana."
                            systemSecretStatusColor = .green.opacity(0.85)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            systemSecretStatus = "Greška pri kreiranju .secret datoteke: \(error.localizedDescription)"
                            systemSecretStatusColor = .red.opacity(0.85)
                        }
                    }
                }
            }
        }
    }

    private func validateSystemSecretFileViaPanel() {
        guard let masterKey = session.masterKey else {
            systemSecretStatus = "Prvo otključaj aplikaciju (master ključ nije dostupan)."
            systemSecretStatusColor = .red.opacity(0.8)
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["secret"]
        panel.title = "Odaberi .secret datoteku za provjeru"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                validateSystemSecretFile(at: url, masterKey: masterKey)
            }
        }
    }

    /// Korišteno i za panel i za drag & drop
    private func validateSystemSecretFile(at url: URL, masterKey: SymmetricKey) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try SecretSystemFileService.shared.validateFile(at: url)
                let payload = try SecretSystemFileService.shared.loadSystemSecretFile(from: url, masterKey: masterKey)

                let type = payload["type"] ?? "nepoznato"
                let id = payload["id"] ?? "—"

                let msg = "Datoteka je valjana.\nTip: \(type)\nID: \(id)"
                DispatchQueue.main.async {
                    systemSecretStatus = msg
                    systemSecretStatusColor = .green.opacity(0.9)
                }
            } catch {
                DispatchQueue.main.async {
                    systemSecretStatus = "Datoteka nije valjana ili se ne može pročitati: \(error.localizedDescription)"
                    systemSecretStatusColor = .red.opacity(0.9)
                }
            }
        }
    }

    private func handleSystemSecretDrop(providers: [NSItemProvider]) -> Bool {
        guard let masterKey = session.masterKey else {
            systemSecretStatus = "Prvo otključaj aplikaciju (master ključ nije dostupan)."
            systemSecretStatusColor = .red.opacity(0.8)
            return false
        }

        let identifier = UTType.fileURL.identifier
        var handled = false

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(identifier) {
                provider.loadItem(forTypeIdentifier: identifier, options: nil) { (item, error) in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        handled = true
                        validateSystemSecretFile(at: url, masterKey: masterKey)
                    }
                }
            }
        }

        return handled
    }
    #else
    private func pickDefaultFolder(forNotes: Bool) { }
    private func createSystemSecretFileViaPanel() { }
    private func validateSystemSecretFileViaPanel() { }
    #endif
}
