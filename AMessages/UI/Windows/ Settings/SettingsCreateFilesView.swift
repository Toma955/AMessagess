import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsCreateFilesView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Datoteke")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                Toggle(isOn: $session.rememberDefaultFolders) {
                    Text("Zapamti zadano mjesto za spremanje .secret datoteka")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))

                // NOTES FOLDER
                VStack(alignment: .leading, spacing: 6) {
                    Text("Zadana mapa za bilješke")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    HStack(spacing: 8) {
                        Text(session.notesDefaultFolderPath.isEmpty
                             ? "Nije odabrano"
                             : session.notesDefaultFolderPath)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        #if os(macOS)
                        Button {
                            chooseFolder(forNotes: true)
                        } label: {
                            Image(systemName: "folder")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.white.opacity(0.95))
                                )
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        #endif
                    }
                }

                // HISTORY FOLDER
                VStack(alignment: .leading, spacing: 6) {
                    Text("Zadana mapa za povijest razgovora")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    HStack(spacing: 8) {
                        Text(session.historyDefaultFolderPath.isEmpty
                             ? "Nije odabrano"
                             : session.historyDefaultFolderPath)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        #if os(macOS)
                        Button {
                            chooseFolder(forNotes: false)
                        } label: {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.white.opacity(0.95))
                                )
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        #endif
                    }
                }

                Text("Ako nisu postavljena zadana mjesta, aplikacija će uvijek pitati gdje spremiti novu .secret datoteku.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(18)
        }
    }

    #if os(macOS)
    private func chooseFolder(forNotes: Bool) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Odaberi mapu"

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
    #endif
}
