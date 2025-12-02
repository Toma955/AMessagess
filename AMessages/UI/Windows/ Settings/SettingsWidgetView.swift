import SwiftUI

struct SettingsWidgetView: View {
    @EnvironmentObject var session: SessionManager

    // PORUKE – detaljne postavke
    @State private var msgSendOnEnter: Bool = false
    @State private var msgSoundEnabled: Bool = true
    @State private var msgNotificationsEnabled: Bool = true
    @State private var msgTextScale: Double = 1.0      // 1.0 = normalno
    @State private var msgThemeIndex: Int = 0          // 0…5 kao u Messages

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Widgeti")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                // PORUKE – posebne postavke (vezano na session.showMessagesEntry)
                MessagesWidgetSectionView(
                    enabled: $session.showMessagesEntry,
                    sendOnEnter: $msgSendOnEnter,
                    soundEnabled: $msgSoundEnabled,
                    notificationsEnabled: $msgNotificationsEnabled,
                    textScale: $msgTextScale,
                    themeIndex: $msgThemeIndex
                )

                // NEOVISNE PORUKE
                GenericWidgetSectionView(
                    title: "Neovisne poruke",
                    description: "Widget za brzi uvid u poruke koji radi neovisno o glavnom prozoru.",
                    enabled: $session.showIndependentMessagesEntry
                )

                // BILJEŠKE
                GenericWidgetSectionView(
                    title: "Bilješke",
                    description: "Brzi pristup zadnjim bilješkama i označenim zapisima.",
                    enabled: $session.showNotesEntry
                )

                // ARHIVA (koristi showHistoryEntry)
                GenericWidgetSectionView(
                    title: "Arhiva",
                    description: "Widget za pregled arhiviranih razgovora i zapisa.",
                    enabled: $session.showHistoryEntry
                )
            }
            .padding(18)
        }
    }
}

// MARK: - PORUKE – sekcija (toggle + opis)

struct MessagesWidgetSectionView: View {
    @Binding var enabled: Bool
    @Binding var sendOnEnter: Bool
    @Binding var soundEnabled: Bool
    @Binding var notificationsEnabled: Bool
    @Binding var textScale: Double
    @Binding var themeIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $enabled) {
                Text("Poruke")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))

            Text("Widget za glavni razgovor – povezan s prozorom poruka (Enter za slanje, tema, zvukovi…).")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            if enabled {
                MessagesWidgetSettingsContentView(
                    sendOnEnter: $sendOnEnter,
                    soundEnabled: $soundEnabled,
                    notificationsEnabled: $notificationsEnabled,
                    textScale: $textScale,
                    themeIndex: $themeIndex
                )
            } else {
                Text("Widget je trenutno isključen.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - PORUKE – detaljne postavke (izvučeno u poseban view)

struct MessagesWidgetSettingsContentView: View {
    @Binding var sendOnEnter: Bool
    @Binding var soundEnabled: Bool
    @Binding var notificationsEnabled: Bool
    @Binding var textScale: Double
    @Binding var themeIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Osnovne postavke")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            sendOnEnterToggle
            soundToggle
            notificationsToggle
            themePicker
            textSizeSlider
            footerHint
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var sendOnEnterToggle: some View {
        Toggle(isOn: $sendOnEnter) {
            Text("Slanje poruke tipkom Enter")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
        }
        .toggleStyle(SwitchToggleStyle(tint: .red))
    }

    private var soundToggle: some View {
        Toggle(isOn: $soundEnabled) {
            Text("Zvukovi za nove poruke")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
        }
        .toggleStyle(SwitchToggleStyle(tint: .red))
    }

    private var notificationsToggle: some View {
        Toggle(isOn: $notificationsEnabled) {
            Text("Obavijesti za nove poruke")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
        }
        .toggleStyle(SwitchToggleStyle(tint: .red))
    }

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tema pozadine razgovora")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            Picker("", selection: $themeIndex) {
                Text("Ultra prozirna").tag(0)
                Text("Prozirna").tag(1)
                Text("Tamna").tag(2)
                Text("Midnight plava").tag(3)
                Text("Zelena").tag(4)
                Text("Ljubičasta").tag(5)
            }
            .pickerStyle(.segmented)
        }
    }

    private var textSizeSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Veličina teksta poruka")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            Slider(value: $textScale, in: 0.8...1.4, step: 0.05) {
                Text("Veličina teksta")
            }

            Text(String(format: "Trenutno: %.0f%%", textScale * 100))
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var footerHint: some View {
        Text("Ove postavke zamjenjuju Quick Settings traku iznad razgovora (Enter, tema, zvukovi, veličina teksta).")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.6))
            .padding(.top, 4)
    }
}

// MARK: - Generička sekcija za ostale widgete

struct GenericWidgetSectionView: View {
    let title: String
    let description: String
    @Binding var enabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $enabled) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))

            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            if enabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Osnovne postavke")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Ovdje ćeš moći prilagoditi izgled i ponašanje ovog widgeta (pozicija, veličina, sadržaj…).")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
            } else {
                Text("Widget je trenutno isključen.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
