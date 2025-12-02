import SwiftUI

/// Prozor za "Neovisne poruke" / serverless.
/// Za sada je placeholder – kasnije unutra ubacujemo ConnectionAgentView + sve kao MessengerWindow.
struct IndependentMessagesWindow: View {
    var body: some View {
        ZStack {
            // lagana pozadina da ne bude prazno
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Neovisne poruke")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("Ovdje će doći serverless / agent sučelje (isti layout kao Messenger, plus ConnectionAgentView).")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .padding(16)
        }
    }
}
