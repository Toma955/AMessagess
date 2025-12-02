import SwiftUI

struct SettingsGeneralView: View {
    @EnvironmentObject var session: SessionManager
    @ObservedObject private var localization = Localization.shared   // ⇐ DODANO

    @Binding var themeSelection: AppThemeID
    @Binding var languageCode: String
    @Binding var soundEnabled: Bool
    @Binding var notificationsEnabled: Bool

    // Lokalne UX stvari (za sada samo UI, bez spajanja na logiku)
    @State private var windowsDisplayMode: Int = 0    // 0 = Prozor, 1 = Lista

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Općenito")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                // MARK: - Tema aplikacije
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tema aplikacije")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    ThemeSelectorHorizontal(selection: $themeSelection)

                    Text("Odaberi pozadinsku temu koja će se koristiti u svim prozorima aplikacije.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                // MARK: - Jezik sučelja
                VStack(alignment: .leading, spacing: 8) {
                    Text("Jezik sučelja")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Picker("", selection: $languageCode) {
                        Text("Hrvatski").tag("hr")
                        Text("English").tag("en")
                        Text("Deutsch").tag("de")
                        Text("Français").tag("fr")
                    }
                    .pickerStyle(.segmented)

                    Text("Promjena jezika primijenit će se na tekstove u aplikaciji.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                // MARK: - Zvučni efekti
                Toggle(isOn: $soundEnabled) {
                    Text("Zvučni efekti")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))

                Text("Uključi ili isključi zvukove za nove poruke i obavijesti.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))

                // MARK: - Obavijesti
                Toggle(isOn: $notificationsEnabled) {
                    Text("Sistemske obavijesti")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))

                Text("Ako je omogućeno, macOS može prikazivati obavijesti kada stignu nove poruke.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))

                // MARK: - Kontrole / UX opcije
                VStack(alignment: .leading, spacing: 10) {
                    Text("Kontrole aplikacije")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    // Focus mode – globalni flag u SessionManageru
                    Toggle(isOn: $session.focusModeEnabled) {
                        Text("Focus mode")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))

                    // Prikaži / sakrij Session ID polje u status baru
                    Toggle(isOn: $session.showSessionIdField) {
                        Text("Prikaži polje za Session ID")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))

                    // Lock gumb dolje u status baru
                    Toggle(isOn: $session.showLockButton) {
                        Text("Prikaži gumb za zaključavanje aplikacije")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))

                    // Quit gumb (power) – izlazak iz aplikacije
                    Toggle(isOn: $session.showQuitButton) {
                        Text("Prikaži gumb za izlazak iz aplikacije")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))

                    // Arhiva / povijest – gumb s povećalom + dock
                    Toggle(isOn: $session.showHistoryEntry) {
                        Text("Prikaži gumb za arhivu/povijest")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))

                    // Prikaz prozora – Prozor / Lista (za sada samo UI priprema)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prikaz prozora")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))

                        Picker("", selection: $windowsDisplayMode) {
                            Text("Prozor").tag(0)
                            Text("Lista").tag(1)
                        }
                        .pickerStyle(.segmented)

                        Text("Odaberi želiš li da se prozori prikazuju klasično ili kompaktnije kao lista. Ponašanje ćemo kasnije povezati s dockom i layoutom prozora.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text("Ove opcije upravljaju prikazom glavnih kontrola u statusnoj traci i docku (Session ID polje, lock, arhiva, izlaz iz aplikacije). Focus mode i prikaz prozora su za sada priprema – kasnije ćemo definirati konkretno ponašanje.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)
                }

                Spacer(minLength: 12)

                InfoBoxView(
                    title: "Savjet",
                    message: "Većinu postavki možeš prilagoditi bez ponovnog pokretanja. Sigurnosne opcije će se kasnije premjestiti u karticu Sigurnost."
                )
                .padding(.top, 8)
            }
            .padding(18)
        }
        // ⇩⇩⇩ OVO JE NOVO – SPOJ NA Localization
        .onAppear {
            // ako je binding prazan, povuci trenutno postavljeni jezik
            if languageCode.isEmpty {
                languageCode = localization.currentLanguage.rawValue
            } else if let lang = ApplicationLanguage(rawValue: languageCode) {
                localization.setLanguage(lang)
            }
        }
        .onChange(of: languageCode) { newValue in
            if let lang = ApplicationLanguage(rawValue: newValue) {
                localization.setLanguage(lang)
            }
        }
    }
}

// MARK: - Horizontalni selector za teme



struct ThemePreviewCard: View {
    let themeId: AppThemeID
    let isSelected: Bool

    private var borderColor: Color {
        isSelected
        ? Color(red: 0.0, green: 0.95, blue: 0.45)
        : Color.white.opacity(0.25)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.85))

                ThemePreviewBackground(themeId: themeId)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(4)
            }
            .frame(width: 130, height: 80)

            Text(themeId.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.horizontal, 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: isSelected ? 2.0 : 1.0)
        )
        .shadow(
            color: Color.black.opacity(isSelected ? 0.9 : 0.5),
            radius: isSelected ? 16 : 10,
            x: 0,
            y: 10
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }
}

struct ThemePreviewBackground: View {
    let themeId: AppThemeID

    var body: some View {
        Group {
            switch themeId {
            case .onlineGreen:
                BackgroundView()
            case .oceanBlue:
                OceanBackgroundView()
            case .violetNight:
                NordicBackgroundView()
            case .goldenSunset:
                OrientBackgroundView()
            case .warmOrange:
                GreenParadiseBackgroundView()
            case .alertRed:
                NebulaBackgroundView()
            case .pureBlack:
                Color.black
            case .pureWhite:
                Color.white
            }
        }
        .drawingGroup()
    }
}

// MARK: - Info box

struct InfoBoxView: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.yellow.opacity(0.9))
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
