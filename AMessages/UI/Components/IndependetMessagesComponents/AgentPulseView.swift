// AgentPulseView
// Placeholder za animaciju "impulsa" poruke A→B. Za sada samo statičan prikaz.

import SwiftUI

struct AgentPulseView: View {
    var body: some View {
        Circle()
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 6, height: 6)
            )
    }
}
