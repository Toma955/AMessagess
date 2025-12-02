import SwiftUI

enum AppLanguage {
    case hr, en, de, fr
}

private struct WelcomeStrings {
    let title: String
    let subtitle: String

    let serverTitle: String
    let serverInfo: String

    let cryptoTitle: String
    let cryptoInfo: String

    let storageTitle: String
    let storageInfo: String

    let primaryButton: String
    let secondaryButton: String

    static func forLanguage(_ lang: AppLanguage) -> WelcomeStrings {
        switch lang {
        case .hr:
            return .init(
                title: "AMessages status",
                subtitle: "Brza provjera stanja sustava prije korištenja aplikacije.",

                serverTitle: "Server veza",
                serverInfo: "Provjera može li se uspostaviti veza s relay serverom.",

                cryptoTitle: "Kriptografija",
                cryptoInfo: "Lokalne kripto-funkcije i ključevi spremni za rad.",

                storageTitle: "Spremanje podataka",
                storageInfo: "Lokalna pohrana i log datoteke dostupne.",

                primaryButton: "Započni razgovor",
                secondaryButton: "Otvori postavke"
            )

        case .en:
            return .init(
                title: "AMessages status",
                subtitle: "Quick system check before using the app.",

                serverTitle: "Server connection",
                serverInfo: "Checks if relay server is reachable.",

                cryptoTitle: "Cryptography",
                cryptoInfo: "Local crypto functions and keys ready.",

                storageTitle: "Storage",
                storageInfo: "Local storage and log files available.",

                primaryButton: "Start conversation",
                secondaryButton: "Open settings"
            )

        case .de:
            return .init(
                title: "AMessages Status",
                subtitle: "Schneller Systemcheck vor der Verwendung der App.",

                serverTitle: "Serververbindung",
                serverInfo: "Prüft, ob der Relay-Server erreichbar ist.",

                cryptoTitle: "Kryptographie",
                cryptoInfo: "Lokale Krypto-Funktionen und Schlüssel bereit.",

                storageTitle: "Speicher",
                storageInfo: "Lokaler Speicher und Log-Dateien verfügbar.",

                primaryButton: "Konversation starten",
                secondaryButton: "Einstellungen öffnen"
            )

        case .fr:
            return .init(
                title: "Statut AMessages",
                subtitle: "Vérification rapide du système avant d’utiliser l’app.",

                serverTitle: "Connexion au serveur",
                serverInfo: "Vérifie si le serveur relais est joignable.",

                cryptoTitle: "Cryptographie",
                cryptoInfo: "Fonctions et clés locales prêtes à l’emploi.",

                storageTitle: "Stockage",
                storageInfo: "Stockage local et fichiers journaux disponibles.",

                primaryButton: "Commencer une conversation",
                secondaryButton: "Ouvrir les réglages"
            )
        }
    }
}

struct WelcomeWindow: View {
    @EnvironmentObject var windowManager: WindowManager

    // za sada default HR, kasnije izvučeš iz postavki
    var language: AppLanguage = .hr

    @State private var isServerConnected: Bool = false
    @State private var isCryptoReady: Bool = true
    @State private var isStorageReady: Bool = true

    private var strings: WelcomeStrings {
        WelcomeStrings.forLanguage(language)
    }

    var body: some View {
        VStack {
            Spacer()

            GlassPanel {
                VStack(alignment: .center, spacing: 18) {
                    // NASLOV + OPIS
                    VStack(spacing: 6) {
                        Text(strings.title)
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(strings.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Divider()

                    // STATUSI – centrirani blok, redovi sami ostaju lijevo radi čitljivosti
                    VStack(alignment: .leading, spacing: 12) {
                        statusRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: strings.serverTitle,
                            isOK: isServerConnected,
                            info: strings.serverInfo
                        )

                        statusRow(
                            icon: "lock.shield",
                            title: strings.cryptoTitle,
                            isOK: isCryptoReady,
                            info: strings.cryptoInfo
                        )

                        statusRow(
                            icon: "externaldrive",
                            title: strings.storageTitle,
                            isOK: isStorageReady,
                            info: strings.storageInfo
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // GUMBI – centrirani
                    HStack(spacing: 12) {
                        Button {
                            windowManager.open(kind: .messages)
                        } label: {
                            Text(strings.primaryButton)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.95))
                                )
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)

                        Button {
                            windowManager.open(kind: .settings)
                        } label: {
                            Text(strings.secondaryButton)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                }
                .frame(maxWidth: 420)
            }

            Spacer()
        }
        .onAppear {
            // TODO: jednom ovdje možeš napraviti pravi ping na server itd.
            simulateChecks()
        }
    }

    // MARK: - Status red

    private func statusRow(
        icon: String,
        title: String,
        isOK: Bool,
        info: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 22)

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

    // MARK: - Demo provjere

    private func simulateChecks() {
        // za sada samo fake animacija – kasnije spojiš na pravi RelayClient itd
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { isServerConnected = true }
        }
    }
}
