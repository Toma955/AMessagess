import SwiftUI
import CryptoKit

#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct HistoryWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var session: SessionManager

    @State private var title: String = "Povijest razgovora"
    @State private var content: String = ""

    @State private var currentURL: URL? = nil

    @State private var isSearching: Bool = false
    @State private var searchText: String = ""

    @State private var isLoading: Bool = false
    @State private var lastError: String? = nil

    @State private var isDropTargeted: Bool = false   // lokalni zeleni okvir

    private let secretService = SecretNoteService()

    // MARK: - Close

    private func closeHistory() {
        if let idx = windowManager.windows.firstIndex(
            where: { $0.kind == .history && !$0.isDocked }
        ) {
            windowManager.windows.remove(at: idx)
        }
    }

    // MARK: - Open .secret file (gumb)

    private func onOpenFileTapped() {
        guard let masterKey = session.masterKey else {
            lastError = "Sesija nije otključana (nema ključa)."
            return
        }

        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if #available(macOS 11.0, *) {
            let type = UTType(filenameExtension: "secret") ?? .data
            panel.allowedContentTypes = [type]
        } else {
            panel.allowedFileTypes = ["secret"]
        }

        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    self.openURL(url, with: masterKey)
                }
            }
        }
        #else
        lastError = "Otvaranje .secret datoteka podržano je samo na macOS-u."
        #endif
    }

    // MARK: - Open helper

    private func openURL(_ url: URL, with masterKey: SymmetricKey) {
        self.currentURL = url
        self.title = url.deletingPathExtension().lastPathComponent
        self.loadFile(from: url, masterKey: masterKey)
    }

    private func loadFile(from url: URL, masterKey: SymmetricKey) {
        isLoading = true
        lastError = nil
        content = ""

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let text = try self.secretService.loadNote(
                    from: url,
                    masterKey: masterKey
                )

                DispatchQueue.main.async {
                    self.content = text
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastError = "Ne mogu pročitati datoteku.\n\(error)"
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Drag & drop handler (lokalno)

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let masterKey = session.masterKey else {
            lastError = "Sesija nije otključana (nema ključa)."
            return false
        }

        guard let item = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier("public.file-url")
        }) else {
            return false
        }

        item.loadItem(forTypeIdentifier: "public.file-url",
                      options: nil) { data, _ in
            guard
                let data = data as? Data,
                let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }

            guard url.pathExtension == "secret" else { return }

            DispatchQueue.main.async {
                self.openURL(url, with: masterKey)
            }
        }

        return true
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if isSearching {
                    searchHeader
                } else {
                    normalHeader
                }

                ZStack {
                    HistoryBackground()
                        .clipShape(Rectangle())

                    if isLoading {
                        ProgressView("Učitavam…")
                            .progressViewStyle(.circular)
                            .foregroundColor(.white)
                    } else if let err = lastError {
                        ScrollView {
                            Text(err)
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else if content.isEmpty {
                        Text("Odaberi ili dovuci .secret datoteku za prikaz povijesti.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(content)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.95))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }

            // zeleni okvir oko prozora kad se drag-a IZNAD ovog history windowa
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.green, lineWidth: 3)
                    .shadow(color: .green.opacity(0.8), radius: 14)
                    .padding(4)
                    .transition(.opacity)
            }
        }
        .onDrop(
            of: ["public.file-url"],
            isTargeted: $isDropTargeted,
            perform: handleDrop(providers:)
        )
        // ⬇️ reagira na globalni drop (pendingHistoryFileURL)
        .onAppear {
            guard let masterKey = session.masterKey else { return }
            if let url = windowManager.pendingHistoryFileURL,
               currentURL == nil {
                windowManager.pendingHistoryFileURL = nil
                openURL(url, with: masterKey)
            }
        }
        .onChange(of: windowManager.pendingHistoryFileURL) { newURL in
            guard let masterKey = session.masterKey else { return }
            guard let url = newURL, currentURL == nil else { return }
            windowManager.pendingHistoryFileURL = nil
            openURL(url, with: masterKey)
        }
    }

    // MARK: - Headeri

    private var normalHeader: some View {
        HStack(spacing: 10) {
            // Lijevo: open + info
            HStack(spacing: 6) {
                Button {
                    onOpenFileTapped()
                } label: {
                    Circle()
                        .fill(Color(red: 0.20, green: 0.85, blue: 0.45))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    if let url = currentURL {
                        lastError = "Datoteka: \(url.lastPathComponent)\n\nPutanja:\n\(url.path)"
                    } else {
                        lastError = "Nijedna datoteka nije učitana."
                    }
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

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

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
                    // TODO: filter / settings
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button {
                    closeHistory()
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
                    Color(red: 0.16, green: 0.20, blue: 0.30),
                    Color(red: 0.10, green: 0.10, blue: 0.18)
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

                TextField("Pretraži tekst…", text: $searchText)
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
                    Color(red: 0.16, green: 0.20, blue: 0.30),
                    Color(red: 0.10, green: 0.10, blue: 0.18)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Background

private struct HistoryBackground: View {
    var lineSpacing: CGFloat = 22
    var lineColor: Color = Color.white.opacity(0.12)

    var body: some View {
        GeometryReader { geo in
            Color.black.opacity(0.45)

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
