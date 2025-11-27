import SwiftUI

struct WelcomeWindow: View {
    @EnvironmentObject var windowManager: WindowManager

    @State private var isServerConnected: Bool = false
    @State private var isCryptoReady: Bool = true
    @State private var isStorageReady: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AMessages status")
                .font(.title2.bold())

            Text("Brza provjera stanja sustava prije korištenja aplikacije.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            VStack(spacing: 10) {
                statusRow(
                    icon: "network",
                    title: "Veza sa serverom",
                    isOK: isServerConnected,
                    info: isServerConnected ? "Spojeno" : "Nije spojeno"
                )

                statusRow(
                    icon: "lock.shield",
                    title: "Kriptografski modul",
                    isOK: isCryptoReady,
                    info: isCryptoReady ? "Aktivan" : "Problem"
                )

                statusRow(
                    icon: "internaldrive",
                    title: "Lokalna pohrana",
                    isOK: isStorageReady,
                    info: isStorageReady ? "Spremna" : "Problem s diskom"
                )
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    // čim nastaviš → otvori glavni (messages) prozor
                    windowManager.open(kind: .messages)
                } label: {
                    Text("Nastavi")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.95))
                        )
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func statusRow(icon: String, title: String, isOK: Bool, info: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(info)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Circle()
                .fill(isOK ? Color.green : Color.red)
                .frame(width: 10, height: 10)
        }
    }
}
