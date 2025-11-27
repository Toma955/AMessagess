import SwiftUI

struct SettingsAboutView: View {
    let appVersion: String
    let buildNumber: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("O aplikaciji")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AMessages")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("Sigurna komunikacija bez pohrane razgovora u cloudu.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Verzija: \(appVersion) (\(buildNumber))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Autor: Toma Babić")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }

                Divider().background(Color.white.opacity(0.15))

                Text("AMessages je dizajniran kao alat za end-to-end enkriptiranu komunikaciju, "
                     + "bez trajnog spremanja razgovora na server. Ključ i datoteka su jedino što omogućuje dekripciju podataka.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
    }
}
