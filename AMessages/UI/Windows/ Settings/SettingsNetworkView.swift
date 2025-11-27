import SwiftUI

struct SettingsNetworkView: View {
    @EnvironmentObject var session: SessionManager

    @Binding var serverText: String
    @Binding var isTestingConnection: Bool
    @Binding var connectionStatus: SettingsWindow.ConnectionStatus?

    let runTestConnection: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Internet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Adresa servera")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text("Glavni poslužitelj za razmjenu poruka.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))

                    TextField("https://server.tvoja-domena.com", text: $serverText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .foregroundColor(.white)
                }

                Divider().background(Color.white.opacity(0.15))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Test konekcije")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text("Provjeri može li se aplikacija spojiti na zadani server (zasad simulacija).")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 10) {
                        Button {
                            runTestConnection()
                        } label: {
                            HStack(spacing: 6) {
                                if isTestingConnection {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 13, weight: .semibold))
                                }

                                Text(isTestingConnection ? "Testiram..." : "Testiraj konekciju")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.95))
                            )
                            .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTestingConnection || session.serverAddress.isEmpty)

                        if let status = connectionStatus {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(status == .ok ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)

                                Text(status == .ok ? "Online" : "Neuspješno")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}
