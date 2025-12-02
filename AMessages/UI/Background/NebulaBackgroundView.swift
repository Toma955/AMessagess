import SwiftUI

struct NebulaBackgroundView: View {
    var body: some View {
        ZStack {
            // osnovna tamna pozadina
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.01, blue: 0.05),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // ljubičasti oblak
            RadialGradient(
                colors: [
                    Color(red: 0.80, green: 0.40, blue: 1.00).opacity(0.60),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )
            .blendMode(.screen)
            .blur(radius: 50)

            // plavi oblak
            RadialGradient(
                colors: [
                    Color(red: 0.40, green: 0.80, blue: 1.00).opacity(0.50),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 450
            )
            .blendMode(.screen)
            .blur(radius: 50)

            // crveno-žuti sjaj
            RadialGradient(
                colors: [
                    Color(red: 1.00, green: 0.60, blue: 0.60).opacity(0.40),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 520
            )
            .blendMode(.screen)
            .blur(radius: 50)
        }
        .ignoresSafeArea()
    }
}
