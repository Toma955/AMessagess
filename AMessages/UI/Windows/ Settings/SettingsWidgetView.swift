import SwiftUI

struct SettingsWidgetView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Widgeti")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                Toggle(isOn: $session.islandEnabled) {
                    Text("Prikaži Island (AMessages ID widget)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))

                Toggle(isOn: $session.dockEnabled) {
                    Text("Prikaži Dock s prozorima (Glass dock)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Intenzitet pozadinske animacije")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Slider(value: $session.backgroundAnimationIntensity,
                           in: 0.3...1.5,
                           step: 0.1) {
                        Text("Intenzitet")
                    }
                    Text("Niži intenzitet = mirnija pozadina, viši = dinamičniji lava efekt.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(18)
        }
    }
}
