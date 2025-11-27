import SwiftUI
import CryptoKit

#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct NotesWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var session: SessionManager

    @State private var noteTitle: String = "Nova bilješka"
    @State private var noteText: String = ""

    @State private var isSearching: Bool = false
    @State private var searchText: String = ""

    @State private var noteURL: URL? = nil
    @State private var isSaving: Bool = false

    private let secretService = SecretNoteService()

    // MARK: - Zatvaranje

    private func closeNotes() {
        if let idx = windowManager.windows.firstIndex(
            where: { $0.kind == .notes && !$0.isDocked }
        ) {
            windowManager.windows.remove(at: idx)
        }
    }

    // MARK: - Save / Info

    private func onSaveTapped() {
        guard let masterKey = session.masterKey else {
            print("Nema masterKey-a – preloader još nije otključao sesiju.")
            return
        }

        // prvi put – tražimo lokaciju
        if noteURL == nil {
            #if os(macOS)
            showSavePanel(masterKey: masterKey)
            #else
            print("Spremanje fajla podržano je samo na macOS-u (NSSavePanel).")
            #endif
        } else if let url = noteURL {
            // već znam gdje spremam → direktno save
            performSave(to: url, masterKey: masterKey)
        }
    }

    private func onInfo() {
        // kasnije: info o noti (putanja, vrijeme, sl.)
        print("Info o bilješci – TODO UI")
    }

    // MARK: - macOS Save Panel

    #if os(macOS)
    private func showSavePanel(masterKey: SymmetricKey) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true

        if #available(macOS 11.0, *) {
            let type = UTType(filenameExtension: "secret") ?? .data
            panel.allowedContentTypes = [type]
        } else {
            panel.allowedFileTypes = ["secret"]
        }

        let sanitizedTitle = sanitizedFilename(from: noteTitle)
        panel.nameFieldStringValue = sanitizedTitle.isEmpty
            ? "Biljeska.secret"
            : "\(sanitizedTitle).secret"

        // NE koristimo runModal (blokira / ponekad se ponaša čudno u SwiftUI),
        // nego async varijantu.
        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    self.noteURL = url
                    self.performSave(to: url, masterKey: masterKey)
                }
            }
        }
    }
    #endif

    private func sanitizedFilename(from title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return trimmed.components(separatedBy: invalid).joined(separator: "_")
    }

    private func performSave(to url: URL, masterKey: SymmetricKey) {
        isSaving = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.secretService.saveNote(
                    text: self.noteText,
                    to: url,
                    masterKey: masterKey
                )
                print("Bilješka spremljena na: \(url.path)")
            } catch {
                print("Greška pri spremanju bilješke: \(error)")
            }

            DispatchQueue.main.async {
                self.isSaving = false
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                searchHeader
            } else {
                normalHeader
            }

            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.white.opacity(0.10))

                LinedBackground()
                    .clipShape(Rectangle())

                noteEditor
            }
        }
    }

    // MARK: - Headeri

    private var normalHeader: some View {
        HStack(spacing: 10) {
            // Lijevo: SAVE + INFO
            HStack(spacing: 6) {
                Button {
                    onSaveTapped()
                } label: {
                    saveIcon
                }
                .buttonStyle(.plain)

                Button {
                    onInfo()
                } label: {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.25, blue: 0.25))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "info")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Sredina: naziv bilješke
            TextField("Naziv bilješke", text: $noteTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(.vertical, 2)

            Spacer()

            // Desno: lupa, settings, X
            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.25,
                                          dampingFraction: 0.8)) {
                        isSearching = true
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: quick settings za bilješke
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button {
                    closeNotes()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.65, blue: 0.25),
                    Color(red: 1.0, green: 0.50, blue: 0.20)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private var searchHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)

                TextField("Pretraži bilješke", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color.white)
            )
            .foregroundColor(.black)

            Button {
                withAnimation(.spring(response: 0.25,
                                      dampingFraction: 0.8)) {
                    isSearching = false
                    searchText = ""
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.65, blue: 0.25),
                    Color(red: 1.0, green: 0.50, blue: 0.20)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Save ikona (samo pokazujemo je li u tijeku spremanje)

    private var saveIcon: some View {
        Group {
            if isSaving {
                Circle()
                    .fill(Color(red: 0.95, green: 0.25, blue: 0.25))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(360))
                            .animation(
                                .linear(duration: 1.0)
                                    .repeatForever(autoreverses: false),
                                value: isSaving
                            )
                    )
            } else {
                Circle()
                    .fill(Color(red: 0.20, green: 0.85, blue: 0.45))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
    }

    // MARK: - Editor

    @ViewBuilder
    private var noteEditor: some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            TextEditor(text: $noteText)
                .scrollContentBackground(.hidden)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.clear)
        } else {
            TextEditor(text: $noteText)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.clear)
        }
    }
}

/// Pozadinske vodoravne linije kao u bilježnici
private struct LinedBackground: View {
    var lineSpacing: CGFloat = 22
    var lineColor: Color = Color.white.opacity(0.18)

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width

            Path { path in
                var y: CGFloat = 0
                while y < height {
                    path.move(to: CGPoint(x: 10, y: y + 0.5))
                    path.addLine(to: CGPoint(x: width - 10, y: y + 0.5))
                    y += lineSpacing
                }
            }
            .stroke(lineColor, lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}
