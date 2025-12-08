// AgentStatusBadge
// Mala ikonica koja pokazuje osnovno stanje (onDevice / LAN / P2P + boja).

import SwiftUI

struct AgentStatusBadge: View {

    let diagnosis: IndependentMessagesDiagnosisResult

    private var iconName: String {
        switch diagnosis.topologyMode {
        case .onDevice: return "internaldrive"
        case .lan: return "point.3.filled.connected.trianglepath.dotted"
        case .p2pInternet: return "globe"
        }
    }

    private var color: Color {
        switch diagnosis.faultLocation {
        case .none:
            return .green
        case .localDevice, .localNetwork:
            return .orange
        case .internet, .remoteSide, .server:
            return .red
        }
    }

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(6)
            .background(
                Circle()
                    .fill(color.opacity(0.8))
            )
    }
}
