import SwiftUI

struct MessagesQuickSettingsBar: View {
    @Binding var messageTextScale: CGFloat
    @Binding var sendOnEnter: Bool
    @Binding var soundEnabled: Bool
    @Binding var notificationsEnabled: Bool

    /// Preostalo vrijeme (u sekundama) do isteka 15 min od zadnje poruke
    let remainingSeconds: Int

    let onSaveConversation: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // A mali
            Button {
                messageTextScale = max(0.8, messageTextScale - 0.1)
            } label: {
                Text("A")
                    .font(.system(size: 11, weight: .regular))
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            // A veliki
            Button {
                messageTextScale = min(1.6, messageTextScale + 0.1)
            } label: {
                Text("A")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 18)
                .background(Color.white.opacity(0.25))

            // Enter šalje – samo ikona, kapsula, zelena kad je ON
            Button {
                sendOnEnter.toggle()
            } label: {
                Image(systemName: "return")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                sendOnEnter
                                ? Color.green
                                : Color.white.opacity(0.14)
                            )
                    )
                    .foregroundColor(sendOnEnter ? .white : .white.opacity(0.9))
            }
            .buttonStyle(.plain)

            Spacer()

            // Zvuk – samo ikona
            Button {
                soundEnabled.toggle()
                print("🔊 [SOUND] soundEnabled =", soundEnabled)
            } label: {
                Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(
                                soundEnabled
                                ? Color.white.opacity(0.95)
                                : Color.white.opacity(0.14)
                            )
                    )
                    .foregroundColor(soundEnabled ? .black : .white.opacity(0.9))
            }
            .buttonStyle(.plain)

            // Notifikacije – samo ikona
            Button {
                notificationsEnabled.toggle()
                print("🔔 [NOTIF] notificationsEnabled =", notificationsEnabled)
            } label: {
                Image(systemName: notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(
                                notificationsEnabled
                                ? Color.white.opacity(0.95)
                                : Color.white.opacity(0.14)
                            )
                    )
                    .foregroundColor(notificationsEnabled ? .black : .white.opacity(0.9))
            }
            .buttonStyle(.plain)

            // Spremi – samo disk ikona, kapsula
            Button(action: {
                print("💾 [SAVE] Ručno spremanje iz quick settings bara.")
                onSaveConversation()
            }) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.95))
                    )
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)

            // TIMER 15:00 → 00:00, kapsula, boja od zelene prema crvenoj
            let minutes = max(0, remainingSeconds) / 60
            let seconds = max(0, remainingSeconds) % 60
            let timeText = String(format: "%02d:%02d", minutes, seconds)

            let progress = max(0.0, min(1.0, Double(remainingSeconds) / Double(15 * 60)))
            // progress 1.0 = full zeleno, 0.0 = crveno
            let r = 0.2 + (0.9 - 0.2) * (1.0 - progress)
            let g = 0.8 + (0.2 - 0.8) * (1.0 - progress)
            let b = 0.3 + (0.2 - 0.3) * (1.0 - progress)
            let timerColor = Color(red: r, green: g, blue: b)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .medium))
                Text(timeText)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(timerColor)
            )
            .foregroundColor(.white)
        }
    }
}
