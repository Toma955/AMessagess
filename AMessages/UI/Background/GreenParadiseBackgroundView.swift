import SwiftUI

struct GreenParadiseBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.06, blue: 0.02),
                    Color(red: 0.00, green: 0.12, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color(red: 0.10, green: 0.80, blue: 0.40).opacity(0.6),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 350
            )
            .blendMode(.screen)
            .blur(radius: 40)

            RadialGradient(
                colors: [
                    Color(red: 0.20, green: 0.95, blue: 0.50).opacity(0.50),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 450
            )
            .blendMode(.screen)
            .blur(radius: 40)

            RadialGradient(
                colors: [
                    Color(red: 0.05, green: 0.60, blue: 0.25).opacity(0.40),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .blendMode(.screen)
            .blur(radius: 40)
        }
        .ignoresSafeArea()
    }
}
