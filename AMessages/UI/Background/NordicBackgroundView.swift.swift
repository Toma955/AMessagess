import SwiftUI

struct NordicBackgroundView: View {
    var body: some View {
        ZStack {
            // noćno nebo
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.02, blue: 0.06),
                    Color(red: 0.00, green: 0.00, blue: 0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // zelena zavjesa
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.95, blue: 0.60).opacity(0.7),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            .blur(radius: 50)

            // plava
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.80, blue: 1.00).opacity(0.5),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            .blur(radius: 50)

            // ljubičasta
            LinearGradient(
                colors: [
                    Color(red: 0.60, green: 0.40, blue: 1.00).opacity(0.5),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            .blur(radius: 50)
        }
        .ignoresSafeArea()
    }
}
