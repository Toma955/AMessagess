import SwiftUI

struct SettingsSecurityView: View {
    @EnvironmentObject var session: SessionManager

    @Binding var autoLockSelection: Int
    let autoLockOptions: [Int]
    @Binding var panicRequiresPin: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Sigurnost")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Automatsko zaključavanje")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text("Nakon koliko neaktivnosti se sesija zaključava i briše ključ iz memorije.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))

                    Picker("", selection: $autoLockSelection) {
                        ForEach(autoLockOptions, id: \.self) { value in
                            if value == 0 {
                                Text("Isključeno").tag(0)
                            } else {
                                Text("\(value) min").tag(value)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider().background(Color.white.opacity(0.15))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Panic lock")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Toggle(isOn: $panicRequiresPin) {
                        Text("Za panic lock traži PIN prije brisanja ključeva")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))

                    Text("Panic lock će u budućnosti trenutačno zatvoriti sve prozore i obrisati ključeve iz memorije. "
                         + "Ova opcija dodaje dodatnu potvrdu prije takve akcije.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(18)
        }
    }
}
