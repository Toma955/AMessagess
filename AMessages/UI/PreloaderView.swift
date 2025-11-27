import SwiftUI
import UniformTypeIdentifiers

struct PreloaderView: View {
    @EnvironmentObject var session: SessionManager
    @StateObject private var preloader = Preloader()

    @State private var pinDigits: [String] = Array(repeating: "", count: 12)
    @FocusState private var focusedIndex: Int?
    @State private var isTargeted = false   // highlight za drag & drop

    var body: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 16) {
                Text("AMessages")
                    .font(.title2)

                // 12 PIN polja
                HStack(spacing: 8) {
                    ForEach(0..<12, id: \.self) { index in
                        PinDigitBox(
                            text: $pinDigits[index],
                            index: index,
                            focusedIndex: $focusedIndex,
                            onChanged: checkAndUnlock
                        )
                    }
                }

                if let url = preloader.profileURL {
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let error = preloader.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(isTargeted ? .ultraThickMaterial : .ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 10)
            // cijeli okvir je drop zona
            .onDrop(of: [UTType.fileURL],
                    isTargeted: $isTargeted,
                    perform: handleDrop(providers:))
            .onAppear {
                focusedIndex = 0
            }
        }
    }

    // MARK: - Logika

    private func checkAndUnlock() {
        preloader.pin = pinDigits.joined()

        // čim imamo file + 12 znakova → pokušaj unlock
        if preloader.canUnlock {
            preloader.unlock(using: session)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier,
                          options: nil) { item, _ in
            var url: URL?

            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let u = item as? URL {
                url = u
            }

            if let finalURL = url {
                DispatchQueue.main.async {
                    preloader.setProfile(url: finalURL)
                    checkAndUnlock()
                }
            }
        }

        return true
    }
}
